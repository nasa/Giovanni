# $Id: Makefile,v 1.26 2015/08/24 21:17:48 kbryant Exp $

# Makefile for regression test scripts for the G4 GUI.

TEST_DIR = $(PREFIX)/www/js

TEST_SUPPORT = 	RegressionTest_Utilities.js

AUTOMATED_TESTS = \
	UI-AlertMessages-002.js \
	UI-ArAvTs-001.js \
	UI-BboxPicker-001.js \
	UI-BboxPicker-002.js \
	UI-BookmarkableUrl-001.js \
	UI-BrowserCompatibility-001.js \
	UI-CorrelationMap-001.js \
	UI-DataSelectionButtons-001.js \
	UI-DataSelectionButtons-002.js \
	UI-DatePicker-001.js \
	UI-DatePicker-009.js \
	UI-DatePicker-010.js \
	UI-DatePicker-012.js \
	UI-DatePicker-015.js \
	UI-DatePicker-016.js \
	UI-ServicePicker-001.js \
	UI-ServicePicker-002.js \
	UI-ServicePicker-003.js \
	UI-ServicePicker-004.js \
	UI-MaxPoints-001.js \
	UI-InteractiveScatter-001.js \
	UI-TimeAveragedScatterPlot-001.js \
	#UI-DatePicker-011.js \
		UI-DatePicker-013.js \
		UI-History-001.js \
		UI-History-005.js \
		UI-History-009.js \ #

START_INTERACTIVE_TESTS = \
	UI-StartInteractiveTests.js

INTERACTIVE_TESTS = \
	UI-ServicePicker-BBoxPicker-001.js \

TEST_FILES = \
	$(AUTOMATED_TESTS) \
  $(TEST_SUPPORT) \
#	$(START_INTERACTIVE_TESTS) \
	$(INTERACTIVE_TESTS) #

$(TEST_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi

$(TEST_DIR)/GiovanniRegressionTest.js: $(TEST_FILES) $(TEST_DIR) Makefile
	/bin/rm -f $@.tmp
	for file in $(TEST_FILES); do \
		/bin/cat $$file >> $@.tmp; \
	done
	/bin/mv $@.tmp $@

install: $(TEST_DIR)/GiovanniRegressionTest.js
