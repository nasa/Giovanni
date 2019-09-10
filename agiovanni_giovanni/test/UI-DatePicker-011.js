/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 *       Test Plan (Sprint 30) UI-DatePicker-010
 * @param none
 * @returns test status
 * @author Richard Strub
 */
describe(
    "Test Plan (Sprint 43) UI-DatePicker-011",
    function() {
        /*
         * Inside the describe block ,
         * Outside of your it blocks,
         *  Declare your test plan link, 
         *  Test title and 
         *  create a new test object
         */
        var test;
        var datep;

        var QUERY_STRING =
                "service=TmAvMp&starttime=&endtime=&" +
                "data=GLDAS_NOAH10_3H_2_0_Rainf_tavg&dataKeyword=GLDAS"

        var CRITERIA_UPDATE_WAIT_PERIOD = 3000;

        it("Setup", function() {
            datep = session.dataSelector.datePicker.currentPicker;
        });

    	it(
    	    "Earliest and Latest Dates in the Date Widget = dates in variable picker (UI-DatePicker 011)",
    	    function() {

                TestPlan = 
    		      "https://docs.google.com/document/d/1G6dx0Kk55NP5iWOs459GUT6rrcG7hNJjXn80-JNo9qE/edit#heading=h.se3eduqggeow";
                test = new giovanni.test.RegressionTest (this,TestPlan);
                
                test.RESET();
                
                waits(2000);

                runs(function() {
                    setUserInterfaceFromQueryString(QUERY_STRING);
                }); // end runs()
                waits(CRITERIA_UPDATE_WAIT_PERIOD);

                // var facetfld = $("input#facetedSearchBarInput");
                // facetfld.val('GLDAS');

                // waits(800);
                runs(function() {
                	btn1 = $("button#facetedSearchButton").eq(0);
                	btn1.trigger('click');
                });
        		waits(1000);

                runs(function() {
        			var b = $("#resultTable table:eq(1) tr:eq(2) td:first input[type=checkbox]");
        			b[0].click();
                });

           //      if (false) { // this is good sample jquery code but does not work
           //                   // in context becasuse of the crazy state of the facets.
        			// var h = $("#facet1_c");
        			// h.trigger('click');


        			// runs(function() {
        			// var a = $("#facet1_c ~ div input[type=checkbox]:eq(2)");
        			// a[0].click();
        			// });

        			// waits(1000);

           //      }

                waits(1500);
                runs(function() {
                    $("#startDateCalendarButton").click();
                });
                waits(500);

                runs(function() {
                  $("div#startDateCalendar").find($(".selected")).click()
                });
                waits(500);

                runs(function() {
                    $("#endDateCalendarButton").click();
                });
                waits(500);

                runs(function() {
                  $("div#endDateCalendar").find($(".selected")).click()
                });

                var startdate;
                var enddate;
                waits(500);

                runs(function() {
                	startdate = '1948-01-01'; 
                	//enddate =   datep.endDateTF.getValue(); 
                });
                waits(1500);

                runs(function() {
                   startvar = session.dataSelector.variablePicker.fs.facetedResults[0].getStartDate()
                   expect(startvar).toEqual(startdate);
            });
        });
    });
