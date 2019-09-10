/**
 * @this This file contains a stub test to signal the transition from
 * automated to interactive tests.
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Start interactive tests",
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

             it("should indicate to the tester that the remaining tests " +
                "require user interaction.",
                function() {

                    // Set up the regression test infrastructure.
                    regressionTest =
                        new giovanni.test.RegressionTest(this, TEST_PLAN_LINK);

                    // Reset the page to the default state, and wait
                    // for the update to complete.
                    runs(function() {
                        regressionTest.RESET();
                    }); // end runs()
                    waits(GUI_RESET_WAIT_PERIOD);

                    // Do nothing.
                    runs(function() {
                        alert("ATTENTION: The remaining tests require user " +
                              "interaction.");
                        expect(true).toBe(true);
                    }); // end runs()

                }); // end it()

         }); // end describe()
