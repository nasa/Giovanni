/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-DatePicker-010
 * @param none
 * @returns test status
 * @author Richard Strub, refactored Andrey Zasorin
 */
describe("UI-DatePicker-010",
	function() {	

		var QUERY_STRING =
			"service=TmAvMp&starttime=2014-03-12T16:32:00Z&" +
			"endtime=2014-03-15T20:43:59Z&" +
			"data=NLDAS_FORA0125_MA_002_pressfc"; 

		beforeEach(async function(){
			await querySetup(QUERY_STRING);
		});

		it("select hours unavailable for monthly variable.",
			async function() {
				// make sure hours are disabled

				expect(document.getElementById('startTimeContainer_hours').disabled.toString()).toEqual('true');
				expect(document.getElementById('startTimeContainer_hours').value).toEqual('00');
			
				expect(document.getElementById('endTimeContainer_hours').disabled.toString()).toEqual('true');
				expect(document.getElementById('endTimeContainer_hours').value).toEqual('23');
		});

});
