//$Id: FacetedSelector.js,v 1.118 2015/08/07 17:49:17 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $

giovanni.namespace("widget");

/**
 * Initializes the faceted selector and triggers the initial search query
 * 
 * @constructor
 * @this {giovanni.widget.FacetedSelector}
 * @param {String, String, Object, Function}
 * @returns {giovanni.widget.FacetedSelector}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector = function(containerId, resultsContainerId, dataSourceURLprefix, config, resultCallback, callbackContext)
{
  this.containerId = containerId;
  this.dataSourceURLprefix = dataSourceURLprefix;
  this.config = config;

  this.facets=[];
  this.facetedResults=[];

  this.resultCallback = resultCallback;
  this.callbackContext = callbackContext;

  this.baseQuery = '?version=2.2&indent=on&facet=true&facet.sort=index&wt=json';

  this.facetsContainerId = 'facetsCellScrollable';
  this.facetedResultsPanelId = 'facetedResultsPanel';
  this.facetedResultsContainerId = 'facetedResultsCell';
  this.selectedResultsContainerId = resultsContainerId;

  this.selectedVariables = new Array();

  this.facetedResultTable = null;

  this.variableConstraint = null;
  this.service = giovanni.portal.serviceDataAccessor.DEFAULT_SERVICE;

  this.latestSearchResponse = new Array();

  this.latestSearchKeyword = null;

  this.keywordArray = [];
  this.keywordDS = null;
  this.keywordAutoComplete = null; 
  this.autoCompKeyListener = null;

  this.facetFieldQuery = '';
  for (var i=0; i<this.config.searchFacets.length; i++)
  {
    this.facetFieldQuery += '&facet.field='+this.config.searchFacets[i].name;
  }

  this.ACTIVE_CONS = 'dataFieldActive:true';
  this.baseConstraint = this.ACTIVE_CONS;

  var queryStr = this.baseQuery+this.facetFieldQuery+'&q='+this.baseConstraint;
  this.activeTransactions = {};
  // make an async query, on success : build the facet list, on failure : display error message
  var asyncCallback =
    {
        scope: this,
        success: giovanni.widget.FacetedSelector.prototype.loadFacetInfo,
        failure: function(obj)
        {
    //TODO use this for debugging, if required 
    //alert(YAHOO.lang.dump(obj));
    alert("Failed to retrieve facet information from the datasource. Please try loading the page again.");
        },
        timeout: 5000,
        countonly: true
    };
  if (typeof this.dataSourceURLprefix == "string") {
    asyncCallback.baseUrl = this.dataSourceURLprefix;
    asyncCallback.query = queryStr;
    this.scheduleTransaction(asyncCallback);
  } else if (typeof this.dataSourceURLprefix == "function") {
    this.dataSourceURLprefix(asyncCallback, this);
  }
};

/**
 * Handles the ajax response from the initial search query and loads the facet info
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {Object}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.loadFacetInfo = function(resp)
{
  var respObj = YAHOO.lang.JSON.parse(resp.responseText);
  var fields = respObj.facet_counts.facet_fields;

  // store the max possible no of dataset rows in the response
  this.totRowCount = respObj.response.numFound;
  // create the facets with the information retrieved from the datasource
  var fIndex=0;
  //var facetsHtmlStr = '<h2>Select Variable(s)</h2>'
  //var facetsHtmlStr = '<fieldset><legend>Select Variable(s)</legend>';
  var facetsHtmlStr = '<div id="'+this.facetsContainerId+'">';
  for (var i=0; i<this.config.searchFacets.length; i++)
  {
    var cur = this.config.searchFacets[i];
    var valids = fields[cur.name];

    // create divs to contain facets
    facetsHtmlStr += '<div id="facet'+i+'" class="facetGroup"></div><br/>'; 

    this.facets[fIndex++] = new giovanni.widget.Facet('facet'+i, cur, valids, 
        this.facetChangeHandler, this);
  }
  facetsHtmlStr += '</div>';


  var winWidth = giovanni.util.getWinSize()[0];
  var winHeight = giovanni.util.getWinSize()[1];
  this.facetsCellHeightMargin = 360;
  var facetsCellHeight = (winHeight - this.facetsCellHeightMargin) + 'px';
  this.resultsCellHeightMargin = 415;
  var resultsCellHeight = (winHeight - this.resultsCellHeightMargin) + 'px';
  this.resultsCellWidthMargin = 375;
  var resultsCellWidth = (winWidth - this.resultsCellWidthMargin) + 'px';

  var fsBodyHtml = '<fieldset><legend>Select Variables</legend>'
      //+ '<div id="facetsCell" style="height:'+facetsCellHeight+'">' + facetsHtmlStr + '</div>'
      + '<div id="facetsCell" >' + facetsHtmlStr + '</div>'
      + '<div id="'+this.facetedResultsPanelId+'" class="panel facetResultsPanel" valign="top">'
      + '<div class="tally" style="border-top: none;">' 
      + '<span style="font-size:12px; font-weight:bold; float:left;">Number of matching Variables: '
      + '<span class="" id="matchingFacetedResultsCount">0</span> of '
      + '<span class="" id="totalFacetedResultsCount">'+this.totRowCount+'</span>'
      + '</span>'
      + '<span style="font-size:12px; font-weight:bold; float:left; margin-left:3em;">Total Variable(s) included in Plot: ' 
      + '<span class="" id="'+this.selectedResultsContainerId+'_count">0</span>'
      + '</span>'
      + '<div style="clear:both"></div>'
      + '</div>'

      + '<div id="facetedResultsStatusBar" class="tally" style="font-size:12px;font-weight:bold;color:red"></div>'

      + '<div id="facetedSearchBar" class="facetedSearchBar">'
      + '<label for="facetedSearchBarInput">Keyword :&nbsp;</label>'
      + '<input id="facetedSearchBarInput" class="facetedSearchBarInput" type="text"/>'
      + '<div id="facetedSearchBarResults"></div>'
      + '<button type="button" id="facetedSearchButton" title="Enter a keyword and click to search">Search</button>'
      + '<button type="button" id="facetedClearButton" title="Clear the search results">Clear</button><br/>'
      + '</div>'

      + '<div id="'+this.facetedResultsContainerId+'">'// style="height:'+resultsCellHeight+'; width: '+resultsCellWidth+';">'
      + '<div id="resultTable"></div>'
      + '</div>'
      + '</div>'
      + '</fieldset>';

  document.getElementById(this.containerId).innerHTML = fsBodyHtml;

  // attach listener for search and reset button clicks
  YAHOO.util.Event.addListener("facetedSearchButton", "click", this.performKeywordSearch, this, true);
  YAHOO.util.Event.addListener("facetedClearButton", "click", this.performKeywordSearchReset, this, true);

  // attach listener for window resize events; controls the facet and faceted results divs
  YAHOO.util.Event.addListener(window,"load",this.doResize,{},this);
  YAHOO.util.Event.addListener(window,"resize",this.doResize,{},this);

  this.getAutoCompleteKeywords();

  this.render();

  if(REGISTRY){
    REGISTRY.markComponentReady(this.containerId);
  } 
};

giovanni.widget.FacetedSelector.prototype.doResize = function (event, args) {
  var facetedResultWidthMargin = 350;
  var width = giovanni.util.getWinSize()[0];

  document.getElementById("facetedResultsPanel").style.width = (width - facetedResultWidthMargin) + "px";
  if (this.facetedResultTable != null) {
    this.facetedResultTable.render();
  }
};

giovanni.widget.FacetedSelector.prototype.getAutoCompleteKeywords = function() {
  var keywordQueryStr = "daac-bin/aesir_proxy.pl/terms?terms.fl=dataFieldKeywords&terms.limit=-1&wt=json";
  var keywordsCallback = {
      scope: this,
      success: giovanni.widget.FacetedSelector.prototype.handleKeywordSuccess,
      failure: function(obj)
      {
    alert("Warning: Failed to retrieve auto complete suggestions from the server.");
      },
      timeout: 5000
  };
  YAHOO.util.Connect.asyncRequest('GET', keywordQueryStr, keywordsCallback, null);
};

giovanni.widget.FacetedSelector.prototype.handleKeywordSuccess = function(resp) {
  var respObj = null;
  try {
    respObj = YAHOO.lang.JSON.parse(resp.responseText);
  } catch(x)  {
    alert("Warning: Failed to parse auto complete suggestions obtained from the server.");
    return;
  }

  // Solr 1.4 returns 'terms' as an array with first element of
  // "dataFieldKeywords" and second element an array,
  // while Solr 4 returns 'terms' as an object containing
  // the dataFieldKeywords array.
  var respArray = (respObj.terms.dataFieldKeywords) ? respObj.terms.dataFieldKeywords : respObj.terms[1];
  this.keywordArray = [];
  var index=0;
  for (var i=0; i<respArray.length; i=i+2) {
    this.keywordArray[index++]=respArray[i];
  }

  if (this.keywordDS == null) {
    this.keywordDS = new YAHOO.util.LocalDataSource(this.keywordArray);   // field definition optional for a local data source
  }

  if (this.keywordAutoComplete == null) {
    this.keywordAutoComplete = new YAHOO.widget.AutoComplete("facetedSearchBarInput","facetedSearchBarResults", this.keywordDS);
    this.keywordAutoComplete.useShadow = true;
    this.keywordAutoComplete.autoHighlight=false;
  }

  //  the textboxKeyEvent doesn't detect the ENTER key
  //  this.keywordAutoComplete.textboxKeyEvent.subscribe(function(type, args) {
  //    //args[0] is reference to the autocomplete object
  //    var keyCode = args[1];
  //    if (keyCode == 13) {
  //      this.performKeywordSearch(null);
  //    }
  //  });

  if (this.autoCompKeyListener == null) {
    this.autoCompKeyListener = new YAHOO.util.KeyListener("facetedSearchBarInput", 
        {keys:13}, 
        {fn:this.performKeywordSearch, scope:this, correctScope:true});
    this.autoCompKeyListener.enable();
  }
};

giovanni.widget.FacetedSelector.prototype.performKeywordSearchReset = function(event) {
  document.getElementById("facetedSearchBarInput").value='';
  this.latestSearchKeyword = ''; // while clearing search, also clear the last remembered keyword at the same time
  this.performKeywordSearch(event);
};

giovanni.widget.FacetedSelector.prototype.performKeywordSearch = function(event) {
  var countonly = false;
  // cancel any active AJAX transactions
  this.cancelActiveTransactions();

  var keyword = document.getElementById("facetedSearchBarInput").value;
  //TODO change this
  var keywordSearchQuery = this.baseQuery + this.facetFieldQuery; //+ '&fl=dataFieldLongName'
  if (keyword==null || keyword=='') {
    countonly = true;
    keywordSearchQuery += '&q='+this.baseConstraint;
  } else {
    countonly = false;
    keywordSearchQuery += '&q='+this.baseConstraint+' AND dataFieldKeywordsText:('+keyword+')';
  }

  // add the service to the query, for the proxy to respond back with variable constraints based on the service
  keywordSearchQuery += '&service='+this.service;

  var errCallback = function(obj) {
    console.log("Error : giovanni.widget.FacetedSelector : " + obj);
    document.getElementById("facetedSearchBarInput").value = (this.latestSearchKeyword?this.latestSearchKeyword:'');
    alert("Failed to perform a keyword search");
  };
  this.scheduleTransaction({
    query: keywordSearchQuery,
    scope: this,
    success: giovanni.widget.FacetedSelector.prototype.handleKeywordSearchSuccess,
    failure: errCallback,
    argument: [false, null, keyword],
    countonly: countonly
  });
};

giovanni.widget.FacetedSelector.prototype.handleKeywordSearchSuccess = function(resp) {
  var respObj = null;
  respObj = resp.responseObject;
  // search was successful - remember this keyword
  this.latestSearchKeyword = resp.argument[2];

  // unselect all facets
  for (var i=0; i<this.facets.length; i++) {
    this.facets[i].setValue([]);
  }

  this.updateResult(resp);
  if (respObj.response.docs.length!=0) { // if 0, updateCount is called from updateResult
    this.updateCount(resp);
  }
};

/**
 * Constructs the filter queries reqd for fetching results and facet counts
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {String}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.getFilter = function(queryType, targetFacet)
{
  var queryStr = '';
  var filterArr = [];
  for (var i=0; i<this.facets.length; i++)
  {
    // if the current facet is the target facet, whose count is to be upated,
    // don't include it in the filter
    // i.e., the target facet's counts are influenced by selections in ALL OTHER FACETS
    if (queryType==='count' && targetFacet != null && this.facets[i] === targetFacet)
      continue;

    var values = this.facets[i].getValue();
    if (values.length > 0)
    {
      var filterStr = this.facets[i].name+':(';

      filterStr += escape('"'+values[0]+'"');
      for (var j=1; j<values.length; j++)
      {
        filterStr += escape(' OR ');
        filterStr += escape('"'+values[j]+'"');
      }
      filterStr += ')';
      filterArr[filterArr.length] = filterStr;
    }
  }
  if (filterArr.length>0)
  {
    var delimStr = null;
    if (queryType==='result') {
      delimStr = '&fq=';
    } else if(queryType==='count') { 
      delimStr = ' AND ';
    }
    queryStr += '&fq='+filterArr[0];
    for (var i=1; i<filterArr.length; i++)
    {
      queryStr += delimStr+filterArr[i];
    }
  }
  return queryStr;
};

/**
 * Disable UI elements inside a HTML element and all its children recursively
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {Object}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.recursiveDisableInputElements = function(element) {
  if (element.nodeName=="INPUT") {
    try {
      element.setAttribute("disabled", "disabled");
    }
    catch(E){}
  }
  if (element.childNodes && element.childNodes.length > 0) {
    for (var i = 0; i < element.childNodes.length; i++) {
      this.recursiveDisableInputElements(element.childNodes[i]);
    }
  }
};

/**
 * Checks if all count queries have completed, and resets the mouse cursor 
 * to 'default' if so (or sets to 'wait' otherwise), for the faceted selector container. 
 *
 * @this {giovanni.widget.FacetedSelector}
 * @author Chocka
 */
