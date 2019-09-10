//$Id: VariablePicker.js,v 1.62 2015/08/06 19:04:27 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $


giovanni.namespace("widget");

giovanni.widget.VariablePicker = function (containerId, dataUrl, config) {
    this.container = document.getElementById(containerId);
    if (this.container == null) {
        this.setStatus("Error: element '" + containerId + "' not found!", true);
        return;
    }
    this.containerId = containerId;
    this.resultContainerId = containerId + "SelVar";
    this.fs = null;
    //  this.selectedVariables = new Array();
    //  this.selectedVariablesTable = null;
    this.lastLoadedQuery = null;
    this.resultIndex = 0;
    this.dataAccessor = dataUrl;
    this.allowMultiple = config.allowMultiple;
    this.render();
};

giovanni.widget.VariablePicker.dataQueryPartName = 'data';
giovanni.widget.VariablePicker.facetQueryPartName = 'variableFacets';
giovanni.widget.VariablePicker.keywordPartName = 'dataKeyword';
giovanni.widget.VariablePicker.portalQueryPartName = 'portalFacet';

giovanni.widget.VariablePicker.prototype.render = function () {
    var config = {};
    config.searchFacets = [
        {
            "name": "dataFieldDiscipline",
            "label": "Disciplines"
        },
        {
            "name": "dataFieldMeasurement",
            "label": "Measurements"
        },
                       //{"name":"dataProductInstrumentShortName", "label":"Instruments", "columns":"1"}, 
                       //{"name":"dataProductPlatformShortName", "label":"Platforms", "columns":"1"},
        {
            "name": "dataProductPlatformInstrument",
            "label": "Platform / Instrument",
            "columns": "1"
        },
        {
            "name": "dataProductSpatialResolution",
            "label": "Spatial Resolutions"
        },
        {
            "name": "dataProductTimeInterval",
            "label": "Temporal Resolutions"
        },
        {
            "name": "dataFieldWavelength",
            "label": "Wavelengths",
            "columns": "1"
        },
        {
            "name": "dataFieldDepth",
            "label": "Depths"
        },
        {
            "name": "specialFeatures",
            "label": "Special Features"
        },
        {
            "name": "dataFieldTags",
            "label": "Portal"
        },
                     ];
    this.fs = new giovanni.widget.FacetedSelector(this.containerId, this.resultContainerId, this.dataAccessor, config, this.handleResults, this);

    if (REGISTRY) {
        REGISTRY.register(this.containerId, this);
    } else {
        alert("no REGISTRY so could not register DatePicker");
    }
};


/**
 * Fires an event in the registry when the component value is changed
 * 
 * @this {giovanni.widget.VariablePicker}
 * @author Chocka
 */
giovanni.widget.VariablePicker.prototype.fire = function () {
    if (REGISTRY) {
        REGISTRY.fire(this);
    } else {
        alert("No REGISTRY to fire an event");
    }
};

