giovanni.namespace("util");


giovanni.util.defaultDomain = function () {
    var url = window.location;
    var host = url.hostname;
    var defaultJSONString = "{\"" + url.hostname + "\":[\"" + url.hostname + "\"]}";
    return YAHOO.lang.JSON.parse(defaultJSONString);
};

giovanni.util.domainRetrieveFlag = false;
giovanni.util.currentURL = null;
giovanni.util.availableDomains = null;

/*
 * create button utility - wraps library-specific button creation
 *
 * @params {String,String,String,String,Function}
 * @author K. Bryant
 * @returns {YAHOO.widget.Button}
 */

giovanni.util.createButton = function (bId, bContainer, bLabel, bTitle, bFunc) {
    var btn = new YAHOO.widget.Button({
        type: "button",
        id: bId,
        container: bContainer,
        label: bLabel,
        title: bTitle,
        onclick: bFunc
    });
    return btn;
};

/*
 * removeByValue - used by variable picker
 *
 * @params {Array,String}
 * @author Choka
 */
giovanni.util.removeByValue = function (arr, val) {
    for (var i = 0; i < arr.length; i++) {
        if (arr[i] == val) {
            arr.splice(i, 1);
            break;
        }
    }
};

/*
 * extracts a query value from a url given a field name
 * 
 * @params {String,String}
 * @author K. Bryant
 * @return {String} 
 */
giovanni.util.extractQueryValue = function (url, fieldName) {
    fieldName = fieldName.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&;]" + fieldName + "(=([^&#;]*)|&|#|;|$)"),
        results = regex.exec(url);
    // This routine would be more useful if it returned null if fieldName
    // is not found in the query string, but for backward compatibility
    // we'll return an empty string instead
    //if (!results) return null;
    if (!results) return '';
    if (!results[2]) return '';

    // After extracting the value in results[2], handle any URI encoding
    return decodeURIComponent(results[2].replace(/\+/g, " "));
};

/*
 * checks if an array contains the given object 
 * 
 * @params {Array, Object}
 * @author Chocka
 * @return {boolean} 
 */
giovanni.util.contains = function (arr, obj) {
    var count = arr.length;
    if (count > 0) {
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] === obj) {
                return true;
            }
        }
    }
    return false;
};

/*
 * fetches the size of the inner browser window (or the 
 * 'client' size if innerWidth is not available, in IE 8 
 * for example)
 * 
 * @author K. Bryant
 * @return Array
 */
giovanni.util.getWinSize = function () {
    if (window.innerWidth != undefined) {
        return [window.innerWidth, window.innerHeight];
    } else {
        var B = document.body,
            D = document.documentElement;
        return [Math.max(D.clientWidth, B.clientWidth),
        Math.max(D.clientHeight, B.clientHeight)];
    }
};

var uid = (
    function () {
        var id = 0;
        return function () {
            return id++;
        };
    }
)();

giovanni.util.getParamValueByName = function (pkey, pquery) {
    var vals = new Array();
    var queryStr = "";
    var params = new Array();
    //var key = "";
    var pCount = 0;
    var criteria = pquery + "";

    if (pkey != null && pkey != 'undefined' && criteria != '') {
        key = pkey + "=";
        var pos = criteria.indexOf("?");
        if (pos > 0) {
            queryStr = criteria.substring(pos + 1);
        } else {
            queryStr = criteria;
        }
        // try ampersand as the separator first
        params = queryStr.split("&");
        // if no luck, try semicolon...
        params = params.length == 1 ? queryStr.split(";") : params;
        var num = params.length;
        for (var i = 0; i < num; i++) {
            var parm = params[i].split("=");
            var pname = parm[0]; // param value could contain "=" also
            if (pname == pkey) {
                vals[pCount] = params[i].substring(params[i].indexOf("=") + 1);
                pCount++;
            }
        }
    }

    if (pCount == 1) {
        return vals[0];
    } else {
        return vals;
    }
};

String.prototype.startsWith = function (str) {
    return (this.match("^" + str) == str);
};

String.prototype.endsWith = function (str) {
    return (this.match(str + "$") == str);
};

String.prototype.trim = function () {
    return this.replace(/^\s*/, "").replace(/\s*$/, "");
};

giovanni.util.map = function (ls, f) {
    var ls2 = [];
    for (var i = 0; i < ls.length; i++) {
        ls2.push(f(ls[i]));
    }
    return ls2;
};

giovanni.util.filter = function (ls, f) {
    var ls2 = [];
    for (var i = 0; i < ls.length; i++) {
        if (f(ls[i])) {
            ls2.push(ls[i]);
        }
    }
    return ls2;
};

giovanni.util.any = function (ls, f) {
    for (var i = 0; i < ls.length; i++) {
        if (f(ls[i])) {
            return true;
        }
    }

    return false;
}

