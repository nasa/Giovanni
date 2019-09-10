CONTEXT_ROOT = $(PREFIX)/www/EDDA
CSS_DIR = $(CONTEXT_ROOT)/css

CSS_FILES = \
	demo_page.css \
	demo_table.css \
	edda.css \
	dataFieldsStatus.css

$(CSS_DIR)/%.css: %.css
	if [ ! -d $(CSS_DIR) ]; then install -m 775 -d $(CSS_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

install: ${CSS_FILES:%=${CSS_DIR}/%}

test: ${CSS_FILES:%=${CSS_DIR}/%}
