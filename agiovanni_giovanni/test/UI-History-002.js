/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-History-002
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-History-002",
         function() {

             // This URL links back to the test plan which describes
             // the individual tests. It is currently stored in Google
             // Docs.
             var TEST_PLAN_LINK = "https://docs.google.com/document/d/" +
                  "1G6dx0Kk55NP5iWOs459GUT6rrcG7hNJjXn80-JNo9qE/edit#" +
                  "heading=h.e5io02xfr60i";

             // The RegressionTest object for this test.
             var regressionTest;

             // Wait period (milliseconds) for GUI update after
             // resetting the interface.
             var GUI_RESET_WAIT_PERIOD = 1000;

             // HTTP query strings for the data selection criteria to
             // load.
             var QUERY_STRING = "service=StSc&" +
                  "starttime=2003-01-01T00:00:00Z&endtime=2003-01-05T23:59:59Z&" +
                  "bbox=-54.141,-27.422,-23.203,11.25&" + 
                  "data=MOD08_D3_6_Cloud_Top_Temperature_Mean%2CMOD08_D3_6_Cloud_Top_Temperature_Night_Mean&" +
                  "variableFacets=dataProductTimeInterval%3Adaily%3B&" +
                  "dataKeyword=MODIS-Terra&" +
                  "portal=GIOVANNI&format=json";

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 1000;

	     // Timeout (milliseconds) for waiting for the results screen
	     // to update after pressing the "Plot Data" button.
	     var PLOT_GENERATION_TIMEOUT = 60000;

             // Wait period (milliseconds) for the plot images to
             // load.
             var PLOT_IMAGE_LOAD_WAIT_PERIOD = 4000;

             // Timeout (milliseconds) after clicking the 'Plot
             // Options' link.
             var PLOT_OPTIONS_TIMEOUT = 4000;

             var Chrome = false;

             it("should find the plot options for a static scatter plot.",
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
             
                    runs(function() {
                      console.log('This test runs after several others that are not finished yet');
                      console.log('So I am waiting for those to finish');
                      waits(25000);
                    });

                   
		    var n;
                    runs(function() {
                      //var historyViewList = document.getElementById("sessionWorkspaceHistoryViewHistoryViewTree");
                      if (window.browserChecker.name != 'Firefox') {
                        Chrome = true;
                      }
		      if (Chrome) {
			n = $("span:contains('Plot Options')").length;
		      }else{
                        //historyViewList = document.getElementById("sessionWorkspaceHistoryViewHistoryViewList");
			n = $("a:contains('Plot Options')").length;
		      }
                    }); // end runs()

                    // Wait for the 'Plot Options' link to become
                    // available.
                    var plotOptionsLink;
                    // Number of previous plots with Plot Options
                    waitsFor(function() {
                          // Fetch the list (a <ul>) of history entries.
                          var historyViewList = $("span:contains('History')");
                          if (!historyViewList) {
                            return false;
                          }

                          var a;
                          if (Chrome) {
                        	a = $("span:contains('Plot Options')");
                          }else{
                        	a = $("a:contains('Plot Options')");
                          }
                          // This is the next plot to appear (not all plots have plot options links)
                          if (!a.get(n-1)) {
                               return false;
                          }
                          // The link is ready. 0th is newest
                          if(a){ 
			    console.log('found  plot options link');
                            plotOptionsLink = a.get(0);
                            return true;
 		 	  }else{
			    return false;
			  }
                        },
                        "the 'Plot Options' link to be ready.",
                        PLOT_GENERATION_TIMEOUT
                     ); // end waitsFor()

                    // A slight pause to allow the images to be seen.
                    waits(PLOT_IMAGE_LOAD_WAIT_PERIOD);

                    // Click the 'Plot Options' link.
                    runs(function() {
                        console.log('trying to click plot options link');
                        plotOptionsLink.click();
                    }); // end runs()
                    waits(PLOT_IMAGE_LOAD_WAIT_PERIOD);

                    // Verify that plot options for both variables are
                    // available.
                    waitsFor(function() {
                        var resultViewContainer =
                            document.getElementById("resultViewContainer");
                        if (!resultViewContainer) {
                            return false;
                        }
                        var plotOptionsRow = $('.plotOptionsRow').get(0);
                        if (!plotOptionsRow) {
                            return false;
                        }
                        plotOptionsRow = $('.plotOptionsRow').get(1);
                        if (!plotOptionsRow) {
                            return false;
                        }
                        return true;
                      },
                      "the plot options controls to appear.",
                      PLOT_OPTIONS_TIMEOUT
                    ); // end waitsFor()

                    // Trivial runs() required after the last wait.
                    runs(function() {
                        expect(true).toBe(true);
                    }); // end runs()

                }); // end it()

         }); // end describe()
