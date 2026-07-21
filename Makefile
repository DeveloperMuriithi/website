build:
	rm -rf build && mkdir build
	ruby wruby.rb 

clean:
	rm -rf build/*

.PHONY: build clean
