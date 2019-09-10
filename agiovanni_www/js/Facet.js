//$Id: Facet.js,v 1.25 2015/05/04 14:25:14 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $

giovanni.namespace("widget");

/**
 * Initializes a facet
 * 
 * @constructor
 * @this {giovanni.widget.Facet}
 * @param {String, String, String, Array, Function, Object}
 * @returns {giovanni.widget.Facet}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet = function(containerId, facetInfo, valids, facetChangeCallback, callbackContext)
{
	this.containerId = containerId;
	this.name = facetInfo.name;
	this.label = facetInfo.label;
	this.valids = valids;
	this.facetChangeCallback = facetChangeCallback;
	this.callbackContext = callbackContext;
	this.numOfCols = facetInfo.columns==undefined?1:facetInfo.columns;
//	this.hideInvalid = facetInfo.hideInvalid==undefined?false:facetInfo.hideInvalid;
	this.hiddenValues = [];
	this.DISABLE_MODE = 'HIDE'; // DISABLE or HIDE facets with 0 count
};

giovanni.widget.Facet.prototype.hideValuesWithZeroCount = function() {
  var tmpArr = [];
  this.hiddenValues = [];
  for (var i=0; i<this.valids.length; i=i+2)
  {
    if (this.valids[i+1]==0) { // if the count is 0 in the initial list of valids, hide that value permanently
      this.hiddenValues.push(this.valids[i]);
    } else {
      tmpArr.push(this.valids[i]);
      tmpArr.push(this.valids[i+1]);
    }
  }
  this.valids = tmpArr;
};

/**
 * Creates the facets's HTML content 
 * 
 * @this {giovanni.widget.Facet}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.render = function()
{
  this.hideValuesWithZeroCount();
  if (this.valids.length==0) {
    var container = document.getElementById(this.containerId); 
    container.style.display = 'none';
    container.nextSibling.style.display = 'none';
    return; // 'valids' is empty if all counts are 0 - do not render this facet
  }

  var htmlStr = '<h3 class="collapsible" id="'+this.getCollapsibleHeaderId()+'"><span></span>'+this.label+'</h3>'
	  +'<div class="facetInputs">';
	var col = 0;
	// split valids into tuple array so we can sort valids by hits
	var tuples =[];
	for(var i=0;i<this.valids.length;i=i+2){
            tuples.push([this.valids[i],this.valids[i+1]]);
        }
	tuples.sort(function(a,b) {
            //a = parseInt(a[1]);
            //b = parseInt(b[1]);
            //return b-a;
            return a < b ? -1 : (a > b ? 1 :0);
        });
        
	for (var i=0; i<tuples.length; i++)
	{
		if (col % this.numOfCols == 0) htmlStr += '<div>'; 
		htmlStr += '<input id="'+giovanni.util.formHtmlId(this.name,tuples[i][0])+'" type="checkbox" name="'
				+this.name+'" value="'+tuples[i][0]+'" '
				// enable/disable necessary only after the user selects a facet for search
				//+(this.valids[i+1]<=0?'disabled="disabled"':'')
				+'>'
			+'</input>'
			+'<span id="'+giovanni.util.formHtmlId(this.name,tuples[i][0],'label')+'" class=""'
				// enable/disable necessary only after the user selects a facet for search
				//+(this.valids[i+1]<=0?'style="color:grey"':'')
				+'>'+tuples[i][0].replace('deg.','&deg;')+'</span>'
			+' <span id="'+giovanni.util.formHtmlId(this.name,tuples[i][0],'count')+'">('+tuples[i][1]+')</span>';
		if (col++ % this.numOfCols == this.numOfCols-1) htmlStr += '</div><br/>';
	}
	if(col%this.numOfCols != 0) htmlStr += '</div><br/>';
	htmlStr += '</div>';
	// place holder for displaying selected facet values, when the facet is collapsed
	htmlStr += '<div id="'+this.getCollapsedInfoDivId()+'"></div>';
	document.getElementById(this.containerId).innerHTML = htmlStr;
	for (var i=0; i<tuples.length; i++)
	{
		YAHOO.util.Event.addListener(giovanni.util.formHtmlId(this.name,tuples[i][0]), 'click', this.facetChangeCallback, false, this.callbackContext);
	}
};

/**
 * Shows the selected facet values info in a div below the facet header. 
 * Used when the facet is in a collapsed state. 
 * 
 * @this {giovanni.widget.Facet}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.showCollapsedInfo = function() {
  var values = this.getValue();
  // display tooltip on the header
  var header = $('#'+this.getCollapsibleHeaderId())[0]; //jQuery returns an array of the matched elements - get the first one
  if (header) {
    header.title=values.join(', ');
  }
  // display selected values in the info div
  var infoDiv = $('#'+this.getCollapsedInfoDivId())[0]; //jQuery returns an array of the matched elements - get the first one
  if (values.length>0 && infoDiv) {
    infoDiv.innerHTML = ''; // clear the info div of any old values
    var MAX_ITEMS = 2; // max items to display before showing ellipsis (...)
    var ulElem = document.createElement("ul");
    for (var i=0; i<values.length; i++) {
      var liElem = document.createElement("li");
      liElem.appendChild(document.createTextNode(i<MAX_ITEMS ? values[i] : "..."));
      ulElem.appendChild(liElem);
      if (i>=MAX_ITEMS) break;
    }
    infoDiv.appendChild(ulElem);
  }
};

/**
 * Clears the collapsed info div below the facet header. 
 * Used before a facet moves to the expanded state. 
 * 
 * @this {giovanni.widget.Facet}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.clearCollapsedInfo = function() {
  // clear tooltip on the header
  var header = $('#'+this.getCollapsibleHeaderId())[0]; //jQuery returns an array of the matched elements - get the first one
  if (header) {
    header.title='';
  }
  // clear the info div
  var infoDiv = $('#'+this.getCollapsedInfoDivId())[0]; //jQuery returns an array of the matched elements - get the first one
  if (infoDiv) {
    infoDiv.innerHTML = '';
  }
};

/**
 * Updates the facet's appearance based on user selection
 * 
 * @this {giovanni.widget.Facet}
 * @param {boolean}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.update = function(disableByCount)
{
  var tmpArr = [];
  for (var i=0; i<this.valids.length; i=i+2) {
    if (giovanni.util.contains(this.hiddenValues, this.valids[i])) {
      continue;
    } else {
      tmpArr.push(this.valids[i]);
      tmpArr.push(this.valids[i+1]);
    }
  }
  this.valids = tmpArr;
  if (this.valids.length==0) {
    return; // if the list of valids after eliminating hidden values is empty, this facet is already hidden, nothing to update
  }

  var first = document.getElementById(giovanni.util.formHtmlId(this.name,this.valids[0]));
  var facContainer = first.parentNode.parentNode.parentNode;

  var hideFacet = true;

  // split valids into tuple array so we can sort valids by hits
  var tuples = [];
  for(var i=0;i<this.valids.length;i=i+2){
      tuples.push([this.valids[i],this.valids[i+1]]);
  }
  tuples.sort(function(a,b) {
      a = parseInt(a[1]);
      b = parseInt(b[1]);
      //return a < b ? -1 : (a > b ? 1 :0);
      return b-a;
  });

  for (var i=0; i<tuples.length; i++)
	{
		var cur = document.getElementById(giovanni.util.formHtmlId(this.name,tuples[i][0]));
		var cur_label = document.getElementById(giovanni.util.formHtmlId(this.name,tuples[i][0],'label'));
		var cur_count = document.getElementById(giovanni.util.formHtmlId(this.name,tuples[i][0],'count'));
		
		if (tuples[i][1]>0 || cur.checked)
		{
			cur.removeAttribute('disabled');
			cur_label.style.color = '';
			cur_count.innerHTML = '('+tuples[i][1]+')';
			cur_count.style.color = '';
			var parent = cur.parentNode;
			if (parent.getElementsByTagName('input').length==1) { // only 1 facet per div - so show the div and the line break following that
				parent.style.display = 'inline-block';
				parent.nextSibling.style.display = 'inline';
			} else { // more facets in the same line - show just this facet's information
				cur.style.display = 'inline';
				cur_label.style.display = 'inline';
				cur_count.style.display = 'inline';
			}
			// show the facet group - in case it was hidden already
			hideFacet = false;
			facContainer.style.display = 'inline-block';
			facContainer.nextSibling.style.display = 'inline';
		} else if (disableByCount) {
			cur_count.innerHTML = '('+tuples[i][1]+')';
			if (this.DISABLE_MODE == 'DISABLE') {
				cur.setAttribute("disabled", "disabled");
				cur_label.style.color = 'grey';
				cur_count.style.color = 'grey';
			} else if (this.DISABLE_MODE == 'HIDE') {
				var parent = cur.parentNode;
				if (parent.getElementsByTagName('input').length==1) { // only 1 facet per div - so hide the div and the line break following that
					parent.style.display = 'none';
					parent.nextSibling.style.display = 'none';
				} else { // more facets in the same line - hide just this facet's information
					cur.style.display = 'none';
					cur_label.style.display = 'none';
					cur_count.style.display = 'none';
				}
			}
		}
	}
  if (hideFacet && this.DISABLE_MODE == 'HIDE') {
    // hide the facet group
    facContainer.style.display = 'none';
    facContainer.nextSibling.style.display = 'none';
  }
};

/**
 * Returns the value of the items selected in this facet
 * 
 * @this {giovanni.widget.Facet}
 * @returns {Array}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.getValue = function()
{
	var values=[];
	var index=0;
	for (var i=0; i<this.valids.length; i=i+2)
	{
		var element = document.getElementById(giovanni.util.formHtmlId(this.name,this.valids[i]));
		if (element.checked === true)
		{
			values[index++]=this.valids[i];
		}
	}
	return values;
};

/**
 * Sets the facet's selections based on the passed in values  
 * 
 * @this {giovanni.widget.Facet}
 * @param {Array}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.setValue = function(values)
{
	for (var i=0; i<this.valids.length; i=i+2)
	{
		var element = document.getElementById(giovanni.util.formHtmlId(this.name,this.valids[i]));
		if (giovanni.util.contains(values, this.valids[i]))
		{
			element.checked = true;
		} else {
			element.checked = false; 
		}
	}
	// refresh the collapsed state info, if applicable, to reflect the new value
  var locator = '#'+this.getCollapsibleHeaderId();
  if ($(locator).collapsible('collapsed')) {
    this.clearCollapsedInfo();
    this.showCollapsedInfo();
  }
};

/**
 * Returns the ID of the header element displaying this facet's label
 * which can be collapsed/opened  
 * 
 * @this {giovanni.widget.Facet}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.getCollapsibleHeaderId = function() {
  return this.containerId+'_c';
};

/**
 * Returns the ID of the div element that will display the facet's collapsed 
 * state information  
 * 
 * @this {giovanni.widget.Facet}
 * @returns {String}
 * @author Chocka Chidambaram
 */
giovanni.widget.Facet.prototype.getCollapsedInfoDivId = function() {
  return this.containerId+'_c_i';
};