/*
 * Displays a new browser window named 'help' with the url contents
 * 
 * @params {URL}
 * @author K. Bryant
 */
giovanni.util.displayHelpWindow = function (url) {
    var target = "help";
    var config = "scrollbars,resizeable,width=1000,height=500";
    var helpwin = window.open(url, target, config);
    helpwin.focus();
};

giovanni.util.formHtmlId = function () {
    var id = '';
    for (var i = 0; i < arguments.length - 1; i++) {
        id += giovanni.util.removeNonIdChars(arguments[i]) + '_';
    }
    id += giovanni.util.removeNonIdChars(arguments[i]);
    return id;
};

giovanni.util.removeNonIdChars = function (val) {
    return val.replace(/[^-A-Za-z0-9_:.]/g, '');
};

giovanni.util.generateEvent = function (elem, type, obj) {
    var evt = document.createEvent('UIEvents');
    evt.initUIEvent(type, true, false, elem, 0);
    window.dispatchEvnt(evt);
};

/*
 * Derives target value depending on platform.  Used by the event handlers.
 *
 * @params {YAHOO.util.Event}
 * @return {HTML Element}
 * @author K. Bryant
 */
giovanni.util.getTarget = function (e) {
    var targ = null;
    if (!e) e = window.event;
    if (e.target) targ = e.target;
    else if (e.srcElement) targ = e.srcElement;
    if (targ.nodeType == 3) // defeat Safari bug
        targ = targ.parentNode;
    return targ;
};

giovanni.util.getObjLength = function (obj) {
    var len = 0;
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) len++;
    }
    return len;
};

giovanni.util.getObjCopy = function (obj) {
    var newObj = {};
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            newObj.key = obj[key];
        }
    }
    return newObj;
};

/*
 * Calculates and returns the data points involved in the current query
 * 
 * @params {} 
 * @returns {String}
 * @author K. Bryant
 */
giovanni.util.getDataPointsCount = function () {
    var url = window.location.hash;
    var start, stop = null;
    if (session.getDataSelector().datePicker) {
        var dtRange = session.getDataSelector().datePicker.getValue();
        // try to split with '&' first
        var dtA = dtRange.split('&');
        // if no split, try with ';'
        dtA = dtA.length == 1 ? dtRange.split(';') : dtA;
        start = dtA[0].split('=')[1];
        stop = dtA[1].split('=')[1];
    }
    var bbox = null;
    if (session.getDataSelector().boundingBoxPicker) {
        var allBboxes = [];
        // Get the bounding box associated with the user's selection. This is the
        // intersection of the user's selected bounding box and shape.
        var selectionBbox = session.getDataSelector().boundingBoxPicker.getEffectiveBoundingBox();

        if (selectionBbox != null) {
            if (selectionBbox.length == 0) {
                // There was a bounding box and a shape, but no intersection.
                // Might as well just use a zero-sized bounding box for the max
                // points calculation.
                allBboxes.push([0, 0, 0, 0]);
            } else {
                allBboxes.push(selectionBbox);
            }
        }

        // Get the largest variable bounding box
        var variableBbox = session.getDataSelector().variablePicker.getLargestBoundingBox();
        // Check to make sure we got a bounding box for variables. (There may not be
        // any variables selected.)
        if (variableBbox.length == 4) {
            allBboxes.push(variableBbox);
        }

        // See if we got any bounding boxes. If no selection box, or shapes, or 
        // variables were selected, there is no bounding box.
        if (allBboxes.length > 0) {
            // Find the intersection of the user's selection and the largest variable bounding box.
            // If there is no intersection, this function will return null.
            bbox = session.getDataSelector().boundingBoxPicker.findIntersection(allBboxes);
        }

    }
    var service = null;
    if (session.getDataSelector().servicePicker) {
        service = session.getDataSelector().servicePicker.getValue().split('=')[1];
    }
    var spRes = null;
    if (session.getDataSelector().variablePicker) {
        spRes = session.getDataSelector().variablePicker.getMaxSpatRes();
    }
    var points = 0;
    if (start && stop && bbox && service && spRes) {
        var varCount = 1;
        var startDate = new Date(start);
        var stopDate = new Date(stop);
        // calculate date points, taking into account the temporal resolution
        // convert delta time in milliseconds to minutes, and then divide by resolution (points/minute)
        var tempRes = session.dataSelector.variablePicker.getMaxTempRes();
        var datePoints;
        if (tempRes === -1) {
            datePoints = 0;
        } else {
            datePoints = Math.round(
                (stopDate.getTime() - startDate.getTime()) / 1000 / 60 / tempRes);
        }

        // get geographic width and height of the intersection of the user's selection
        // and the largest variable bounding box.
        var cd = giovanni.util.getCartesianDistance(bbox);
        var height = cd[2];
        var width = cd[1];
        // regridding is done to align all variables to the highest resolution (smallest grid cell)
        var gridCells;
        if (spRes[0] === -1 || spRes[1] === -1) {
            // Latitude resolution or longitude resolution could not be determined
            // for any selection.
            gridCells = 0;
        } else {
            gridCells = (height * width) / (spRes[0] * spRes[1]);
        }
        points = new Number(varCount *
            (service.indexOf('TmAvSc') > -1 ? 1 : datePoints) *
            gridCells);
        points = points.toFixed(0);
    }
    return points;
};

