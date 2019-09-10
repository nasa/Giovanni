HTML_DIR = $(PREFIX)/www/xsl
HTML_XSL_FILES = DataVariableFilters.xsl GiovanniResponse.xsl NoScriptPlotSel.xsl NoScriptVarSel.xsl NoScriptOption.xsl Plot.xsl NoScriptVar2Sel.xsl VerticalOption.xsl Plot.xsl GiovanniResponse.xsl




$(HTML_DIR)/%.xsl: %.xsl $(HTML_DIR) Makefile
	install $< $(HTML_DIR)
	if [ -O $@ ]; then chmod 664 $@; fi


install: ${HTML_XSL_FILES:%=${HTML_DIR}/%} ${XSL_FILES:%=${HTML_DIR}/%}

$(HTML_DIR):
	mkdir -p  $(HTML_DIR)

