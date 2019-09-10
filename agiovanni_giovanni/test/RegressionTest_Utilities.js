function mychange(element) {

	//if ("fireEvent" in element)
	//	element.fireEvent("onchange");
	//else {
		var evt = document.createEvent("HTMLEvents");
		evt.initEvent("change", false, true);
		element.dispatchEvent(evt);
	//}

}

/**
 * @this is a function used to trigger click events
 * @param element -
 *            document element to be triggered
 * @return
 */
function myfire(element) {

	//if ("fireEvent" in element)
	//	element.fireEvent("onclick");
	//else {
		var evt = document.createEvent("HTMLEvents");
		evt.initEvent("click", false, true);
		element.dispatchEvent(evt);
	//}

}

// This utility function is used to send a mousedown-mouseup event
// pair to a div element, since the click event does not seem to be
// processed. The events are set to occur at the upper-left corner of
// the div.

function clickADiv(div) {

    // Create a mouse event (left mouse button down) and send it to
    // the div.
    var mousedownEvent = document.createEvent("MouseEvent");
    mousedownEvent.initMouseEvent(
        "mousedown", true, true, window, 0, 0, 0, 0, 0,
        false, false, false, false, 0, null
    );
    div.dispatchEvent(mousedownEvent);

    // Create a mouse event (left mouse button up) and send it to the
    // div.
    var mouseupEvent = document.createEvent("MouseEvent");
    mouseupEvent.initMouseEvent(
        "mouseup", true, true, window, 0, 0, 0, 0, 0,
        false, false, false, false, 0, null
    );
    div.dispatchEvent(mouseupEvent);

}

// This utillity function loads the contents of a query string into
// the various components of the user interface.


function setUserInterfaceFromQueryString(queryString) {
		var UIComponents = REGISTRY.getUIComponents();
		for (var i = 0; i < UIComponents.length; i++) {
				if (UIComponents[i].loadFromQuery instanceof Function) {
						UIComponents[i].loadFromQuery(queryString);
				}
		}
}

// This utillity function selects service picker.


function getServicePickerId(nodevalue) {
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

// Submit a HTTP GET request for the specified RSS feed. Return the
// XMLHttpRequest object for the connection.

function requestRSSFeedContent(rssURL) {
		var rssRequest = new XMLHttpRequest();
		rssRequest.open("GET", rssURL);
		rssRequest.send(null);
		return rssRequest;
}

// Check to see if the specified XMLHttpRequest object has a complete
// RSS response. Return true if so, false if not.

// Value of readyState in HTTP request when response loading has
// completed.
var HTTP_RESPONSE_LOAD_COMPLETE = 4;

// Response code for a successful HTTP request.
var HTTP_REQUEST_OK = 200;

function rssFeedComplete(rssRequest) {
		if (rssRequest.readyState == HTTP_RESPONSE_LOAD_COMPLETE &&
				rssRequest.status == HTTP_REQUEST_OK) {
				return true;
		}
		return false;
}

// Parse the XML from the specified RSS feed request. Return a XML DOM
// object for the parsed content.

function parseRSSFeed(rssRequest) {
		var rssXML = rssRequest.responseText;
		var xmlParser = new DOMParser();
		var rssDOM = xmlParser.parseFromString(rssXML, "text/xml");
		return rssDOM;
}

//plotting and checking UI

function plotting() {
	return new Promise(function(resolve, reject) {
		// Press the "Plot Data" button. Note that the
		// plots are considered done when both plot <img>
		// elements are found. The tests which follow this
		// wait period may run so fast that the user does
		// not see the actual plot images.
		var plotDataButton =
			document.getElementById("sessionDataSelToolbar" +
			"plotBTN-button");
		plotDataButton.click();

		var interval = setInterval(function(){
			var resultViewContainer =
				document.getElementById("resultContainer");
			if (!resultViewContainer) {
				return false;
			}	 
			var imageFrame = resultViewContainer.childNodes[0];
			if (!imageFrame) {
				return false; 
			}
			var img = imageFrame.childNodes[0];
			if (!img) {
				return false;
			}
			var plot = img.childNodes[0];
			if (!plot) {
				return false;
			}
			clearInterval(interval);
			resolve();
		}, 3000);
	});
}

//just setup UI from query

function querySetup(QUERY_STRING, plot) {
	return new Promise(function(resolve, reject) {
		// Load the bookmarked URL into the GUI.

    // Creating login interval to ensure user is logged in before we can setup test bed
		var loginInterval = setInterval(function(){		
      if(login.isLoggedIn) {
        clearInterval(loginInterval);
        // after we're sure user logged in, we still need to allow UI to render itself. 
        // Sometimes function call to load UI form query happens before UI components are ready
        // 500 ms delay should take care of that. 
        setTimeout(function() {
          setUserInterfaceFromQueryString(QUERY_STRING);
        }, 500);
      }	else {
        return false;
      }
		}, 300);		
		
		var interval = setInterval(async function(){
			var resultTable = document.getElementById('resultTable');
			if (resultTable && resultTable.childNodes.length > 0) {
				if (plot) {
					clearInterval(interval);
					await plotting();
					resolve();
				} else {
					clearInterval(interval);
					resolve();
				}
			} else {
				return false;
			}
		}, 500);
	});
}

function querySetupNoVar(QUERY_STRING) {
	return new Promise(function(resolve, reject) {
		// Load the bookmarked URL into the GUI.
		setTimeout(function(){			
			setUserInterfaceFromQueryString(QUERY_STRING);
		}, 1000);	

		setTimeout(function(){			
			resolve();
		}, 1300);
	});
}


function browserHasPromises() {
	return typeof Promise !== 'undefined';
}

function getAsyncCtor() {
	try {
		eval("var func = async function(){};");
	} catch (e) {
		return null;
	}

	return Object.getPrototypeOf(func).constructor;
}

function browserHasAsyncAwaitSupport() {
		return getAsyncCtor() !== null;
	}
