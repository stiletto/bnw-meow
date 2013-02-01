STATIC = dist/static
STATIC_P = deb_dist/srv/bnw-meow/static
REVISION = $(shell git rev-parse --short HEAD)
.PHONY: coffee

all: index coffee eco

# Install basic deps what you will need for building (or developing)
install-deps:
	sudo apt-get install npm gpp
	# Also needed for watch script:
	# sudo apt-get install inotify-tools
	sudo npm install -g coffee-script
	npm install eco requirejs

index:
	gpp -H -DVERSION=dev -o dist/index.html templates/index.gpp

index-product:
	gpp -H -DVERSION="$(REVISION)" -DPRODUCT -o "$(STATIC_P)/../index.html" \
		templates/index.gpp

coffee:
	coffee -o "$(STATIC)/js/" -bc coffee/

eco:
	-mkdir "$(STATIC)/js/templates/"
	bash -c 'ls templates/*.eco | while read file; do\
		tmp="`basename "$$file"`";\
		dest="$(STATIC)/js/templates/$${tmp/\.eco/.js}";\
		./eco.js "$$file" "$$dest";\
	done'

watch: all
	./watch.sh

pre-deb:
	rm -rf deb_dist/ *.deb
	cp -r deb/ deb_dist/
	find deb_dist/ -name '.*.swp' -delete
	mkdir -p "$(STATIC_P)/css/" "$(STATIC_P)/js/"
	cp -r "$(STATIC)/img/" "$(STATIC_P)"

minify:
	cat $(STATIC)/css/*.css > "$(STATIC_P)/css/default.css"
	./minify.js
	sed "s/^VERSION =.*/VERSION = '$(REVISION)';/" \
		"$(STATIC)/js/load_product.js" >> "$(STATIC_P)/js/meow.js"

deb: pre-deb index-product coffee eco minify
	dpkg -b deb_dist/ bnw-meow.deb

clean:
	rm -rf deb_dist/
	# Clean all compiled js files
	find $(STATIC)/js/ -mindepth 1 -maxdepth 1 ! -path '*/vendor' \
		-exec rm -r '{}' \;