giovanni.widget.VariablePicker.prototype.loadFromQuery = function (query) {

    // clear the current state of the variable picker
    this.fs.selectedVariables = [];
    document.getElementById(this.resultContainerId + '_count').innerHTML = 0;
    var container = document.getElementById(this.fs.facetsContainerId);
    this.fs.uncheckElements(container);
    document.getElementById("facetedSearchBarInput").value = '';
    this.fs.latestSearchKeyword = '';

    // retrieve and set facet selections, if available
    var facQstr = giovanni.util.getParamValueByName(
        giovanni.widget.VariablePicker.facetQueryPartName, query);
    var facData = facQstr instanceof Array ? (facQstr.length > 0 ? facQstr[0] : "") : facQstr;
    facData = decodeURIComponent(facData);
    if (facData != null && facData != "") {
        var facDataArr = facData.split(';');
        for (var i = 0; i < facDataArr.length; i++) {
            if (facDataArr[i] == "") continue;
            var tmp = facDataArr[i].split(':');
            var facetName = tmp[0];
            var facetValues = tmp[1].split(',');

            for (var j = 0; j < this.fs.facets.length; j++) {
                var fac = this.fs.facets[j];
                if (fac.name === facetName) {
                    // set the checkboxes corresponding to the selected values
                    fac.setValue(facetValues);
                    // slide open the facet, if it has a selected value, upon page load
                    var locator = '#' + fac.getCollapsibleHeaderId();
                    $(locator).collapsible('open');
                    // disabled feature: keeping the facet closed, and showing collapsed info
                    //fac.showCollapsedInfo();
                    break;
                }
            }
        }
        // close facets that don't have selected values
        for (var i = 0; i < this.fs.facets.length; i++) {
            var fac = this.fs.facets[i];
            if (!fac.getValue().length) {
                var locator = '#' + fac.getCollapsibleHeaderId();
                $(locator).collapsible('close');
            }
        }
    } else {
        // no facets selected. open the first 2 and collapse the rest 
        for (var i = 0; i < this.fs.facets.length; i++) {
            var fac = this.fs.facets[i];
            var locator = '#' + fac.getCollapsibleHeaderId();
            if (i < 2) {
                $(locator).collapsible('open');
            } else {
                $(locator).collapsible('close');
            }
        }
    }

    // retrieve and set keyword search term, if available
    var dataKeywordStr = giovanni.util.getParamValueByName(
        giovanni.widget.VariablePicker.keywordPartName, query);
    dataKeywordStr = decodeURIComponent(dataKeywordStr);
    if (dataKeywordStr != null && dataKeywordStr != '') {
        this.fs.latestSearchKeyword = dataKeywordStr;
        document.getElementById("facetedSearchBarInput").value = dataKeywordStr;
    }

    // retrieve and set variable selections, if available
    var qstr = giovanni.util.getParamValueByName(
        giovanni.widget.VariablePicker.dataQueryPartName, query);
    var varData = qstr instanceof Array ? (qstr.length > 0 ? qstr[0] : "") : qstr;

    varData = decodeURIComponent(varData);

    if (varData != null && varData != "") {
        // sharding
        var baseQuery = 'q=' + this.fs.baseConstraint + '&version=2.2&indent=on&wt=json';
        var facetFieldQuery = '&fq=dataFieldId:(';

        var vars = this.parseDataFromQueryString(varData);
        var zValueMap = {};
        var unitsMap = {};
        var indexMap = {};

        $.each(vars, function (idx, var_) {
            facetFieldQuery += '"' + var_.id + '"';
            indexMap[var_.id] = vars.length - idx;
            if (idx + 1 < vars.length) {
                facetFieldQuery += ' OR ';
            }

            if (var_.z) {
                zValueMap[var_.id] = var_.z;
            }

            if (var_.units) {
                unitsMap[var_.id] = var_.units;
            }
        });

        facetFieldQuery += ')';
        var errCallback = function (obj) {
            var msg = "Failed to retrieve variable information from the datasource."
            alert(msg);
            console.error(msg);
        };
        // Make XHR request to load product-level information
        // +'&rows='+vars.length
        giovanni.util.getCatalogData({
            query: baseQuery + facetFieldQuery,
            scope: this,
            success: giovanni.widget.VariablePicker.prototype.handleLoadFromQuerySuccess,
            failure: errCallback,
            argument: [zValueMap, unitsMap, indexMap]
        });
    }

    /* when selected variables are present in the query, the call to facet change handler should 
     * happen after the selected variables are fetched first. So this will occur in handleSelection 
     * method of the FacetedSelector
     * 
     * for queries without selected variables the facet change handler is invoked right here
     */
    else {
        this.fs.facetChangeHandler(null, null); // the default arguments will suffice for this case
    }

    // save query to 'reset' later
    this.lastLoadedQuery = query;
};

