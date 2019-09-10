/*
** $Id: History.js,v 1.10 2015/02/20 21:56:52 kbryant Exp $
** -@@@ Giovanni, Version $Name:  $
*/

// establish the component namespace
giovanni.namespace("app");
/**
 * Constructor
 *
 * @this {giovanni.app.History}
 * @param {Object}
 * @author Chocka
 */
giovanni.app.History = function (config) {
  config = (config==null?{}:config);
  
  this.portal = config.portal;
  this.urlPrefix = config.urlPrefix;
  
  // array to store the result objects
  this.results = new Array();
    
  // result added event
  this.resultAddEvent = new YAHOO.util.CustomEvent('ResultAddEvent', this);
};

/**
 * Returns the result objects
 *
 * @this {giovanni.app.History}
 * @return {Array}
 * @author Chocka
 */
giovanni.app.History.prototype.getResults = function() {
  return this.results;
};

/**
 * Returns the result object with the given ID
 *
 * @this {giovanni.app.History}
 * @return {giovanni.app.Result}
 * @author Chocka
 */
giovanni.app.History.prototype.getResultById = function(id) {
  for (var i=0; i<this.results.length; i++) {
    if(this.results[i].getId()==id) {
      return this.results[i];
    }
  }
};

/**
 * Creates and adds a new result object from the given service query string,
 * to the list of result objects contained in this history. Returns the new
 * result object if successful.
 *
 * @this {giovanni.app.History}
 * @param {String, String}
 * @return giovanni.app.Result
 * @author Chocka
 */
giovanni.app.History.prototype.createResult = function(sessionId, title, query) {
  var config = {portal:this.portal, sessionId:sessionId, 
      title:title, queryData:query, urlPrefix:this.urlPrefix};
  var res = new giovanni.app.Result(config);
  return this.addResult(res)?res:null;
};

/**
 * Restores previous results (from an 'old' session)
 *
 * @this {giovanni.app.History}
 * @param {String, String, String, Object}
 * @return giovanni.app.Result
 * @author K. Bryant
 */
giovanni.app.History.prototype.restoreResult = function (sessionId, title, query, result) {
  var config = {portal:this.portal, sessionId:sessionId, 
      title:title, queryData:query, urlPrefix:this.urlPrefix, queryResult: result, restoreFlag: true};
  var res = new giovanni.app.Result(config);
  return this.addResult(res,true)?res:null;
}

/**
 * Restores previous results (from an 'old' session)
 *
 * @this {giovanni.app.History}
 * @param {String, String, String, Object}
 * @return No explicit return object 
 * @author K. Bryant
 */
giovanni.app.History.prototype.updateRestoredResult = function (sessionId, title, query, o) {
  for(var i=0;i<this.results.length;i++) {
    if (this.results[i].resultId === o.session.resultset[0].result[0].id) {
      this.results[i].updateResult(o);
      break;
    }
  }
}

/**
 * Adds the result object to the list of result objects contained in this history.
 * Returns true if successful.
 *
 * @this {giovanni.app.History}
 * @param {giovanni.app.Result}
 * @return boolean
 * @author Chocka
 **/
giovanni.app.History.prototype.addResult = function(result, restore) {
  if (!this.resultExists(result)) {
    this.results.push(result);
    this.resultAddEvent.fire(result);
  }
  if (restore) result.resultUpdateEvent.fire({restore:true}); 
  return true;
};

/**
 * Check whether a result is contained within the result list 
 * Return true if it does; false otherwise
 **/
giovanni.app.History.prototype.resultExists = function (result) {
  var exists = false;
  var numberOfResults = this.results.length;
  for (var i=0;i<numberOfResults;i++) {
    if (result.criteria && result.getId() === this.results[i].getId()) {
      exists = true;
      break;
    }
  }
  return exists;
};

giovanni.app.History.prototype.clear = function () {
  // delete each result object
  for (var i=0;i<this.results.length;i++) {
    delete this.results[i];
  }
  // establish a new results array
  this.results = [];
  // reset the index so we count properly from the start
  giovanni.app.Result.index = 1;
}