/*
 * Calculates and returns the time steps and interval type involved in the current query
 * 
 * @params {} 
 * @returns [{Number}, {String}]
 * @author K. Bryant
 */
giovanni.util.getTimeSteps = function () {
    var dtRange = session.getDataSelector().datePicker.getValue();
    var climFound = session.getDataSelector().datePicker.dateRangePicker.climFound;
    var allClim = session.getDataSelector().datePicker.dateRangePicker.allClim;
    var dtA = dtRange.split('&');
    var start = dtA[0].split('=')[1];
    var stop = dtA[1].split('=')[1];
    var datePoints = 0;
    var dateInterval;
    if (start != "" && stop != "") {
        var startDate = new Date(start);
        var stopDate = new Date(stop);
        // calculate date points, taking into account the temporal resolution
        // convert delta time in milliseconds to minutes and divide by resolution (points/minute)
        var tempRes = session.dataSelector.variablePicker.getMaxTempRes();
        if (tempRes == 1000000) {
            datePoints = 0;
        } else {
            if (climFound && allClim) {
                // If only climatology variables are selected, compute the
                // number of points as the difference in months modulo 12.
                datePoints = stopDate.getUTCMonth() - startDate.getUTCMonth();
                if (datePoints < 0) {
                    datePoints = datePoints + 12;
                }
            } else {
                if (dtA.length > 2) {
                    // If a seasonal picker was used, and the resolution was months,
                    // count the number of points as if the resolution was in years,
                    // since only a range of years can be selected. Convert months to
                    // years by multiplying by 12.
                    var intervalType = dtA[2].split('=')[0];
                    if ((intervalType === 'months') || (intervalType === 'seasons')) {
                        if (tempRes == 43800) {
                            tempRes = tempRes * 12;
                        }
                    }
		}
                datePoints = Math.round(
                    (stopDate.getTime() - startDate.getTime()) / 1000 / 60 / tempRes);
            }
        }
        switch (tempRes) {
        case 1:     dateInterval = 'minutely';
            break;
        case 30:    dateInterval = 'half-hourly';
            break;
        case 60:    dateInterval = 'hourly';
            break;
        case 180:   dateInterval = '3-hourly';
            break;
        case 1440:  dateInterval = 'daily';
            break;
        case 11520: dateInterval = '8-daily';
            break;
        case 43800: dateInterval = 'monthly';
            break;
        case 525600: dateInterval = 'yearly';
            break;
        }
    }
    var timeStepsAndInterval = [datePoints, dateInterval];
    return timeStepsAndInterval;
}

/*
 * Checks if the contents of two arrays are equal, irrespective of the 
 * order in which they appear in the arrays
 * 
 * @params {Array, Array} 
 * @returns {boolean}
 * @author Chocka
 */
giovanni.util.areArraysEqual = function (array1, array2) {
    var temp = new Array();
    if ((!array1[0]) || (!array2[0])) { // If either is not an array
        return false;
    }
    if (array1.length != array2.length) {
        return false;
    }
    // Put all the elements from array1 into a "tagged" array
    for (var i = 0; i < array1.length; i++) {
        key = (typeof array1[i]) + "~" + array1[i];
        // Use "typeof" so a number 1 isn't equal to a string "1".
        if (temp[key]) {
            temp[key]++;
        } else {
            temp[key] = 1;
        }
        // temp[key] = # of occurrences of the value (so an element could appear multiple times)
    }
    // Go through array2 - if same tag missing in "tagged" array, not equal
    for (var i = 0; i < array2.length; i++) {
        key = (typeof array2[i]) + "~" + array2[i];
        if (temp[key]) {
            if (temp[key] == 0) {
                return false;
            } else {
                temp[key]--;
            }
            // Subtract to keep track of # of appearances in array2
        } else { // Key didn't appear in array1, arrays are not equal.
            return false;
        }
    }
    // If we get to this point, then every generated key in array1 showed up the exact same
    // number of times in array2, so the arrays are equal.
    return true;
};

/*
 * Used by any component that opens panels to notify other components
 * so they can clean up their open panels
 *
 * @author K. Bryant
 */
