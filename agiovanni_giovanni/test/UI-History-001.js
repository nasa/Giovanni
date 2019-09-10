/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-001
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-001",
         function() {

             // This URL links back to the test plan which describes
             // the individual tests. It is currently stored in Google
             // Docs.
             var TEST_PLAN_LINK = "https://docs.google.com/document/d/" +
                 "1ukml1Z7S-nrexNuJ5q7Il3FP5Jo8ECQXI8OIJoV11TE/edit#" +
                 "heading=h.7ohqtaw4cf0v";

             // The RegressionTest object for this test.
             var regressionTest;

             // Wait period (milliseconds) for GUI update after
             // resetting the interface.
             var GUI_RESET_WAIT_PERIOD = 1000;

             // HTTP query strings for the data selection criteria to
             // load.
             var QUERY_STRING = "service=StSc&" +
                 "starttime=2003-01-01&endtime=2003-01-05T23:59:59Z&" +
                 "bbox=-41.4844, -7.3945, -35.1562, -1.0664&" +
                 "data=TRMM_3B42RT_Daily_7_precipitation%2CTRMM_3B42_Daily_7_precipitation&" +
                 "dataKeyword=rainfall";

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 1000;

	     // Timeout (milliseconds) for waiting for the results screen
	     // to update after pressing the "Plot Data" button.
	     var PLOT_GENERATION_TIMEOUT = 60000;

             // Number of history entries to check.
             var NUM_RESULT_SETS = 2;

             // Name strings for history elements.
             var HISTORY_ELEMENT_NAMES = [
                 "User Input",
                 "Plots",
                 "Downloads",
                 "Lineage"
             ];

             // Wait period (milliseconds) for the plot images to
             // load.
             var PLOT_IMAGE_LOAD_WAIT_PERIOD = 4000;

             it("should find history entries for simultaneous time averaged " +
                "map and interactive scatter plot.",
                function() {

                    // Set up the regression test infrastructure.
                    regressionTest =
                        new giovanni.test.RegressionTest(this, TEST_PLAN_LINK);
                    expect(regressionTest).toBeTruthy();

                    // Reset the page to the default state, and wait
                    // for the update to complete.
                    runs(function() {
                        regressionTest.RESET();
                    }); // end runs()
                    waits(GUI_RESET_WAIT_PERIOD)

                    // Load the bookmarked URL into the GUI.
                    runs(function() {
                        setUserInterfaceFromQueryString(QUERY_STRING);
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Press the "Plot Data" button.
                    runs(function() {
                        var plotDataButton =
                            document.getElementById("sessionDataSelToolbar" +
                                                    "plotBTN-button");
                        expect(plotDataButton).toBeTruthy();
                        plotDataButton.click();
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Press the button to return to the data
                    // selection screen.
                    runs(function() {
                        var backToDataSelectionButton =
                            document.getElementById("sessionWorkspaceToolbar" +
                                                    "selectDataBTN-button");
                        expect(backToDataSelectionButton).toBeTruthy();
                        backToDataSelectionButton.click();
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Select the interactive scatter plot.
                    runs(function() {
                        var interactiveScatterPlotRadiobutton =
                            document.getElementById("sessionDataSelSvcPkCtrl" +
                                                    "IaSc");
			if(interactiveScatterPlotRadiobutton==null)
                            interactiveScatterPlotRadiobutton =
                                document.getElementById("service_comparison+" +
                                                    "IaSc");
                        expect(interactiveScatterPlotRadiobutton).toBeTruthy();
                        interactiveScatterPlotRadiobutton.click();
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Press the "Plot Data" button.
                    runs(function() {
                        var plotDataButton =
                            document.getElementById("sessionDataSelToolbar" +
                                                    "plotBTN-button");
                        expect(plotDataButton).toBeTruthy();
                        plotDataButton.click();
                    }); // end runs()
                     var historyViewList = document.getElementById("sessionWorkspaceHistoryViewHistoryViewList");
                     var Chrome = false;
                     if (window.browserChecker.name != 'Firefox') {
                        Chrome = true;
                     } 


                    // Wait for the history nodes to complete. They
                    // are considered complete when the child <li>
                    // elements each contain a <a> element.
                    waitsFor(function() {

                        // Fetch the list (a <ul>) of history entries.
                        var historyViewList =
                            $("span:contains('History')");
                        if (!historyViewList) {
                            return false;
                        }
                        if (Chrome) {
							var a = $("span:contains('Interactive')").get(0);
							if (!a) {
									return false;
							}
							var ul = $("span:contains('Static')").get(0);
							if (!ul) {
									return false;
							}
                        }
                        else {
							var a = $("a:contains('Interactive')").get(0);
							if (!a) {
									return false;
							}
							var ul = $("a:contains('Static')").get(0);
							if (!ul) {
									return false;
							}
                        }


                        // Make sure the history for each result set
                        // is complete.
                        for (var i = 0; i < NUM_RESULT_SETS; i++) {

                            // Fetch the history entry (a <li>) for
                            // the current result set. It should have
                            // a child <a> and <ul> at all times.

                            // Check each history element for this
                            // history entry. Each element is either a
                            // <li> with text, or a <li> containing a
                            // <a>. The tag name is used for the <a>
                            // check since the <li> may still have
                            // just text inside.
                            for (var j = 0; j < HISTORY_ELEMENT_NAMES.length; j++) {
                                var str; 
                                if (Chrome) {
                                	str =  "span:contains('" +  HISTORY_ELEMENT_NAMES[j] +  "\')";
                                }
                                else {
                                	str =  "li:contains('" +  HISTORY_ELEMENT_NAMES[j] +  "\')";
                                }
                                var li = $(str).get(0); 
                                if (!li) {
                                    return false;
                                }
                                li = $(str).get(1); 
                                if (!li) {
                                    return false;
                                }
                            }

                        }

                        // All history entries are complete.
                        return true;

                    },
                             "the histories to complete.",
                             PLOT_GENERATION_TIMEOUT
                            ); // end waitsFor()

                    // Trivial runs() required after the last wait.
                    runs(function() {
                        expect(true).toBe(true);
                    }); // end runs()
                    
                }); // end it()

         }); // end describe()
