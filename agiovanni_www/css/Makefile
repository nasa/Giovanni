WWW_DIR = $(PREFIX)/www
CSS_DIR = $(WWW_DIR)/css
DIRS    = $(CSS_DIR) $(WWW_DIR)
CSS_T   = giovann4_min.css
CSS_FILES = \
	noscript.css \
	DateBox.css \
	MapDisplay.css \
	giovanni.css \
	tableless_layout.css \
	Workspace.css \
	ScatterPlot.css \
	Services.css \
	HistoryView.css \
	MessageBoard.css \
	Map.css \
	MapAnimation.css \
	TableView.css \
	Splash.css  

MIN_FILES =  ${CSS_FILES:%=min-%}

$(DIRS):
	if [ ! -d $@ ]; then mkdir -p $@; fi; chmod 0755  $@;


$(MIN_FILES): min-%: %   
	echo $@ $<
	java -jar ../yuicompressor-2.4.6.jar -o min-$< $<
	cat min-$< >> giovanni4.min.css
 
${CSS_DIR}/giovanni4.min.css:   $(MIN_FILES)  $(DIRS)
	install giovanni4.min.css $(CSS_DIR)

$(CSS_DIR)/%.css: %.css $(CSS_DIR) Makefile
	install $< $(CSS_DIR)
	if [ -O $@ ]; then chmod 664 $@; fi

install: $(CSS_DIR)/giovanni4.min.css  ${CSS_FILES:%=${CSS_DIR}/%}  
 
