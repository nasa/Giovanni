/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-008
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-008",
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
             var QUERY_STRING = "service=TmAvMp&" +
                 "starttime=2003-01-01&endtime=2003-01-05T23:59:59Z&" +
                 "bbox=-54.141,-27.422,-23.203,11.25&" +
                 "data=MOD08_D3_6_Aerosol_Optical_Depth_Land_Ocean_Mean%2C" +
                 "MOD08_D3_6_AOD_550_Dark_Target_Deep_Blue_Combined_Mean&" +
                 "dataKeyword=MODIS-Terra";

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 3000;

	     // Timeout (milliseconds) for waiting for the results screen
	     // to update after pressing the "Plot Data" button.
	     var PLOT_GENERATION_TIMEOUT = 30000;

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

             // Number of plots in the first result set.
             var NUM_PLOTS_1 = 2;

             // Number of plots in the second result set.
             var NUM_PLOTS_2 = 2;

             // Wait period (milliseonds) for plot visibility.
             var PLOT_LOAD_WAIT_PERIOD = 2000;

             var Chrome = false;
             if (window.browserChecker.name != 'Firefox') {
                 Chrome = true;
             }

             it("should be able to move back and forth between result sets.",
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

                    // Wait for the history nodes to complete. They
                    // are considered complete when the child <li>
                    // elements each contain a <a> element.
                    if (Chrome) {
                      waitsFor(function() {
                       var plotsLink = $("span:contains('Plots')").length;
                        if (plotsLink < 2) {
                          return false;
                        }
                        var scatterplot_arrived = 
                         $("div#resultContainer").find("table#interactiveScatterPlotContainer").length;
                        if (scatterplot_arrived < 1) {
                          return false;
                        }
                      
                        // All history entries are complete.
                        return true;

                    },
                             "the histories to complete.",
                             PLOT_GENERATION_TIMEOUT
                            ); // end waitsFor()
                    }
                    else {
                    waitsFor(function() {

                        // Fetch the list (a <ul>) of history entries.
                        var historyViewList =
                            document.getElementById("sessionWorkspaceHistory" +
                                                    "ViewHistoryViewList");
                        if (!historyViewList) {
                            return false;
                        }

                        // Make sure the history for each result set
                        // is complete.
                        for (var i = 0; i < NUM_RESULT_SETS; i++) {

                            // Fetch the history entry (a <li>) for
                            // the current result set. It should have
                            // a child <a> and <ul> at all times.
                            var historyEntry = historyViewList.childNodes[i];
                            if (!historyEntry) {
                                return false;
                            }
                            var a = historyEntry.childNodes[0];
                            if (!a) {
                                return false;
                            }
                            var ul = historyEntry.childNodes[1];
                            if (!ul) {
                                return false;
                            }

                            // Check each history element for this
                            // history entry. Each element is either a
                            // <li> with text, or a <li> containing a
                            // <a>. The tag name is used for the <a>
                            // check since the <li> may still have
                            // just text inside.
                            for (var j = 0; j < HISTORY_ELEMENT_NAMES.length;
                                 j++) {
                                var li = ul.childNodes[j];
                                if (!li) {
                                    return false;
                                }
                                var a = li.getElementsByTagName("a")[0];
                                if (!a) {
                                    // Interactive scatter plot has no
                                    // plot options.
                                    if (j == 2) {
                                        continue;
                                    }
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

                     }
                    // Click the 'Plots' link for result 1.
                    waits(PLOT_LOAD_WAIT_PERIOD);
                    if (Chrome) {
                      waitsFor(function() {
                       var plotsLen = $("span:contains('Plots')").length;
                        if (plotsLen < 2) {
                          return false;
                        }
                       var plotsLink = $("span:contains('Plots')");
                        plotsLink.eq(1).click();
                        
                        // All history entries are complete.
                        return true;

                    },
                             "to click the second plot button.",
                             PLOT_GENERATION_TIMEOUT
                            ); // end waitsFor()
                    }
                    else {
                    runs(function() {
                        var historyViewList =
                            document.getElementById("sessionWorkspaceHistory" +
                                                    "ViewHistoryViewList");
                        var historyEntry = historyViewList.childNodes[1];
                        var ul = historyEntry.childNodes[1];
                        var plotsLI = ul.childNodes[1];
                        var plotsLink = plotsLI.getElementsByTagName("a")[0];
                        plotsLink.click();
                    }); // end runs()
                    }

                    // Verify that the result 1 plots are shown.
                    waitsFor(function() {
                        var resultViewContainer =
                            document.getElementById("resultViewContainer");
                        if (!resultViewContainer) {
                            return false;
                        }
                        var twoplots = $("div#resultContainer").find(".imageFrame").length;
                        if (twoplots < 2) {
                                return false;
                        }
                        return true;
                    },
                             "the time-averaged maps to reappear.",
                             PLOT_GENERATION_TIMEOUT
                            );
                    waits(PLOT_LOAD_WAIT_PERIOD);

                    // Click the 'Plots' link for result 2.
                    if (Chrome) {
                      waitsFor(function() {
                       var plotsLen = $("span:contains('Plots')").length;
                        if (plotsLen <  2) {
                          return false;
                        }
                       var plotsLink = $("span:contains('Plots')");
                        plotsLink.eq(0).click();
                        
                        // All history entries are complete.
                        return true;

                    },
                             "to click the second plot button.",
                             PLOT_GENERATION_TIMEOUT
                            ); // end waitsFor()
                    }
                    else {
                    runs(function() {
                        var historyViewList =
                            document.getElementById("sessionWorkspaceHistory" +
                                                    "ViewHistoryViewList");
                        var historyEntry = historyViewList.childNodes[0];
                        var ul = historyEntry.childNodes[1];
                        var plotsLI = ul.childNodes[1];
                        var plotsLink = plotsLI.getElementsByTagName("a")[0];
                        plotsLink.click();
                    }); // end runs()
                    }

                    // Verify that the result 2 plots are shown.
                    waitsFor(function() {
                        var interactiveScatterPlotContainer =
                            document.getElementById("interactiveScatterPlot" +
                                                    "Container");
                        if (!interactiveScatterPlotContainer) {
                            return false;
                        }
                        var tbody =
                            interactiveScatterPlotContainer.childNodes[0];
                        if (!tbody) {
                            return false;
                        }
                        var tr = tbody.childNodes[1];
                        if (!tr) {
                            return false;
                        }

                        // Check the plot has been created.
                        var td = tr.childNodes[0];
                        if (!td) {
                            return false;
                        }
                        var div = td.childNodes[1];
                        if (!div) {
                            return false;
                        }
                        var chartContainer = div.childNodes[0];
                        if (!chartContainer) {
                            return false;
                        }
                        var svg = chartContainer.childNodes[0];
                        if (!svg) {
                            return false;
                        }

                        // Check the map has been created.
                        td = tr.childNodes[1];
                        if (!td) {
                            return false;
                        }
                        div = td.childNodes[1];
                        if (!div) {
                            return false;
                        }
                        var mapContainer = div.childNodes[0];
                        if (!mapContainer) {
                            return false;
                        }
                        var OLviewPort = mapContainer.childNodes[0];
                        if (!OLviewPort) {
                            return false;
                        }
                        var OLcontainer = OLviewPort.childNodes[0];
                        if (!OLcontainer) {
                            return false;
                        }
                        // This is as deep as we can reasonably go.

                        // All plots are complete.
                        return true;
                    },
                             "the interactive scatter plots to reappear.",
                             PLOT_GENERATION_TIMEOUT
                            );
                    waits(PLOT_LOAD_WAIT_PERIOD);

                    // Trivial runs() required after the last wait.
                    runs(function() {
                        expect(true).toBe(true);
                    }); // end runs()

                }); // end it()

         }); // end describe()