giovanni.widget.FacetedSelector.prototype.updateCursor = function() {
  var container = document.getElementById(this.containerId);
  container.style.cursor = (Object.keys(this.activeTransactions).length === 0) ? 'default' : 'wait';
};

/**
 * Recursively unchecks DOM elements if possible
 *
 * @this {giovanni.widget.FacetedSelector}
 * @param {DOM Element}
 * @author K. Bryant
 */
giovanni.widget.FacetedSelector.prototype.uncheckElements = function (element) {
  try{
    element.checked = false;
  }catch(E){}

  if(element.childNodes && element.childNodes.length > 0){
    for(var i = 0; i < element.childNodes.length; i++){
      this.uncheckElements(element.childNodes[i]);
    }
  }
};

/**
 * Unchecks all facet elements and zeroes the tally and faceted results container
 *
 * @this {giovanni.widget.FacetedSelector}
 * @author K. Bryant
 */
giovanni.widget.FacetedSelector.prototype.clearSelections = function () {
  var container = document.getElementById(this.facetsContainerId);
  this.uncheckElements(container);
  //this.facetChangeHandler(null,true);
  this.performKeywordSearchReset(null);
  for (var i=0; i<this.facets.length; i++) {
    // clear any info displayed under collapsed facets
    this.facets[i].clearCollapsedInfo();
    var locator = '#'+this.facets[i].getCollapsibleHeaderId();
    if (i<2) {
      $(locator).collapsible('open');
    } else {
      $(locator).collapsible('close');
    }
  }
};

