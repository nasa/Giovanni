/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-009
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-009",
         function() {

             // This URL links back to the test plan which describes
             // the individual tests. It is currently stored in Google
             // Docs.

             var TEST_PLAN_LINK = "https://docs.google.com/document/d/" +
                      "1G6dx0Kk55NP5iWOs459GUT6rrcG7hNJjXn80-JNo9qE/edit#" +
                      "heading=h.xw407jciblkr";

             // The RegressionTest object for this test.
             var regressionTest;

             // Wait period (milliseconds) for GUI update after
             // resetting the interface.
             var GUI_RESET_WAIT_PERIOD = 1000;

             // HTTP query strings for the data selection criteria to
             // load.
             //var QUERY_STRING = "service=TmAvMp&" +
             //    "starttime=2003-01-01&endtime=2003-01-05T23:59:59Z&" +
             //    "bbox=-54.141,-27.422,-23.203,11.25&" +
             //    "data=MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean%2C" +
             //    "MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean&" +
             //    "dataKeyword=MODIS-Terra";

             var QUERY_STRING = "service=TmAvMp&starttime=2005-01-01T00:00:00Z&endtime=2005-01-05T23:59:59Z&bbox=-54.141,-27.422,-23.203,11.25&data=OMAEROe_003_SingleScatteringAlbedoMW_463_0%2COMAERUVd_003_FinalAerosolSingleScattAlb500"

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 2000;

	     // Timeout (milliseconds) for waiting for the results screen
	     // to update after pressing the "Plot Data" button.
	     var PLOT_GENERATION_TIMEOUT = 5000;

             // Number of history entries to check.
             var NUM_RESULT_SETS = 2;

             // Name strings for history elements.
             var HISTORY_ELEMENT_NAMES = [
                 "User Input",
                 "Plots",
                 "Plot Options",
                 "Downloads",
                 "Lineage"
             ];

             // Wait period (milliseconds) for plot loading.
             var PLOT_LOAD_WAIT_PERIOD = 5000;

             var Chrome = false;
             if (window.browserChecker.name != 'Firefox') {
                 Chrome = true;
             }


             it("should be able to recover user input from previous " +
                "result sets",
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

                    // Select the scatter plot.
                    runs(function() {
                        var scatterPlotRadiobutton =
                            document.getElementById("sessionDataSelSvcPkCtrl" +
                                                    "StSc");
			if(!scatterPlotRadiobutton)
                            scatterPlotRadiobutton =
                                document.getElementById("service_comparison+" +
                                                    "StSc");
                        expect(scatterPlotRadiobutton).toBeTruthy();
                        scatterPlotRadiobutton.click();
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
                    waits(PLOT_LOAD_WAIT_PERIOD);

                    if (Chrome) {
                      runs(function() {
                        var UserInputLink = $("span:contains('User Input')")
                        UserInputLink.eq(1).click(); // Time Averated Map 'User Input' node
                      }); // end runs()
                    }
                    else {
                    // Click the 'User Input' link for result 1.
                    runs(function() {
                        var historyViewList =
                            document.getElementById("sessionWorkspaceHistory" +
                                                    "ViewHistoryViewList");
                        var historyEntry = historyViewList.childNodes[1];
                        var ul = historyEntry.childNodes[1];
                        var userInputLI = ul.childNodes[0];
                        var userInputLink =
                            userInputLI.getElementsByTagName("a")[0];
                        userInputLink.click();
                    }); // end runs()
                    }

                    // Verify that the user input for the first set is
                    // shown.
                    waitsFor(

                        function() {
			    var radioBtn = null;
                            // check for old service picker format
                            var oldMapRadioButton =
                                document.getElementById("sessionDataSelSvcPkCtrl" +
                                                    "TmAvMp");
                            // if it looks like the new format, try to get that
                            if (!oldMapRadioButton) {
                                radioBtn = document.getElementById("service_maps+" +
                                                    "TmAvMp");
                            }else{
                                radioBtn = oldMapRadioButton;
                            }
                            // if it's the new format, check the control parent
                            // as that would need to be selected as well
                            if(!oldMapRadioButton) {
                                var groupContainer = document.getElementById('mapsGroupCtrl');
                                if(!groupContainer) return false;
                                if(groupContainer.getAttribute('class').indexOf('Selected')<0) return false;
                            }
                            // check the map radio button for selection
                            if (!radioBtn) return false;
                            if (!radioBtn.checked) return false;

                            return true;
                        },
                        "the first set of user input to reappear.",
                        CRITERIA_UPDATE_WAIT_PERIOD
                    );

                }); // end it()

         }); // end describe()