giovanni.util.panelOpenEvent = new YAHOO.util.CustomEvent("PanelOpenEvent");

/*
 * Handles panelOpenEvents.  This method is used as the handling method by those
 * giovanni.widget classes that need to listen for panelOpenEvents so they can
 * clean up (e.g., hide) their own panels.  Used by SeasonalDatePicker, 
 * DateRangePicker, BoundingBoxPicker
 *
 * @this {Object}
 * @params {YAHOO.util.CustomEvent,Array, Object}
 * @returns void
 * @author K. Bryant
 */
giovanni.util.handlePanelOpenEvent = function (type, args, o) {
    if (o != undefined) {
        var callingObject = o.callingObject;
        var callback = o.callback;
        if (args[0] != callingObject) {
            callback.call(callingObject);
        }
    }
};

giovanni.util.getSelectedValue = function (radios) {
    var val = null;
    for (var i = 0; i < radios.length; i++) {
        if (radios[i].checked) {
            val = radios[i].value;
        }
    }
    return val;
};

giovanni.util.getCartesianDistance = function (boundsArr) {
    if (!Array.isArray(boundsArr)) 
      boundsArr = boundsArr.split(",");
    var x1 = parseFloat(boundsArr[0]);
    var y1 = parseFloat(boundsArr[1]);
    var x2 = parseFloat(boundsArr[2]);
    var y2 = parseFloat(boundsArr[3]);

    // handle crossing of the 180 meridian
    if (x1 > x2 && x2 < 0) {
        x2 = 360 - Math.abs(x2);
    }

    var x = Math.abs(x2 - x1);
    var y = Math.abs(y2 - y1);
    var d = Math.sqrt((x * x) + (y * y));
    return [d, x, y];
};

// This code to:
// 1. get the data just once
// 2. run new URL(window.location.href) just once.
// became to large to keep in returnShardedDomain()
giovanni.util.catalogShardStatus = function () {

    if (!this.availableDomains) {
        if (giovanni.util.domainRetrieveFlag == true) {
            // we tried and couldn't get the shards
            return false;
        }
        // lets go get the shards

        // This flag is not to signal when we have the data but
        // only when we have started to get the data - so that
        // we only try once
        giovanni.util.domainRetrieveFlag = true;
        giovanni.util.getDomainLookup();
        return false; // return false because getDomainLookup takes a while...
    }

    // Let's try to create the object just once:
    var url = giovanni.util.currentURL ? giovanni.util.currentURL : window.location;
    giovanni.util.currentURL = url;
    // initial retrieval not completed:
    if (this.availableDomains != null) {
        // configuration not supplied:
        if (!this.availableDomains[url.hostname]) {
            return false;
        }
    }
    return true;
};

giovanni.util.returnShardedDomain = function (urlpath) {
    if (!giovanni.util.catalogShardStatus()) {
        return urlpath;
    }

    url = giovanni.util.currentURL;
    var thisServerDomains = this.availableDomains[url.hostname];
    var whichDomainThisTime = Math.floor(Math.random() * thisServerDomains.length) + 0;

    var host = url.hostname;
    var port = url.port;
    var http = url.protocol;

    var newdomain;

    if (thisServerDomains.length > 0) {
        newdomain = url.protocol + "//" + thisServerDomains[whichDomainThisTime];
    } else {
        newdomain = url.protocol + "//" + url.hostname;
    }

    if (port.length > 0) {
        newdomain += ":" + port;
    }

    // Chrome doesn't like:
    //if ( url.pathname.contains("/giovanni/") ) {

    // if path contains /giovanni/ then we know where we are
    if (RegExp("/giovanni.*/").test(url.pathname)) {
        var pathTop = url.pathname.split("giovanni")[0];
        newdomain += pathTop + "giovanni";
    } else { // pathname contains up to filename (index.html, index-debug.html) 
        var dirs = url.pathname.split("/");
        var i = 0;
        // WARNING: this is pretty much wrong, since base URL would not contain cgi-bin (it should be in urlpath instead)
        while (dirs[i].indexOf("-") === -1 && // cgi-bin (daac-bin will be included in urlpath)
            dirs[i].indexOf(".") === -1 &&
            i < dirs.length) { // index.html
            if (dirs[i].length > 0) {
                newdomain += "/" + dirs[i];
            }
            ++i;
        }
    }

    newdomain += "/" + urlpath
    return newdomain

};

giovanni.util.getDomainLookup = function () {

    // prevent OPTIONS request. prevent x-requested-with header 
    YAHOO.util.Connect.setDefaultXhrHeader();
    YAHOO.util.Connect.resetDefaultHeaders()

    var domainQueryStr = "daac-bin/getGiovanniDomainLookup.pl";
    var dlCallback = {
        scope: this,
        success: giovanni.util.handleDomainLookupSuccess,
        failure: function (obj) {
            // See note in handleDomainLookupSuccess;
        },
        timeout: 5000
    };
    YAHOO.util.Connect.asyncRequest('GET', domainQueryStr, dlCallback, null);
};