/**
 * Upon user selection of a facet, this method triggers a new search query to the database
 * to get updated faceted results and counts
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {Object, Boolean}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.facetChangeHandler = function(event, validateSelection, updateTotalCount)
{
  var countonly = false;
  // cancel any active AJAX transactions
  this.cancelActiveTransactions();

  // disable all elements under the parent (variable picker) div
  // the facets which are disabled here get enabled again, based on facet counts,
  // when the update method of Facet component executes after the AJAX response comes back
  var container = document.getElementById(this.facetsContainerId);
  this.recursiveDisableInputElements(container);

  var qStr;
  if (this.latestSearchKeyword==null || this.latestSearchKeyword=='') {
    qStr = '&q='+this.baseConstraint;
    document.getElementById("facetedSearchBarInput").value = '';
  } else {
    qStr = '&q='+this.baseConstraint+' AND dataFieldKeywordsText:('+this.latestSearchKeyword+')';
    document.getElementById("facetedSearchBarInput").value = this.latestSearchKeyword;
  }

  var prefix = this.baseQuery+this.facetFieldQuery+qStr;

  var query1 = this.getFilter('result', null);

  // change query str to allow for the max no of dataset result rows possible, for this group of facets
  var resultQuery = prefix+query1;
  if (query1 === '' && !(this.latestSearchKeyword!=null&&this.latestSearchKeyword!='')) countonly = true;

  // add the service to the query, for the proxy to respond back with variable constraints based on the service
  resultQuery += '&service='+this.service;

  // make an async query for results. on success : update the facet info, on failure : display error message
  var errCallback = function(obj) {
    //TODO - use this dump for debugging, if required
    //alert(YAHOO.lang.dump(obj));
    alert("Failed to retrieve variables from the datasource for the selected facets. Please try again.");
    // set the cursor back to default
  };
  this.scheduleTransaction({
    query: resultQuery,
    scope: this,
    success: giovanni.widget.FacetedSelector.prototype.updateResult,
    failure: errCallback,
    argument: [validateSelection, null, updateTotalCount],
    countonly: countonly
  });
  var self = this;
  if (query1!=''||(this.latestSearchKeyword!=null&&this.latestSearchKeyword!='')) // make async query for facet counts [if reqd]
  {
    //var query2 = null, countQuery = null;
    //    for (var i=0; i<this.facets.length; i++)
    //    {
    setTimeout (function() {
      return recursiveTimeoutFunction(prefix, validateSelection, self, 0);
    }, 100);
    //    } // END of FOR
  } // END of IF
};

function recursiveTimeoutFunction (prefix, validateSelection, self, index) {
  var query2 = self.getFilter('count', self.facets[index] /* the facet whose count is to be updated */);
  // if (query2!='') // if no selections have been made in all other facets, skip querying/updating this facet
  var countQuery = prefix+query2;
  var argument = [validateSelection, self.facets[index], /* the facet whose count is updated by this async query */
                  countQuery /* the query being executed */, 1 /* retry counter */];
  self.scheduleTransaction({
    query: countQuery,
    scope: self,
    success: giovanni.widget.FacetedSelector.prototype.updateCount,
    failure: giovanni.widget.FacetedSelector.prototype.handleCountFailure,
    argument: argument,
    timeout: 8000,
    countonly: true
  });

  index++;
  if (index<self.facets.length) {
    setTimeout (function() {
      return recursiveTimeoutFunction(prefix, validateSelection, self, index);
    }, 100);
  }
};  

giovanni.widget.FacetedSelector.prototype.handleCountFailure = function(obj)
{
  //Use this dump for debugging, if required
  //alert(YAHOO.lang.dump(obj));
  alert("Failed to update counts for the " + obj.argument[1].label + " facet. Please try selecting facets again.");
};

