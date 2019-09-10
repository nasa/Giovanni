/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-004
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-004",
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
             var CRITERIA_UPDATE_WAIT_PERIOD = 1000;

	     // Timeout (milliseconds) for waiting for the results screen
	     // to update after pressing the "Plot Data" button.
	     var PLOT_GENERATION_TIMEOUT = 60000;

             // Wait period (milliseconds) for the plot images to
             // load.
             var PLOT_IMAGE_LOAD_WAIT_PERIOD = 4000;

             // Timeout (milliseconds) after clicking the 'Lineage'
             // link.
             var LINEAGE_TIMEOUT = 1000;

             // Regular expression pattern to use when matching
             // against the title of the lineage display.
             var RESULT_TITLE_PATTERN = /Map of average over time/;

             // Wait period (milliseconds) for the lineage to load.
             var LINEAGE_LOAD_WAIT_PERIOD = 2000;

             var Chrome = false;
             if (window.browserChecker.name != 'Firefox') {
                 Chrome = true;
             }

             it("should find the lineage for the current results.",
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

                    // Wait for the 'Lineage' link to become
                    // available.
                    var lineageLink;
                    var n = $("span:contains('Result ')").length;



                    if (Chrome) {
                      waitsFor(function() {
                            a = $("span:contains('Lineage')").get(n);
                            if (!a) {
                                return false;
                            }
                            // This is the one we want.
                            a = $("span:contains('Lineage')").get(0);
                        // The link is ready.
                        lineageLink = a;
                        return true;

                    },
                             "the non-Firefox 'Lineage' link to be ready.",
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

                        // Fetch the history entry for the current
                        // plot.
                        var historyEntry = historyViewList.childNodes[0];
                        if (!historyEntry) {
                            return false;
                        }

                        // Check if the 'Lineages' link is available.
                        var ul = historyEntry.childNodes[1];
                        if (!ul) {
                            return false;
                        }
                        var lineageLI = ul.childNodes[4];
                        if (!lineageLI) {
                            return false;
                        }
                        var a = lineageLI.getElementsByTagName("a")[0];
                        if (!a) {
                            return false;
                        }

                        // The link is ready.
                        lineageLink = a;
                        return true;

                    },
                             "the 'Lineage' link to be ready.",
                             PLOT_GENERATION_TIMEOUT
                            ); // end waitsFor()
                    }

                    // A slight pause to allow the images to be seen.
                    waits(PLOT_IMAGE_LOAD_WAIT_PERIOD);

                    // Click the 'Lineage' link.
                    runs(function() {
                        lineageLink.click();
                    }); // end runs()

                    // Wait for the lineage to appear.
                    waitsFor(function() {
                        var sessionWorkspaceResultView =
                            document.getElementById("sessionWorkspaceResultView");
                        if (!sessionWorkspaceResultView) {
                            return false;
                        }
                        var resultTitleDiv =
                            sessionWorkspaceResultView.childNodes[0];
                        if (!resultTitleDiv) {
                            return false;
                        }
                        var resultTitle = resultTitleDiv.textContent;
                        if (!resultTitle.match(RESULT_TITLE_PATTERN)) {
                            return false;
                        }
                        var scrubbedFiles =   $("a:contains('scrubbed')")
                        if (!scrubbedFiles) {
                            return false;
                        }
                        return true;
                    },
                             "the lineage to appear.",
                             LINEAGE_TIMEOUT
                            ); // end waitsFor()

                    // Wait a bit so the user can see the lineage.
                    waits(LINEAGE_LOAD_WAIT_PERIOD);

                    // Trivial runs() required after the last wait.
                    runs(function() {
                        expect(true).toBe(true);
                    }); // end runs()

                }); // end it()

         }); // end describe()
