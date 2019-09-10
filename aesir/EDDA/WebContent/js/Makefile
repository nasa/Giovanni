CONTEXT_ROOT = $(PREFIX)/www/EDDA
JS_DIR = $(CONTEXT_ROOT)/js
JS_FILES = \
	edda.js \
	jquery.collapsible.min.js \
	jquery.dataTables.min.js

$(JS_DIR)/%.js: %.js
	if [ ! -d $(JS_DIR) ]; then install -m 775 -d $(JS_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

install: ${JS_FILES:%=${JS_DIR}/%}

test: ${JS_FILES:%=${JS_DIR}/%}