giovanni.util.handleDomainLookupSuccess = function (resp) {
    var domainObj = null;
    var array;
    try {
        domainObj = YAHOO.lang.JSON.parse(resp.responseText);
        giovanni.util.availableDomains = domainObj;
    } catch (x) {
        // If it doesn't reach this function it probably means getGiovanniDomainLookup.pl does not exist
        // If it fails here it means that getGiovanniDomainLookup.pl has returned it's not-json error msg.
        return;
    }
};

// This function expands upon YAHOO.util.Connect.asyncRequest
// to enable sharding, chunking, retries on failures, and adaptive timeout.
// By default, the function chunks all queries into 1000 rows ('options.chunkRows')
// and uses sharding to build target catalog URLs. 
// Chunking can be turned off by setting 'options.chunk' to false. 
// Sharding can be turned off by setting 'options.sharding' to false. 
//
// Also by default, it tries to be smart about failures:
// - on timeout failures, the function tries to double timeout and tries again
//   until the timeout exceeds the preset 'options.maxtimeout' option
// - on all other failures, it attempts to retry the request up to 'options.retries' times,
//   setting retries to -1 will trigger infinite failure retries.
//
// Input to the function looks similar to a standard asyncRequest with these differences:
// - Query should be specified right in the passed options
// - Success callback returns responseObject (parsed JSON) rather than responseText
// - Supports a number of additonal options, see 'options' variable in the function
//   for the full list of available parameters
//
// All options are optional - use-provided options (userOptions) merely override default options
// set in the 'options' variable. Typically, you would want to provide a query and a success callback.
//
// Important parameters are also rows, countonly, and chunking.
//  - Setting rows to 0 or adding '&rows=0' to the query or setting countonly=true will
//    all make the function to request 0 rows from the catalog, which is useful for 
//    getting a number of matching results.
//  - Setting rows to some number AND setting chunking to false will make the function
//    retrieve only this specified number of rows. If chunking is set to true (and it is, by default)
//    rows will be ignored (unless rrows=0) and the function will retrieve all the available rows.
//    Rows can also be set by adding '&rows=' to the query.


