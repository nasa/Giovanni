IMAGE_DIR = $(PREFIX)/www/img
IMAGE_FILES = \
  clock_trans.png \
  closed.png \
  delete.png \
  favicon.ico \
  giovanni_icons.png \
  green_map_marker.png \
  loading.gif \
  mapserver.gif \
  nasa-logo-png-transparent-4.png \
  nco.gif \
  open.png \
  openlayers.gif \
  progress.gif \
  updownArrows.gif \
  inprogress.gif \
  yui_calbtn.gif

$(IMAGE_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi 

$(IMAGE_DIR)/%.jpg: %.jpg $(IMAGE_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(IMAGE_DIR)/%.gif: %.gif $(IMAGE_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(IMAGE_DIR)/%.png: %.png $(IMAGE_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(IMAGE_DIR)/%.ico: %.ico $(IMAGE_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

install: ${IMAGE_FILES:%=${IMAGE_DIR}/%}
