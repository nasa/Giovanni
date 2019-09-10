/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 *       Test Plan (Sprint 30) UI-DatePicker-013
 * @param none
 * @returns test status
 * @author Richard Strub
 */
describe(
    "Test Plan (Sprint 43) UI-DatePicker-013",
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
        var QUERY_STRING = "service=TmAvMp&starttime=&endtime=&bbox=-180,-90,180,90&data=GSSTFM_3_SET1_INT_E&variableFacets=dataProductTimeInterval%3Amonthly%3B";

        it("Setup", function() {
            session.dataSelector.clearSelections();
            datep = session.dataSelector.datePicker.currentPicker;
        });

        it(
            "Month auto-fill 1 (UI-DatePicker 013)",
            function() {

                TestPlan =
                    "https://docs.google.com/document/d/1vIP13XFkMwPAOQBPLgRFJUZykV9-W8Ctk1M7PAiZOZE/edit#heading=h.zgkuft71pvzr";
                test = new giovanni.test.RegressionTest (this,TestPlan);


                runs(function() {
                    setUserInterfaceFromQueryString(QUERY_STRING);
                }); // end runs()

                waits(1000);
                runs(function() {
                    // set dates with arbitrary days...they should be set
                    // correctly due to the 'month-only' setting of the picker
                    datep.startDateTF.setValue('2008-01-01');
                    datep.endDateTF.setValue('2008-02-29');
                    //datep.validate();
                });
                waits(1000);
                runs(function() {
                    var startdate = datep.startDateTF.getValue();
                    var enddate =   datep.endDateTF.getValue();
                    var startDay = startdate.split("-")[2];
                    var endDay = enddate.split("-")[2];
                    expect(startDay).toMatch('01');
                    expect(endDay).toMatch('29');
                });

             }
         );
    });
