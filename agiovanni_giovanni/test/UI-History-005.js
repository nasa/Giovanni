/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-005
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-005",
         function() {

             // This URL links back to the test plan which describes
             // the individual tests. It is currently stored in Google
             // Docs.
             var TEST_PLAN_LINK = "https://docs.google.com/document/d/" + 
                 "1G6dx0Kk55NP5iWOs459GUT6rrcG7hNJjXn80-JNo9qE/edit#" + 
                 "heading=h.i7q4o2v7kqm5";

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
                 "data=MOD08_D3_6_Aerosol_Optical_Depth_Land_Ocean_Mean&" +
                 "variableFacets=dataProductTimeInterval%3Adaily%3B&" +
                 "dataKeyword=MODIS-Terra"; 

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 1000;

	     // Timeout (milliseconds) for waiting for the results screen
	     // to update after pressing the "Plot Data" button.
	     var PLOT_GENERATION_TIMEOUT = 30000;

             // Wait period (milliseconds) for the plot images to
             // load.
             var PLOT_IMAGE_LOAD_WAIT_PERIOD = 15000;

             // Timeout (milliseconds) after clicking the 'Lineage'
             // link.
             var LINEAGE_TIMEOUT = 6000;

             // Wait period (milliseconds) for the lineage to load.
             var LINEAGE_LOAD_WAIT_PERIOD = 6000;

             // Number of plots in results.
             var NUM_PLOTS = 1;

             var Chrome = false;
             if (window.browserChecker.name != 'Firefox') {
                 Chrome = true;
             }

             it("should move back and forth between lineage and plots.",
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

                    
                    // A slight pause to allow the images to be seen.
                    waits(PLOT_IMAGE_LOAD_WAIT_PERIOD);

                    // Click the 'Lineage' link.
                    if (Chrome) {
                        runs(function() {
                            var lineageLink = $("span:contains('Lineage')");
                            lineageLink.click();
                        }); // end runs()
                    }
                    else {
                      runs(function() {
                        var historyViewList =
                            document.getElementById("sessionWorkspaceHistory" +
                                                    "ViewHistoryViewList");
                        var historyEntry = historyViewList.childNodes[0];
                        var ul = historyEntry.childNodes[1];
                        var lineageLI = ul.childNodes[3];
                        var lineageLink = lineageLI.getElementsByTagName("a")[0];
                        lineageLink.click();
                      }); // end runs()
                    } // end if Chrome

                    // Wait for the lineage to appear.
                    //if (Chrome) {
                    waitsFor(function() {

                          // fetch result container
                          var linText = $("div.resultContainer").children("td:contains('Catalog')");
                          //var linText = $("th:contains('Step 1.')");
                          if (!linText) {
                              return false;
                          } 
                          return true;
                       }, 
                       "the lineage to appear.", 
                       LINEAGE_TIMEOUT); // end waitsFor()

                    // Wait a bit so the user can see the lineage.
                    waits(LINEAGE_LOAD_WAIT_PERIOD);

                    // Click on the 'Plots' link in the history.
                    if (Chrome) {
                      runs(function() {
                        var plotsLink = $("span:contains('Plots')")
                        plotsLink.click();
                      }); // end runs()
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
                    } // end if Chrome

                    // Wait for the plots to be visible again.
                    waitsFor(function() {
                        for (var i = 0; i < NUM_PLOTS  ; i++) {
                            var imgFrame = $("div.mapFrame").eq(i).find("div.olPlotMap").length;
                            if (imgFrame == 0) {
                                return false;
                            }
                        }
                        return true;
                      },
                      "the plots to reappear.",
                      PLOT_GENERATION_TIMEOUT
                    );

                    // Trivial runs() required after the last wait.
                    //runs(function() {
                    //    expect(true).toBe(true);
                    //}); // end runs()

                }); // end it()

         }); // end describe()
