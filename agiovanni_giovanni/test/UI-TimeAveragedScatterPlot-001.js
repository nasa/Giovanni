/**
* @this This file contains a single Jasmine test specification for:
* UI-TimeAveragedScatterPlot-001
* @param none
* @returns test status
* @author Andrey Zasorin
*/

describe("UI-TimeAveragedScatterPlot-001",
	function() {
		
		// Timeout period (milliseconds) for this spec to complete.
		jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000;		

		// HTTP query string for the data selection criteria to
		// load.

		var QUERY_STRING = "service=TmAvSc&" +
			"starttime=2003-01-01T00:00:00Z&endtime=2003-01-05T23:59:59Z&" +
			"bbox=-54.141,-27.422,-23.203,11.25&" +
			"data=TRMM_3B42_Daily_7_precipitation%2CTRMM_3B42RT_Daily_7_precipitation&" +
			"variableFacets=dataFieldMeasurement%3APrecipitation%3BdataProductTimeInterval%3Adaily%3B&" +
			"dataKeyword=TRMM";

		if (!browserHasAsyncAwaitSupport()) {
			return;
		}

		beforeEach(async function() {
			await querySetup(QUERY_STRING, true);
		});

		it("should create a 5-day time-averaged scatter plot",
			async function() {

				expect($('#interactiveScatterPlotContainer')).toBeTruthy();
				expect($('.highcharts-root')).toBeTruthy();
				expect($('.scatterMap, .interactivePlot,  .olMap')).toBeTruthy();

		}); // end it()

}); // end describe()
