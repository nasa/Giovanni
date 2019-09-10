/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-TimeSeries-001
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-TimeSeries-001",
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

             // HTTP query string for the data selection criteria to
             // load.
             var QUERY_STRING = "service=ArAvTs&" +
                 "starttime=2003-01-01&endtime=2003-01-05T23:59:59Z&" +
                 "bbox=-54.141,-27.422,-23.203,11.25&" +
                 "data=MOD08_D3_6_Aerosol_Optical_Depth_Land_Ocean_Mean%2C" +
                 "MOD08_D3_6_AOD_550_Dark_Target_Deep_Blue_Combined_Mean&" +
                 "dataKeyword=MODIS-Terra";

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 1000;

             // Timeout period (milliseconds) for plot generation.
             var PLOT_GENERATION_TIMEOUT = 120000;

             // Wait period (milliseconds) for the plot images to
             // load.
             var PLOT_IMAGE_LOAD_WAIT_PERIOD = 4000;

             var NUMBER_OF_PLOTS = 2;

             it("should generate a time series plot on the results screen.",
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
                    waits(GUI_RESET_WAIT_PERIOD);

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

                    // Wait for the plot to finish. The plot is
                    // finished when the <img> element for the plot is
                    // found.
                    waitsFor(function() {
                        var resultViewContainer =
                            document.getElementById("resultViewContainer").childNodes[1];
                        if (resultViewContainer === null) {
                            return false;
                        }
                        if (resultViewContainer.childNodes.length <= 1) {
    		            return false;
                        }
                        for (i = 0; i < NUMBER_OF_PLOTS; i++) {
                            var imageFrame = resultViewContainer.childNodes[i];

                        	if (imageFrame === null) {
                            	return false;
                        	}
                        	var img = imageFrame.childNodes[2];
                        	if (img === null || img === undefined) {
                            	return false;
                        	}
						}
    		        	return true;
    		    	},
                             "the plot to be generated.",
                             PLOT_GENERATION_TIMEOUT
		            ); // end waitsFor()

                    // Wait a bit to allow the plot image to be seen
                    // by the user.
                    waits(PLOT_IMAGE_LOAD_WAIT_PERIOD);

                }); // end it()

         }); // end describe()