giovanni.widget.VariablePicker.prototype.handleLoadFromQuerySuccess = function (resp) {
    var respObj = resp.responseObject;
    var resultObjArr = respObj.response.docs;
    var facetedResultArr = [];
    var zValueMap = resp.argument[0];
    var unitsMap = resp.argument[1];
    var indexMap = resp.argument[2];
    resultObjArr.sort(function(a, b) {
        if (indexMap[a.dataFieldId] > indexMap[b.dataFieldId]) return -1;
        if (indexMap[b.dataFieldId] > indexMap[a.dataFieldId]) return 1;
        return 0;
    });

    for (var i = 0; i < resultObjArr.length; i++) {
        // this result will be used only to reload the selected variables from a query
        // so just the data part of the result is sufficient
        // the callback information in the constructor can be ignored
        var data = resultObjArr[i];
        var zVal = zValueMap[data.dataFieldId];
        var units = unitsMap[data.dataFieldId];

        if (zVal) {
            data.userSelectedZDimValue = zVal;
        }

        if (units) {
            data.userSelectedUnits = units;
        }

        facetedResultArr[facetedResultArr.length] = new giovanni.widget.FacetedResult(this.fs, data, null, null);
    }

    this.fs.handleSelection(null, [facetedResultArr, true, null, null]);
};

giovanni.widget.VariablePicker.prototype.getValue = function () {
    var returnString = '';
    var is3dSvc = session.dataSelector.servicePicker.is3DService();

    if (this.fs.selectedVariables.length > 0) {
        var selVars = [];

        for (var i = 0; i < this.fs.selectedVariables.length; i++) {
            var curVar = this.fs.selectedVariables[i];

            // Add contents of bracket-enclosed semicolon seperated list to an array.
            // This array will be joined and appended to the variable name if 
            // non-empty.
            var bracketContents = [];

            if (!is3dSvc && curVar.is3DVariable) {
                var zValue = curVar.getZDimValue();
                if (zValue) {
                    bracketContents.push('z=' + zValue);
                }
            }

            if (curVar.getUnits() && curVar.getUnits() != curVar.getDefaultUnits()) {
                bracketContents.push('units=' + curVar.getUnits());
            }

            // Append square bracket contents to variable name if non-empty.
            selVars[i] = curVar.getId();

            if (bracketContents.length > 0) {
                selVars[i] += '(' + bracketContents.join(':') + ')';
            }
        }
        returnString += giovanni.widget.VariablePicker.dataQueryPartName + '=';
        returnString += encodeURIComponent(selVars.join(','));
    }

    var facQueryReq = false;
    var facQueryStr = giovanni.widget.VariablePicker.facetQueryPartName + '=';
    for (var i = 0; i < this.fs.facets.length; i++) {
        var fac = this.fs.facets[i];
        var facValue = fac.getValue();
        if (facValue.length > 0) {
            facQueryReq = true;
            facQueryStr += encodeURIComponent(fac.name + ':' + facValue.join(',') + ';');
        }
    }
    if (facQueryReq) {
        returnString += (returnString != '' ? '&' : '') + facQueryStr;
    }

    var keyword = this.fs.latestSearchKeyword;
    if (keyword != null && keyword != '') {
        var keywordStr = giovanni.widget.VariablePicker.keywordPartName + '=';
        keywordStr += encodeURIComponent(keyword);
        returnString += (returnString != '' ? '&' : '') + keywordStr;
    }

    return returnString;
};

giovanni.widget.VariablePicker.prototype.validate = function () {
    var valResp = null;
    var msg = null;
    var statusBar = document.getElementById("facetedResultsStatusBar");

    if (this.fs.selectedVariables == null || this.fs.selectedVariables.length == 0) {
        msg = "No variables selected";
    } else {
        msg = this.fs.validateVariableConstraints(true);

        /**
         * Check for WARNING conditions ONLY -
         * in this case, it's warning users that units conversion does not apply
         * when the selected service is 'CoMp' (Correlation Map)
         **/
        if (this.fs.service == 'CoMp') {
            var areVarsConvertible = false;
            var selVars = this.fs.selectedVariables;
            for (var i = 0; i < selVars.length; i++) {
                if (selVars[i].data.dataFieldDestinationUnits != null) {
                    areVarsConvertible = true;
                    break;
                }
            }
            if (areVarsConvertible) {
                var curMsg = statusBar.innerHTML;
                var correlationMsg = "<span style='color:green;'>Reminder:  'Map, Correlation' plot does not support units conversion.  Choose a different plot to convert units.</span>";
                statusBar.innerHTML = curMsg != "" ? curMsg + "<br/>" + correlationMsg : correlationMsg;
            }
        }

    }

    if (msg == null || msg.length == 0) {
        valResp = new giovanni.widget.ValidationResponse(true, "Variable Picker validation passed");
    } else {
        valResp = new giovanni.widget.ValidationResponse(false, msg);
    }
    return valResp;
};