/**
 * Handles the ajax response from the updated search queries, and updates faceted results 
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {Object}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.updateResult = function(resp) {
  var respObj = resp.responseObject;

  // save the constraints to enforce on selected variables
  this.variableConstraint = respObj.constraint;

  // update the facet results with the new information retrieved from the datasource
  this.facetedResults = this.selectedVariables.slice(0);
  var updateTotalCount = resp.argument[2];
  if (updateTotalCount===true) {
    // update only the displayed total row count
    // do not update the instance variable this.totRowCount, which stores the total records for the entire portal
    // DISABLING total count update for now
    // document.getElementById("totalFacetedResultsCount").innerHTML = respObj.response.numFound;
  }
  var results = respObj.response.docs;
  this.latestSearchResponse = results;
  document.getElementById("matchingFacetedResultsCount").innerHTML = results.length;
  var htmlStr = '' 
      //'<div id="facetedResultsStatusBar" class="tally" style="font-size:12px;color:red"></div>'
      //+ '<div id="scrollContainer" style="vertical-align: top; overflow-y:scroll; height: '
      //+(giovanni.util.getWinSize()[1]-this.resultsCellHeightMargin)+'px; width: '+(giovanni.util.getWinSize()[0]-this.resultsCellWidthMargin)+'px;">'
      //+ '<div id="'+this.facetedResultsContainerId+'" style="height:'+(giovanni.util.getWinSize()[1]-this.resultsCellHeightMargin)+'px'
      //  +'; width: '+(giovanni.util.getWinSize()[0]-this.resultsCellWidthMargin)+'px;vertical-align:top; overflow-y:scroll;overflow-x:hidden;">'
      + '<div id="resultTable"></div>'
      //+ '</div>'
      ;
  //  document.getElementById(this.facetedResultsContainerId).style.height = (giovanni.util.getWinSize()[1]-this.resultsCellHeightMargin)+'px';

  //DEBUG INFO document.getElementById(this.facetedResultsContainerId).innerHTML = '<div>'+resp.argument[0]+'</div>'+htmlStr;
  document.getElementById(this.facetedResultsContainerId).innerHTML = htmlStr;
  //document.getElementById(this.facetedResultsContainerId).style.width = (giovanni.util.getWinSize()[0]-this.resultsCellWidthMargin)+'px';

  for (var i=0; i<results.length; i++)
  {
    var contains = false;
    for (var j=0; j<this.selectedVariables.length; j++) {
      if (this.selectedVariables[j].data.dataFieldId == results[i].dataFieldId) {
        contains = true;
        break;
      }
    }
    if (!contains) {
      var facResult = new giovanni.widget.FacetedResult(this, results[i], this.resultCallback, this.callbackContext);
      this.facetedResults[this.facetedResults.length] = facResult;
    }
  }

  var customButtonFormatter = function(el, oRecord, oColumn, oData){
    var myButton = document.createElement('input');
    myButton.type = 'checkbox';
    myButton.title = 'Add this variable';
    myButton.checked = oData.checked;
    //myButton.innerHTML = '<span style="white-space: nowrap;"><img alt="" src="./img/add.png">Add</span>';
    myButton.setAttribute('style','font-size:2em;margin-left:-0.05em');
    el.appendChild(myButton);
    YAHOO.util.Event.addListener(myButton, "click", oData.parent.handleSelection, [[oData], false, myButton, oRecord], oData.parent);
  };

  var checkBoxSort = function (a, b, desc) { 
    // handle empty values 
    if(!YAHOO.lang.isValue(a)) { 
      return (!YAHOO.lang.isValue(b)) ? 0 : 1; 
    } 
    else if(!YAHOO.lang.isValue(b)) { 
      return -1; 
    } 
    // compare the 'checked' attribute
    var comp = YAHOO.util.Sort.compare;
    var val1 = a.getData()["addCheckBox"].checked;
    var val2 = b.getData()["addCheckBox"].checked;
    var compState = comp(val1, val2, desc); 
    return compState; 
  }; 

  var customLinkFormatter = function(el, oRecord, oColumn, oData){
    if (YAHOO.lang.isString(oData)) {
      var longName = oData;
      var longNameLink = oRecord.getData('paramDescUrl');
      var shortName = oRecord.getData('shortName');
      var shortNameLink = oRecord.getData('prodDescUrl');
      var toolTipList = oRecord.getData('toolTipList');

      var titleStr = "";
      for(var i=0; i<toolTipList.length; i++) {
        for (label in toolTipList[i]) {
          titleStr += label + " = " + toolTipList[i][label] + '\n';
        }
      }
      if (titleStr!="") titleStr = titleStr.substring(0, titleStr.length-1);

      var longNameStr = longName;
      if (YAHOO.lang.isString(longNameLink) && longNameLink.length) {
        longNameStr = '<a href="' + longNameLink + '" target="_blank" title="' + titleStr + '" class="facetedResultLink" onclick="YAHOO.util.Event.stopPropagation(event)">' + longName + '</a>';
      }
      var shortNameStr = '';
      if (YAHOO.lang.isString(shortName) && shortName.length) {
        if (YAHOO.lang.isString(shortNameLink) && shortNameLink.length ) {
          shortNameStr = '&nbsp;&nbsp;&nbsp;&nbsp;' 
              + '<b>(</b><a href="' + shortNameLink + '" target="_blank" class="facetedResultLink" onclick="YAHOO.util.Event.stopPropagation(event)">' + shortName + '</a><b>)</b>';
        } else {
          shortNameStr = '&nbsp;&nbsp;&nbsp;&nbsp;' 
              + '<b>(</b>' + shortName + '<b>)</b>';
        }
      }
      el.innerHTML = "<div style='width:100%'>"+longNameStr + shortNameStr + "</div>";
    } else {
      el.innerHTML = YAHOO.lang.isValue(oData) ? oData : "";
    }
  };

  var tempResHeader = "<img src=\"./img/clock_trans.png\" title=\"Temporal Resolution\" width=\"20\" height =\"20\" align=\"center\"></img>";
  var customTempResFormatter = function(el, oRecord, oColumn, oData){
    if (YAHOO.lang.isString(oData)) {
      var interval = oData;
      var htmlElem = document.createElement("div");
      switch(interval) {
      case 'half-hourly': 
        htmlElem.appendChild(document.createTextNode("Half-Hourly")); 
        htmlElem.setAttribute("title", "Half-Hourly");
        break;
      case 'hourly': 
        htmlElem.appendChild(document.createTextNode("Hourly")); 
        htmlElem.setAttribute("title", "Hourly");
        break;
      case 'daily': 
        htmlElem.appendChild(document.createTextNode("Daily"));
        htmlElem.setAttribute("title", "Daily");
        break;
      case '8-daily': 
        htmlElem.appendChild(document.createTextNode("8-Daily"));
        htmlElem.setAttribute("title", "8-Daily");
        break;
      case 'monthly': 
        htmlElem.appendChild(document.createTextNode("Monthly"));
        htmlElem.setAttribute("title", "Monthly");
        break;
      default:
        htmlElem.appendChild(document.createTextNode(interval));
        htmlElem.setAttribute("title", interval);
      }
      el.appendChild(htmlElem);
    } else {
      el.innerHTML = YAHOO.lang.isValue(oData) ? oData : "";
    }
  };
  var tempResSort = function (a, b, desc) {
    // handle empty values 
    if(!YAHOO.lang.isValue(a)) { 
      return (!YAHOO.lang.isValue(b)) ? 0 : 1; 
    } 
    else if(!YAHOO.lang.isValue(b)) { 
      return -1; 
    } 
    var comp = YAHOO.util.Sort.compare;
    var facResult1TempRes = giovanni.widget.FacetedSelector.getTempResOrder(a.getData("varTempRes"));
    var facResult2TempRes = giovanni.widget.FacetedSelector.getTempResOrder(b.getData("varTempRes"));
    var compState = comp(facResult1TempRes, facResult2TempRes, desc); 
    return compState;
  };

  var selectedService = this.service; 
  var unitsFormatter = function (el, oRecord, oColumn, oData) {
    if (YAHOO.lang.isArray(oData) || 1) {
      var facResult = oRecord.getData('addCheckBox');
      var srcUnits = oRecord.getData('units');
      var destUnits = oRecord.getData('destUnits') || [];
      var allUnits = [srcUnits].concat(destUnits);

      allUnits.sort();

      // Return early if the drop-down size is 1 
      // The UI will show the option as a label in the column.
      // Reformatting is done on the entry if it is unitless, in which case it is replaced with '-'.
      if (allUnits.length == 1) {

        var label = srcUnits;

        // if unitless
        if (srcUnits == '1' || srcUnits == '' || srcUnits == 'NoUnits') {
          label = '-';
        } 

        el.innerHTML = label;
        return;
      }    

      // Build drop-down list in shadow DOM. The ID provides a global access 
      // point for retrieving the variable's selected units.
      var xselect = $('<select>');
      if( selectedService == "CoMp" ){ // CoMp does not care about or support units conversion
        xselect = $('<select disabled class="disabledSelect">');
      }
      xselect.attr('id', facResult.getId() + "_units");
      xselect.css('text-align', 'center');

      for (var i = 0; i < allUnits.length; i++) {
        // Build option element
        var xoption = $('<option>');
        var label = allUnits[i];

        if (allUnits[i] == srcUnits) {
          label = '<b>' + label + '</b>';
        }

        var selected = false;
        selected = selected || (facResult.data.userSelectedUnits
            && facResult.data.userSelectedUnits == allUnits[i]);
        selected = selected || (! facResult.data.userSelectedUnits
            && srcUnits == allUnits[i]);

        if (selected) { 
          xoption.attr('selected', 'selected');
        }

        xoption.attr('value', allUnits[i]);
        xoption.html(label);

        // Add option element as child of select element
        xselect.append(xoption);
      }

      // Write drop-down list to element
      $(el).empty();
      $(el).append(xselect);

      // Bind to change event, firing update event from faceted result if
      // it is checked.
      xselect.change(function(event) {
        YAHOO.util.Event.stopPropagation(event);
        facResult.data.userSelectedUnits = document.getElementById(facResult.getId() + '_units').value;
        if (facResult.checked) {
          var vo = facResult.parent.callbackContext.validate();
          if(vo.valid)
            facResult.parent.callbackContext.fire();
        }
      });
      xselect.click(function(event) {
        YAHOO.util.Event.stopPropagation(event);
      });
    } else {
      el.innerHTML = YAHOO.lang.isValue(oData) ? oData : "-";
    }
  };

  var unitsSort = function(a, b, desc) {  
    var facResultA = a.getData("addCheckBox");
    var facResultB = b.getData("addCheckBox");

    var val1 = facResultA.data.userSelectedUnits || facResultA.data.dataFieldUnits;
    var val2 = facResultB.data.userSelectedUnits || facResultB.data.dataFieldUnits;

    return YAHOO.util.Sort.compare(val1, val2, desc); 
  }

  var zDimFormatter = function (el, oRecord, oColumn, oData) {
    if (YAHOO.lang.isString(oData)) {
      var zDimType = oData;
      var zDimUnits = oRecord.getData('zDimUnits');
      var zDimValids = oRecord.getData('zDimValids').split(' ');
      var facResult = oRecord.getData('addCheckBox');
      // restore the user selected Z dim value
      var zDimVal = facResult.data.userSelectedZDimValue;

      var is3d = session.dataSelector.servicePicker.is3DService();
      if (is3d) {
        // if 3d service - show the range of values (read-only)
        el.innerHTML = zDimValids[0] + ' - ' + zDimValids[zDimValids.length-1] + ' '  + zDimUnits;
      } else {
        // if 2d service - user has to select a z dimension slice
        // display a dropdown (sinlge select for now) for the user to select
        // later this could be multi select - but that involves changes outside too (var picker evaluation)
        var selEl = document.createElement("select");
        selEl.id = facResult.getId()+"_ZDim";
        selEl.title = "Select " + zDimType;
        for (var i=0; i<zDimValids.length; i++) {
          selEl.options[i] = new Option(zDimValids[i], zDimValids[i]);
          if (zDimValids[i]==zDimVal) {
            selEl.options[i].setAttribute('selected', 'selected');
          }
        }
        el.appendChild(selEl);
        var lab = document.createElement("label");
        lab.appendChild(document.createTextNode(' ' + zDimUnits));
        el.appendChild(lab);
        YAHOO.util.Event.addListener(selEl, "change", function(event) {
          YAHOO.util.Event.stopPropagation(event);
          facResult.data.userSelectedZDimValue = event.target.value;
          if (facResult.checked) {
            // invoke VariablePicker fire as the a var selection has changed
            facResult.parent.callbackContext.fire();
          }
        });
        YAHOO.util.Event.addListener(selEl, "click", function(event) {
          YAHOO.util.Event.stopPropagation(event);
        });
      }
    } else { // for 2-d variables there is no Z dim data
      el.innerHTML = YAHOO.lang.isValue(oData) ? oData : "-";
    }
  };

  var zDimSort = function (a, b, desc) { 
    // handle empty values 
    if(!YAHOO.lang.isValue(a)) { 
      return (!YAHOO.lang.isValue(b)) ? 0 : 1; 
    } 
    else if(!YAHOO.lang.isValue(b)) { 
      return -1; 
    } 
    // compare the 'checked' attribute
    var comp = YAHOO.util.Sort.compare;
    var facResult1 = a.getData("addCheckBox");
    var val1 = giovanni.widget.FacetedSelector.findZDimValue(facResult1);
    var facResult2 = b.getData("addCheckBox");
    var val2 = giovanni.widget.FacetedSelector.findZDimValue(facResult2);
    var compState = comp(val1, val2, desc); 
    return compState; 
  }; 

  var resultColumnDefs = [
                          { key:"addCheckBox", label:"", resizeable: false, sortable:true, sortOptions:{sortFunction:checkBoxSort}, 
                            formatter:customButtonFormatter, width:10, className:"align-center"},
                          { key:"varName", label: "<label>Variable</label>", 
                              resizeable:true, sortable:true, formatter:customLinkFormatter, width:'50%'},
                          { key:"destUnits", label:"<label title='Click to sort on selected units'>Units</label>",
                                          resizeable:true, sortable:true, sortOptions:{sortFunction:unitsSort}, formatter:unitsFormatter, className:"align-center", width:90},
                          { key:"source", label:"<label title='Click to sort on Source'>Source</label>",
                                resizeable:true, sortable:true, width:50},
                          { key:"varTempRes", label:"<label title='Click to sort on Temporal Resolution'>Temp.Res.</label>", 
                                  resizeable:true, sortable:true, sortOptions:{sortFunction:tempResSort}, formatter:customTempResFormatter, className:"align-center", width:60},  
                          { key:"varSpatRes", label:"<label title='Click to sort on Spatial Resolution'>Spat.Res.</label>", 
                                    resizeable:true, sortable:true, className:"align-center", width:50}, //removed 'text' formatter to allow html entity (&deg;)  
                          { key:"varBeginDtTm", label:"<label title='Click to sort on Begin Date'>Begin Date</label>", 
                                      resizeable:true, sortable:true, formatter:"text", className:"align-center", width:70}, 
                          { key:"varEndDtTm", label:"<label title='Click to sort on End Date'>End Date</label>", 
                                        resizeable:true, sortable:true, formatter:"text", className:"align-center", width:70}, 
                          ];



  var resultDS = new YAHOO.util.LocalDataSource([]);
  resultDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSARRAY;
  resultDS.responseSchema = {
      fields: ["addCheckBox", "varName", "zDim", "verTempRes", "varSpatRes", "varBeginDtTm", "varEndDtTm", "shortName", "paramDescUrl", "prodDescUrl", "toolTipList", "zDimUnits", "zDimValids", "source"]
  };

  if (this.facetedResults.length > 0) {
    this.doResize(null, null);

    // Render all the results. History has shown that using addRows() with
    // a list is significantly faster than multiple calls to addRow()
    var rows = [];

    var thereAre3DVariables = false;
    for (var i = 0; i < this.facetedResults.length; i++) {
      rows.push(this.facetedResults[i].getRow());
      if(this.facetedResults[i].is3DVariable && !thereAre3DVariables){
        thereAre3DVariables = true;
      }
    }

    if(thereAre3DVariables){
      resultColumnDefs.push(
          { 
            key:"zDim", label:"<label title='Click to sort on Vertical Slice'>Vert. Slice</label>", 
            resizeable:false, sortable:true, 
            sortOptions:{sortFunction:zDimSort}, formatter:zDimFormatter, className:"align-center", width:75
          }
          );
    }

    // create the data table
    this.facetedResultTable = new YAHOO.widget.ScrollingDataTable("resultTable", resultColumnDefs, resultDS,{width:'100%',height:'auto'});

    this.facetedResultTable.addRows(rows);

    for (var i = 0; i < this.facetedResults.length; i++) {
      if (this.facetedResults[i].checked) {
        this.facetedResultTable.selectRow(i);
      }
    }

    this.facetedResultTable.subscribe("rowMouseoverEvent", this.facetedResultTable.onEventHighlightRow);
    this.facetedResultTable.subscribe("rowMouseoutEvent", this.facetedResultTable.onEventUnhighlightRow);
    this.facetedResultTable.subscribe("rowClickEvent", this.handleRowSelect, this, true); 
  }

  if (results.length == 0) {
    // if there are no new results, the search has been reset. 
    // Update the facet counts with the counts in this response
    this.updateCount(resp);
  }

  if(resp.argument[0]) { //validateSelection
    this.validateVariableConstraints();
  }

  //TODO consider adding variable picker fire
  // but avoid doing it again at the end of handleSelection in case of "replace" ('load from query' or the old 'reload criteria' functionality)
  var varPicker = this.callbackContext;
  var vo = varPicker.validate(); // used to check units selections, for example

  // fire a picker change if validation is true, if the results length are > 0 or
  // if the validation fails, but there are no results (i.e., no facets selected)
  if(vo.valid || results.length > 0 || (!vo.valid && results.length === 0))
    varPicker.fire();
};

giovanni.widget.FacetedSelector.findZDimValue = function (facResult) {
  var val = null;
  if (facResult.is3DVariable) {
    if (session.dataSelector.servicePicker.is3DService()) {
      var valids = facResult.data.dataFieldZDimensionValues;
      val = valids[0] + ' - ' + valids[valids.length-1] + ' '  
          + facResult.data.dataFieldZDimensionUnits;
    } else {
      val = parseInt(document.getElementById(facResult.getId()+"_ZDim").value);
    }
  } else {
    val = '-';
  }
  return val;
};

giovanni.widget.FacetedSelector.getTempResOrder = function (res) {
  var val = 0;
  switch (res) {
  case 'half-hourly': val=1; break;
  case 'hourly': val=2; break;
  case '3-hourly': val=3; break;
  case 'daily': val=4; break;
  case '8-daily': val=5; break;
  case 'monthly': val=6; break;
  default: val=7; break;
  };
  return val;
};

/**
 * Handles the ajax response from the updated search queries, and updates individual facet counts
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {Object}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.updateCount = function(resp)
{
  var respObj = resp.responseObject;
  var fields = respObj.facet_counts.facet_fields;
  //var validateSelection = resp.argument[0];
  var facetToUpdate = resp.argument[1]; /* the facet whose count is to be updated from this response */

  // update the facets fields with the new information retrieved from the datasource
  for (var i=0; i<this.facets.length; i++)
  {
    var cur = this.facets[i];

    if (facetToUpdate != null && facetToUpdate != cur) continue;

    cur.valids = fields[cur.name];
    //cur.update(changedFacet!=cur);
    cur.update(true);
  }
};

