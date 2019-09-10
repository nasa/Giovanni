/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-DataSelectionButtons-004
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("Sprint 43 test UI-DataSelectionButtons-004",
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

             // Wait period (milliseconds) after changing search
             // criteria.
             var CRITERIA_UPDATE_WAIT_PERIOD = 1000;

             // Wait period (milliseconds) after pressing the Feedback
             // button.
             var FEEDBACK_WAIT_PERIOD = 10000;

             // Text label for variable to select.
             var SELECTED_VARIABLE_LABELS = [
                 "Aerosol Optical Depth 550 nm (Deep Blue), Land-only, " +
                     "MODIS-Terra, 1 x 1 deg.",
                 "Aerosol Optical Depth 550 nm (Deep Blue), Land-only, " +
                     "MODIS-Aqua, 1 x 1 deg."
             ];

             it("should generate a feedback email with a portal URL.",
                function() {

                    // Set up the regression test infrastructure.
                    regressionTest =
                        new giovanni.test.RegressionTest(this, TEST_PLAN_LINK);
                    expect(regressionTest).toBeTruthy();

                    // Reset the page to the default state, and wait for
                    // the update to complete.
                    runs(function() {
                        regressionTest.RESET();
                    }); // end runs()
                    waits(GUI_RESET_WAIT_PERIOD);

                    // Find and click the Scatter Plot radio button.
                    runs(function() {
                        var scatterPlotRadioButton =
                            document.getElementById("sessionDataSelSvcPkCtrl" +
                                                    "StSc");
			if(scatterPlotRadioButton==null) 
				scatterPlotRadioButton = document.getElementById("service_comparison+StSc");
                        expect(scatterPlotRadioButton).toBeTruthy();
                        scatterPlotRadioButton.click();
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Find the keyword entry field, and enter 'deep
                    // blue'.
                    runs(function() {
                        var keywordInput =
                            document.getElementById("facetedSearchBarInput");
                        expect(keywordInput).toBeTruthy();
                        keywordInput.value = "deep blue";
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Find and click the keyword search button.
                    runs(function() {
                        var searchButton =
                            document.getElementById("facetedSearchButton");
                        expect(searchButton).toBeTruthy();
                        searchButton.click();
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Select the needed variables.
                    runs(function() {
                        var resultTable =
                            document.getElementById("resultTable");
                        expect(resultTable).toBeTruthy();
                        var yui_dt_bd = resultTable.childNodes[2];
                        expect(yui_dt_bd).toBeTruthy();
                        var table = yui_dt_bd.childNodes[0];
                        expect(table).toBeTruthy();
                        var yui_dt_data = table.childNodes[2];
                        expect(yui_dt_data).toBeTruthy();
                        for (var i = 0; i < yui_dt_data.childNodes.length;
                             i++) {
                            var tr = yui_dt_data.childNodes[i];
                            expect(tr).toBeTruthy();
                            var variableTd = tr.childNodes[1];
                            expect(variableTd).toBeTruthy();
                            var variableDiv = variableTd.childNodes[0];
                            expect(variableDiv).toBeTruthy();
                            var a = variableDiv.childNodes[0];
                            expect(a).toBeTruthy();
                            var variableLabel = a.textContent;
                            expect(variableLabel.length).toBeGreaterThan(0);
                            if (SELECTED_VARIABLE_LABELS.indexOf(variableLabel)
                                != -1) {
                                var checkboxTd = tr.childNodes[0];
                                expect(checkboxTd).toBeTruthy();
                                var checkboxDiv = checkboxTd.childNodes[0];
                                expect(checkboxDiv).toBeTruthy();
                                var checkbox = checkboxDiv.childNodes[0];
                                expect(checkbox).toBeTruthy();
                                checkbox.click();
                            }
                        }
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Enter the end date of 1 January 2003 in the
                    // date picker. Triggering the onchange event for
                    // the year field causes the date string to be
                    // placed in the bookmarkable URL.
                    runs(function() {
                        var datePicker = session.dataSelector.datePicker.currentPicker;
                        expect(datePicker).toBeTruthy();
                        datePicker.endDateTF.setValue("2003-01-01");
                        regressionTest.triggerOnChangeEvent(endContainer_year);
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Enter a small geographical bounding
                    // box. Triggering the onchange event for the
                    // bounding box field causes the bounding box
                    // string to be added to the bookmarkable URL.
                    runs(function() {
                        var boundingBoxInput =
                            document.getElementById("sessionDataSelBbPkbbox");
                        expect(boundingBoxInput).toBeTruthy();
                        boundingBoxInput.value = "-5, -5, 5, 5";
                        regressionTest.triggerOnChangeEvent(boundingBoxInput);
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                    // Find and click the Feedback button. Note that
                    // the contents of the mail message, and the
                    // results from clicking or pasting the URL into a
                    // new browser window, cannot be checked by this
                    // script.
                    runs(function() {
                        alert("After pressing the 'OK' button below, " +
                              "a mail message should appear containing " +
                              "the results of the Feedback button. Verify " +
                              "that the UserAgent in the message corresponds " +
                              "to your browser. Then click or paste the URL " +
                              "from the message into a new browser window, " +
                              "and verify your search criteria are loaded " +
                              "in the new window.");
                        var feedbackButton =
                            document.getElementById('sessionDataSelToolbarfeedbackBTN-button');
                        expect(feedbackButton).toBeTruthy();
                        feedbackButton.click();
                    }); // end runs();
                    waits(FEEDBACK_WAIT_PERIOD);

                    // Check that the mail window appeared.
                    runs(function() {
                        var didMailWindowAppear =
                            confirm("Did the mail window appear with your " +
                                    "browser UserAgent string and selection " +
                                    "criteria, and did the criteria load " +
                                    "into the new browser window " +
                                    "('OK' = yes)?");
                        expect(didMailWindowAppear).toBe(true);
                    }); // end runs()
                    waits(CRITERIA_UPDATE_WAIT_PERIOD);

                }); // end it()

         }); // end describe()
