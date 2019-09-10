//$Id: RegressionTest.js,v 1.10 2015/03/06 03:27:43 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $

/**
 * Runs all tests it is concatenated with. An html file is expected to contain a
 * button which will run the runTest() function contained in this file. Jasmine
 * will then run all of the it() functions.
 * 
 * @this a jasmine.Spec file that contains the initializer function runTest()
 *       and other functions needed by various jasmine function like myfire(),
 *       mychange() and showTestPlanOnFailure
 * @param none
 * @returns test status
 * @author Richard Strub
 */

/**
 * 
 * @this is a trigger function for Jasmine. Starts all tests An html file is
 *       expected to contain a button which will run the runTest() function
 *       contained in this file. Jasmine will then run all of the it()
 *       functions.
 */


var TestTile;
var TestUrl;
var CurrentJasmineObj;

if (typeof giovanni.test =="undefined"){
  giovanni.namespace("giovanni.test");
}

giovanni.namespace("giovanni.test.RegressionTest");

/**
 * Creates the Giovanni.test.RegressionTest object.
 * 
 * @this {Giovanni.test.RegressionTest
 * @param 
 * @returns {Giovanni.test.RegressionTest} 
 * @author rstrub 
 */
giovanni.test.RegressionTest=function(it, TestPlanUrlTOCLoc) {

  this.id = "RegressionTest";
  if (TestPlanUrlTOCLoc) {
   CurrentJasmineObj = it;
   TestUrl = TestPlanUrlTOCLoc;
   TestTitle = this.description;
  }
  else {
  alert("Developers need to include a test plan url that describes their test. It looks something like this: https://docs.google.com/document/d/1ukml1Z7S-nrexNuJ5q7Il3FP5Jo8ECQXI8OIJoV11TE/edit#heading=h.7ohqtaw4cf0v");
  alert("They also need to include the it() function object");
  }



}

  beforeEach(function() {
    //giovanni.test.RegressionTest.prototype.RESET ();
  });
  afterEach(function() {
    giovanni.test.RegressionTest.prototype.showTestPlanOnFailure(CurrentJasmineObj,TestUrl); 
  });


/**
 * Runs the test 
 * 
 * @this {Giovanni.test.RegressionTest}
 * @param {Date, Date} d1 is the Minimum Bound, d2 is the Max Bound
 */
giovanni.test.RegressionTest.runTest = function(){

      var jasmineEnv = jasmine.getEnv();
      jasmineEnv.updateInterval = 1000;

      var trivialReporter = new jasmine.TrivialReporter();

      jasmineEnv.addReporter(trivialReporter);

      jasmineEnv.specFilter = function(spec) {
        return trivialReporter.specFilter(spec);
      };

      var currentWindowOnload = window.onload;

      execJasmine();

      function execJasmine() {
        jasmineEnv.execute();
      }

}

/**
 * 
 * @param it -
 *            jasmine it() object
 * @param URLofTestPlan 
 * @param Title of Test-
 *            link to the test in the test plan
 * @return Shows a link to test plan 
 # I pass these global variables in because...
 */
giovanni.test.RegressionTest.prototype.showTestPlanOnFailure = 
          function (it,TestPlanUrlTOCLoc) {

    if (!it) {
		return;
    }
	mystatus = it.results();
	var myparent;
	var div;
	if (mystatus.failedCount > 0) {
        //alert(CurrentJasmineObj.description);
		if (!document.getElementById("FailedList")) {

			myparent = document.getElementById("sessionDataSel");
			div = document.createElement("div");
			div.innerHTML = "These tests failed. These are links to these tests in the test plan";
			myul = document.createElement("ul");
			myul.id = "FailedList";
			div.appendChild(myul);
			myparent.appendChild(div);
			myparent = myul;
		} else {
			myparent = document.getElementById("FailedList");
		}

		if (myparent) {
			myli = document.createElement("li");
			var a = document.createElement('a');
			a.title = it.description; 
			a.innerHTML = a.title;
			a.target = "Regression Test Plan";
			a.href = TestPlanUrlTOCLoc;
			myli.appendChild(a);
			myparent.appendChild(myli);
		}

	}
}
/**
 * @this is a function used to trigger onchange events
 * @param element -
 *            document element to be triggered
 * orgname is mychange
 * @return
 */
giovanni.test.RegressionTest.prototype.triggerOnChangeEvent = function (element) {
	if ("fireEvent" in element)
		element.fireEvent("onchange");
	else {
		var evt = document.createEvent("HTMLEvents");
		evt.initEvent("change", false, true);
		element.dispatchEvent(evt);
	}

}
/**
 * @this is a function used to trigger click events
 * @param element -
 *            document element to be triggered
 * orgname was myfire
 * @return
 */
