/**
 * @this
 * UI-ServicePicker-002
 * @Andrey Zasorin
 */

describe("UI-ServicePicker-002", function() {

	var btn;

	beforeAll(function(done) {
		setTimeout(function(){      
			btn = $('#service_timeseries\\+ArAvTs');
		}, 1000);
		setTimeout(function(){
			done();
		}, 1500);
	});	

	beforeEach(function(done){
		btn.click();
		setTimeout(function(){
			done();
		}, 1500);
	});

	//We're going to alternate services requring 'at least 2 variable' and 'at least 1 variable'
	//and check that status message updates on UI

	it('Expect datepicker and variablepicker status messages' , function() {    
		var datep = session.dataSelector.datePicker.currentPicker;
		expect(datep.statusStr).toContain('Please specify a start date');
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select at least 1 variable');

		//prep for next spec
		btn = $('#service_maps\\+DiTmAvMp');
	});

	it('Expect \'Please select 2 variables\' status message for DiTmAvMp' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select 2 variables');

		//prep for next spec
		btn = $('#service_maps\\+AcMp');
	});

	it('Expect \'Please select at least 1 variable\' status message for AcMp' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select at least 1 variable');

		//prep for next spec
		btn = $('#service_comparison\\+TmAvSc');
	});

	it('Expect \'Please select 2 variables\' status message for TmAvSc' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select 2 variables');

		//prep for next spec
		btn = $('#service_vertical\\+CrLn');
	});

	it('Expect \'Please select at least 1 variable\' status message for CrLn' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select at least 1 variable');

		//prep for next spec
		btn = $('#service_comparison\\+IaSc');
	});

	it('Expect \'Please select 2 variables\' status message for IaSc' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select 2 variables');

		//prep for next spec
		btn = $('#service_timeseries\\+HvLn');
	});

	it('Expect \'Please select at least 1 variable\' status message for HvLn' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select at least 1 variable');

		//prep for next spec
		btn = $('#service_timeseries\\+DiArAvTs');
	});

	it('Expect \'Please select 2 variables\' status message for DiArAvTs' , function() {		
		var message = $('#facetedResultsStatusBar').text();
		expect(message).toContain('Please select 2 variables');

		//this is last spec
	});

});