/**
 *  Fetch variable units given a giovanni.widget.FacetedResult object
 *   
 *  @this {giovanni.widget.VariablePicker}
 *  @params {giovanni.widget.FacetedResult}
 *  @returns {String}
 *  @author K. Bryant
 **/
giovanni.widget.VariablePicker.prototype.getUnits = function (result) {
    var units = result.getUnits(); // try the getUnits function first
    if (units == null) // if null is returned, 
        units = result.data.dataFieldUnits; // fetch units from dataFieldUnits attribute
    return units;
}

giovanni.widget.VariablePicker.prototype.isSelectedAlready = function (obj) {
    for (var i = 0; i < this.fs.selectedVariables.length; i++) {
        if (this.fs.selectedVariables[i].getValue() == obj.getValue())
            return true;
    }
    return false;
};

giovanni.widget.VariablePicker.prototype.updateComponent = function (obj) {

    // convert queryString object to string before use
    if (typeof obj == 'object') obj = obj.join();
    obj = decodeURIComponent(obj);
    var params = obj.split("&");
    if (params.length == 0) return;
    var service = '';
    for (var i = 0; i < params.length; i++) {
        if (params[i].indexOf('service=') == 0) {
            service = params[i].split("=")[1];
            break;
        }
    }

    this.fs.service = service;
    this.fs.clearSelections();
    if (service.match("AcMp")) {
        this.fs.baseConstraint = "dataFieldAccumulatable:true AND " + this.fs.ACTIVE_CONS;
    } else if (service.match("QuCl") || service.match("InTs")) {
        this.fs.baseConstraint = "dataProductTimeInterval:monthly AND " + this.fs.ACTIVE_CONS;
    } else {
        this.fs.baseConstraint = this.fs.ACTIVE_CONS;
    }

    var validate = (isLoadInProgress instanceof Function && isLoadInProgress()) ? false : true;
    this.fs.facetChangeHandler(null, validate, true);


    return;
};

/**
 * Clears user selections (does not restore default selections as there are none currently)
 *
 * @this {giovanni.widget.VariablePicker}
 * @author K. Bryant
 */
giovanni.widget.VariablePicker.prototype.clearSelections = function () {
    // clear selected variables
    //	if(this.selectedVariablesTable!=null){
    //		this.selectedVariablesTable.deleteRows(0,this.selectedVariables.length);
    this.fs.selectedVariables = [];
    //	}
    // removed after separate selected variables section was removed
    //document.getElementById(this.resultContainerId).style.display='none';
    // clear selected tally
    document.getElementById(this.resultContainerId + '_count').innerHTML = 0;
    // clear facet selections and facet results ('available' variables)
    this.fs.clearSelections();

    // clearing variable picker should call fire().
    // but fs.clearselections has a async call to it which clears the keyword, unchecks facets and put the faceted selecto
    // to the inital state. The variable picker's fire should be called only after that, which would put the 
    // call to fire at the end of the updateResult() method of faceted selector
};

/**
 * Resets the user selections to the defaults....if there were any... 
 *
 * @this {giovanni.widget.VariablePicker}
 * @author K. Bryant
 */
giovanni.widget.VariablePicker.prototype.resetSelections = function () {
    if (this.lastLoadedQuery != null) {
        this.loadFromQuery(this.lastLoadedQuery);
    } else {
        this.clearSelections();
    }

};

