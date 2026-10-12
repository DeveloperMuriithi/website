RUBY ?= $(shell rbenv which ruby 2>/dev/null || command -v ruby)

build:
	rm -rf build && mkdir build
	$(RUBY) wruby.rb

clean:
	rm -rf build/*

watch:
	$(RUBY) bin/watch-build.rb

.PHONY: build clean watch
