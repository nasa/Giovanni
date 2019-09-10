JS_DIR = $(PREFIX)/www/js

$(JS_DIR):
	if [ ! -d $@ ]; then mkdir -p $@; fi; chmod 755 $@;

APP_FILES = \
        History.js \
        Login.js \
        Result.js \
        Session.js \
        SessionManager.js

WIDGET_FILES = \
        BoundingBoxPicker.js \
        Calendar.js \
        DatePicker.js \
        DateRangePicker.js \
        Facet.js \
        FacetedResult.js \
        FacetedSelector.js \
  InteractiveTimeSeries.js \
        MapAnimation.js \
        MapDisplay.js \
        OverlayMap.js \
        PaletteSelection.js \
        Services.js \
        ScatterPlot.js \
        SeasonalDatePicker.js \
        StaticPlot.js \
  TableView.js \
        Toolbar.js \
        ValidationResponse.js \
        VariablePicker.js \
        VerticalProfile.js \
        Splash.js \

UI_FILES = \
        DataSelector.js \
        HistoryView.js \
        ResultView.js \
        Workspace.js \
        Panel.js \
        MessageBoard.js \
        ServicesFilter.js

UTIL_FILES = \
        DateTime.js \
        Registry.js \
        BrowserCompatibilityCheck.js \
        data_accessor.js


MIN_FILES = \
	namespace.js \
	util.js \
	footer.js \
	History.js \
	Login.js \
	Result.js \
	Session.js \
	SessionManager.js \
	Panel.js \
	DataSelector.js \
	HistoryView.js \
	ResultView.js \
	Toolbar.js \
	Workspace.js \
	Registry.js \
	ValidationResponse.js \
	Services.js \
	ServicesFilter.js\
	DatePicker.js \
	DateRangePicker.js \
	SeasonalDatePicker.js \
	Calendar.js \
	StaticPlot.js \
	DateTime.js \
	BoundingBoxPicker.js \
	MapDisplay.js \
	VariablePicker.js \
	BrowserCompatibilityCheck.js \
	data_accessor.js \
	Facet.js \
	FacetedResult.js \
	FacetedSelector.js \
	MessageBoard.js \
	MapAnimation.js \
	PaletteSelection.js \
	ScatterPlot.js \
	VerticalProfile.js \
  InteractiveTimeSeries.js \
  TableView.js \
        OverlayMap.js \
        Splash.js \

OTHER_FILES = \
	jquery.collapsible.min.js \
	jscolor.min.js \
	highcharts.js \
	exporting.js \
	namespace.js \
	util.js \
        footer.js

MIN_DIR = $(JS_DIR)
WIDGET_DIR = $(JS_DIR)/widget
UI_DIR = $(JS_DIR)/ui
UTIL_DIR = $(JS_DIR)/util
OTHER_DIR = $(JS_DIR)
APP_DIR = $(JS_DIR)/app
MINAPP_FILES =     ${MIN_FILES:%=minapp-%}

# NON-MINIFIED FOR DEBUGGING by index_debug.html
$(APP_DIR)/%js: %js
	if [ ! -d $(APP_DIR) ]; then install -d $(APP_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

$(WIDGET_DIR)/%js: %js
	if [ ! -d $(WIDGET_DIR) ]; then install -d $(WIDGET_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

$(UI_DIR)/%js: %js
	if [ ! -d $(UI_DIR) ]; then install -d $(UI_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

$(UTIL_DIR)/%js: %js
	if [ ! -d $(UTIL_DIR) ]; then install -d $(UTIL_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

$(OTHER_DIR)/%js: %js
	if [ ! -d $(OTHER_DIR) ]; then install -d $(OTHER_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

$(JS_DIR)/%js: %.js
	if [ ! -d $@ ]; then install -d $@; fi
	install $< $@
	if [ -O $@ ]; then chmod 775 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<


# MINIFICATION:
$(OTHER_DIR)/%js: %js 
	if [ ! -d $(OTHER_DIR) ]; then install -d $(OTHER_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod 664 $@; fi
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

$(MINAPP_FILES): minapp-%: %
	java -jar ../yuicompressor-2.4.6.jar -o minapp-$< $<

${MIN_DIR}/giovanni4.min.js:  $(MINAPP_FILES) $(JS_DIR)
	cat $(MINAPP_FILES) > giovanni4.min.js
	install giovanni4.min.js $(MIN_DIR)

install: ${OTHER_FILES:%=${OTHER_DIR}/%}  ${APP_FILES:%=${APP_DIR}/%} ${WIDGET_FILES:%=${WIDGET_DIR}/%} ${UI_FILES:%=${UI_DIR}/%} ${UTIL_FILES:%=${UTIL_DIR}/%}  ${MIN_DIR}/giovanni4.min.js

test: ${OTHER_FILES:%=${OTHER_DIR}/%}
