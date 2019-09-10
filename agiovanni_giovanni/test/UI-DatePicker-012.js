/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-DatePicker-012
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */
describe("UI-DatePicker-012",
	function() {

		var QUERY_STRING =
			"service=TmAvMp&starttime=2014-03-12T16:32:00Z&" +
			"endtime=2014-03-15T20:43:59Z&" +
			"data=NLDAS_FORB0125_H_002_apcpsfc%2CNLDAS_FORA0125_MA_002_pressfc"

		var CRITERIA_UPDATE_WAIT_PERIOD = 3000;     

		beforeEach(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

		it("select hours available for monthly and hourly variables selected.",
			async function() {
				// make sure hours are available

				expect(document.getElementById('startTimeContainer_hours').disabled.toString()).toEqual('false');
				expect(document.getElementById('startTimeContainer_hours').value).toEqual('16');
				expect(document.getElementById('endTimeContainer_hours').disabled.toString()).toEqual('false');
				expect(document.getElementById('endTimeContainer_hours').value).toEqual('20');
		});

});
