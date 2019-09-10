/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 * UI-BboxPicker-002
 * @param none
 * @returns test status
 * @author Richard Strub, refactored Andrey Zasorin
 */
describe("UI-BboxPicker-002",
	function() {

		var QUERY_STRING = "service=TmAvMp&"+
						"starttime=&endtime=&"+
						"bbox=-20,-20,20,20&"+
						"data=NLDAS_NOAH0125_H_002_evpsfc&"+
						"variableFacets=dataProductPlatformShortName%3ANLDAS Noah Land Surface Model%3B";

		beforeAll(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

		it("no data map message is displayed",
			async function() {
				var elem = document.getElementById('sessionDataSelBbPkstatusDiv');
				expect(elem.innerHTML).toContain("Evapotranspiration");
		});
});



