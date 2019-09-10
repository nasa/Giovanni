/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-DatePicker-015
 * @param none
 * @returns test status
 * @author K. Bryant
 */
describe( "UI-DatePicker-015",
	function() {

	var QUERY_STRING = 
			  "service=TmAvMp&" + 
			  "starttime=2008-01-12T00:00:00Z&" + 
			  "endtime=2008-02-23T23:59:59Z&" +
			  "bbox=-180,-90,180,90&" + 
			  "variableFacets=dataProductTimeInterval%3Amonthly%3B";

	beforeAll(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

	afterEach(function(done){
		setTimeout(function(){
			done();
		}, 3500);
	});

	it("Month Picker - Auto-Correct Date when selecting month data (inspect datePicker before variable)",
		async function() {
	
			var datep = session.dataSelector.datePicker.currentPicker;			

			var start = datep.startDateTF.getValue();
			var end   = datep.endDateTF.getValue();
			expect(start).toEqual('2008-01-12');
			expect(end).toEqual('2008-02-23');

			var checkboxes;

			var resultTable = document.getElementById('resultTable');
			var inputElements = resultTable.getElementsByTagName('input');
			checkboxes = new Array();
				for(var i=0;i<inputElements.length;i++){
						if(inputElements[i].type=='checkbox'){
						checkboxes.push( inputElements[i] );
				}
			}

			checkboxes[0].click();
		});
	
	it("Month Picker - Auto-Correct Date when selecting month data (inspect after variable selected)",
		async function() {

			var datep = session.dataSelector.datePicker.currentPicker;

			var start = datep.startDateTF.getValue();
			var end   = datep.endDateTF.getValue();
			expect($('#startDateContainer_day').prop('readonly')).toBeTruthy();
      expect($('#endContainer_day').prop('readonly')).toBeTruthy();
			expect(start).toEqual('2008-01-01');
			expect(end).toEqual('2008-02-29');

	});

});
