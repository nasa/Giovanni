HTML_DIR = $(PREFIX)/www
CFG_DIR = $(PREFIX)/cfg
HTML_FILES = \
	index.html \
	index-debug.html \
	header.html \
	footer.html \
	regression-test.html \
	noscriptTemplate.html

$(HTML_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi

$(HTML_DIR)/%.html: %.html $(HTML_DIR) Makefile
	install $< $@

$(HTML_DIR)/test_index.html: $(HTML_DIR)/index.html $(HTML_DIR) Makefile
	perl createTestHtml.pl -f $< -o $@

$(HTML_DIR)/test_index_debug.html: $(HTML_DIR)/index-debug.html $(HTML_DIR) Makefile
	perl createTestHtml.pl -f $< -o $@

# Must use a relative link, otherwise during RPM generation the link
# will point to the temporary directory used to build giovanni4.
$(HTML_DIR)/giovanni_services.xml: $(CFG_DIR)/giovanni_services.xml $(HTML_DIR) Makefile
	ln -fs ../cfg/giovanni_services.xml $(HTML_DIR)/giovanni_services.xml

$(HTML_DIR)/giovanni-login-redirect: giovanni-login-redirect $(HTML_DIR) Makefile
	install $< $@

install: ${HTML_FILES:%=${HTML_DIR}/%} $(HTML_DIR)/giovanni-login-redirect $(HTML_DIR)/test_index.html $(HTML_DIR)/test_index_debug.html $(HTML_DIR)/giovanni_services.xml
