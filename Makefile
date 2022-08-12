.PHONY: write build compress publish clean

write:
	hugo server --disableFastRender --buildDrafts 

build:
	hugo --verbose

compress: build
	find ./public \( -name "*.html" -or -name "*.xml" -or -name "*.css" -or -name "*.js" \) -exec gzip --verbose --keep --force {} \;

publish: build compress
	rsync --archive --progress --delete ./public/ nuc:/home/htdocs/tsak.dev/

clean:
	rm -Rf ./resources/_gen ./public
