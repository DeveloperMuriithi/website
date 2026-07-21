# wruby

* Minimal blog and static site generator built with Ruby
* Licensed under [MIT](https://choosealicense.com/licenses/mit/)
* The "w" is silent...

## Setup

1. `gem install bundler`
2. `bundle install`

## Getting Started

Make your changes in the main configuration file `_config.yml` file (site URL, your name,
etc.).

* Blog posts go under the `posts` directory as markdown files
* Posts need to be structured with an `h1` on the first line, a space on the second, and the date on the third line (ie. 2024-07-20)
* Pages go under the `pages` directory as markdown files
* Media (images, videos etc) go in the root `public` directory
* Main styling is found in `public/style.css` (feel free to get creative!)

## Defaults

* The homepage only displays the first `5` posts. You can configure this in `_config.yml` under `post_count`.
* The full blog post index will be generated at `yoursite.com/posts`
* This means you need to have a `posts.md` file in your `pages` directory (or change `posts_index` the core `_config.yml`)
* Your generated files can be compressed by default by setting the `compress_site` to `true`

## Running

1. `wruby` is based off of Ruby 3.3.8 (use `rbenv` or `rvm` to avoid privilege conflicts)
2. Install bundler: `gem install bundler`
3. Install gems: `bundle install`
4. Run `make build` in the root directory
5. Upload `build` folder to your server
6. Share your blog or site!