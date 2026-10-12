# Personal site built with wruby

This repository uses [wruby](https://sr.ht/~bt/wruby/), a small Ruby static-site builder. Markdown, shared HTML, and CSS are the source; wruby writes the deployable site to `build/`.

The builder code lives in `wruby.rb`. The site content and design live in `index.md`, `pages/`, `posts/`, `_includes/`, and `public/`. Keep edits to the site in those content and presentation files unless you are intentionally changing how wruby builds the site.

## Setup

1. `gem install bundler`
2. `bundle install`

## Site settings and design

Edit `_config.yml` for the canonical site URL, site title, author label, content paths, and build options. Shared page structure is in `_includes/header.html` and `_includes/footer.html`; visual styling is in `public/style.css`.

The shared UI keeps the collapsible glass navigation, the footer credit, and the color-dot theme control. The page follows system light/dark appearance until a theme is selected; a selected palette is saved in local storage across pages. Paper is the light palette, and Midnight is black with a green accent. Keep palette values in `public/style.css` and the shared controls in the includes.

## Write and publish content

Create a draft note or project with the helper. Drafts live under `_drafts/` and are not included in a build:

```sh
ruby bin/content.rb new note "A useful investigation"
ruby bin/content.rb new project "A small systems experiment"
```

Edit the generated Markdown file. When it is ready to appear on the site, publish it by using the slug printed by the helper:

```sh
ruby bin/content.rb publish note a-useful-investigation
ruby bin/content.rb publish project a-small-systems-experiment
```

Notes become `posts/<slug>.md`. They need a title on line 1, a blank line on line 2, and an ISO date (`YYYY-MM-DD`) on line 3. Projects become `pages/projects/<slug>.md`; the Projects index is updated automatically. Pages can also be edited directly in `pages/`. Images and other static assets belong in `public/`.

Publishing moves the file into wruby's input folders; it does not deploy anything. Review the page locally before committing and pushing.

## Build and preview

Install the gems once with `bundle install`, then build the static site:

```sh
make build
```

To keep rebuilding automatically while editing, run this in a terminal:

```sh
make watch
```

The watcher performs an initial build and rebuilds when content, templates, styles, configuration, or `wruby.rb` changes. Keep your local static server pointed at `build/` and refresh the browser to see updates. Stop the watcher with Ctrl-C. A normal `make build` is still available for one-off builds.

## Defaults

* The homepage only displays the first `5` posts. You can configure this in `_config.yml` under `post_count`.
* The full blog post index will be generated at `yoursite.com/posts`
* This means you need to have a `posts.md` file in your `pages` directory (or change `posts_index` the core `_config.yml`)
* Your generated files can be compressed by default by setting the `compress_site` to `true`

## Deploy

Cloudflare Pages is the production host. Connect this GitHub repository to a Pages project with `main` as the production branch, `bundle exec make build` as the build command, and `build` as the output directory. The root `.ruby-version` pins the build runtime to Ruby 3.3.8. Cloudflare Pages deploys pushes to `main` and creates preview deployments for pull requests and other branches.

GitHub Actions runs the same build on pushes and pull requests as a separate build check; it does not deploy the site. For local previews, use `make watch` and serve the generated `build/` directory.

wruby follows its upstream MIT license. The upstream project is at [sr.ht/~bt/wruby](https://sr.ht/~bt/wruby/); this repository contains local site-specific styling, content workflow helpers, and hardening in `wruby.rb`.
