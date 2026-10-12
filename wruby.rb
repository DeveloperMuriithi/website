require 'kramdown'
require 'fileutils'
require 'date'
require 'rss'
require 'find'
require 'yaml'
require 'cgi'
require 'zlib'

# Set proper encoding for reading file paths
def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

# Load configuration
config = YAML.safe_load_file('_config.yml')

site_url    = config['site_url']
site_name   = config['site_name']
author_name = config['author_name']

posts_dir        = config['directories']['posts']
pages_dir        = config['directories']['pages']
public_dir       = config['directories']['public']
output_dir       = config['directories']['output']
posts_output_dir = config['directories']['posts_output']
pages_output_dir = config['directories']['pages_output']

header_file      = config['files']['header']
footer_file      = config['files']['footer']
root_index_file  = config['files']['root_index']
posts_index_file = config['files']['posts_index']
rss_file         = config['files']['rss']

post_count    = config['misc']['post_count']
compress_site = config['misc']['compress_site']

# Make sure output directories exist
[output_dir, posts_output_dir, pages_output_dir].each { |dir| FileUtils.mkdir_p(dir) }

# Read the footer content
footer_content = read_utf8(footer_file)

# Replace the title meta tag in the header.html
def replace_title_placeholder(header_content, title)
  header_content.gsub('<title>{{TITLE}}</title>', "<title>#{CGI.escapeHTML(title)}</title>")
end

# Grab the title from each markdown file
def extract_title_from_md(lines)
  first_line = lines.first
  first_line&.start_with?('# ') ? first_line[2..-1].strip : 'Blog Index'
end

# Convert markdown files
def process_markdown_files(input_directory, output_directory, header_content, footer_content, require_dates: false)
  items = Dir.glob("#{input_directory}/**/*.md").map do |path|
    md_content = read_utf8(path)
    lines = md_content.lines

    title = extract_title_from_md(lines)
    if require_dates
      begin
        raw_date = lines[2]&.strip || ''
        raise Date::Error unless raw_date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

        date = Date.iso8601(raw_date)
      rescue Date::Error, ArgumentError
        raise ArgumentError, "Missing or invalid post date in #{path}; expected a date on line 3"
      end
    else
      date = Date.new(1970, 1, 1)
    end
    html_content = Kramdown::Document.new(md_content).to_html

    relative_path = path.sub("#{input_directory}/", '').sub('.md', '')
    item_dir = File.join(output_directory, relative_path)
    output_file = File.join(item_dir, 'index.html')
    FileUtils.mkdir_p(item_dir)

    header = replace_title_placeholder(header_content, title)
    File.write(output_file, header + html_content + footer_content)

    { title: title, date: date, link: "#{relative_path}/", content: html_content }
  end
end

# Create the root index file
def generate_index(posts, header_content, footer_content, root_index_file, post_count, output_dir, posts_dir)
  root_index_content = read_utf8(root_index_file)
  root_title = extract_title_from_md(root_index_content.lines)
  root_html = Kramdown::Document.new(root_index_content).to_html

  header = replace_title_placeholder(header_content, root_title)

  index_content = header + root_html
  unless posts.empty?
    index_content << "<h2>Recent notes</h2>\n"
    index_content << "<ul class=\"posts\">\n"
    posts.first(post_count).each { |post| index_content << post_list_item(post, posts_dir) }
    index_content << "</ul>\n"
  end
  index_content << footer_content

  File.write("#{output_dir}/index.html", index_content)
end

# Create the full posts list page
def generate_full_posts_list(posts, header_content, footer_content, posts_index_file, output_dir, posts_dir)
  posts_index_content = read_utf8(posts_index_file)
  posts_title = extract_title_from_md(posts_index_content.lines)
  posts_html = Kramdown::Document.new(posts_index_content).to_html

  header = replace_title_placeholder(header_content, posts_title)

  list_content = header + posts_html
  unless posts.empty?
    list_content << "<ul class=\"posts\">\n"
    posts.each { |post| list_content << post_list_item(post, posts_dir) }
    list_content << "</ul>\n"
  end
  list_content << footer_content

  File.write("#{output_dir}/posts/index.html", list_content)
