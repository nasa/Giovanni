/**
 * @this
 * UI-ServicePicker-004
 * @Andrey Zasorin
 */

describe("UI-ServicePicker-004", function() {
	
	var QUERY_STRING = 
			'service=CoMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T01:59:59Z' + 
			'&bbox=-54.141,-27.422,-23.203,11.25' + 
			'&data=NLDAS_FORA0125_H_002_apcpsfc%2CNLDAS_NOAH0125_H_002_evpsfc&dataKeyword=NLDAS';

	beforeAll(async function(){
		// Load the bookmarked URL into the GUI.
		await querySetup(QUERY_STRING);
	});

	it('Multiple status messages check (3 hours, reminder, and no data)' , 
		function() { 

		var datep = session.dataSelector.datePicker.currentPicker;
    expect(datep.statusStr).toContain('3 hours');

    var elemNode = document.getElementById('facetedResultsStatusBar');
    expect(elemNode.innerHTML).toContain("Reminder");

    var dataNode = document.getElementById('sessionDataSelBbPkstatusDiv');
    expect(dataNode.innerHTML).toContain("has no data");
	});		

});