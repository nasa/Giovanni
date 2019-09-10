BIN_DIR = $(PREFIX)/bin/AESIR
BIN_FILES = \
	post_aesir_solr.pl \
	updateDataProductEndDateTime.pl \
	import_aesir_variables.pl \
        compare2Aesirs.py

$(BIN_DIR)/%.pl: %.pl
	if [ ! -d $(BIN_DIR) ]; then install -m 775 -d $(BIN_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 775 $@; fi

$(BIN_DIR)/%.py: %.py
	if [ ! -d $(BIN_DIR) ]; then install -m 775 -d $(BIN_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 775 $@; fi

install: ${BIN_FILES:%=${BIN_DIR}/%}

test: ${BIN_FILES:%=${BIN_DIR}/%}
