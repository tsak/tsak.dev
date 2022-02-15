.PHONY: write build publish clean

write:
	hugo server --disableFastRender --buildDrafts 

build:
	hugo --verbose

publish: build
	rsync --archive --progress ./public/ nuc:/home/htdocs/tsak.dev/

clean:
	rm -Rf ./resources/_gen ./public