giovanni.util.getCatalogData = function (userOptions) {
    //baseUrl, request, argument, scope, successCallback, failureCallback, shard
    // Set defaults
    var options = {
        baseUrl: './daac-bin/catalogServices.pl', // base URL of the catalog
        query: null, // Solr search query
        scope: null, // Scope ('this') to set on the callbacks
        success: null, // Success callback
        failure: null, // Failure callback
        timeout: 5000, // How long to wait for a request to come back
        maxtimeout: 30000, // Maximum value for timeout
        argument: null, // Additoinal .argument to be put on the callback response object
        shard: true, // To shard or not to shard
        chunk: true, // To chunk or not to chunk
        chunkRows: 700, // How many rows to request in a single chunk
        rows: null, // How many rows to request (ignore if chunk is true, unless set to 0). Can also be setup on the query, e.g. &row=0
        countonly: false, // Sets rows to 0 to get the number of matching results (but not the documents)
        retries: 5, // Turns on retries of failed requests. -1 - infinite retries
        retryTime: 1000 // Delay between the retries
    }

    for (key in userOptions) {
        if (key in options && userOptions[key] !== undefined && userOptions[key] !== null) options[key] = userOptions[key];
    };

    var ourRequest = '?';
    var ourAsyncCallback = null;
    var currentTransaction = null;
    var requestId = null;
    var done = false;
    var retries = options.retries;
    var cancelled = false;

    var getBaseUrl = function (options) {
        if (options.shard !== null && options.shard === false) return options.baseUrl;
        return giovanni.util.returnShardedDomain(options.baseUrl);
    };
    // This handles a transaction success
    var ourSuccessCallback = function (res) {
        // Check if this is the last request (numFound = collected.length)
        // - If not:
        // ----- Append response to results
        // ----- Call YAHOO.... with the same callback, but incremented starting page
        // - If yes:
        // ----- Send appended result to the client
        var requestURL = res.argument[0];
        var ourAsyncCallback = res.argument[1];
        var collected = res.argument[2];
        var resObj = null;
        if (cancelled) return; // Do nothing if the transaction was cancelled while it failed
        try {
            resObj = YAHOO.lang.JSON.parse(res.responseText);
        } catch (e) {
            console.log('Failed to json-parse catalog response.');
            if (options.failure !== null) {
                res.tId = requestId;
                if (options.argument !== null) res.argument = options.argument;
                if (options.scope !== null) options.failure = options.failure.bind(options.scope);
                options.failure(res);
            }
            return;
        };
        var rowsRequested = parseInt(resObj.responseHeader.params.rows);
        var startPrevious = parseInt(resObj.response.start);
        var startNew = startPrevious + rowsRequested;
        var expected = (rowsRequested === 0) ? 0 : parseInt(resObj.response.numFound);
        collected = collected.concat(resObj.response.docs);

        if (collected.length >= expected) {
            done = true;
            if (collected.length > expected) console.log('Warning: Received more data from the catalog then expected');
            delete res.argument;
            if (options.argument !== undefined && options.argument !== null) res.argument = options.argument;
            // Mend response header
            res.tId = requestId;
            resObj.response.docs = collected;
            resObj.response.start = 0;
            resObj.responseHeader.params.rows = collected.length;
            res.responseObject = resObj;
            // Return result to the client
            if (options.success !== null) {
                if (options.scope !== undefined && options.scope !== null) options.success = options.success.bind(options.scope);
                options.success(res);
            }
        } else {
            requestURL = requestURL.replace(/start\=\d+/, 'start=' + startNew);
            ourAsyncCallback.argument = [requestURL, ourAsyncCallback, collected];
            currentTransaction = YAHOO.util.Connect.asyncRequest('GET', getBaseUrl(options) + requestURL, ourAsyncCallback, null);
        };
    };

    // This handles a transaction failure
    var ourFailureCallback = function (res) {
        var requestURL = res.argument[0];
        var ourAsyncCallback = res.argument[1];
        var collected = res.argument[2];
        var msg = "Failed to retrieve information from the datasource.";
        if (cancelled) return; // Do nothing if the transaction was cancelled while it failed
        if (res.statusText === 'transaction aborted' && !cancelled && options.timeout < options.maxtimeout) {
            if (retries !== -1) retries = retries + 1;
            options.timeout = options.timeout * 2;
            ourAsyncCallback.timeout = options.timeout;
            console.log('Catalog request timed out. Increasing to ' + options.timeout + '.');
        }
        if (retries > 0 || retries === -1) { // If request failed - give it another try. -1 - endless retries
            retries--;
            ourAsyncCallback.argument = res.argument;
            setTimeout(function () {
                console.log(msg, 'Trying again.');
                currentTransaction = YAHOO.util.Connect.asyncRequest('GET', getBaseUrl(options) + requestURL, ourAsyncCallback, null);
            }, 1000); // Wait 1 second before retry
            return;
        }
        done = true;
        if (options.failure !== null) {
            res.tId = requestId;
            if (options.argument !== null) res.argument = options.argument;
            if (options.scope !== null) options.failure = options.failure.bind(options.scope);
            options.failure(res);
        } else {
            alert(msg);
            // Uncomment for debugging
            // alert(YAHOO.lang.dump(res));
            // console.failure(res);
            // console.failure(msg);
        }
    };

    // Enable sharding by default
    if (options.rows === null && options.query !== null) {
      // If rows are not supplied on the options but are present on the query -
      // extract from query and move to options
      var rows = /rows\=(\d+)/.exec(options.query);
      if (rows !== null) options.rows = parseInt(rows[1]);
    };
    if (options.countonly) options.rows = 0; // Set rows to 0 if all we need is counts
    options.query = options.query.replace(/\&*rows\=\d+/,''); // Remove rows from the query. At this point, we have them in options.rows
    if (options.rows !== null && options.rows === 0) options.chunk = false;  // 0-row requests do not need chunking
    if (options.chunk) options.rows === null; // Disabled rows if chunking is on
    if (options.query !== null && options.query !== '' ) ourRequest += options.query;
    
    if (options.chunk) {
      ourRequest += '&rows=' + options.chunkRows + '&start=0';
    } else {
      if (options.rows !== null) ourRequest += '&rows=' + options.rows;
    };
    
    ourRequest = ourRequest.replace('?&', '?').replace(/\?+/, '?'); // Cleanup request
  
    ourAsyncCallback = {
      scope: this,
      success: ourSuccessCallback,
      failure: ourFailureCallback,
      timeout: options.timeout
    };
    ourAsyncCallback.argument = [ourRequest, ourAsyncCallback, []];
    currentTransaction = YAHOO.util.Connect.asyncRequest('GET', getBaseUrl(options) + ourRequest, ourAsyncCallback, null);
    requestId = currentTransaction.tId;
    
    var transactionObject = {
      'abort': function(scope, success, failure) {
        retries = 0; // Cancell any remaining retries
        cancelled = true;
        if (done) return;
        if (YAHOO.util.Connect.isCallInProgress(currentTransaction)) {
          //console.log("Aborting active transaction : " + trans.tId);
          var options = {};
          if (success !== undefined && success !== null) options.s = success;
          if (failure !== undefined && failure !== null) options.failure = failure;
          if (scope !== undefined && scope !== null) options.scope = scope;
          YAHOO.util.Connect.abort(currentTransaction, options);
        }
      },
      'getTransaction': function() {
         return currentTransaction;
      },
      'tId': requestId
    };
    
    return transactionObject;
};


