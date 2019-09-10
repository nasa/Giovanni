CONTEXT_ROOT = $(PREFIX)/www/EDDA
IMG_DIR = $(CONTEXT_ROOT)/images

IMG_FILES = \
	back_disabled.png \
	back_enabled.png \
	back_enabled_hover.png \
	closed.png \
	feedback.png \
	forward_disabled.png \
	forward_enabled.png \
	forward_enabled_hover.png \
	loader.gif \
	loader_small.gif \
	open.png \
	sort_asc.png \
	sort_asc_disabled.png \
	sort_both.png \
	sort_desc.png \
	sort_desc_disabled.png

$(IMG_DIR)/%.png: %.png
	if [ ! -d $(IMG_DIR) ]; then install -m 775 -d $(IMG_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(IMG_DIR)/%.gif: %.gif
	if [ ! -d $(IMG_DIR) ]; then install -m 775 -d $(IMG_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

install: ${IMG_FILES:%=${IMG_DIR}/%}

test: ${IMG_FILES:%=${IMG_DIR}/%}