/**
 * Returns the ID for this picker, which is the ID of the HTML element 
 * containing this picker
 *
 * @this {giovanni.widget.VariablePicker}
 * @author Chocka
 */
giovanni.widget.VariablePicker.prototype.getId = function () {
    return this.containerId;
};

/**
 * Returns the highest spatial resolution among the selected variables  
 *
 * @this {giovanni.widget.VariablePicker}
 * @returns Array an array of size 2 (lat and lon resolution)
 * @author Chocka
 */
giovanni.widget.VariablePicker.prototype.getMaxSpatRes = function () {
    var res = [-1, -1];
    var selVars = this.fs.selectedVariables;
    if (selVars.length > 0) {
        var tRes = [-1, -1];
        var spResStr = '';
        for (var i = 0; i < selVars.length; i++) {
            tRes = selVars[i].getResolutionInDegrees();
            for (var r = 0; r < 2; r++) {
                if (res[r] === -1 && tRes[r] !== -1)
                    res[r] = tRes[r];
                else if (tRes[r] === -1 && res[r] !== -1)
                ; //do nothing
                else if (tRes[r] < res[r])
                    res[r] = tRes[r];
            }
        }
    }
    return res;
};

/**
 * Returns the lowest spatial resolution among the selected variables  
 *
 * @this {giovanni.widget.VariablePicker}
 * @returns Array an array of size 2 (lat and lon resolution)
 * @author Chocka
 */
giovanni.widget.VariablePicker.prototype.getMinSpatRes = function () {
    var res = [-1, -1];
    var selVars = this.fs.selectedVariables;
    if (selVars.length > 0) {
        var tRes = [-1, -1];
        var spResStr = '';
        for (var i = 0; i < selVars.length; i++) {
            tRes = selVars[i].getResolutionInDegrees();
            for (var r = 0; r < 2; r++) {
                if (res[r] === -1 && tRes[r] !== -1)
                    res[r] = tRes[r];
                else if (tRes[r] === -1 && res[r] !== -1)
                ; //do nothing
                else if (tRes[r] > res[r])
                    res[r] = tRes[r];
            }
        }
    }
    return res;
};

/**
 * Returns the highest temporal resolution among the selected variables
 * in minutes
 *
 * @this {giovanni.widget.VariablePicker}
 * @returns Integer The highest temporal resolution in minutes
 * @author Chocka
 */
giovanni.widget.VariablePicker.prototype.getMaxTempRes = function () {
    var res = 1000000; // some big random number
    var selVars = this.fs.selectedVariables;
    if (selVars.length > 0) {
        var tRes = 1000000;
        for (var i = 0; i < selVars.length; i++) {
            switch (selVars[i].data.dataProductTimeInterval) {
            case 'minutely':
                tRes = 1;
                break;
            case 'half-hourly':
                tRes = 30; // 30 minutes
                break;
            case 'hourly':
                tRes = 60; // 60 minutes
                break;
            case '3-hourly':
                tRes = 180; // 3 * 60 minutes
                break;
            case 'daily':
                tRes = 1440; // 24 hours * 60 minutes
                break;
            case '8-daily':
                tRes = 1440 * 8; // 8 * 24 hours * 60 minutes
                break;
            case 'monthly':
                tRes = 43800; // 30.417 avg days per month in a year * 24 hours per day * 60 mins per hour 
                // OLD NOTES :
                // tried setting tRes = 40320; // 28 * 60 * 24 minutes (least possible value for a month)
                // but it doesn't work well over long periods. For example for if the chosen time gap is 12 months
                // from Jan to Dec - the time range in minutes is 365 days * 1440 mins per day = 525600 minutes
                // dividing 525600 / 40320 = 13.03 ie 13 time slices - which is wrong (should have been 12)  
                break;
            }
            res = tRes < res ? tRes : res;
        }
    }
    return res;
};

