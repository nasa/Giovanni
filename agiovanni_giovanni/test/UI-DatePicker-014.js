/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 *       Test Plan (Sprint 30) UI-DatePicker-014
 * @param none
 * @returns test status
 * @author Richard Strub
 */
describe(
    "Test Plan (Sprint 43) UI-DatePicker-014",
    function() {
        /*
         * Inside the describe block ,
         * Outside of your it blocks,
         *  Declare your test plan link, 
         *  Test title and 
         *  create a new test object
         */
        var test;

        var QUERY_STRING = "service=TmAvMp&starttime=2008-01-01T00:00:00Z&endtime=2008-02-29T23:59:59Z&bbox=-180,-90,180,90&data=GSSTFM_3_SET1_INT_E&variableFacets=dataProductTimeInterval%3Amonthly%3B";
        it("Setup", function() {
            session.dataSelector.clearSelections();
            //datep = session.dataSelector.datePicker.currentPicker;
        });

        it(
            "Month Picker - tabbing auto-correct (UI-DatePicker 014)",
            function() {

                TestPlan =
           "https://docs.google.com/document/d/1vIP13XFkMwPAOQBPLgRFJUZykV9-W8Ctk1M7PAiZOZE/edit#heading=h.bwcxkfmm7714";
                var test = new giovanni.test.RegressionTest (this,TestPlan);

                runs(function() {
                    setUserInterfaceFromQueryString(QUERY_STRING);
                }); // end runs()

                var datep = session.dataSelector.datePicker.currentPicker;
                waits(1000);
                runs(function() {
                    var startMonth = document.getElementById('startDateContainer_month');
                    var stopMonth = document.getElementById('endContainer_month');
                    datep.startDateTF.setValue('2008-01-12');
                    //datep.validate();
                    startMonth.focus();
                    startMonth.blur();
                    datep.endDateTF.setValue('2008-02-22');
                    //datep.validate();
                    stopMonth.focus();
                    stopMonth.blur();
                });

                var startdate;
                var enddate;
                waits(1500);
                runs(function() {
                    start = datep.startDateTF.getValue();
                    end   = datep.endDateTF.getValue();
                    expect(start).toEqual('2008-01-01');
                    expect(end).toEqual('2008-02-29');
                });

            });

    });
