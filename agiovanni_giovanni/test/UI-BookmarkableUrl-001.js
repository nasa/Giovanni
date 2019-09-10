/**
 * @this This file contains a single Jasmine test specification for:
 *       UI-BookmarkableUrl-001
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */

describe("UI-BookmarkableUrl-001",
  function() {
  	
		var QUERY_STRING = 
			"service=TmAvMp&" +
			"starttime=2003-01-01T06:00:00Z&endtime=2003-01-01T07:59:59Z&" +
			"bbox=-120,20,-70,50&" +
			"data=NLDAS_NOAH0125_H_002_evpsfc&" +
			"variableFacets=dataProductPlatformInstrument%3ANLDAS%20Model%3B&portal=GIOVANNI&format=json";		 

		beforeAll(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetup(QUERY_STRING);
		});

		it("should populate the GUI from a bookmarked URL",
			function() {
				// Plot type
				var mapRadioButton = document.getElementById("sessionDataSelSvcPkCtrl" + "TmAvMp");
				if (mapRadioButton==null) mapRadioButton = document.getElementById("service_maps+TmAvMp");
				expect(mapRadioButton).toBeTruthy();
				expect(mapRadioButton.checked).toBe(true);

				// Start date/time
				var startDateContainer_year = document.getElementById("startDateContainer_year");

				expect(startDateContainer_year).toBeTruthy();
				expect(startDateContainer_year.value).toBe("2003");

				var startDateContainer_month = document.getElementById("startDateContainer_month");

				expect(startDateContainer_month).toBeTruthy();
				expect(startDateContainer_month.value).toBe("01");

				var startDateContainer_day = document.getElementById("startDateContainer_day");

				expect(startDateContainer_day).toBeTruthy();
				expect(startDateContainer_day.value).toBe("01");

				var startHours = document.getElementById("startTimeContainer_hours");

				expect(startHours).toBeTruthy();
				expect(startHours.value).toBe("06");

				// End date/time
				var endContainer_year = document.getElementById("endContainer_year");

				expect(endContainer_year).toBeTruthy();
				expect(endContainer_year.value).toBe("2003");

				var endContainer_month = document.getElementById("endContainer_month");

				expect(endContainer_month).toBeTruthy();
				expect(endContainer_month.value).toBe("01");

				var endContainer_day = document.getElementById("endContainer_day");

				expect(endContainer_day).toBeTruthy();
				expect(endContainer_day.value).toBe("01");

				var endHours = document.getElementById("endTimeContainer_hours");

				expect(endHours).toBeTruthy();
				expect(endHours.value).toBe("07");

				// Bounding box
				var bboxField = document.getElementById("sessionDataSelBbPkbbox");

				expect(bboxField).toBeTruthy();
				var bbox = bboxField.value;
				expect(bbox).toBe("-120,20,-70,50");

				// Platforms
				var checkbox = document.getElementById("dataProductPlatformInstrument_NLDASModel");

				expect(checkbox).toBeTruthy();
				expect(checkbox.checked).toBe(true);

				// Selected variables
				var resultTable = document.getElementById("resultTable");

				expect(resultTable).toBeTruthy();
				var yui_dt_bd = resultTable.childNodes[2];
				expect(yui_dt_bd).toBeTruthy();
				var table = yui_dt_bd.childNodes[0];
				expect(table).toBeTruthy();
				var tbody = table.childNodes[2];
				expect(tbody).toBeTruthy();
				var tr = tbody.childNodes[0];
				expect(tr).toBeTruthy();
				var td = tr.childNodes[0];
				expect(td).toBeTruthy();
				var div = td.childNodes[0];
				expect(div).toBeTruthy();
				checkbox = div.childNodes[0];
				expect(checkbox).toBeTruthy();
				expect(checkbox.checked).toBe(true);

		}); // end it()

}); // end describe()
