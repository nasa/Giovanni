//FacetedResult.js,v 1.10 2013/04/11 12:40:00 cchidamb Exp
//-@@@ aGiovanni, HEAD

giovanni.namespace("widget");

/**
 * Initializes a faceted search result
 * 
 * @constructor
 * @this {giovanni.widget.FacetedResult}
 * @param {String, Object, Function}
 * @returns {giovanni.widget.FacetedResult}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedResult = function (container, docInfo, resultCallback, callbackContext) {
    this.parent = container;
    this.resultCallback = resultCallback;
    this.callbackContext = callbackContext;
    this.checked = false;
    this.is3DVariable = false;
    this.isClimatology = false;

    this.data = docInfo;
    // this is not necessary now as SOLR would change it to current UTC time itself
    // leaving this code in place just in case (the output of toISO8601DateTimeString is not in UTC though)
    if (this.data.dataProductEndDateTime == undefined ||
        this.data.dataProductEndDateTime == null ||
        this.data.dataProductEndDateTime == '' ||
        this.data.dataProductEndDateTime == '2038-01-19T03:14:07Z') {
        this.data.dataProductEndDateTime = new Date().toISO8601DateTimeString();
    }
};

/**
 * Gets the contents of this row as would be added to the table
 * with addRow() or addRows();
 * 
 * @this {giovanni.widget.FacetedResult}
 * @return object containing row information
 * @author Chocka Chidambaram, Daniel da Silva
 */
giovanni.widget.FacetedResult.prototype.getRow = function () {
    var resultTable = this.parent.facetedResultTable;

    if (this.data.dataFieldZDimensionType) {
        this.is3DVariable = true;
    }
    if (this.data.hasOwnProperty("dataProductSpecialFeatures") &&
        this.data.dataProductSpecialFeatures.indexOf("climatology") >= 0) {
        this.isClimatology = true;
    }

    var newRow = {
        'addCheckBox': this,
        'varName': this.data.dataFieldLongName,
        'zDim': this.data.dataFieldZDimensionType,
        'varTempRes': this.data.dataProductTimeInterval,
        'varSpatRes': this.data.dataProductSpatialResolution.replace("deg.", "&deg;"),
        'varBeginDtTm': this.getStartDate(),
        'varEndDtTm': this.getEndDate(),
        "shortName": this.data.dataProductShortName + ' v' + this.data.dataProductVersion,
        "paramDescUrl": this.data.dataFieldDescriptionUrl,
        "prodDescUrl": this.data.dataProductDescriptionUrl,
        "toolTipList": [{
                "Data Variable": this.data.dataFieldSdsName ? this.data.dataFieldSdsName : this.data.dataFieldLongName
            },
            {
                "Data Product": this.data.dataProductId + ": " + this.data.dataProductLongName
            },
            {
                "Instr./Plat.": this.data.dataProductInstrumentShortName + "/" + this.data.dataProductPlatformShortName
            }],
        "units": this.data.dataFieldUnits,
        "destUnits": this.data.dataFieldDestinationUnits,
        "zDimUnits": this.data.dataFieldZDimensionUnits,
        "zDimValids": this.data.dataFieldZDimensionValues,
        "source": this.data.dataProductPlatformInstrument
    };

    return newRow;
};

/**
 * Returns a string representation of the faceted result
 * 
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedResult.prototype.getValue = function () {
    return this.data.dataFieldLongName;
};

/**
 * Returns the machine usable ID of the faceted result
 * 
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedResult.prototype.getId = function () {
    return this.data.dataFieldId;
};

/**
 * Returns the user selected Z dimension value for the variable 
 * represented by this faceted result
 * 
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedResult.prototype.getZDimValue = function () {
    var elem = document.getElementById(this.getId() + "_ZDim");
    return (elem ? elem.value : null);
};

/**
 * Returns the user selected units for the variable represented by this
 * faceted result.
 *
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Daniel da Silva
 */
giovanni.widget.FacetedResult.prototype.getUnits = function () {
    var elem = document.getElementById(this.getId() + "_units");
    return (elem ? elem.value : null);
};

/**
 * Returns the default units for the variable represented by this
 * faceted result.
 *
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Daniel da Silva
 */
giovanni.widget.FacetedResult.prototype.getDefaultUnits = function () {
    return this.data.dataFieldUnits;
};


/**
 * Returns the variable start date time
 * 
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedResult.prototype.getStartDate = function () {
    return this.data.dataProductBeginDateTime.split('T')[0];
};

/**
 * Returns the variable end date time
 *  
 * @this {giovanni.widget.FacetedResult}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedResult.prototype.getEndDate = function () {
    return this.data.dataProductEndDateTime.split('T')[0];
};

/**
 * Gets the approximate resolution of the data in latitude and longitude
 * 
 * @this {giovanni.widget.FacetedResult}
 * @returns array of size 2 with latitude and longitude in degrees
 * @author Christine Smit (stolen from Chocka)
 */
giovanni.widget.FacetedResult.prototype.getResolutionInDegrees = function () {
    var tRes = [-1, -1];
    var spResStr = this.data.dataProductSpatialResolution;
    var units = "deg";
    if (spResStr.indexOf('km') > -1) {
        units = "km";
    }
    if (spResStr.match("x")) {
        tRes[0] = units === 'km' ?
            parseFloat(spResStr.substring(0, spResStr.indexOf('x'))) / 100 :
            parseFloat(spResStr.substring(0, spResStr.indexOf('x')));
        tRes[1] = units === 'km' ?
            parseFloat(spResStr.substring(spResStr.indexOf('x') + 1)) / 100 :
            parseFloat(spResStr.substring(spResStr.indexOf('x') + 1));
    } else {
        tRes[0] = units === 'km' ? parseFloat(spResStr) / 100 : parseFloat(spResStr);
        tRes[1] = tRes[0];
    }

    return tRes

}