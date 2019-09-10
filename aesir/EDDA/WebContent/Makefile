CONTEXT_ROOT = $(PREFIX)/www/EDDA
HTML_DIR = $(CONTEXT_ROOT)
HTML_FILES = \
	index.html \
	js.html \
	EDDA_help.html

XSD_FILES = \
	EDDA_dataField.xsd \
	EDDA_dataProduct.xsd

$(HTML_DIR)/%.html: %.html
	if [ ! -d $(HTML_DIR) ]; then install -m 775 -d $(HTML_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(HTML_DIR)/%.xsd: %.xsd
	if [ ! -d $(HTML_DIR) ]; then install -m 775 -d $(HTML_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

css: force_ok 
	cd css; make $(MFLAGS) PREFIX=$(PREFIX) install; cd ..

images: force_ok
	cd images; make $(MFLAGS) PREFIX=$(PREFIX) install; cd ..

js: force_ok
	cd js; make $(MFLAGS) PREFIX=$(PREFIX) install; cd ..

install: css images js ${HTML_FILES:%=${HTML_DIR}/%} ${XSD_FILES:%=${HTML_DIR}/%}

test: ${HTML_FILES:%=${HTML_DIR}/%}

force_ok:
	true