/**
 * Handles the user select/unselect action on variables from the faceted search result list
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @param {Object, Object}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.handleSelection = function(event, param)
{
  if (event) YAHOO.util.Event.stopPropagation(event);
  // the set of facetedresults which was selected/unselected (added/removed)
  var facetedResultArr = param[0];
  // boolean - to replace the current list of selected variables
  var replace = param[1];
  // the checkbox for the record (row) in the faceted result table, representing the selected variable
  var checkbox = param[2];
  // the record (row) in the faceted result table, representing the selected variable
  var record = param[3];

  var action = '';
  if (checkbox!=null && checkbox.checked != undefined) {
    action = checkbox.checked?'add':'remove';
  } else {
    action = 'add';
  }

  var newRowAdded = false;
  var rowDeleted = false;
  if (action=='add')
  {
    if (replace) {
      this.selectedVariables = [];
    }
    for (var i=0; i<facetedResultArr.length; i++) {
      var res = facetedResultArr[i];
      this.selectedVariables [this.selectedVariables.length] = res;
      res.checked = true;
      // during replacement (load from url), the table has not been created yet
      // the row selection will be done later, when the table is created and 
      // the row is rendered from the render method of FacetedResult
      if (!replace) {
        this.facetedResultTable.selectRow(record);
      }
      newRowAdded = true;
    }
  } else if (action=='remove'){
    for (var i=0; i<facetedResultArr.length; i++) {
      var res = facetedResultArr[i];
      this.selectedVariables.splice(this.selectedVariables.indexOf(res), 1);
      res.checked = false;
      this.facetedResultTable.unselectRow(record);
      rowDeleted = true;
      // delete the record from the result table
      // if this faceted result is not a part of the latest facet search
      var retain = false;
      for (var j=0; j<this.latestSearchResponse.length; j++) {
        if (res.data.dataFieldId == this.latestSearchResponse[j].dataFieldId) {
          retain = true;
          break;
        }
      }
      if (!retain) { 
        this.facetedResultTable.deleteRow(record);
        if (this.facetedResultTable.getRecordSet().getLength() == 0) {
          document.getElementById('resultTable').innerHTML = '';
        }
      }
    }
  }

  // if the data has been replaced, its either a 'load from query' or 'reload critieria' scenario
  // the facet search results have to be regenerated 
  // (and variable constraints evaluated after that - call from updateResult method)
  if (replace) {
    this.facetChangeHandler(null, true);
  } else { // else just evaluate the constraints
    this.validateVariableConstraints();
  }

  if (newRowAdded || rowDeleted) {
    document.getElementById(this.selectedResultsContainerId+'_count').innerHTML = this.selectedVariables.length;

    // whenever the variables selected/unselected, update the selected variables array in VariablePicker
    // which is used to construct the query when the user hits the get plots button
    var varPicker = this.callbackContext;
    //    varPicker.selectedVariables = this.selectedVariables;
    varPicker.validate();
    varPicker.fire();
  }
};

/**
 * Validates the variable constraints for the selected service
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.validateVariableConstraints = function() {
  var statusMsg = [];
  var alertMsg = [];

  if (this.variableConstraint != null) {
    var min = this.variableConstraint.min_datafield_count;
    var max = this.variableConstraint.max_datafield_count;
    var eqAttrList = this.variableConstraint.equal_datafield_attr;
    var eqAttrs = eqAttrList ? eqAttrList.split(',') : [];
    var eqLabelList = this.variableConstraint.equal_datafield_attr_label;
    var eqLabels = eqLabelList ? eqLabelList.split(',') : [];
    var mandAttrList = this.variableConstraint.has_datafield_attr;
    var mandAttrs = mandAttrList ? mandAttrList.split(',') : [];
    var mandLabelList = this.variableConstraint.has_datafield_attr_label;
    var mandLabels = mandLabelList ? mandLabelList.split(',') : [];
    var mandValueList = this.variableConstraint.has_datafield_attr_value;
    var mandValues = mandValueList ? mandValueList.split(',') : [];
    var mandMsg = this.variableConstraint.has_datafield_attr_msg;

    if (this.selectedVariables.length < min) {
      if (min == max) {
        statusMsg.push('Please select ' + min + ' variable' + (min>1?'s':''));
      } else {
        statusMsg.push('Please select at least ' + min + ' variable' + (min>1?'s':''));
      }
    } else if (this.selectedVariables.length > max) {
      var str = 'Maximum variables allowed for this service is ' + max;
      statusMsg.push(str);
      alertMsg.push(str);
    }

    if (eqAttrs.length > 0 && this.selectedVariables.length > 1) {
      var showedComparisonMsg = false;
      var showedUnitsMsg = false;
      for (var j=0; j<eqAttrs.length; j++) {
        var eqAttr = eqAttrs[j];
        var attrValue = this.selectedVariables[0].data[eqAttr];
        var mismatch = false;
        for (var i=1; i<this.selectedVariables.length; i++) {
          if (attrValue instanceof Array) { // if the values are arrays
            var arr1 = attrValue;
            var arr2 = this.selectedVariables[i].data[eqAttr];
            // check if arr1 and arr2 contain the same values 
            if (!giovanni.util.areArraysEqual(arr1, arr2)) { 
              mismatch = true;
            }
          } else if (attrValue !== this.selectedVariables[i].data[eqAttr]) { // if not arrays, check directly for equality
            mismatch = true;
          }
          if (mismatch || this.selectedVariables.length > 1) { // if there is a mismatch...
            var label = eqLabels[j] ? eqLabels[j].toLowerCase() : eqAttr.replace(/([A-Z])/g, " $1").toLowerCase();
            var str = null;
            // check difference comparisons (two variables) for units equality
            if(session.dataSelector.servicePicker.isDifferenceService()){ // and it's a difference service
              var vars = this.selectedVariables;
              var units = vars[0].getUnits() ? vars[0].getUnits() : vars[0].getDefaultUnits();
              for(var v=0;vars && v<vars.length;v++){
                if(units != (vars[i].getUnits() ? vars[i].getUnits() : vars[i].getDefaultUnits() )){
                  // and the variable units are not equal
                  if (!showedComparisonMsg) {
                    str = "Variable units must be the same when a comparison service is selected.";
                    statusMsg.push(str);
                    alertMsg.push(str);
                    showedComparisonMsg = true;
                  }
                  break;
                }
              }
            }
            // if there is a mismatch, report it
            if(mismatch && !showedUnitsMsg){
              str = 'All selected variables should have the same ' + label + '.';
              statusMsg.push(str);
              alertMsg.push(str);
              showedUnitsMsg = true;
            }
            break;
          }
        }
      }
    }

    var serviceInfo = $(giovanni.portal.serviceDataAccessor.services).find('service[name="'+this.service+'"]')[0];

    if (mandAttrs.length > 0 && this.selectedVariables.length > 0 && mandValues.length == 0) {
      var pushErrMsg = false;
      for (var j=0; j<mandAttrs.length; j++) {
        var mandAttr = mandAttrs[j];
        for (var i=0; i<this.selectedVariables.length; i++) {
          if (this.selectedVariables[i].data[mandAttr] == null) {
            //            var str = "'" + this.selectedVariables[i].data.dataFieldLongName +  
            //              "' does not have the required " + mandLabels[j] + " attribute";
            var str = "'" + this.selectedVariables[i].data.dataFieldLongName +  
                "' cannot be used for " + serviceInfo.getAttribute("label") + ' ' + serviceInfo.getAttribute("groupLbl");
            statusMsg.push(str);
            alertMsg.push(str);
            pushErrMsg = true;
          }
        }
      }
      if (pushErrMsg) {
        statusMsg.push(mandMsg);
        alertMsg.push(mandMsg);
      }
    }

    // Check a mandatory value
    if (mandAttrs.length > 0 && this.selectedVariables.length > 0 && mandValues.length > 0 &&
        mandAttrs.length == mandValues.length ) {
      var pushErrMsg = false;
      for (var j=0; j<mandAttrs.length; j++) {
        var mandAttr = mandAttrs[j];
        var mandValue = mandValues[j]; // assumes mandAttrs and mandValues are the SAME LENGTH!
        for (var i=0; i<this.selectedVariables.length; i++) {
          if (this.selectedVariables[i].data[mandAttr] == null) {
            //            var str = "'" + this.selectedVariables[i].data.dataFieldLongName +  
            //              "' does not have the required " + mandLabels[j] + " attribute";
            var str = "'" + this.selectedVariables[i].data.dataFieldLongName +  
                "' cannot be used for " + serviceInfo.getAttribute("label") + ' ' + serviceInfo.getAttribute("groupLbl");
            statusMsg.push(str);
            alertMsg.push(str);
            pushErrMsg = true;
          }else if (this.selectedVariables[i].data[mandAttr].toString() != mandValue) {
            //            var str = "'" + this.selectedVariables[i].data.dataFieldLongName +  
            //              "' does not have the required " + mandLabels[j] + " attribute value ('" + mandValue + "') for this service";
            var str = "'" + this.selectedVariables[i].data.dataFieldLongName +  
                "' cannot be used for " + serviceInfo.getAttribute("label") + ' ' + serviceInfo.getAttribute("groupLbl");
            statusMsg.push(str);
            alertMsg.push(str);
            pushErrMsg = true;
          }
        }
      }
      if (pushErrMsg) {
        statusMsg.push(mandMsg);
        alertMsg.push(mandMsg);
      }
    }
  }

  // check for 3D variables and 'shape' in the URL - TEMPORARY CHECK
  // - should removed when workflows with shape handle slices
  var shapeMsg = this.check3DVarsAndShape();
  if(shapeMsg.length>0) statusMsg = statusMsg.concat(shapeMsg);

  document.getElementById('facetedResultsStatusBar').innerHTML = statusMsg.join("<br/>");
  return statusMsg.join("\n");
};

/*
 * A check to see if 3D variables are being used when shapefiles are selected.
 * This should be a temporary check.  Ultimately, such constraints should all
 * be in a constraints configuration db
 *
 * @this {giovanni.widget.FacetedSelector}
 * @params {}
 * @return {String}
 * @author K. Bryant
 */
