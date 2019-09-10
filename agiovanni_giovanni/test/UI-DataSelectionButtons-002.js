/**
 * @this This file contains a single Jasmine test specification for:
 *       UI-DataSelectionButtons-002
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */

describe("UI-DataSelectionButtons-002",
	function() {
		// Timeout period (milliseconds) for this spec to complete.
		jasmine.DEFAULT_TIMEOUT_INTERVAL = 90000;

		// HTTP query string for the data selection criteria to load.
		var QUERY_STRING =
			"service=TmAvMp&" +
			"starttime=2005-01-01T00:00:00Z&endtime=2005-01-04T23:59:59Z&" +
			"bbox=-180,-90,180,90&" +
			"data=AIRX3STD_006_Temperature_A(z%3D1000)&" +
			"variableFacets=dataFieldMeasurement%3AAir%20Temperature%3B&" +
			"dataKeyword=AIRS&portal=GIOVANNI&format=json";
		
		var Chrome = false;

		if (window.browserChecker.name != 'Firefox') {
			Chrome = true;
		}

		beforeAll(async function() {
			await querySetup(QUERY_STRING, true);
		});

		beforeEach(function(done) {
			setTimeout(function(){
				done();
			}, 1000)
		});

		it("should generate a plot when Plot Data is pressed",
			async function() {	

				if (Chrome) {
					var lineage_link = $("span:contains('Lineage')");
				} 
				else {
					var lineage_link = $("a:contains('Lineage')");
				}

				expect(lineage_link).toBeTruthy();
				
				var resultViewContainer = document.getElementById("resultContainer").childNodes[0];
				var imageFrame = resultViewContainer.childNodes[0];
				var img = imageFrame.childNodes[0];
				expect(img.textContent).toContain("Air Temperature");

		}); // end it()

		it("should navigate between data selection and result tabs (go to data selection)", 
			async function () {

				var dataSelectionButton = document.getElementById("sessionWorkspaceToolbarselectDataBTN-button");
				expect(dataSelectionButton).toBeTruthy();
				dataSelectionButton.click();

		});

		it("should navigate between data selection and result tabs (go to results)", 
			async function () {

				var resultsButton =	document.getElementById("sessionDataSelToolbarbackBTN-button");
				expect(resultsButton).toBeTruthy();
				resultsButton.click();
		});

 }); // end describe()
