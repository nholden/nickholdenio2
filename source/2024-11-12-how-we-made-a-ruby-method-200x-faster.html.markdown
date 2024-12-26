---
title: 'How we made a Ruby method 200x faster'
---

One morning, Campsite was slow. Normally snappy interactions had loading spinners and delayed data.

Our observability tooling let us know it wasn’t just us, and it gave us some hints about what was happening.

- An [Axiom monitor](https://axiom.co/docs/monitor-data/monitors){:target="_blank"} sent us a “high API request queue time” message via [our Campsite integration](https://developers.campsite.com/){:target="_blank"}. Web server processes were fully utilized, and requests were forced to wait.
- [Fly.io metrics](https://fly.io/docs/monitoring/metrics/){:target="_blank"} showed HTTP response times were significantly elevated, but didn’t show an increase in traffic.
- [PlanetScale insights](https://planetscale.com/docs/concepts/query-insights){:target="_blank"} didn’t show any increase in database query latency.

The spikes in request queue times and response times lined up with a deploy, so with no better leads, we reverted the change, which had refactored how we transform rich text. Request queue times and response times returned to normal levels, and Campsite felt fast again.

## A refactor

Campsite stores lots of rich text, including in posts, comments, messages, and call summaries. We store that rich text as HTML.

Before the PR that introduced the performance regression, we had a single PlainText class responsible for transforming HTML into plain text. Simplified, it looked something like this:

~~~ruby
class PlainText
  def initialize(original)
    @parsed = Nokogiri::HTML.fragment(original)
  end

  def text
    process_node(@parsed).strip
  end

  private
  
  def process_node(node)
    case node.name
    when "#document-fragment"
      # ...
    when "text"
      # ...
    when "ol", "ul"
      # ...
    when "link-unfurl"
      # ...
    when "resource-mention"
      # ...
    when "br"
      # ...
    when "img", "table", "script", "figure", "figcaption", "tr", "td", "th", "thead", "tbody", "tfoot", "col", "colgroup", "details"
      # ...
    else
      # ...
    end
  end
end
~~~

This served us well, but it was a little messy. The large and growing case statement was smelly to us. We had a new requirement coming — along with transforming content to plain text, we needed to transform content to Markdown.

We decided to refactor this code to a more object-oriented solution.

~~~ruby
# lib/html_transform.rb
class HtmlTransform
  HANDLERS = [
    Text,
    List,
    ListItem,
    Code,
    # ...
  ].freeze

  def initialize(html)
    @html = html
  end

  attr_reader :html

  def plain_text
    @plain_text ||= document.plain_text
  end

  def markdown
    @markdown ||= document.markdown
  end

  private

  def document
    @document ||= Document.new(node: Nokogiri::HTML.fragment(html))
  end
end

# lib/html_transform/base.rb
class HtmlTransform
  class Base
    def initialize(node:)
      @node = node
    end

    attr_reader :node

    def handler(node)
      HANDLERS.find { |handler| node.matches?(handler.selector) } || HtmlTransform::Base
    end

    def children
      node.children.map do |child|
        handler(child).new(node: child)
      end
    end

    class << self
      attr_reader :selector

      def register_selector(selector)
        @selector = selector
      end
    end
  end
end

# lib/html_transform/code.rb
class HtmlTransform
  class Code < Base
    register_selector "code"

    def plain_text
      node.text
    end

    def markdown
      "`#{node.text}`"
    end
  end
end
~~~

In our new approach, we had more, smaller classes that each focused on transforming particular node types. It became straightforward to share code between plain text and markdown outputs.

Each node class called a `register_selector` method that accepted a CSS selector string defining which elements the class should transform. In the snippet above, the `HtmlTransform::Code` class transforms nodes matching the CSS selector `code`.

We updated our tests to run against the new approach. With them passing, we deployed the change. Immediately after, we saw the performance regression.

## Spelunking in flamegraphs

To figure out why the new code was slow, after the revert, we profiled it in development. We use [rack-mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler?tab=readme-ov-file){:target="_blank"} in development and production to profile Ruby code.

rack-mini-profiler works best out-of-the-box for traditional Rails applications that render HTML. Our Rails app primarily serves as an API for our client Next.js application, so it mostly renders JSON, but we still find rack-mini-profiler valuable. One way is with rack-mini-profiler’s [built-in route](https://github.com/MiniProfiler/rack-mini-profiler?tab=readme-ov-file#using-miniprofilers-built-in-route-for-apps-without-html-responses){:target="_blank"} that serves a blank page with a speed badge.

To debug this performance regression we started with [flamegraphs](https://github.com/MiniProfiler/rack-mini-profiler?tab=readme-ov-file#flamegraphs){:target="_blank"}, which rack-mini-profiler and [stackprof](https://github.com/tmm1/stackprof){:target="_blank"} generate.

We created a post with lots of elements in development. Then, we navigated to the GET post API endpoint and appended `?pp=flamegraph` to the URL. We clicked “left heavy” so that identical stacks would be grouped together and we could easily see which method calls were taking up the most time.

We searched for `HtmlTransform`, and we found a call to `plain_text` that took close to 200ms and 40% of the total request time.

![Flamegraph with a call to `plain_text` taking 187.49ms](/images/faster-ruby-method-1.png)

We sifted through the methods `HtmlTransform#plain_text` called. We figured our application code caused the performance regression, so we started looking for expensive methods that we explicitly called in our code.

The most suspicious calls were to `Nokogiri::XML::Node#matches?`. These were the calls furthest down the stack that we recognized from our code, and they accounted for nearly all of the time spent in `HtmlTransform#plain_text`.

![Flamegraph with many long calls to `Nokogiri::XML::Node#matches?](/images/faster-ruby-method-2.png)

This was a change between our original implementation and the refactor. In the original version, our case statement compared `node.name` to strings. In the new version, we passed CSS selectors to `node.matches?`.

## Removing suspicious method calls

To replace `node.matches?` in our refactored code, we introduced a new `HANDLERS_BY_NODE_NAMES` hash constant. Each key is a node name string and each value is a class inheriting from `HtmlTransform::Base`. Instead of calling `node.matches?` with a CSS selector, we look up `HANDLERS_BY_NODE_NAMES[node.name]`.

~~~ruby
# lib/html_transform.rb
class HtmlTransform
  HANDLERS_BY_NODE_NAMES = [
    Text,
    List,
    ListItem,
    Code,
    # ...
  ].each_with_object({}) do |handler, result|
    handler::NODE_NAMES.each { |node_name| result[node_name] = handler }
  end.freeze

  # ...
end

# lib/html_transform/base.rb
class HtmlTransform
  class Base
    # ...

    def handler(node)
      HANDLERS_BY_NODE_NAMES[node.name] || HtmlTransform::Base
    end

    # ...
  end
end

# lib/html_transform/code.rb
class HtmlTransform
  class Code < Base
    NODE_NAMES = ["code"].freeze

    # ...
  end
end
~~~

With the new code in place, the time spent in `plain_text` went from nearly 200ms and 40% of the total request time to under 1ms and less than 1% of the total request time.

![Flamegraph with a call to `plain_text` taking 0.96ms](/images/faster-ruby-method-3.png)

## Less work, faster code

Looking at [the source](https://github.com/sparklemotion/nokogiri/blob/e05b9949b794ca94b37a90f2fb2555d99a37daa5/lib/nokogiri/xml/node.rb#L1088-L1092){:target="_blank"}, when you call `Nokogiri::XML::Node#matches?`, Nokogiri…

- Generates a list of ancestors for this node
- Picks the last ancestor and searches it for all of the descendants matching the CSS selector
- Checks if this node is included in the searched descendants

As we learned, that can get expensive when you do it many times in a web request. In our case, we could skip all the traversal and searching and only consider the node’s `name`.

With the new version of the refactor deployed, we continued to see snappy interactions in Campsite. We had a great new foundation for transforming rich text, and we had a renewed appreciation for profiling and flamegraphs.