giovanni.widget.FacetedSelector.prototype.check3DVarsAndShape = function () {
  var query = session.dataSelector.getValue();
  var msg = new Array();
  if(query!=""){
    // extract to see if there is a 'shape' field
    var isShapePresent = giovanni.util.extractQueryValue(query,'shape') != "" ? true : false;
    if(isShapePresent){
      for(var i=0;i<this.selectedVariables.length;i++){
        if(this.selectedVariables[i].is3DVariable){
          var str = this.selectedVariables[i].data.dataFieldLongName
              + " (" + this.selectedVariables[i].data.dataProductShortName + ")"
              + " has a third dimension"
              + " (" + this.selectedVariables[i].data.dataFieldZDimensionType + ")" 
              + " and cannot be used with shapefiles at this time.";
          msg.push(str);
        }
      }
    }
  }
  return msg;
}

/**
 * Creates the HTML content of the faceted selector
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.render = function()
{
  for (var i=0; i<this.facets.length; i++)
  {
    this.facets[i].render();
  }
};

/**
 * Cancels pending AJAX transactions issued from the FacetedSelector
 * 
 * @this {giovanni.widget.FacetedSelector}
 * @author Chocka Chidambaram
 */
giovanni.widget.FacetedSelector.prototype.cancelActiveTransactions = function() {
  var arrStr = [];
  for (var key in this.activeTransactions) {
    if (this.activeTransactions.hasOwnProperty(key)) {
      this.activeTransactions[key].abort(this, null, null);
    }
  };
  this.activeTransactions = {};
  this.updateCursor();
};

