/**
 * @this This file contains a single Jasmine test specification for:
 *       Sprint 43 test UI-CorrelationMap-001
 * @param none
 * @returns test status
 * @author Eric Winter
 */

describe("UI-CorrelationMap-001",
function() {

	// Timeout period (milliseconds) for this spec to complete.
	jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000;

	// HTTP query string for the data selection criteria to
	// load.
	var QUERY_STRING =
	"service=CoMp&starttime=2003-01-01T00:00:00Z&" +
	"endtime=2003-01-05T23:59:59Z&" +
	"bbox=-54.141,-27.422,-23.203,11.25&" +
	"data=TRMM_3B42RT_Daily_7_precipitation%2C" + 
	"TRMM_3B42_Daily_7_precipitation&" +
	"dataKeyword=rainfall";
	
	var MAP_TITLES = [
		"Correlation for 2003-01-01 01:30Z - 2003-01-06 01:29Z",
		"Time matched sample size for 2003-01-01 01:30Z - 2003-01-06 01:29Z",
		"Time matched difference for 2003-01-01 01:30Z - 2003-01-06 01:29Z (Var. 1 - Var. 2)"
	];


	beforeEach(async function() {
		await querySetup(QUERY_STRING, true);
	});

	it("should create correlation, sample size, and difference maps",
		async function() {
			
		var currentPlots = $(".mapFrame");
		expect(currentPlots.length).toEqual(3);

		for (var i = 0; i < MAP_TITLES.length; i++) {
			var plotMapTitle = $("div.plotMapTitle_map").get(i).childNodes[0];
			var title = plotMapTitle.textContent;
			expect(title).toContain(MAP_TITLES[i]);
		}

	}); // end it()

}); // end describe()
