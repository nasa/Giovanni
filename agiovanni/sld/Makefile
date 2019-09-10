SLD_DIR = $(PREFIX)/www/sld
SLD_FILES := $(shell ls *.xml)
PNG_FILES := $(shell ls *.png)
JSON_FILES := $(shell ls *.json)

$(SLD_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi

$(SLD_DIR)/%.xml: %.xml $(SLD_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(SLD_DIR)/%.png: %.png $(SLD_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

$(SLD_DIR)/%.json: %.json $(SLD_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi

fixed_sld_install:
	cd fixed_sld && $(MAKE) $(MAKEFLAGS) install 

install: ${SLD_FILES:%=${SLD_DIR}/%} fixed_sld_install

install_for_edda: ${PNG_FILES:%=${SLD_DIR}/%} ${JSON_FILES:%=${SLD_DIR}/%}
