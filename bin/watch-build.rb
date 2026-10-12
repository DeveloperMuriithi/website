#!/usr/bin/env ruby

require 'digest'
require 'rbconfig'

ROOT = File.expand_path('..', __dir__)
WATCH_PATHS = %w[_config.yml index.md Makefile wruby.rb _includes pages posts public]

def fingerprint
  files = WATCH_PATHS.flat_map do |entry|
    path = File.join(ROOT, entry)
    if File.file?(path)
      [path]
    elsif File.directory?(path)
      Dir.glob(File.join(path, '**', '*'), File::FNM_DOTMATCH).select { |child| File.file?(child) }
    else
      []
    end
  end.uniq.sort

  digest = Digest::SHA256.new
  files.each do |path|
    digest << path.delete_prefix(ROOT)
    digest << File.binread(path)
  end
  digest.hexdigest
end

puts 'Watching Markdown, templates, styles, and wruby.rb. Press Ctrl-C to stop.'
previous = nil
begin
  loop do
    current = fingerprint
    if current != previous
      puts(previous ? 'Changes detected; rebuilding…' : 'Building…')
      success = system('make', 'build', chdir: ROOT)
      puts 'Build failed. Fix the reported error; the watcher will retry after the next file change.' unless success
      previous = current
    end
    sleep 1
  end
rescue Interrupt
  puts "\nWatcher stopped."
end
