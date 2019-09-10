/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-003
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-003",
         function() {

             var Chrome = false;
             if (window.browserChecker.name != 'Firefox') {
                 Chrome = true;
             }
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
	     var PLOT_GENERATION_TIMEOUT = 60000;

             // Wait period (milliseconds) for the plot images to
             // load.
             var PLOT_IMAGE_LOAD_WAIT_PERIOD = 4000;

             // Timeout (milliseconds) after clicking the 'Downloads'
             // link.
             var DOWNLOADS_TIMEOUT = 1000;

             // Wait period (milliseconds) for downloading both PDFs.
             var DOWNLOADS_WAIT_PERIOD = 10000;

             it("should find download links for PDFs of the plots.",
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

                    // Wait for the 'Downloads' link to become
                    // available.
                    var downloadsLink;
                    var n = $("span:contains('Result ')").length;
                    waitsFor(function() {

                        // Fetch the list (a <ul>) of history entries.
                        var historyViewList =
                            document.getElementById("sessionWorkspaceHistory" +
                                                    "ViewHistoryViewList");
                        var a;
                        if (Chrome) {
     						// Fetch the list (a <ul>) of history entries.
                           historyViewList =
                            $("span:contains('Result ')");
                        	if (!historyViewList) {
                            	return false;
                        	}
                            // This means all four plots are there
                            a = $("span:contains('Downloads')").get(n);
                        	if (!a) {
                            	return false;
                        	}
                            // This is the one we want.
                            a = $("span:contains('Downloads')").get(0);

                        }
                        else {
							if (!historyViewList) {
								return false;
							}

							// Fetch the history entry for the current
							// plot.
							var historyEntry = historyViewList.childNodes[0];
							if (!historyEntry) {
								return false;
							}

							// Check if the 'Downloads' link is available.
							var ul = historyEntry.childNodes[1];
							if (!ul) {
								return false;
							}
							var downloadsLI = ul.childNodes[3];
							if (!downloadsLI) {
								return false;
							}
							var a = downloadsLI.getElementsByTagName("a")[0];
							if (!a) {
								return false;
							}
						}

                        // The link is ready.
                        downloadsLink = a;
                        return true;

                    },
                             "the 'Downloads' link to be ready.",
                             PLOT_GENERATION_TIMEOUT
                            ); // end waitsFor()

                    // A slight pause to allow the images to be seen.
                    waits(PLOT_IMAGE_LOAD_WAIT_PERIOD);

                    // Click the 'Downloads' link.
                    runs(function() {
                        downloadsLink.click();
                    }); // end runs()

                    // Wait for both download links to appear.
                    var downloadLinks = [];
                    waitsFor(function() {
                        var downloadContainer =
                            document.getElementById("downloadContainer");
                        if (!downloadContainer) {
                            return false;
                        }
                        var a = downloadContainer.childNodes[0];
                        if (!a) {
                            return false;
                        }
                        downloadLinks.push(a);
                        a = downloadContainer.childNodes[2];
                        if (!a) {
                            return false;
                        }
                        downloadLinks.push(a);
                        return true;
                    },
                             "the download links to appear.",
                             DOWNLOADS_TIMEOUT
                            ); // end waitsFor()

                    // Download both PDFs.
                    runs(function() {
                        for (var i = 0; i < downloadLinks.length; i++) {
                            downloadLinks[i].click();
                        }
                    }); // end runs()
                    waits(DOWNLOADS_WAIT_PERIOD);

                    // Verify that both files were downloaded.
                    runs(function() {
                        var didBothFilesDownload =
                             confirm("Did both files download ('OK' = yes)?");
                        expect(didBothFilesDownload).toBe(true);
                    }); // end runs()

                }); // end it()

         }); // end describe()
