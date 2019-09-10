/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 *       Test Plan (Sprint 30) UI-BboxPicker 003
 * @param none
 * @returns test status
 * @author Richard Strub
 */

describe(
    "Test Plan (Sprint 43) UI-BboxPicker 006 ",
    function() {

        var DocUIBboxPicker006 = 
  	    'https://docs.google.com/document/d/1vIP13XFkMwPAOQBPLgRFJUZykV9-W8Ctk1M7PAiZOZE/edit#heading=h.qltpcjf5xgyy';
        var test;

        // Wait period (milliseconds) for GUI update after resetting
        // the interface.
        var GUI_RESET_WAIT_PERIOD = 1000;

	it(
	    "Watch for bounding box dateline flip (UI-BboxPicker 006)",
	    function() {
                // This is a case where only the test title changes:
                // i.e. this test isn't in the test plan. I am just opening the map
                var TestPlan = DocUIBboxPicker006;
                test = new giovanni.test.RegressionTest (this,TestPlan);

                // Reset the page to the default state, and wait for
                // the update to complete.
                runs(function() {
                    test.RESET();
                }); // end runs()
                waits(GUI_RESET_WAIT_PERIOD);

		runs(function() {
            alert("Please watch the map for the next few seconds please. Error if it flips");
		    var element = document.getElementById('sessionDataSelBbPkmapLink');
                    myfire(element);
		    
		});
		waits(1900);
                var map;
		runs(function() {
                    map = session.dataSelector.boundingBoxPicker.Map.map;
                    expect(map).toBeTruthy();
                    var center = new OpenLayers.LonLat(180,0);
                    expect(center).toBeTruthy();
                    map.panTo(center);
		});
		waits(1900);
		runs(function() {
		    field = document.getElementById('sessionDataSelBbPkbbox');
                    field.value = '178, 75, -178, 88';
                    mychange(field);
		    
		});
		waits(1900);
		runs(function() {
		    field = document.getElementById('sessionDataSelBbPkbbox');
                    field.value = ' 160, -29, -178, -12 ';
                    mychange(field);
		});
		waits(1900);
		runs(function() {
		    field = document.getElementById('sessionDataSelBbPkbbox');
                    field.value = '178, 45, -178, 50 ';
                    mychange(field);
		    
		});
		waits(1900);
		runs(function() {
		    expect(map).toNotBe(null);
		});
		runs(function() {
		    field = document.getElementById('sessionDataSelBbPkbbox');
                    field.value = '178, 45, -138, 50 ';
                    mychange(field);
		    
		});
		waits(1900);
		// The map can NO LONGER be closed by clicking on the globe
		runs(function() {
                    var closeButton = $("div#mapPanel").find("a");
                    closeButton[0].click();
		    
		});
	    });

    });
