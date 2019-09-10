/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-CorrelationMap-001
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("UI-ArAvTs-001",
function() {

	// Timeout period (milliseconds) for this spec to complete.
	jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000;

	// HTTP query string for the data selection criteria to
	// load.
	var QUERY_STRING =
        "service=ArAvTs&starttime=2016-01-01T00:00:00Z&" + 
        "endtime=2017-01-31T23:59:59Z&bbox=90.2417,25.8742,90.6042,26.4895&" +
        "data=AIRS3STM_006_RelHumSurf_A";

	
	var MAP_TITLES = [
		"Time Series, Area-Averaged of Relative Humidity at Surface (Daytime/Ascending, AIRS-only) monthly 1 deg. [AIRS AIRS3STM v006] percent over 2016-Jan - 2017-Jan, Region 90.2417E, 25.8742N, 90.6042E, 26.4895N"
	];


	beforeEach(async function() {
		await querySetup(QUERY_STRING, true);
	});

	it("should snap to nearest grid and create time series plot",
		async function() {
			
		var currentPlots = $(".imageFrame");
		expect(currentPlots.length).toEqual(1);

		for (var i = 0; i < MAP_TITLES.length; i++) {
      var plotTitle = $("img.plotImage").attr('title');
			expect(plotTitle).toContain(MAP_TITLES[i]);
		}

	}); // end it()

}); // end describe()
