/**
 * @this
 * UI-ServicePicker-003
 * @Andrey Zasorin
 */

describe("UI-ServicePicker-003", function() {
  var QUERY_STRING = 
    'service=IaSc&starttime=2005-01-01T00:00:00Z&endtime=2005-01-05T23:59:59Z' + 
    '&bbox=-114.6094,-30.2344,16.1719,52.7344' + 
    '&data=OMAEROe_003_SingleScatteringAlbedoMW_463_0%2COMAERUVd_003_FinalAerosolSingleScattAlb500';

  beforeAll(async function(){
    // Load the bookmarked URL into the GUI.
    await querySetup(QUERY_STRING);
  });

	it('The Select Plot component message displays (868061) exceeds the maximum (30000) we can process for Scatter (Interactive)' , 
		function() { 
		var elemNode = document.getElementById('sessionDataSelSvcPkStatus');
    expect(elemNode.innerHTML).toContain("exceeds");
  });   

});

