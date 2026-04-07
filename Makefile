.PHONY: dev clean build

dev:
	bundle exec jekyll serve --livereload --incremental --config _config.yml,_config.dev.yml

build:
	bundle exec jekyll build

clean:
	bundle exec jekyll clean