end

def post_list_item(post, posts_dir)
  href = "/#{posts_dir}/#{post[:link]}".split('/').map { |part| CGI.escape(part).gsub('+', '%20') }.join('/')
  "<li><span>#{CGI.escapeHTML(post[:date].to_s)}</span><a href='#{CGI.escapeHTML(href)}'>#{CGI.escapeHTML(post[:title])}</a></li>\n"
end

# Generate the RSS 2.0 feed
def generate_rss(posts, rss_file, author_name, site_name, site_url, posts_dir)
  rss = RSS::Maker.make("2.0") do |maker|
    maker.channel.author      = author_name
    maker.channel.updated     = Time.now.to_s
    maker.channel.title       = "#{site_name} RSS Feed"
    maker.channel.description = "The official RSS Feed for #{site_url}"
    maker.channel.link        = site_url

    posts.each do |post|
      date = Date.parse(post[:date].to_s).to_time + 12*60*60 # Force time to midday
      item_link    = "#{site_url}/#{posts_dir}/#{post[:link]}"
      item_title   = post[:title]
      item_content = post[:content]

      maker.items.new_item do |item|
        item.link        = item_link
        item.title       = item_title
        item.updated     = date.to_s
        item.pubDate     = date.rfc822
        item.description = item_content
      end
    end
  end

  File.write(rss_file, rss)
end

def generate_sitemap(pages, posts, site_url, output_dir, posts_dir)
  urls = ["#{site_url}/"]
  pages.reject { |page| page[:link].start_with?('404/') }.each { |page| urls << "#{site_url}/#{page[:link]}" }
  posts.each { |post| urls << "#{site_url}/#{posts_dir}/#{post[:link]}" }
  entries = urls.uniq.map do |url|
    "  <url><loc>#{CGI.escapeHTML(url)}</loc></url>"
  end
  File.write(File.join(output_dir, 'sitemap.xml'), "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n#{entries.join("\n")}\n</urlset>\n")
  File.write(File.join(output_dir, 'robots.txt'), "User-agent: *\nAllow: /\n\nSitemap: #{site_url}/sitemap.xml\n")
end

# Process header, posts, pages, etc.
header_content = read_utf8(header_file)

posts = process_markdown_files(posts_dir, posts_output_dir, header_content, footer_content, require_dates: true).sort_by { |post| -post[:date].to_time.to_i }
pages = process_markdown_files(pages_dir, pages_output_dir, header_content, footer_content)

# Cloudflare Pages recognizes a top-level 404.html as the custom not-found page.
not_found_page = File.join(pages_output_dir, '404', 'index.html')
FileUtils.cp(not_found_page, File.join(output_dir, '404.html')) if File.file?(not_found_page)

generate_index(posts, header_content, footer_content, root_index_file, post_count, output_dir, posts_dir)
generate_full_posts_list(posts, header_content, footer_content, posts_index_file, output_dir, posts_dir)
generate_sitemap(pages, posts, site_url, output_dir, posts_dir)
FileUtils.cp_r(public_dir, output_dir)
generate_rss(posts, rss_file, author_name, site_name, site_url, posts_dir)
if compress_site == true
  Find.find(output_dir) do |path|
    next unless File.file?(path) && path.match?(/\.(html|css)\z/)

    File.open("#{path}.gz", 'wb') do |compressed|
      Zlib::GzipWriter.wrap(compressed) do |gzip|
        File.open(path, 'rb') do |source|
          while (chunk = source.read(16 * 1024))
            gzip.write(chunk)
          end
        end
      end
    end
  end
end

puts "Blog built successfully in '#{output_dir}' folder. Have a great day!"
