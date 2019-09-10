giovanni.namespace("widget");

/**
 * Constructor for ValidationResponse
 * 
 * @param valid boolean
 * @param msg String
 * @returns {giovanni.widget.ValidationResponse}
 */
giovanni.widget.ValidationResponse = function (valid,msg) {
  // validation state
  this.valid = Boolean(valid);
  // validation msg
  this.msg = msg;
};

/**
 * Returns true if this validation response represents a successful validation
 * 
 * @returns boolean
 */
giovanni.widget.ValidationResponse.prototype.isValid = function () {
  return this.valid;
};

/**
 * Returns the validation message to be displayed
 *
 * @returns String
 */
giovanni.widget.ValidationResponse.prototype.getMessage = function () {
  return this.msg;
};