giovanni.widget.FacetedSelector.prototype.scheduleTransaction = function(options) {
  var self = this;
  var transaction = null;
  var wrappedOptions = {};
  // Wrap supplied handlers to handle status changes
  var receiveTransaction = function(transactionId) {
    if (transactionId in self.activeTransactions) delete self.activeTransactions[transactionId];
    self.updateCursor();
  };
  var failureHandler = function(obj) {
    receiveTransaction(obj.tId);
    if ('failure' in options) options.failure.bind(this)(obj);
  };
  var successHandler = function(obj) {
    receiveTransaction(obj.tId);
    if ('success' in options) options.success.bind(this)(obj);
  };
  for (key in options) {
    wrappedOptions[key] = options[key];
  };
  wrappedOptions.success = successHandler;
  wrappedOptions.failure = failureHandler;
  transaction = giovanni.util.getCatalogData(wrappedOptions);
  this.activeTransactions[transaction.tId] = transaction;
  this.updateCursor();
};

/*
 * Handles row selection event.  This is a replacement for the checkbox
 * click event.  This method also filters out events coming from form
 * elements in the row (only <select> for now.  Other form elements would
 * also need to be filtered out at this point (at least in the
 * current event handling scheme).  This method calls handleSelection().
 *
 * @this {giovanni.widget.FacetedSelector}
 * @author K. Bryant
 */
giovanni.widget.FacetedSelector.prototype.handleRowSelect = function (e) {
  // if the mouse event is coming from a <select> don't honor it;
  // we want to handle those separately
  if(e.event.target.nodeName !== "select"){
    var row = this.facetedResultTable.getRecord(e.target);
    var oData = row.getData();
    // get the first TD element of the table
    var firstTD = this.facetedResultTable.getFirstTdEl( row );
    // find input elements in the TD (looking for the variable checkbox)
    var elemArr = firstTD.getElementsByTagName('input');
    // check that there is an HTML collection at this table address
    if (elemArr !== null && elemArr.length > 0){ 
      // get the first element in the collection
      var elem = elemArr[0];
      // is the input element a checkbox (let's hope)?
      // if so, pass it to the handler function so we can select the row
      if (elem.type === 'checkbox') {
        if (elem.checked === true) {
          elem.checked = false;
        } else {
          elem.checked = true;
        }
        var params = [[oData.addCheckBox], false, elem, row];
        this.handleSelection(e,params);
      }
    }
  }
};
