/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-DatePicker-009
 * @param none
 * @returns test status
 * @author Richard Strub, refactored Andrey Zasorin
 */
describe("UI-DatePicker-009",
	function() {
		
		var QUERY_STRING =
			"service=TmAvMp&starttime=2014-03-12T16:32:00Z&" +
			"endtime=2014-03-15T20:43:59Z&" +
			"data=GPM_3IMERGHHE_05_precipitationCal"

		beforeEach(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

		it("select hourly: hours available", async function() { 

			expect(document.getElementById('startTimeContainer_hours').disabled.toString()).toEqual('false');
			expect(document.getElementById('startTimeContainer_hours').value).toEqual('16');
			expect(document.getElementById('startTimeContainer_minutes').disabled.toString()).toEqual('false');
			expect(document.getElementById('startTimeContainer_minutes').value).toEqual('32');
		
			expect(document.getElementById('endTimeContainer_hours').disabled.toString()).toEqual('false');
			expect(document.getElementById('endTimeContainer_hours').value).toEqual('20');
			expect(document.getElementById('endTimeContainer_minutes').disabled.toString()).toEqual('false');
			expect(document.getElementById('endTimeContainer_minutes').value).toEqual('43');		   
		});

	});