/**
 * Returns the lowest temporal resolution among the selected variables
 * in minutes
 *
 * @this {giovanni.widget.VariablePicker}
 * @returns Integer The lowest temporal resolution in minutes
 * @author Chocka
 */
giovanni.widget.VariablePicker.prototype.getMinTempRes = function () {
    var res = -1;
    var selVars = this.fs.selectedVariables;
    if (selVars.length > 0) {
        var tRes = -1;
        for (var i = 0; i < selVars.length; i++) {
            switch (selVars[i].data.dataProductTimeInterval) {
            case 'minutely':
                tRes = 1;
                break;
            case 'half-hourly':
                tRes = 30; // 30 minutes
                break;
            case 'hourly':
                tRes = 60; // 60 minutes
                break;
            case '3-hourly':
                tRes = 180; // 3 * 60 minutes
                break;
            case 'daily':
                tRes = 1440; // 24 hours * 60 minutes
                break;
            case '8-daily':
                tRes = 1440 * 8; // 8 * 24 hours * 60 minutes
                break;
            case 'monthly':
                tRes = 43800; // 30.417 avg days per month in a year * 24 hours per day * 60 mins per hour 
                // OLD NOTES :
                // tried setting tRes = 40320; // 28 * 60 * 24 minutes (least possible value for a month)
                // but it doesn't work well over long periods. For example for if the chosen time gap is 12 months
                // from Jan to Dec - the time range in minutes is 365 days * 1440 mins per day = 525600 minutes
                // dividing 525600 / 40320 = 13.03 ie 13 time slices - which is wrong (should have been 12)  
                break;
            }
            res = tRes > res ? tRes : res;
        }
    }
    return res;
};

/**
 * Gets the largest data bounding box.
 * 
 * @this {giovanni.widget.VariablePicker}
 * @returns {Array} The largest variable bounding box among selected variables 
 *   as a four element array. 
 * @author Christine Smit
 */
giovanni.widget.VariablePicker.prototype.getLargestBoundingBox = function () {
    var area = -1;
    var largestBoundingBox = [];

    var selVars = this.fs.selectedVariables;
    for (var i = 0; i < selVars.length; i++) {
        // Get the data bounding box
        var west = Number(selVars[i].data.dataProductWest);
        var east = Number(selVars[i].data.dataProductEast);
        var south = Number(selVars[i].data.dataProductSouth);
        var north = Number(selVars[i].data.dataProductNorth);

        // Get the size of the bounding box
        var ct = giovanni.util.getCartesianDistance([west, south, east, north]);
        var height = ct[2];
        var width = ct[1];
        var newArea = height * width;

        if (newArea > area) {
            area = newArea;
            largestBoundingBox = [west, south, east, north];
        }

    }

    return largestBoundingBox;
}

/* Parses a query string representation of data=foobar.
 * 
 * @this {giovanni.widget.VariablePicker}
 * @returns {Object} (Inspect to see properties)
 * @author Daniel da Silva
 */
giovanni.widget.VariablePicker.prototype.parseDataFromQueryString = function (encoded) {
    if (encoded.indexOf("data=") == 0) {
        encoded = encoded.substring("data=".length);
    }

    return $.map(encoded.split(','), function (varToken) {
        var varObj = {};
        var bracketContents;

        // Store variable ID, and seperate out array of bracket tokens. If no
        // backets this array is empty.
        if (varToken.indexOf('(') > 0) {
            var leftBracketPos = varToken.indexOf('(');
            varObj.id = varToken.substring(0, leftBracketPos);
            bracketContents = varToken.substring(leftBracketPos + 1, varToken.length - 1)
                .split(':');
        } else {
            varObj.id = varToken;
            bracketContents = [];
        }

        // Store the key/value pair contained in each brack in the variable's object
        // in the return array. If a bracket option is not present, it will result
        // in 'undefined' when accessed in the variable object.
        $.each(bracketContents, function (idx, bracketToken) {
            var keyValuePair = bracketToken.split('=');
            varObj[keyValuePair[0]] = keyValuePair[1];
        });

        return varObj;
    });
}
