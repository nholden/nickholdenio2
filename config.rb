require "active_support/core_ext/array/conversions"

# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

# activate :autoprefixer do |prefix|
#   prefix.browsers = "last 2 versions"
# end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def ruby_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__ruby') { 'Ruby' }
  end

  def rails_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__rails') { 'Rails' }
  end

  def sinatra_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__sinatra') { 'Sinatra' }
  end

  def minitest_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__minitest') { 'Minitest' }
  end

  def rspec_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__rspec') { 'RSpec' }
  end

  def javascript_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__javascript') { 'JavaScript' }
  end

  def typescript_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__typescript') { 'TypeScript' }
  end

  def jest_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__jest') { 'Jest' }
  end

  def mocha_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__mocha') { 'Mocha' }
  end

  def vue_js_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__vue-js') { 'Vue.js' }
  end

  def react_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__react') { 'React' }
  end

  def rubygems_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__rubygems') { 'RubyGems' }
  end

  def documentation_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__documentation') { 'Documentation' }
  end

  def graphql_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__graphql') { 'GraphQL' }
  end

  def docker_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__docker') { 'Docker' }
  end

  def github_actions_tech_tag
    content_tag(:span, class: 'tech-tag tech-tag__github-actions') { 'GitHub Actions' }
  end

  def web_components_tech_tag 
    content_tag(:span, class: 'tech-tag tech-tag__web-components') { 'Web Components' }
  end

  def campsite_contribution_links
    return unless data.try(:campsite_contributions).try(:any?)

    links = data.campsite_contributions.first(3).map do |contribution|
      link_to(contribution.title, contribution.url, target: '_blank')
    end
    
    links.to_sentence
  end
end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end

# Live reload
# https://middlemanapp.com/basics/development-cycle/#livereload
activate :livereload
