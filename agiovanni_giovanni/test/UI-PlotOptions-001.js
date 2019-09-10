/**
 * @this a single jasmine.Spec describe function that runs regression test: Test
 *       Plan (Sprint 30) UI-PlotOptions-001
 * @param none
 * @returns test status
 * @author Richard Strub
 */

describe(
		"Test Plan (Sprint 30) UI-PlotOptions-001",
		function() {

                    // Wait period (milliseconds) for GUI update after
                    // resetting the interface.
                    var GUI_RESET_WAIT_PERIOD = 1000;

            var TestPlan = 
		    "https://docs.google.com/document/d/1ukml1Z7S-nrexNuJ5q7Il3FP5Jo8ECQXI8OIJoV11TE/edit#heading=h.o39cx2t1bzl";
            var test = new giovanni.test.RegressionTest (this,TestPlan);

                    // Reset the page to the default state, and wait
                    // for the update to complete.

			var monitor;
			var callback;
			var varp;
			var srv;
                        var isGroupServicePicker = false;
			var tmp;
			var heading;
			var error_case = 0;
                        var datep;
            var Chrome = false;
            var num_plots = 0;

             if (window.browserChecker.name != 'Firefox') {
             	Chrome = true;
             }

			it("Setup", function() {
                    runs(function() {
                        test.RESET();
                    }); // end runs()
                    waits(GUI_RESET_WAIT_PERIOD);
				srv = session.dataSelector.servicePicker;
				isGroupServicePicker = 
					typeof srv.getGroups === Function ? true : false;
				varp = session.dataSelector.variablePicker;
				datep = session.dataSelector.datePicker.currentPicker;
                var QUERY_STRING = "";
                runs(function() {
                	setUserInterfaceFromQueryString(QUERY_STRING);
                }); // end runs()

			});

			// Do date and map and set up for facet search
			it("Prepare for clicking of Plot Button", function() {
				runs(function() {
				if(isGroupServicePicker){
			        	btn = $("input#sessionDataSelSvcPkCtrlStSc").eq(0);
				}else{
			        	btn = $("input#service_comparison+StSc").eq(0);
				}else{
				}
					btn.trigger('click');
                    datep.startDateTF.setValue('2003-01-01');
                    datep.endDateTF.setValue('2003-01-07');
				}
					btn.trigger('click');
                    datep.startDateTF.setValue('2003-01-01');
                    datep.endDateTF.setValue('2003-01-07');
					mapfld = $("input#sessionDataSelBbPkbbox");
					mapfld.val('-54.141, -27.422, -23.203, 11.250');
					// Search for MYD08
					facetfld = $("input#facetedSearchBarInput");
					facetfld.val('MODIS-Aqua');
				});
				waits(800);
				// Click search button of variable/facet picker
					runs(function() {
						btn1 = $("button#facetedSearchButton").eq(0);
						btn1.trigger('click');

					});
					waits(800);
					// select 3rd checkbox
					runs(function() {
						contr = $("#resultTable");
						cbs = contr.find(":input");
						cbs[2].checked = true;
						test.triggerOnClick(cbs[2]);
					});
					waits(800);
					// Hit variable picker rest:
					runs(function() {
						btn1 = $("button#facetedClearButton").eq(0);
						btn1.trigger('click');
					});
					// Now get the MOD08:
					runs(function() {
						facetfld = $("input#facetedSearchBarInput");
						facetfld.val('MODIS-Terra');
					});
					waits(800);
					// Click search button of variable/facet picker
					runs(function() {
						btn1 = $("button#facetedSearchButton").eq(0);
						btn1.trigger('click');

					});
					waits(800);
					// select 4th checkbox
					runs(function() {
						contr = $("#resultTable");
						cbs = contr.find(":input");
						cbs[3].checked = true;
						test.triggerOnClick(cbs[3]);
					});
				});

			it(
					"Clicking Plot Button, 1 scatter plot appears",
					function() {
						waits(1500);
						runs(function() {
							btn1 = $(
									"button#sessionDataSelToolbarplotBTN-button")
									.eq(0);
							btn1.trigger('click');
                            if (Chrome) {
                	          num_plots = $("span:contains('Plot Options')").length  ;
                            }
                            else {
                	           num_plots = $("a:contains('Plot Options')").length 
                            }
                            console.log('There are ' + num_plots + ' plots with Plot options on the page');
							setFirstPlotMonitor();
						});

						callback = jasmine.createSpy();
						/*
						 * waitsFor
						 */
						waitsFor(function() {
							return callback.callCount > 0;
						}, "First Scatter Plot never displayed", 40000);

						runs(function() {
							expect(error_case).toEqual(0);
						});

					});

			it("Changing minimum and replotting", function() {
            var TestPlan = 
		    "https://docs.google)com/document/d/1ukml1Z7S-nrexNuJ5q7Il3FP5Jo8ECQXI8OIJoV11TE/edit#heading=h.o39cx2t1bzl";
            var test = new giovanni.test.RegressionTest (this,TestPlan);

				if (error_case == 1) {
					expect('Original Plot failed so...').toEqual(
							"This was skipped");
					return;
				}
				waits(2000); // lets admire images
					runs(function() {
						link = document.getElementById("result1PlotOptions");
						if (link) {
							test.triggerOnClick(link);
						} else {
							// Chrome:
					link = $("span:contains('Plot Options')").eq(0);
					link.click();
				}
			});
			waits(500);

			runs(function() {
				field = document
						.getElementById("MYD08_D3_051_Optical_Depth_Land_And_Ocean_MeanMIN");
				if (field != null) {
					field.value = "-1.1";
                    mychange(field);
				}

			});
			waits(500);
			runs(function() {
				button = $("button#rePlotBTN-button").eq(0);
				button.trigger('click');
				// I think in this case I can use the same monitor
				setPlotMonitor();
			});

			callback = jasmine.createSpy();
			/*
			 * waitsFor
			 */
			waitsFor(function() {
				return callback.callCount > 0;
			}, "Replotted Images never displayed", 90000);

			waits(2000)// wait a second so we can fool with title...
			runs(function() {
				heading = $("div#sessionWorkspaceResultView").find(
						".resultTitle");
				heading
						.html("You have 10 seconds to check that y axis starts at -1.1");
				heading.css('color', 'red');
			});
			waits(4000)

			runs(function() {
				heading.css('color', 'black');
				expect(error_case).toEqual(0);

			});
		}	);

			it("Restoring defaults and replotting again...", function() {
				var TestPlan = 
				"https://docs.google.com/document/d/1ukml1Z7S-nrexNuJ5q7Il3FP5Jo8ECQXI8OIJoV11TE/edit#heading=h.o39cx2t1bzl";
            	var test = new giovanni.test.RegressionTest (this,TestPlan);
				waits(2000); //lets admire replotted image
					if (error_case == 1) {
						expect('Original Plot failed so...').toEqual(
								"This was skipped");
						return;
					}
					runs(function() {
						link = document.getElementById("result1PlotOptions");
						if (link) {
							test.triggerOnClick(link);
						} else {
							// Chrome:
					link = $("span:contains('Plot Options')").eq(0);
					link.click();
				}

			});
			waits(500);

			// Hit restore defaults button:
			runs(function() {
				button = $("button#restoreDefaultsBTN-button").eq(0);
				button.trigger('click');
			});

			runs(function() {
				button = $("button#rePlotBTN-button").eq(0);
				button.trigger('click');
				// I think in this case I can use the same monitor
				setPlotMonitor();
			});

			callback = jasmine.createSpy();
			/*
			 * waitsFor
			 */
			waitsFor(function() {
				return callback.callCount > 0;
			}, "Replotted default Images never displayed", 30000);

			waits(2000); //lets admire replotted image
			runs(function() {
				heading
						.html("You have 10 seconds to check that the y axis starts at -0.05");
				heading.css('color', 'red');
				expect(callback.callCount).toBeGreaterThan(0);

			});
			waits(4000);
		}	);
			it(
					"Returning to Data Page and resetting",
					function() {
				       var TestPlan = 
					   "https://docs.google.com/document/d/1ukml1Z7S-nrexNuJ5q7Il3FP5Jo8ECQXI8OIJoV11TE/edit#heading=h.o39cx2t1bzl";
            			var test = new giovanni.test.RegressionTest (this,TestPlan);
						waits(3000);
						runs(function() {
							if (error_case == 0) {
								heading.css('color', 'black');
							}
						});

						waits(1500);
						// uncheck buttons.
						runs(function() {
							contr = $("#resultTable");
							cbs = contr.find(":input");
							cbs[0].checked = false;
							test.triggerOnClick(cbs[0]);
							cbs[2].checked = false;
							test.triggerOnClick(cbs[2]);
							// Hit main reset button back on Data Selection
							// page:
						    test.RESET();
						});
						runs(function() {
							message = document
									.getElementById('facetedResultsStatusBar').childNodes[0].data;
							expect(message).toContain('2 variables');

						});
                       
					});

			setFirstPlotMonitor = function() {
				monitor = setInterval(monitorFirstPlot, 3000);
			}

   
			monitorFirstPlot = function() {

				//if (session.workspace.resultView.resultViewContainer.children.length > 0) {
                var a;
                if (Chrome) {
                	a = $("span:contains('Plot Options')");
                }
                else {
                	a = $("a:contains('Plot Options')");
                }
                 
                console.log(a.length);
                if (a.length == num_plots + 1) {
					clearInterval(monitor);
					callback();
				}

			}
  
			setPlotMonitor = function() {
				monitor = setInterval(monitorPlot, 3000);
			}
			monitorPlot = function() {
              a = $("button:contains('Restore Defaults')");
                if (a.length < 1) {
					clearInterval(monitor);
					callback();
				}
            }

		});
