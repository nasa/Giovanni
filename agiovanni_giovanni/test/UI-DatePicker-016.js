/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-DatePicker-016
 * @param none
 * @returns test status
 * @refactored Andrey Zasorin
 */
describe("UI-DatePicker-016",
	function() {		
		
		var QUERY_STRING = "service=TmAvMp&starttime=2008-01-01T00:00:00Z&endtime=2008-02-29T23:59:59Z" + 
			"&bbox=-180,-90,180,90&data=GSSTFM_3_SET1_INT_E&variableFacets=dataProductTimeInterval%3Amonthly%3B";

		beforeEach(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

		it("month picker - calendar inspection", async function() {
			
				var calBtn =  document.getElementById('startDateCalendarLink');

				calBtn.click();
				var calContainer = document.getElementById('startDateCalendarDialog');
				// walk down the container tree until select elements are found
				var selectList = calContainer.getElementsByTagName('select');
				var table = calContainer.getElementsByTagName('table');
				var trList = table[0].getElementsByTagName('tr');
				// if the list is not empty, check the selected values for year and month
				var year, month = "";
				if(selectList != null && selectList.length>0){
					var yearSel = selectList[0];
					var monthSel = selectList[1];
					var year = yearSel.options[yearSel.selectedIndex].text;
					var month = monthSel.options[monthSel.selectedIndex].text;
					expect(year).toEqual('2008');
					expect(month).toEqual('01 - Jan');
					expect(trList[1].getAttribute('class')).toEqual('nobody');
				}

				calBtn.click();

				calBtn =  document.getElementById('endDateCalendarLink');
				calBtn.click();

				var calContainer = document.getElementById('endDateCalendar');
				var table = calContainer.getElementsByTagName('table');
				var trList = table[0].getElementsByTagName('tr');
				// walk down the container tree until select elements are found
				var selectList = calContainer.getElementsByTagName('select');
				// if the list is not empty, check the selected values for year and month
				var year, month = "";
				if(selectList != null && selectList.length>0){
					var yearSel = selectList[0];
					var monthSel = selectList[1];
					var year = yearSel.options[yearSel.selectedIndex].text;
					var month = monthSel.options[monthSel.selectedIndex].text;
					expect(year).toEqual('2008');
					expect(month).toEqual('02 - Feb');
					expect(trList[1].getAttribute('class')).toEqual('nobody');
				}
				// close the calendar				
				calBtn.click();
		});

	});

