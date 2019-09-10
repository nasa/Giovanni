/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-DatePicker-001
 * @param none
 * @returns test status
 * @author Richard Strub, refactored Andrey Zasorin
 */
 
describe("UI-DatePicker-001", function() {


		beforeAll(function(done){			
			setTimeout(function(){
				done();
			}, 500);
		});

		

		it("examine datepicker info message", 
			function() {				
				field = document.getElementById('dateRangeDisplay');
				expect(field.innerHTML).toContain('Valid Range: ');
		});

		it("validate proper date in datepicker", 
			function() {
				var datep = session.dataSelector.datePicker.currentPicker;
				datep.startDateTF.setValue('2001-01-32');
				datep.validate();
				var element = document.getElementById("endContainer_year");
				if ("fireEvent" in element)
					element.fireEvent("onchange");
				else {
					var evt = document.createEvent("HTMLEvents");
					evt.initEvent("change", false, true);
					element.dispatchEvent(evt);
				}
				expect(datep.statusStr).toContain('not a valid date');
		});

		it("no info message with Lat-Lon Map and same dates",
			function() {
				var datep = session.dataSelector.datePicker.currentPicker;
				datep.startDateTF.setValue('2001-01-31');
				datep.endDateTF.setValue('2001-01-31');
				datep.validate();
				// btn = $( "input#sessionDataSelSvcPkCtrlTmAvMp").eq(0);
				// if(btn==null) btn = $( "input#service_maps+TmAvMp").eq(0);
				// btn.trigger('click');
				// console.log(datep.statusStr);
				expect(datep.statusStr).toEqual('');
		});

		it("before valid date range message", 
			function() {						
				var datep = session.dataSelector.datePicker.currentPicker;
				datep.startDateTF.setValue('1900-01-01');
				datep.endDateTF.setValue('1900-01-31');
				datep.validate();
				var element = document.getElementById('startDateContainer_year');
				if ("fireEvent" in element)
					element.fireEvent("onchange");
				else {
					var evt = document.createEvent("HTMLEvents");
					evt.initEvent("change", false, true);
					element.dispatchEvent(evt);
				}
				expect(datep.statusStr).toContain('end date');
		});

		it("end date must be greater than the start date message",
			function() {
				var datep = session.dataSelector.datePicker.currentPicker;
				datep.startDateTF.setValue('2003-01-01');
				datep.endDateTF.setValue('2002-01-31');
				datep.validate();
				expect(datep.statusStr).toContain( 'cannot be later than the end date');		    
		});

		it("specify a date (after erasing date)", 
			function() {
				var datep = session.dataSelector.datePicker.currentPicker;	
				datep.startDateTF.setValue('');
				datep.endDateTF.setValue('');
					
				var element = document.getElementById('startDateContainer_year');
				if ("fireEvent" in element)
					element.fireEvent("onchange");
				else {
					var evt = document.createEvent("HTMLEvents");
					evt.initEvent("change", false, true);
					element.dispatchEvent(evt);
				}			
				datep.validate();
				expect(datep.statusStr).toContain('Please specify a start date.');
		});

		it("year 200 is not a valid year or proper date format",
			function() {
				var datep = session.dataSelector.datePicker.currentPicker;
				datep.startDateTF.setValue('200-01-01');
				datep.validate();
				expect(datep.statusStr).toContain('not a valid date');
		});

		it("two hour boxed should show 00 hr and grayed out",
			function() {
				statis = YAHOO.util.Dom.get('startTimeContainer_hours').disabled;
				expect(statis.toString()).toContain('true');

				statis = YAHOO.util.Dom.get('endTimeContainer_hours').disabled;
				expect(statis.toString()).toContain('true');
		});

});