/**
 * Serialize an object into the options portion of a service_manager request.
 * Used by giovanni.widget.OverlayMap.
 *
 * @author K. Bryant
 * @params {Object}
 * @returns {URI}
 **/       
giovanni.util.serialize2URI = function (obj,sep,assignop) {
    var str = [];
    var separator = sep || ",";
    var assignop = assignop || ":";
    for(var p in obj) {
      if(obj.hasOwnProperty(p)) {
        str.push(encodeURIComponent(p) + assignop + encodeURIComponent(obj[p]));
      }
    }
    return str.join(separator);
};

/* convert to 'world' (>180) coordinates */
giovanni.util.scrubBbox = function (inBbox, inProj, isZoomExtent) {
    var bbox = inBbox;
    var proj = inProj ? inProj : 'EPSG:4326';
    if(bbox && bbox !== ""){
        bbox = $.isArray(inBbox) ? inBbox.slice() : inBbox.split(",")
        bbox = bbox.map(function (x) {
            return parseFloat(x);
        });
    }else{
        bbox = [-180,-90,180,90];
    }
    if(proj==='EPSG:4326'){
        var WEST = 0;
        var EAST = 2;
        // transform to double globe from single globe
        // only if we're scrubbing for a layer extent
        // (e.g., one that determines to what extent
        // a layer will be rendered on screen) and not zooming
        // to that extent;
        // transform to single globe from double if
        // we're zooming to the extent; 
        // otherwise transform the coordinates to handle the 180 meridian
        if(!isZoomExtent && bbox[WEST] === -180 && bbox[EAST] === 180){
            bbox[WEST] = -360;
            bbox[EAST] = 360;
        }else if(isZoomExtent && bbox[WEST] === -360 && bbox[EAST] === 360){
            bbox[WEST] = -180;
            bbox[EAST] = 180;
        }else{
            if (bbox[WEST] > 0 && bbox[EAST] < 0) {
                bbox[EAST] = 180 + (180 - (-1 * bbox[EAST]));
            } else if (bbox[WEST] > 0 && bbox[EAST] > 0 && bbox[WEST] > bbox[EAST]) {
                bbox[WEST] = -1 * (180 + (180 - bbox[WEST]));
            } else if (bbox[WEST] < 0 && bbox[EAST] < 0 && bbox[WEST] > bbox[EAST]) {
                bbox[EAST] = 180 + (180 + bbox[EAST]);
            }
        }
    }
    return bbox;
};

giovanni.util.handleMapResolutionChange = function () {
    var map = this.map;
    var proj = this.proj;
    var bbox = this.bbox;
    var layer = giovanni.util.getMapLayer(map,'grid');
    if(layer){
        layer.getSource().updateParams({
        'LAYERS': 'grid' + giovanni.util.getGridIncrement(map,proj,bbox)
        });
    }else{
        console.log("giovanni.util.handleMapResolutionChange:  could not find layer");
    }
}

giovanni.util.getMapLayer = function (map, name) {
  var layer = undefined;
  var lyrName = undefined;
  map.getLayers().forEach(function (lyr) {
    lyrName = lyr.getSource().getParams()['LAYERS'];
    if(lyrName.indexOf(name)>-1){
      layer = lyr;
    }
  });
  return layer;
}

giovanni.util.getGridIncrement = function (map,inProj,bbox) {
    var extent = bbox ? bbox : [-180,-90,180,90];
    if(map){
        var tmpEA = map.getView().calculateExtent(map.getSize());
        // if there are no 'NaN's from the map extent
        // use that instead of the one passed in
        if(!tmpEA.toString().indexOf('NaN')>-1){
            extent = tmpEA.slice();
        }
    }
    var proj = inProj ? inProj : 'EPSG:4326';
    var d = giovanni.util.getCartesianDistance(extent);
    var w = d[1];
    var incr = "45";
    if(proj === 'EPSG:4326'){
        if (w >= 180) {
            incr = "45";
        } else if (w >= 90 && w < 180) {
            incr = "20";
        } else if (w >= 50 && w < 90) {
            incr = "10";
        } else if (w >= 20 && w < 50) {
            incr = "05";
        } else if (w >= 10 && w < 20) {
            incr = "02";
        } else if (w >= 5 && w < 10) {
            incr = "01";
        } else if (w >= 1 && w < 5) {
            incr = "1-2";
        } else if (w < 1) {
            incr = "1-8";
        }
    }else{ // use meters
        if (w > 25000000) {
            incr = "45";
        } else if (w >= 10000000 && w < 25000000){
            incr = "20";
        } else if (w >= 5000000 && w < 10000000) {
            incr = "10";
        } else if (w >= 2000000 && w < 5000000) {
            incr = "05";
        } else if (w >= 1000000 && w < 2000000) {
            incr = "02";
        } else if (w >= 500000 && w < 1000000) {
            incr = "01";
        } else if (w >= 200000 && w < 500000) {
            incr = "1-2";
        } else {
            incr = "1-8";
        }
    }
    return incr;
}

