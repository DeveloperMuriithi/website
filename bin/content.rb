#!/usr/bin/env ruby

require 'date'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
DRAFT_ROOT = File.join(ROOT, '_drafts')

def fail_usage!
  warn <<~USAGE
    Usage:
      ruby bin/content.rb new note "Title"
      ruby bin/content.rb new project "Title"
      ruby bin/content.rb publish note slug
      ruby bin/content.rb publish project slug

    Notes and projects start in _drafts/ and are not included in the website.
  USAGE
  exit 2
end

def slugify(title)
  title.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
end

def new_entry(type, title)
  fail_usage! unless %w[note project].include?(type) && title && !title.strip.empty?

  slug = slugify(title)
  abort 'Title must contain at least one letter or number.' if slug.empty?

  folder = type == 'note' ? 'notes' : 'projects'
  path = File.join(DRAFT_ROOT, folder, "#{slug}.md")
  abort "Draft already exists: #{path.delete_prefix(ROOT + '/')}." if File.exist?(path)

  FileUtils.mkdir_p(File.dirname(path))
  body = if type == 'note'
    "# #{title.strip}\n\n#{Date.today}\n\n## What I was looking into\n\nWrite down the question or problem that started this investigation.\n\n## What I found\n\nAdd observations, commands, code, and evidence as useful.\n\n## Takeaway\n\nSummarize what changed or what remains unknown.\n"
  else
    "# #{title.strip}\n\nStatus: in progress\n\n## Why\n\nWhat prompted this experiment?\n\n## Approach\n\nDescribe the parts you built and the choices you made.\n\n## What I learned\n\nRecord problems, results, and anything still unresolved.\n"
  end
  File.write(path, body)
  puts "Created #{path.delete_prefix(ROOT + '/')}. Edit it, then publish with:"
  puts "  ruby bin/content.rb publish #{type} #{slug}"
end

def publish_entry(type, slug)
  fail_usage! unless %w[note project].include?(type) && slug && slug.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)

  draft_folder = type == 'note' ? 'notes' : 'projects'
  draft = File.join(DRAFT_ROOT, draft_folder, "#{slug}.md")
  destination = if type == 'note'
    File.join(ROOT, 'posts', "#{slug}.md")
  else
    File.join(ROOT, 'pages', 'projects', "#{slug}.md")
  end
  abort "Draft not found: #{draft.delete_prefix(ROOT + '/')}." unless File.file?(draft)
  abort "Published file already exists: #{destination.delete_prefix(ROOT + '/')}." if File.exist?(destination)

  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.mv(draft, destination)
  if type == 'project'
    index = File.join(ROOT, 'pages', 'projects.md')
    content = File.read(index, encoding: 'UTF-8')
    project_title = File.readlines(destination, encoding: 'UTF-8').first.to_s.sub(/\A#\s*/, '').strip
    project_title = project_title.gsub(/[\\\[\]]/) { |character| "\\#{character}" }
    content.sub!(/\nThere are no project write-ups here yet\..*\z/m, "\n")
    content << "\n* [#{project_title}](/projects/#{slug})\n"
    File.write(index, content)
  end
  puts "Published to #{destination.delete_prefix(ROOT + '/')}. Run `make build` to preview."
end

command, type, value = ARGV
case command
when 'new'
  new_entry(type, ARGV.drop(2).join(' '))
when 'publish'
  publish_entry(type, value)
else
  fail_usage!
end
