giovanni.namespace("ui.ServicesFilter");


/**
 * Contains the rules describing which services should be enabled
 * for the selected criteria.
 *
 * @constructor
 * @this {giovanni.ui.ServicesFilter}
 * @param {giovanni.widget.Services.Picker} Service picker on the workspace.
 * @param {giovanni.ui.DataSelector} Data selector component
 * @author D. da Silva
 */
giovanni.ui.ServicesFilter = function (servicePicker, dataSelector) {
    this.servicePicker = servicePicker;
    this.dataSelector = dataSelector;
};


/**
 * Check whether a shape has been selected by the user
 *
 * @returns {Boolean} true if shape in criteria
 * @author D. da Silva
 */
// Private method, determine whether a shape is present
giovanni.ui.ServicesFilter.prototype.isShapePresent = function () {
    // a shape is present if the a shape key is present in the query string.
    var query = this.dataSelector.getValue() || window.location.hash
    return giovanni.util.extractQueryValue(query, 'shape') != "";
};


/**
 * Private method: check whether a vector field variable is selected
 * 
 * @returns {Boolean} true if such a variable is in criteria
 * @author D. da Silva
 */
giovanni.ui.ServicesFilter.prototype.isVectorFieldSelected = function () {
    var selectedVars = this.dataSelector.variablePicker.fs.selectedVariables;
    var checkFunc = function (selVar) {
        return selVar.data.hasOwnProperty('dataFieldVectorComponentNames');
    };

    return giovanni.util.any(selectedVars, checkFunc);
};


/**
 * Private method: check whether a climatology variable is selected
 *
 * @returns {Boolean} true if such a variable is in criteria
 * @author D. da Silva
 */
giovanni.ui.ServicesFilter.prototype.isClimatologySelected = function () {
    var selectedVars = this.dataSelector.variablePicker.fs.selectedVariables;
    var checkFunc = function (selVar) {
        return selVar.isClimatology;
    };

    return giovanni.util.any(selectedVars, checkFunc);
};


/**
 * Execute the rules containing which services to enable.
 *
 * @returns {Array} Contains exactly the services names to enable
 * @author D. da Silva
 */
giovanni.ui.ServicesFilter.prototype.execute = function () {
    // Determine base services to allow before exclusion.
    var allowedServices;

    if (this.isVectorFieldSelected()) {
        allowedServices = [
            "Mp",
            "IaMp",
            "TmAvMp",
            "TmAvOvMp"
        ];
    } else if (this.isShapePresent()) {
        allowedServices = [
            "Mp",
            "IaMp",
            "TmAvMp",
            "TmAvOvMp",
            "AcMp",
            "ArAvTs",
            "HiGm",
            "InTs",
            "QuCl"

        ];
    } else if (this.isClimatologySelected()) {
        allowedServices = [
            "Mp",
            "IaMp",
            "TmAvMp",
            "TmAvOvMp",
            "ArAvTs",
        ];
    } else {
        allowedServices = this.servicePicker.getServiceNames();
    }

    // Check conditions for the services to explicitly disallow.
    // TODO: current no checks here, but they should take the form
    // of the code above.
    var toDisallow = [];

    // Remove these services from the return value.
    var i = toDisallow.length;

    while (i--) {
        var foundIdx = allowedServices.indexOf(toDisallow[i]);
        if (foundIdx >= 0) {
            allowedServices.splice(foundIdx, 1);
        }
    }

    return allowedServices;
};
