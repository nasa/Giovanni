SLD_DIR = $(PREFIX)/www/sld/fixed
SLD_FILES := $(shell ls *.xml)

$(SLD_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi

$(SLD_DIR)/%.xml: %.xml $(SLD_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

install: ${SLD_FILES:%=${SLD_DIR}/%}
