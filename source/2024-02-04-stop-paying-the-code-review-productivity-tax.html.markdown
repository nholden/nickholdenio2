---
title: 'Stop paying the code-review productivity tax'
---

Code review is a powerful tool. As a code author, it’s an opportunity to package your messy ideas into coherent thoughts. As a reviewer, it’s your chance to bring a fresh set of eyes and get caught up on the details of what your teammates have been thinking about.

Reviews come with tradeoffs — context switching is hard and imposes a real productivity tax. But there are some easy ways to reduce that productivity tax.

## Prioritize unblocking others

Give reviews quickly. Nothing’s worse than having lots of energy around your work and then waiting a day or more for code review.

Find natural breaking points throughout your day to check your GitHub notifications and review open pull requests. Starting your day with a cup of coffee and a code review is a great way to warm up your brain and unblock your coworkers. After lunch, or after a meeting, or after taking the dog for a walk are great times to check in on open PRs.

## Trust code authors’ judgment

Think of your feedback in a couple of buckets — blocking and non-blocking. Sometimes you’ll notice changes that will break critical paths for your users. Call those out, and make it clear that they need to be resolved before merging the change.

Most feedback should be non-blocking. Maybe there’s a slightly more performant way to do something, or there’s an edge case that’s worth considering but probably won’t pop up immediately. Call those out, too, but do so with an approval. Let the author decide what makes sense to implement now or save for the future to keep things moving.

## Automate

Never spend time on code style in a code review. It’s a waste of time for you and the author. Rely on linters, like Prettier and Rubocop, to catch style issues in CI. Configure your code editor to style code on save, and if your team uses VS Code, codify that in workspace settings. If you see style in code review that you feel strongly about, it’s your responsibility to open a PR to update your linters.

Automate beyond style, too. If you find yourself regularly suggesting changes about debugging breakpoints or other development artifacts that sneak their way into PRs, add linter rules around those. Have CI make commits directly to PRs with tools to make easily fixable changes. With GitHub Actions, [git-auto-commit-action](https://github.com/stefanzweifel/git-auto-commit-action){:target="_blank"} makes that simple.

## Keep process low

Don’t add any rules to your code review process until you absolutely need them. By default, anyone should be able to approve a PR. When you have an idea of perfect reviewers who have just the right context, request them directly to avoid drive-by reviews.

Consider an approval valid forever, even if an author makes additional changes after the approval. If the author makes significant changes that, in their judgment, warrant another review, it’s their responsibility to request another review.

## Keep PRs small

Break big problems into small changes. Use feature flags to ship small parts of large features into production frequently.

Open PRs for tiny vertical slices. Let’s say you’re adding “widgets” to your application. A PR that’s all of the backend controller actions needed to support all CRUD operations on widgets is hard to review. Instead, start with a PR that introduces a blank page and a new URL behind a feature flag. Later, open another PR that displays some widgets on that page.

## Keep reviews light

It’s a code author’s responsibility to make sure that their code works. As a reviewer, don’t feel responsible for catching every bug that could sneak into a PR. Call out things you notice, and try not to get too hung up on any one part of a change.

As an author, use the PR description field to make reviews easy. Call out the parts of the change that you’d like reviewers to focus on. If your PR includes significant UI changes, include screenshots or video recordings. Link off to documentation about APIs you’re leveraging.

Ultimately, the author and reviewer share the responsibility for reducing the productivity tax and getting the awesome benefits of a quality review.