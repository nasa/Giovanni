/**
* @this a single jasmine.Spec describe function that runs regression test: Test
* UI-MaxPoints-001
* @param none
* @returns test status
* @author Keith Bryant
*/
describe( "UI-MaxPoints-001",
	function() {

		// var datep;
		// it("Setup", function() {
		// 		datep = session.dataSelector.datePicker.currentPicker;
		// });

		var QUERY_STRING = "service=TmAvMp&"+
			"starttime=2014-03-01T00:00:00Z&endtime=2014-06-01T23:59:59Z&"+
			"bbox=-127.8515,-31.2305,71.836,77.0508&"+
			"data=GPM_3IMERGHHE_05_precipitationCal&"+
			"dataKeyword=IMERG";

		beforeAll(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

		afterEach(function(done){
			setTimeout(function(){
				done();
			}, 500);
		});

	it("Testing max points constraint for Time-Averaged Map (exceeds maximum)",
		async function() {
			var datep = session.dataSelector.datePicker.currentPicker;
			var statusMsg = $('#sessionDataSelSvcPkStatus').text();
			var regionInput = $('#sessionDataSelBbPkbbox');

			expect(statusMsg).toContain('exceeds the maximum');
		
			datep.startDateTF.setValue('2014-05-20');
			var element = document.getElementById('startDateContainer_year');
			if ("fireEvent" in element)
				element.fireEvent("onchange");
			else {
				var evt = document.createEvent("HTMLEvents");
				evt.initEvent("change", false, true);
				element.dispatchEvent(evt);
			}
		});

	it("Testing max points constraint for Time-Averaged Map part 2 (no message, after shorter time period selected)",
		async function() {	

			var datep = session.dataSelector.datePicker.currentPicker;
			var statusMsg = $('#sessionDataSelSvcPkStatus').text();

			expect(statusMsg).toEqual('');

			datep.startDateTF.setValue('2014-03-02');
			var element = document.getElementById('startDateContainer_year');
				if ("fireEvent" in element)
					element.fireEvent("onchange");
				else {
					var evt = document.createEvent("HTMLEvents");
					evt.initEvent("change", false, true);
					element.dispatchEvent(evt);
				}
		});
	
	it("Testing max points constraint for Time-Averaged Map part 3 (message back again)",
		async function() {	

			var statusMsg = $('#sessionDataSelSvcPkStatus').text();
			expect(statusMsg).toContain('exceeds the maximum');		
			
			field = document.getElementById('sessionDataSelBbPkbbox');
			field.value = '-103.3594,2.1094,-54.8437,25.3125';
			mychange(field);

		});

	it("Testing max points constraint for Time-Averaged Map part 4 (no message, after when bounding box reduced)",
		async function() {	

			var statusMsg = $('#sessionDataSelSvcPkStatus').text();
			expect(statusMsg).toEqual('');
		});
});