giovanni.util.isGlobal = function (arr) {
  return (arr[0] === -180 && arr[2] === 180) || (arr[0] === -360 && arr[2] === 360);
}
giovanni.util.isDoubleGlobe = function (arr) {
  return arr[0] === -360 && arr[2] === 360;
}

// clean up popup menus during otherwise random window clicks
$(window).click(function() {
  $('.popupMenu').hide();
});

// Temporary measure to support an alternative path to 
// Array.prototype.find() until IE supports it natively
// credit:  https://stackoverflow.com/questions/24143604/array-prototype-find-is-undefined
if (!Array.prototype.find) {
  Object.defineProperty(Array.prototype, 'find', {
    enumerable: false,
    configurable: true,
    writable: true,
    value: function(predicate) {
      if (this == null) {
        throw new TypeError('Array.prototype.find called on null or undefined');
      }
      if (typeof predicate !== 'function') {
        throw new TypeError('predicate must be a function');
      }
      var list = Object(this);
      var length = list.length >>> 0;
      var thisArg = arguments[1];
      var value;

      for (var i = 0; i < length; i++) {
        if (i in list) {
          value = list[i];
          if (predicate.call(thisArg, value, i, list)) {
            return value;
          }
        }
      }
      return undefined;
    }
  });
}

// returns decimal coordinate float
giovanni.util.fromNE = function (val) {
  // make sure the incoming value is a string
  val = val + '';
  // look for matching N, E, S, W characters, case-insensitive
  if(val.match(/N|E/gi)) {
    return parseFloat( val.replace(/N|E/,'') );
  }
  if(val.match(/S|W/gi)) {
    return parseFloat( val.replace(/S|W/,'') ) * -1;
  }
  return parseFloat(val);
};

giovanni.util.fromNEArray = function (box) {
  var a = [];
  for(var i=0;i<box.length;i++){
    a[i] = giovanni.util.fromNE(box[i]);
  }
  return a;
}

// returns NE coordinate string
giovanni.util.toNE = function (val,lat) {
  val = val + '';
  if (lat) {
    if (val.match(/-/gi)) {
      return val.replace('-','') + 'S';
    } else {
      return val + 'N';
    }
  } else {
    if (val.match(/-/gi)) {
      return val.replace('-','') + 'W';
    } else {
      return val + 'E';
    }
  }
  return val;
};

giovanni.util.toNEArray = function (box) {
  var a = [];
  var latFlag = false;
  for(var i=0;i<box.length;i++){
    latFlag = i===1||i===3 ? true : false;
    a[i] = giovanni.util.toNE(box[i],latFlag);
  }
  return a;
}

giovanni.util.getRandom = function () {
  return Math.floor((Math.random() * 10000000000) + 1);
}

giovanni.util.createCookie = function (name,value,days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = encodeURIComponent(name) + "=" + encodeURIComponent(value) + expires + "; path=/";
}
giovanni.util.readCookie = function (name) {
    var nameEQ = encodeURIComponent(name) + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return decodeURIComponent(c.substring(nameEQ.length,c.length));
    }
    return null;
}
giovanni.util.eraseCookie = function (name) {
    createCookie(name,"",-1);
}

giovanni.util.getGuest = function () {
  if (typeof(Storage) === "undefined") return undefined;
  return sessionStorage.getItem("guest");
};
giovanni.util.setGuest = function (name) {
  if (typeof(Storage) === "undefined") {
    console.log("giovanni.util.setGuest():  Web Storage is not supported.  Cannot set guest");
    return;
  }
  sessionStorage.setItem("guest",name);
};
giovanni.util.removeGuest = function () {
  if (typeof(Storage) === "undefined") return;
  sessionStorage.removeItem("guest");
}

/*
 * Credit: MDN polyfill - 
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/includes#Polyfill
 */
if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
    'use strict';
    if (typeof start !== 'number') {
      start = 0;
    }

    if (start + search.length > this.length) {
      return false;
    } else {
      return this.indexOf(search, start) !== -1;
    }
  };
}

/** 
 * Listen to hash changes; if there are any,
 * send the user back to the data selection page
 **/
window.addEventListener('hashchange', function () {
  sessionManager.setUserView('dataSelection');
}, false);
