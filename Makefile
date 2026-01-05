install:
	bundle install

build:
	bundle exec jekyll build

serve:
	bundle exec jekyll serve -H 0.0.0.0 -I --watch