giovanni.test.RegressionTest.prototype.triggerOnClick = function (element) {

	if ("fireEvent" in element)
		element.fireEvent("onclick");
	else {
		var evt = document.createEvent("HTMLEvents");
		evt.initEvent("click", false, true);
		element.dispatchEvent(evt);
	}

}

/**
 * @this is a function to return the id given the text of the radio button
 **/

giovanni.test.RegressionTest.prototype.GetServicePickerId = function (nodevalue) {

	var servicePickerBtns = $("div#sessionDataSelSvcPkCtrlContainer").find(
			":input");
	var thisId;
	for ( var i = 0; i < servicePickerBtns.length; ++i) {
                if (servicePickerBtns[i].value.split('+')[1] == nodevalue) {
                        thisId = servicePickerBtns[i];
                        break;
                }
	}
	return thisId;
}

/** 
 * @this navigates to the main page and clicks on the main reset button
 **/
  

giovanni.test.RegressionTest.prototype.reset_session = function() {
    // session variable
    var session = null;
    var login = null;
    var enableLogin = null;
    var earthdataLoginCfg;


    // cleaning registry for new session
    REGISTRY = new giovanni.util.Registry();
    // REGISTRY.compRegistry = new Array();
    // REGISTRY.evtRegistry = new Array();
    // REGISTRY.consumers = new Array();
    // REGISTRY.readyRegistry = new Array();
    // REGISTRY.allReadyCallbacks = new Array();

    setTimeout(onPortalLoad, 100);

    //callback function: to run after all specified YUI components have been loaded
    function onPortalLoad() {
      // check the browser compatibility
    window.browserChecker.validate(false);

    // create session
    session = new giovanni.app.Session("session", {
      "serviceManagerURL" : "daac-bin/service_manager.pl?",
      "portal" : "GIOVANNI"
    });

      // enableLogin can be included as a query parameter to enable login
      enableLogin = giovanni.util.extractQueryValue(window.location.href, 'enableLogin');

      // Obtain configuration for Earthdata Login, and once we have it,
      // create 'login' object if enabled.
      // Once a user has logged in, methods of the 'login' object may be
      // used to obtain profile information, e.g. login.getRoles()
      // to obtain an array of user roles.
      $.ajax({
                type : "GET",
                dataType : "json",
                url : "daac-bin/getGiovanniConfig.pl?cfg=EARTHDATA_LOGIN",
                success : handleEarthdataLoginCfg,
                error : function (jqXHR, textStatus, errorThrown) {
                    console.log("ERROR reading configuration: " + textStatus + " " + errorThrown + " (" + jqXHR.responseText + ")");
                },
                //context : this
             });

      // get data selector reference from session
      var dataSelector = session.getDataSelector();
      // add pickers to the data selector
      var servicePicker = dataSelector.addWidget(giovanni.ui.DataSelector.SERVICE_PICKER, giovanni.portal.serviceDataAccessor, {
        "view" : "radio"
      });

      var datePicker = dataSelector.addWidget(giovanni.ui.DataSelector.DATE_PICKER, giovanni.portal.dateRangeDataAccessor, {
        "range" : true,
        "minBound" : '1948-01-01T00:00:00',
        "type" : "Date",
        "maxRange" : 0
      });

      var locationPicker = dataSelector.addWidget(giovanni.ui.DataSelector.BOUNDING_BOX_PICKER, 
        giovanni.portal.locationDataAccessor, {
          "maxWidth" : 360,
          "maxHeight" : 180,
          "register" : true,
          "bounds" : []
      });

      var variablePicker = dataSelector.addWidget(giovanni.ui.DataSelector.VARIABLE_PICKER, 
        giovanni.portal.variablesDataAccessor, null);

      var toolbar_config = [ {
        'type' : 'button',
        'name' : 'help',
        'label' : 'Help',
        'title' : 'Get Help!',
        'action' : session.showHelp,
        'source' : session
      }, {
        'type' : 'button',
        'name' : 'reset',
        'label' : 'Reset',
        'title' : 'Reset selections to their defaults',
        'action' : dataSelector.resetSelections,
        'source' : dataSelector
      }, {
//        'type' : 'button',
//        'name' : 'clear',
//        'label' : 'Clear',
//        'title' : 'Clear selections',
//        'action' : dataSelector.clearSelections,
//        'source' : dataSelector
//      }, {
        'type' : 'button',
        'name' : 'feedback',
        'label' : 'Feedback',
        'title' : 'Was there a problem with the portal?  Want to suggest a feature?  Please tell us!',
        'action' : session.sendFeedback,
        'args' : {
          'page' : 'dataSelection'
        },
        'source' : session 
      }, {
        'type' : 'button',
        'name' : 'plot',
        'label' : 'Plot Data',
        'title' : 'To generate a plot, fill out the form above and click this button!',
        'action' : session.initiatePlotData,
        'source' : session,
        'cssClass' : 'plotButton'
      } ];
      
      var toolbar = dataSelector.addWidget(giovanni.ui.DataSelector.TOOLBAR, "", toolbar_config);

      // perform required dependency registrations (source,consumer(s))
      REGISTRY.addEventListener(servicePicker.getId(), variablePicker.getId(), datePicker.getId(),session.getDataSelector().getId());
      REGISTRY.addEventListener(variablePicker.getId(), datePicker.getId(), servicePicker.getId(),locationPicker.getId(), session.getDataSelector().getId());
      REGISTRY.addEventListener(datePicker.getId(), servicePicker.getId(),session.getDataSelector().getId());
      REGISTRY.addEventListener(locationPicker.getId(), servicePicker.getId(),session.getDataSelector().getId());

      // jQuery script for enabling collapsible facets
      // DO THIS BEFORE processing the URL bookmark string # in the next step
      // so that the facets can be opened or collapsed as required while processing the URL
      REGISTRY.addAllReadyCallback(function() {
        try {
          $('.collapsible').collapsible({
            //place to add config items for initializing the collapsible panel
            cookieName:'', // disable cookies
            speed: 300, // 300 ms to complete the slide up or down animation
            animateClose: function (elem, opts) {
              // do the close animation and display collapsed state info for the facet
              elem.next().slideUp(opts.speed, function() { 
                var header = elem[0];
                var facets = session.dataSelector.variablePicker.fs.facets;
                for (var i=0; i<facets.length; i++) {
                  if (facets[i].getCollapsibleHeaderId() == header.id) {
                    facets[i].showCollapsedInfo();
                    break;
                  }
                }
              });
            },
            animateOpen: function (elem, opts) {
              // clear collapsed state info before expanding the facet            
              var header = elem[0];
              var facets = session.dataSelector.variablePicker.fs.facets;
              for (var i=0; i<facets.length; i++) {
                if (facets[i].getCollapsibleHeaderId() == header.id) {
                  facets[i].clearCollapsedInfo();
                  break;
                }
              }
              // do the open animation
              elem.next().slideDown(opts.speed);
            }
          });
          for (var i=0; i<2; i++) {
            var fac = variablePicker.fs.facets[i];
            var locator = '#'+fac.getCollapsibleHeaderId();
            $(locator).collapsible('open');
          }
        } catch(err) {
          console.log("Error while initiating collapsible facets : " + err.message);
        }
      });

      // process bookmark string # and load UI components appropriately
      var queryString = window.location.hash.substring(1);
      if(queryString.length>0){
        REGISTRY.addAllReadyCallback(function() {
          var comps = REGISTRY.getUIComponents();
          if (setLoadInProgress instanceof Function) setLoadInProgress(true);
          for (var i=0; i < comps.length; i++) {
              if(comps[i].loadFromQuery instanceof Function){
                 comps[i].loadFromQuery(queryString);
              }
          }
          if (setLoadInProgress instanceof Function) setLoadInProgress(false);
        });
      }
    }; // END OF onPortalLoad() function

    function handleEarthdataLoginCfg(cfg, textStatus, jqXHR) {

      // Handle return from async call that obtained configuration

      if (cfg) {
        earthdataLoginCfg = cfg.EARTHDATA_LOGIN;
      }

      // Create login if enabled in the configuration
      if (earthdataLoginCfg && (earthdataLoginCfg.enabled || enableLogin)) {
        login = new giovanni.app.Login("login", earthdataLoginCfg);
        if (login) {
          login.checkLogin();
        }
      }
      return false;
    }

    var setLoadInProgress = function(value) {
      session.loadInProgress = Boolean(value);
    };
    
    var isLoadInProgress = function() {
      return session.loadInProgress;
    };
}

giovanni.test.RegressionTest.prototype.RESET = function() {

    // $('#session').empty();

    //this.reset_session();

    // // Go back to data page if not there.
    // var btn1 = $("button#sessionWorkspaceToolbarselectDataBTN-button").eq(0);
    // if (btn1) {
	   // btn1.trigger('click');
    // }
    
    // // Click the Clear button to clear all fields.
    // var clearButton = $("button#sessionDataSelToolbarclearBTN-button").eq(0);
    // if (clearButton) {
    //     clearButton.trigger('click');
    // } else {
    //     alert("Could not find Clear button!");
    // }
    // // <HACK>
    // // Explicitly set the bounding box back to the default global
    // // coverage.
    // var bboxField = document.getElementById("sessionDataSelBbPkbbox");
    // bboxField.value = "-180, -90, 180, 90";
    // </HACK>

}
