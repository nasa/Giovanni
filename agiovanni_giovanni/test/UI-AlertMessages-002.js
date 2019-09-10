/**
 * @this This file contains a single Jasmine test specification for:
 * UI-AlertMessages-002
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */

describe("UI-AlertMessages-002",
	function() {
		
		// Timeout period (milliseconds) for this spec to complete.
		jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000;
		

		// HTTP query string for the data selection criteria to
		// load.

		var QUERY_STRING = "service=TmAvMp&" +
			"starttime=2005-01-01T00:00:00Z&endtime=2005-01-04T23:59:59Z&" +
			"bbox=-180,-90,180,90&" +
			"data=OMAERUVd_003_FinalAerosolAbsOpticalDepth388&" +
			"variableFacets=dataFieldMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3B";

		if (!browserHasAsyncAwaitSupport()) {
			return;
		}

	beforeEach(async function() {
		await querySetup(QUERY_STRING, true);
	});

	it("should find the news alert box on the results screen",
		async function() {
			var headline;
			headline = document.getElementById("headline");
			expect(headline).toBeTruthy();
	}); // end it()

}); // end describe()
