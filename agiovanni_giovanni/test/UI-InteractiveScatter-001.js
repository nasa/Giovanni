/**
* @this This file contains a single Jasmine test specification for:
* UI-InteractiveScatter-001
* @param none
* @returns test status
* @author Eric Winter
*/

describe("UI-InteractiveScatter-001",
	function() {

		// Timeout period (milliseconds) for this spec to complete.
		jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000;

		// HTTP query string for the data selection criteria to
		// load.
		var QUERY_STRING = "service=IaSc&" +
			"&starttime=2010-01-01T00:00:00Z&endtime=2010-01-05T23:59:59Z&" +
			"bbox=-47.1094,-15.3515,-32.3437,2.9297&" + 
			"data=TRMM_3B42_Daily_7_precipitation%2CTRMM_3B42RT_Daily_7_precipitation&" +
			"variableFacets=dataProductPlatformInstrument%3ATRMM%3BdataProductTimeInterval%3Adaily%3B&" +
			"dataKeyword=rainfall";

		if (!browserHasAsyncAwaitSupport()) {
			return;
		}

		beforeEach(async function() {
			await querySetup(QUERY_STRING, true);
		});

		it("should generate an interactive scatter plot on the results screen",
			async function() {
				
				expect($('#interactiveScatterPlotContainer')).toBeTruthy();
				expect($('.highcharts-root')).toBeTruthy();
				expect($('.scatterMap, .interactivePlot,  .olMap')).toBeTruthy();

			}); // end it()

}); // end describe()
