//$Id: SeasonalDatePicker.js,v 1.28 2015/02/03 19:02:55 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $

/*
 * Create the datepicker object to represent date and time
 */

giovanni.namespace("widget");

/**
 * Constructs the seasonal data picker class.  Takes an
 * HTML container element id, a data source URL string and
 * a configuration Object.
 * 
 * @constructor
 * @this {giovanni.widget.SeasonalDatePicker}
 * @param {String, String, Configuration}
 * @returns {giovanni.widget.SeasonalDatePicker}
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker=function(containerId,url,config,parentClass)
{
	//Get the ID of the container element
	this.container=document.getElementById(containerId);
	if (this.container==null){
		this.setStatus("Error [giovanni.widget.DatePicker]: element '"+containerId+"' not found!");
		return;
	}
	this.id = containerId;
	//Store the container's ID
	this.containerId=containerId;

	//Get the data source URL
	this.dataSourceUrl = url;
	if (this.dataSourceUrl==null){
		alert("Error [giovanni.widget.DatePicker]: data source URL is null");
		return;
	}

        this.parentClass = parentClass;
	
	this.minBound = new Date('01/01/1970');
	this.maxBound = new Date();
  
	this.defaultMinBound = new Date('01/01/1970');
	this.defaultMaxBound = new Date();
	//Define an object for holding configuration 
	if (config===undefined){
		config={};
	}

	if(config.range === undefined){
	    config.range = true;
	}
	
	if(config.minBound !== undefined){
	    if (!this.minBound.parse(config.minBound)){
	        this.minBound = new Date('01/01/1970');
	        alert("Could not load date bounds : " + config.minBound);
	    }
	    else {
		// Keeps a default min bound for when the min bound is made null by a data accessor response
		// (usually by removing all of the variables).  This allows us to set a configured default
		// min bound at construction and keep it even in the absense of data
		this.defaultMinBound = this.minBound;
	    }
	}
	if(config.maxBound !== undefined){
	    if (!this.maxBound.parse(config.maxBound)){
	        this.maxBound = new Date();
	        alert("Could not load date bounds : " + config.maxBound);
	    }
	    else{
		this.defaultMaxBound = this.maxBound;
	    }
	}

	if(config.interval === undefined){
	    config.interval = 900000;  // 15 minutes * 60000 milliseconds per minute = 
	}
	if(config.type === undefined){
	    config.type = "DateTime";
	}
	if(config.maxRange === undefined){
	    config.maxRange = 0;
	}
	if(config.minRange === undefined){
	    config.minRange = 0;
	}

	this.seasonsSelector = undefined;
        this.monthsSelector = undefined;
        this.yearRangeSelector = undefined;
        
        this.selectionEvent=new YAHOO.util.CustomEvent("SeasonalSelectionEvent",this);

	this.startDate = null;
	this.endDate = null;
	this.range = config.range;
	this.interval = config.interval;
	this.type = config.type;
	this.maxRange = config.maxRange;
        this.minRange = config.minRange;
	this.statusStr = "";
	this.disabled = false;
	// default value, used when user has not entered anything
	this.defaultStartDateStr = "";
	this.defaultEndDateStr = "";
        this.defaultSeasons = "";
        this.defaultMonths = "";
	// values loaded from a bookmarked URL
	this.urlStartDateStr = "";
	this.urlEndDateStr = "";
        this.urlSeasons = "";
        this.urlMonths = "";
	// calendar min/max bound date string
	this.calMinBound = this.minBound.toISO8601DateString();
	this.calMaxBound = this.maxBound.toISO8601DateString();
	// panel that shows month and season selction lists
	this.panel = null;
	// panel body
	this.panelBody = null;
	// whether the mouse is hovering over the control or not
	//this.inControl = false;
	this.render();
};

/**
 * Creates the GUI for giovanni.widget.DatePicker and registers the component
 * 
 * @this {Giovanni.widget.SeasonalDatePicker}
 * @params {}
 * @return void
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.render = function(){

    // create usage hint
    var hint = document.createElement('div');
    hint.setAttribute('id','datePickerHint');
    hint.setAttribute('class','hint');
    //hint.innerHTML = "Enter date(s) as YYYY-MM-DD or use calendars.";
    hint.innerHTML = "Month or Season and YYYY range.";
    this.container.appendChild(hint);

    /* 
     * New rendering for seasonal picker
     */
    //var seasonalContainer = document.createElement('div');
    //seasonalContainer.setAttribute('id','seasonalUmbrellaContainer');
    //seasonalContainer.setAttribute('class','seasonalUmbrellaContainer');


    var textEntryContainer = document.createElement('div');
    textEntryContainer.setAttribute('id','seasonalTextEntryContainer');
    textEntryContainer.setAttribute('class','seasonalDateContainer seasonalTextEntryContainer');
    var seasonalTextEntry = document.createElement('input');
    seasonalTextEntry.setAttribute('id','seasonalTextEntry');
    seasonalTextEntry.setAttribute('class','textFieldInput');
    seasonalTextEntry.setAttribute('size','32');
    seasonalTextEntry.setAttribute('value','example');
    //seasonalTextEntry.setAttribute('tabindex','1');
    textEntryContainer.appendChild(seasonalTextEntry);
    //seasonalContainer.appendChild(textEntryContainer);

    var calendarLink = document.createElement('a');
    calendarLink.setAttribute('title','Select seasons or months');
    calendarLink.setAttribute('id','seasonCalendarLink');
    calendarLink.innerHTML = "<img id='seasonCalendarButton' alt='Select seasons or months' src='./img/yui_calbtn.gif'/>";
    textEntryContainer.appendChild(calendarLink);

    //this.container.appendChild(seasonalContainer);
    this.container.appendChild(textEntryContainer);


    var yearRangeContainer = document.createElement('div');
    yearRangeContainer.setAttribute('id','yearRangeContainer');
    //yearRangeContainer.setAttribute('class','');
    this.container.appendChild(yearRangeContainer);

    var seasonalPanelContainer = document.createElement('div');
    seasonalPanelContainer.setAttribute('id','seasonalPanel');
    this.container.appendChild(seasonalPanelContainer);
    this.buildPanel();

    var minYear = this.calMinBound.split("-")[0];
    var maxYear = this.calMaxBound.split("-")[0];
    this.yearRangeSelector = new giovanni.widget.SeasonalDatePicker.YearRangeSelector(this,yearRangeContainer,minYear,maxYear);

    // handle mouse entry
    //YAHOO.util.Event.addListener(textEntryContainer,'mouseenter',this.panel.show,{'inPanel':false},this.panel);
    YAHOO.util.Event.addListener('seasonalTextEntryContainer','mouseenter',this.setInControl,{},this);
    // handle mouse motion
    //YAHOO.util.Event.addListener(textEntryContainer,'mousemove',this.panel.show,{'inPanel':false},this.panel);
    YAHOO.util.Event.addListener('seasonalTextEntryContainer','mousemove',this.show,{},this);
    // handle mouse exit
    //YAHOO.util.Event.addListener(textEntryContainer,'mouseleave',this.panel.startHideCheck,{},this.panel);
    YAHOO.util.Event.addListener('seasonalTextEntryContainer','mouseleave',this.hidePanel,{},this);
    // handle focus in
    //YAHOO.util.Event.addListener('seasonalTextEntryContainer','focusin',this.show,{'inControl':true},this);
    YAHOO.util.Event.addListener('seasonalTextEntry','focusin',this.show,{'inControl':true},this);
    // handle blur (focus out)
    //YAHOO.util.Event.addListener(textEntryContainer,'focusout',this.panel.startHideCheck,{},this.panel);
    //YAHOO.util.Event.addListener('seasonalTextEntryContainer','focusout',this.hidePanel,{},this);
    YAHOO.util.Event.addListener('seasonalTextEntry','focusout',this.hidePanel,{},this);
    //YAHOO.util.Event.addListener(calendarLink,'click',this.togglePanel,{},this);
    YAHOO.util.Event.addListener('seasonalTextEntry','change',this.syncWithSelectionList,{},this);

    /* end seasonal rendering */

};

giovanni.widget.SeasonalDatePicker.prototype.setInControl = function (e,o) {
  document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer dateContainerFocus');
  //this.inControl = true;
  this.monthsSelector.setInControl();
  if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
}
giovanni.widget.SeasonalDatePicker.prototype.isInControl = function (e,o) {
  return this.monthsSelector.isInControl();
}
giovanni.widget.SeasonalDatePicker.prototype.show = function (e,o) {
  document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer dateContainerFocus');
  if(o!=null&&o.inControl) this.monthsSelector.inControl = o.inControl;
  this.showTimeout = window.setTimeout(
    function (x) {
      return function () {
        if(x.monthsSelector.isInControl() && !x.panel.isVisible()){
          x.panel.show(undefined,{'inPanel':false});
        }
      };
    }(this),
  100 );
  if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
  giovanni.util.panelOpenEvent.fire(this);
}
giovanni.widget.SeasonalDatePicker.prototype.hidePanel = function (e,o) {
  this.monthsSelector.inControl = false;
  document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer');
  this.panel.startHideCheck(undefined,{'inPanel':false});
  if(e!=undefined) YAHOO.util.Event.stopPropagation(e);

/*
  window.setTimeout(
    function (x) {
      return function () {
          document.getElementById('seasonalTextEntryContainer').setAttribute('class','dateContainer');
          x.panel.startHideCheck(undefined,{'inPanel':false});
      };
    }(this),
  100 );
*/
}

/**
 * Show/hide the season/months selection panel
 *
 * @this {giovanni.widget.SeasonalDatePicker}
 * @params {YAHOO.util.Event,Object}
 * @return void
 * @author K. Bryant
 **/
giovanni.widget.SeasonalDatePicker.prototype.togglePanel = function (e,o) {
    // create the panel if we need to
    if(!this.panel){
        var panelContents = this.buildPanel();
    }
    // show or hid the panel as appropriate
    if(this.panel.isVisible()){
        this.panel.hide();
    }else{
        this.panel.show();
    }
}

giovanni.widget.SeasonalDatePicker.prototype.syncWithSelectionList = function (e,o) {
    var vObj = this.validateTextEntry();
    if(vObj.valid){
        // get the values entered into the text field (returned by validateTextEntry())
        var values = document.getElementById('seasonalTextEntry').value.split(",");
        // grab the list of the currently enabled selector (months or seasons)
        var list = this.monthsSelector.getDisabled() ? this.seasonsSelector.seasons : this.monthsSelector.months;
        // grab the enabled seletor (months or seasons)
        var selector = this.monthsSelector.getDisabled() ? this.seasonsSelector : this.monthsSelector;
        // clear the list
        selector.clear();
        // set checkboxes according to text entry values
        for(var i=0;i<values.length;i++){
            for(var key in list){
                if(values[i].trim() == list[key]){
                    document.getElementById(list[key]+"Sel").checked = true;
                    break;
                }
            }
        }
        var pickerValue = this.validate();
        //if(pickerValue.valid) this.parentClass.fire();
        this.parentClass.fire();
    }   
}

giovanni.widget.SeasonalDatePicker.prototype.validateTextEntry = function () {
    var list = this.monthsSelector.getDisabled() ? this.seasonsSelector.seasons : this.monthsSelector.months;
    var text = document.getElementById('seasonalTextEntry').value;
    this.setTextAsError('seasonalTextEntry',false);
    var msg = "";
    var isError = false;
    //if(text==""){
    //  msg = "Please select a season or month";
    //  this.setStatus(msg,isError);
    //}else{
      var tA = text.split(",");
      var validKeyword = false;
      var inValidKeywords = new Array();
      for(var i=0;i<tA.length;i++){
        if(tA[i]!=""){
          validKeyword = false;
          for(var key in list){
            if(list[key] == tA[i].trim()){
                validKeyword = true;
                break;
            }
          }
          if(!validKeyword) inValidKeywords.push(tA[i]);
        }
      }
      if( inValidKeywords.length>0 ){
        msg += inValidKeywords.join(",");
        isError = true;
        this.setStatus("Invalid search term(s): " + msg,isError);
        this.setTextAsError('seasonalTextEntry',true);
      }else{
        this.setStatus("",false);
      }
    //}
    return new giovanni.widget.ValidationResponse(!isError,msg);
}

/**
 * Build the selection panel HTML and add appropriate listeners
 * 
 * @this {giovanni.widget.SeasonalDatePicker}
 * @params {}
 * @return void
 * @author K. Bryant
 **/
giovanni.widget.SeasonalDatePicker.prototype.buildPanel = function () {

    var panelBody = document.createElement('div');
    panelBody.setAttribute('id','seaonalPanelBody');

    var radioContainer = document.createElement('div');
    radioContainer.setAttribute('id','seasonalRadioControls');
    radioContainer.setAttribute('class','seasonalRadioControls');
    panelBody.appendChild(radioContainer);

    var togglingListContainer = document.createElement('div');
    togglingListContainer.setAttribute('id','togglingListContainer');
    togglingListContainer.setAttribute('class','togglingListContainer');
    panelBody.appendChild(togglingListContainer);

    var monthsListContainer = document.createElement('div');
    monthsListContainer.setAttribute('id','monthsContainer');
    monthsListContainer.setAttribute('class','checkboxList');
    togglingListContainer.appendChild(monthsListContainer);

    var seasonsListContainer = document.createElement('div');
    seasonsListContainer.setAttribute('id','seasonsContainer');
    seasonsListContainer.setAttribute('class','checkboxList');
    togglingListContainer.appendChild(seasonsListContainer);

        var cfg = {
            'containerId':'seasonalPanel',
            'associateId':'textEntryContainer',
            'headerStr':'Select months or seasons'
        }

        this.panel = new giovanni.ui.Panel(cfg);

        this.panel.addElement(panelBody);

    this.monthsSelector = new giovanni.widget.SeasonalDatePicker.MonthsSelector(this,monthsListContainer);
    this.seasonsSelector = new giovanni.widget.SeasonalDatePicker.SeasonsSelector(this,seasonsListContainer);

    this.seasonsSelector.disable();
    this.monthsSelector.enable();


}

/**
 * Validates startDate and endDate
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {giovanni.widget.ValidationResponse} true or false depending on if the date meets predetermined conditions with an explanation 
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.validate = function(){

    // get the month selector
    var months = this.monthsSelector ? this.monthsSelector.getValue() : null;
    var seasons = this.seasonsSelector ? this.seasonsSelector.getValue() : null;
    var years = this.yearRangeSelector.getValue();
    var startYear = years.split(",")[0];
    var stopYear = years.split(",")[1];
    var valid = true;
    this.setTextAsError(this.yearRangeSelector.getId()+"_startYear",false);
    this.setTextAsError(this.yearRangeSelector.getId()+"_stopYear",false);

    var errStr = "";
    if(!this.monthsSelector.getDisabled() && months==""){
        errStr += "Please select a month.";
        valid = false;
    }else if(!this.seasonsSelector.getDisabled() && seasons==""){ 
        errStr += "Please select a season.";
        valid = false;
    }
/*
    if(startYear==""){
        errStr += (errStr!="") ? "  " : "";
        errStr += "Please enter a beginning year.";
        valid = false;
    }
*/
    // is the stopYear empty?  Complain if so; otherwise, check to see that it's a 
    // valid date year
/*
    if(stopYear==""){
        errStr += (errStr!="") ? "  " : "";
        errStr += "Please enter an ending year.";
        valid = false;
    }
*/
    // is ending year older than beginning year?
    if(startYear!="" && stopYear!="" && valid){
        if(parseInt(startYear) > parseInt(stopYear)){
            errStr += (errStr!="") ? "  " : "";
            errStr += "Ending year must be more recent than beginning year.";
            valid = false;
            this.setTextAsError(this.yearRangeSelector.getId()+"_stopYear",true);
        }
    }
    // check boundary conditions
    //var minYearBound = this.minBound.getFullYear();
    //var maxYearBound = this.maxBound.getFullYear();
    // fetch comparison start and stop months; assumes order of the component checkboxes is preserved
    var compMonths = (!this.monthsSelector.getDisabled()) ? this.monthsSelector.getValue() : this.seasonsSelector.getValue();
    var startMonth = compMonths.split(",")[0];
    var endMonth = "";
    if(compMonths!=""){
        var arr = compMonths.split(",");
        endMonth = arr[arr.length-1];
    }
    // get years for comparison
    var compStartYear = startYear;
    var compStopYear = stopYear;
    // set start month if values are seasons
    if(startMonth.indexOf('DJF')>-1){
        startMonth = "12";
        compStartYear = (parseInt(compStartYear) - 1) + "";
    }else if(startMonth.indexOf('MAM')>-1){
        startMonth = "03";
    }else if(startMonth.indexOf('JJA')>-1){
        startMonth = "06";
    }else if(startMonth.indexOf('SON')>-1){
        startMonth = "09";
    }
    // set end month if values are seasons
    if(endMonth.indexOf('DJF')>-1){
        endMonth = "02";
    }else if(endMonth.indexOf('MAM')>-1){
        endMonth = "05";
    }else if(endMonth.indexOf('JJA')>-1){
        endMonth = "08";
    }else if(endMonth.indexOf('SON')>-1){
        endMonth = "11";
    }
    // create dates from months/seasons and years
    var compStartDate = new Date().parse(compStartYear + "-" + startMonth + "-01");
    var cedStr = compStopYear + "-" + endMonth + "-" + this.yearRangeSelector.getDaysInMonth(compStopYear,endMonth);
    var compEndDate = new Date().parse(cedStr);
    // compare against min and max ranges
    if( compEndDate != "" && compEndDate < this.minBound ){
        errStr += (errStr!="") ? "  " : "";
        errStr += "The end date must be "+this.getDateTimeString(this.minBound)+" or later.";
        valid = false;
    }
    if( compStartDate != "" && compStartDate > this.maxBound ){
        errStr += (errStr!="") ? "  " : "";
        errStr += "The beginning must be "+this.getDateTimeString(this.maxBound)+" or earlier.";
        valid = false;
    }

    // need to check validDateRange!!!! with months for variable
    var vObj = this.validateTextEntry();
    if(!vObj.valid) valid = false;
    if(vObj.msg.length>0) errStr += " Invalid season or month: " + vObj.msg;

    // check valid year selections
    if(this.yearRangeSelector){ 
      vObj = this.yearRangeSelector.validate();
      if(!vObj.valid) valid = false;
      if(vObj.msg.length>0) errStr += " " + vObj.msg;
    }

    // show the status
    this.setStatus(errStr,!valid);

    // return a response for those interested
    return new giovanni.widget.ValidationResponse(valid,errStr);
 
};

/**
 * Returns the value of the start time and end time
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {String} formatted in ISO8601 date/datetime standard and returned as 'starttime=&endtime='
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.getValue = function(){
    var returnString = "starttime=&endtime=&month=&season=";

    var years = this.yearRangeSelector;
    var months = this.monthsSelector;
    var seasons = this.seasonsSelector;
    var yearsValue = years.getValue();
    var yearsA = yearsValue && yearsValue != "," ? yearsValue.split(",") : [];
    if(yearsA.length == 2 && !months.getDisabled()){
       returnString = "starttime="+years.getValue().split(",")[0]+ "-01-01T00:00:00Z" 
           + "&endtime="+years.getValue().split(",")[1]+ "-12-31T23:59:59Z" 
           + "&months="+months.getValue();
    }else if (yearsA.length == 2 && !seasons.getDisabled()){
       returnString = "starttime="+years.getValue().split(",")[0]  + "-01-01T00:00:00Z"
           + "&endtime="+years.getValue().split(",")[1] + "-12-31T23:59:59Z" 
           + "&seasons="+seasons.getValue();
    }

    /* seasonal query: 
        service=quasi-season&starttime=1998&endtime=2012&month=01,03,04
        service=interannual&starttime=1998&endtime=2012&season=DJF,JJA
    */

    return returnString;
};

/**
 * Sets the selected value of the start time and end time
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {Object} object contains two strings, startDateStr, endDateStr representing the start and end times to set, respectively 
 * @returns {giovanni.widget.ValidationResponse} whether the date validates or not with an explanation;
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.setValue = function(dates) {
  var dateArr = new Array();
  var startYearStr, stopYearStr;
  if (dates.startDateStr !== undefined) {
    dateArr = dates.startDateStr.split("T");
    startYearStr = dateArr[0];
    // try to get just the year
    startYearStr = startYearStr.split("-")[0];
    //this.starttime = startYearStr;
    //this.startDate = this.setStartTime(dates.startDateStr);
  }
  if(dates.endDateStr !== undefined) {
    dateArr = dates.endDateStr.split("T");
    stopYearStr = dateArr[0];
    // try to get just the year
    stopYearStr = stopYearStr.split("-")[0];
    //this.endtime = stopYearStr;
    //this.endDate = this.setEndTime(dates.endDateStr);
  }
  this.yearRangeSelector.setValue(startYearStr,stopYearStr);
  // set months - undefined indicates the mode is 'seasons'
  this.monthsSelector.setValue(dates.months);
  // set seasons - undefined indicates the mode is 'months'
  this.seasonsSelector.setValue(dates.seasons);
  // validate the incoming values
  var valResp = this.validate();
  // if the incoming values are valid, set the selectors accordingly
  // and fire update event
  if (valResp.isValid()) {
    // !! don't change the default value !!
    // this.defaultStartDateStr = dates.startDateStr;
    // if(this.range === true && dates.endDateStr !== undefined){
    // this.defaultEndDateStr = dates.endDateStr;
    // }
    //this.monthsSelector.setValue(this.months);
    //this.seasonsSelector.setValue(this.seasons);
    //this.yearRangeSelector.setValue(startYearStr,stopYearStr);
    //this.fire();
    this.parentClass.fire();
    this.selectionEvent.fire();
  }
  return valResp;
};

giovanni.widget.SeasonalDatePicker.prototype.setTextValue = function (str) {
    document.getElementById('seasonalTextEntry').value = str;
    this.validate();
}

/**
 * Sets the picker value back to it's initialization values
 *
 * @this (giovanni.widget.DatePicker}
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.prototype.clearSelections = function () {
    this.monthsSelector.clear();
    this.seasonsSelector.clear();
    this.yearRangeSelector.clear();
};

/**
 * Sets the picker value back to it's initialization values
 *
 * @this (giovanni.widget.DatePicker}
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.prototype.resetSelections = function () {
  // if a URL was loaded, reload that value upon reset
  // if not, load the default value for the giovanni page
  var start = this.urlStartDateStr ? this.urlStartDateStr : this.defaultStartDateStr;
  var end = this.urlEndDateStr ? this.urlEndDateStr : this.defaultEndDateStr;
  var seasons = this.urlSeasons ? this.urlSeasons : this.defaultSeasons;
  var months = this.urlMonths ? this.urlMonths : this.defaultMonths;
	this.setValue({
            'startDateStr':start,
            'endDateStr':end,
            'seasons':seasons,
            'months':months
        });
	//this.useHours = false;
	//this.setHours('startHours','00');
	//this.setHours('endHours','23');
};

/**
 * sets dates given a query string
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String} qs is in the format of starttime=&endtime= 
 * @returns {giovanni.widget.ValidationResponse} whether dates validate or not with an explanation
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.loadFromQuery = function(qs){
    var startDate = giovanni.util.extractQueryValue(qs,"starttime");
    var endDate = giovanni.util.extractQueryValue(qs,"endtime");
    var months = giovanni.util.extractQueryValue(qs,"months");
    var seasons = giovanni.util.extractQueryValue(qs,"seasons");
    this.setValue({
        "startDateStr":startDate,
        "endDateStr":endDate,
        "months":months,
        "seasons":seasons
    },true);
    this.urlStartDateStr = startDate;
    this.urlEndDateStr = endDate;
    this.urlMonths = months;
    this.urlSeasons = seasons;
    // set the month/season selector states
    if(months==""&&seasons!=""){
        this.monthsSelector.disable();
        this.seasonsSelector.enable();
    }else if(months!=""&&seasons==""){
        this.seasonsSelector.disable();
        this.monthsSelector.enable();
    }else{
        this.seasonsSelector.disable();
        this.monthsSelector.enable();
    }
/*
    var startDate = "";
    var endDate = "";
    startDate = giovanni.util.extractQueryValue(qs,"starttime");
    if (this.range === true && giovanni.util.extractQueryValue(qs,"endtime") !== "") {
        endDate  = giovanni.util.extractQueryValue(qs,"endtime");
    }
    this.setValue({"startDateStr":startDate,"endDateStr":endDate});
    
    this.urlStartDateStr = startDate;
    this.urlEndDateStr = endDate;
*/

    //this.validate();

};

/**
 * Updates the component bounds based on dependencies in the registry
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String} specifies additional parameters for the data source url to be fetched from in format starttime=&endtime= 
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.updateComponent = function(qs){
    if (typeof this.dataSourceUrl == "function") {
      this.dataSourceUrl(this, qs);
    } else if (typeof this.dataSourceUrl == "string") {
      var dataSourceUrl = this.dataSourceUrl + "?" + qs;
      this.setStatus("Updating date range based on data changes ... ",true);
  
      YAHOO.util.Connect.asyncRequest('GET', dataSourceUrl,
      { 
        success:giovanni.widget.SeasonalDatePicker.fetchDataSuccessHandler,
        failure:giovanni.widget.SeasonalDatePicker.fetchDataFailureHandler,
        argument: {self:this,format:"xml"}
      } );
    }
};

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 * -- FOR NOW, handle multiple date ranges as UNION (regardless of service)
 *      
 * @this {Giovanni.widget.DatePicker}
 * @param {String, String} contains the minBound and the maxBound
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.setBounds = function(minBound,maxBound){

    //var minValid = minBound ? new Date().parse(minBound[0]) : false ;
    //var maxValid = maxBound ? new Date().parse(maxBound[0]) : false ;

    var curMinDate = undefined;
    var curMaxDate = undefined;
    // if min bounds is an array
    if(minBound && minBound instanceof Array){
      curMinDate = minBound[0];
      for(var i=0;i<minBound.length;i++){
        if(minBound[i]<curMinDate){
          curMinDate=minBound[i];
        }
      }
    }
    // if max bounds is an array
    if(maxBound && maxBound instanceof Array){
      curMaxDate = maxBound[0];
      for(var i=0;i<maxBound.length;i++){
        if(maxBound[i]>curMaxDate){
          curMaxDate=maxBound[i];
        }
      }
    }

    this.minBound = curMinDate ? new Date(curMinDate) : this.defaultMinBound;
    this.maxBound = curMaxDate ? new Date(curMaxDate) : this.defaultMaxBound;
    this.showValidDateRange();
    this.yearRangeSelector.setBounds(this.minBound,this.maxBound);
    // find out if this creates a problem for the current user-selected start/stop dates
    this.validate();
};

/** Shows the valid date range given the min/max bounds
 *
 * @this {Giovanni.widget.DatePicker}
 * @author Chocka/K. Bryant
 */
giovanni.widget.SeasonalDatePicker.prototype.showValidDateRange = function () {
  document.getElementById("dateRangeDisplay").innerHTML = (this.minBound==null?"":" Valid Range: "+(this.minBound.toISO8601DateTimeString().split('T')[0]+' to ')) +
                (this.maxBound==null?"":this.maxBound.toISO8601DateTimeString().split('T')[0]);
};

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.Connect}
 * @param {YAHOO Response Object} contains responseText and responseXML from remote request, and specified arguments
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.fetchDataSuccessHandler = function(o){
    var self=o.argument["self"];
    try {
        var startDates = null;
    	var endDates = null;
    	if(o.argument.format === "json") {
    	  var jsonData=YAHOO.lang.JSON.parse(o.responseText);
    	  startDates = (jsonData.startDate !== undefined)? jsonData.startDate:self.minBound;
    	  endDates = (jsonData.endDate !== undefined)? jsonData.endDate:self.maxBound;
    	} else {
    	  var xmlData = o.responseXML;
    	  var dateRange = xmlData.getElementsByTagName('dateRange')[0]; 
    	  startDates = (dateRange.attributes.getNamedItem("STARTDATE"))? dateRange.attributes.getNamedItem("STARTDATE").value : self.minBound;
    	  endDates = (dateRange.attributes.getNamedItem("ENDDATE"))? dateRange.attributes.getNamedItem("ENDDATE").value : self.maxBound; 
    	}
   
	// take the first element of the array for now....later there will be a constraint 
	// that indicates whether the picker should figure a union or intersection of date ranges
	// based on the service and/or variable selection....perhaps this will all be figured out
	// in data_accessor.js which will return a simple pair of dates instead of a pair of arrays 
    	self.setBounds(startDates,endDates);
    }
    catch(x)
    {
      alert("Failed to load dates: " + x.message);
    }
};

/**
 * Handles the failure of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.connect}
 * @param {YAHOO Response Object} contains reason for the failure
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.fetchDataFailureHandler = function(o){
    alert("Could not retrieve data from specified data URL!");
};

/**
 * Set the current status of the component
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String, Boolean} the status string and whether it is an error or not 
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.setStatus = function(msg,isError){
    this.statusStr = msg;
    var statusDiv = document.getElementById('datePickerStatus');
    statusDiv.style.color = (isError === true)? "red":"green";
    statusDiv.innerHTML = "" + msg + "&nbsp;";
};

/**
 * Fetches the current status of the component
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {String} the status string
 * @author K. Bryant 
 */
giovanni.widget.SeasonalDatePicker.prototype.getStatus = function(){
    return this.statusStr;
};

/*
 * If any of the calendars are displayed, hide them; used when switching back to the date range selector
 *
 * @this {giovanni.widget.DatePicker}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.prototype.hide = function () {
  this.yearRangeSelector.hide();
  //if(this.yearRangeSelector.startCal != undefined ){
  //    this.yearRangeSelector.showStartCalendar(null,this.yearRangeSelector);
  //}
  //if(this.yearRangeSelector.stopCal != undefined){
  //    this.yearRangeSelector.showStopCalendar(null,this.yearRangeSelector);
  //}
};

giovanni.widget.SeasonalDatePicker.prototype.setDisabled = function (disabled) {
    this.disabled = disabled;
    if(disabled){
      this.container.style.display = 'none';
    }else{
      this.container.style.display = 'inline-block';
    }
    this.hide(); 
}

/* enable months seletor; disable seasons selector */
giovanni.widget.SeasonalDatePicker.prototype.handleSelectionAsMonths = function (e,o) {
    YAHOO.util.Event.stopPropagation(e);
    this.seasonsSelector.disable();
    this.monthsSelector.enable();
    if(this.monthsSelector.getValue()!=""){
        this.setValue(
            {
                "startDateStr":this.yearRangeSelector.getValue().split(",")[0],
                "endDateStr":this.yearRangeSelector.getValue().split(",")[1],
                "months":this.monthsSelector.getValue(),
                "seasons":this.seasonsSelector.getValue()
            }
        );
    }
}

/* enable seasons selector; disable months selector */
giovanni.widget.SeasonalDatePicker.prototype.handleSelectionAsSeasons = function (e,o) {
    YAHOO.util.Event.stopPropagation(e);
    this.monthsSelector.disable();
    this.seasonsSelector.enable();
    if(this.seasonsSelector.getValue()!=""){
        this.setValue(
            {
                "startDateStr":this.yearRangeSelector.getValue().split(",")[0],
                "endDateStr":this.yearRangeSelector.getValue().split(",")[1],
                "months":this.monthsSelector.getValue(),
                "seasons":this.seasonsSelector.getValue()
            }
        );
    }
}

giovanni.widget.SeasonalDatePicker.prototype.updateValues = function () {
    var seasons = this.seasonsSelector.getValue();
    var months = this.monthsSelector.getValue();
    var dates = {
        "months":months,
        "seasons":seasons,
        "starttime":this.yearRangeSelector.startYear,
        "endtime":this.yearRangeSelector.stopYear
    };
    this.parentClass.setValue(dates);
}

giovanni.widget.SeasonalDatePicker.prototype.setTextAsError = function (id,err) {
    var textInput = document.getElementById(id);
    if(textInput){
      if(err){
         textInput.style.color = "red";
         textInput.style.fontWeight = "bold";
      }else{ 
         textInput.style.color = "black";
         textInput.style.fontWeight = "normal";
      }
    }
}


/**
 * Month selector constructor 
 * 
 * @this {giovanni.widget.SeasonalDatePicker.MonthsSelector}
 * @params {giovanni.widget.SeasonalDatePicker,HTML element, Object}
 * @return {giovanni.widget.SeasonalDatePicker.MonthsSelector}
 * @ K. Bryant
 */
giovanni.widget.SeasonalDatePicker.MonthsSelector = function (picker,container,config) {
    this.picker = picker;
    this.container = container;
    this.config = config;
    this.monthRadio = undefined;
    this.listContainer = undefined;
    this.disabled = false;
    this.defaultMonth = '01';
    this.currentValue = "January";
    this.inControl = false;
    this.months = {
	'01':'January',
	'02':'February',
	'03':'March',
	'04':'April',
	'05':'May',
	'06':'June',
	'07':'July',
	'08':'August',
	'09':'September',
	'10':'October',
	'11':'November',
	'12':'December'
    };
    this.render();
};

/**
 * Renders the month selector component 
 *
 * @this {giovanni.widget.SeasonalDatePicker.MonthsSelector}
 * @params {}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.render = function () {
    // build the month radio button (seasonal selector has one as well)
    this.monthRadio = document.createElement('input');
    this.monthRadio.setAttribute('type','radio');
    this.monthRadio.setAttribute('name','seasonalMode');
    this.monthRadio.setAttribute('id','seasonalModeMonth');
    this.monthRadio.setAttribute('title','Select Months');
    this.monthRadio.setAttribute('class','seasonalMode');
    this.monthRadio.setAttribute('checked',true);
    this.monthRadio.setAttribute('tabIndex','-1');
    // add the control to the radio controls container
    document.getElementById('seasonalRadioControls').appendChild(this.monthRadio);
    // create the label for the radio control
    var label = document.createElement('span');
    label.innerHTML = 'Months';
    // add the label to the radio controls container
    document.getElementById('seasonalRadioControls').appendChild(label);
    YAHOO.util.Event.addListener('seasonalModeMonth',"click",this.picker.handleSelectionAsMonths,{},this.picker);
    // build and add the month selector component
    this.listContainer = document.createElement('div');
    this.listContainer.setAttribute('id','monthsListContainer');
    this.listContainer.setAttribute('class','listContainer listContainerVisible');

    var col1 = document.createElement('div');
    col1.setAttribute('class','column');
    var col2 = document.createElement('div');
    col2.setAttribute('class','column');
    this.listContainer.appendChild(col1);
    this.listContainer.appendChild(col2);

    // sort the month keys
    var monthKeys = [];
    for(var key in this.months){
        monthKeys.push(key);
    }
    monthKeys.sort(function(a,b){ return parseInt(a) - parseInt(b); });
    var count = 0; 
    // for each key in the months array, create a checkbox
    for( var i=0;i<monthKeys.length;i++ ){
        var cb = document.createElement('input');
        cb.setAttribute('type','checkbox');
        cb.setAttribute('id', this.months[monthKeys[i]]+'Sel');
        cb.setAttribute('name','monthsSel');
        cb.setAttribute('value',monthKeys[i]);
        cb.setAttribute('tabIndex','-1');
        // add a listener for the checkbox
	YAHOO.util.Event.addListener(this.months[monthKeys[i]]+'Sel',"click",this.handleCBClick,{},this);
        var label = document.createElement('span');
        label.innerHTML = "<span id='monthsLabel"+monthKeys[i]+"' class='monthsLabel'>"+this.months[monthKeys[i]]+"</span>";
        // apportion the months to two columns
        if(count<6) {
          col1.appendChild(cb);
          col1.appendChild(label);
          col1.appendChild(document.createElement('br'));
        }else{
          col2.appendChild(cb);
          col2.appendChild(label);
          col2.appendChild(document.createElement('br'));
        }
        count++;
    }
    this.container.appendChild(this.listContainer);
};

/**
 * Given a click on a months checkbox, gather all of the checked values and set them
 * in the seasonTextEntry input field
 *
 * @this {giovanni.widget.SeasonalDatePicker.MonthsSelector)}
 * @params (YAHOO.util.Event, Object}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.handleCBClick = function (e,o) {
    if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
    var str = "";
    for( var key in this.months ){
        cb = document.getElementById(this.months[key] + 'Sel');
        str += cb.checked ? this.months[cb.value] + "," : "";
    }
    if(str.length>0) str = str.substring(0,str.length-1);
    this.picker.setTextValue(str);

    this.picker.parentClass.fire();
}

/* 
 * Sets the value of the whole component (handles multi-value).
 * Assumes incoming month values are numerical strings (e.g, '01' == January)
*/
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.setValue = function (valStr) {
    var vals = valStr.split(",");
    // clear current values
    this.clear();
    // parse incoming values and set checkboxes accordingly
    for(var i=0;i<vals.length;i++){
        for(var key in this.months){
	    if(vals[i]==key){
	        document.getElementById(this.months[key]+'Sel').checked = true;
	    }
        }
    }
};

/* Returns the value of any checked month in a concatenated string (CSV) */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.getValue = function () {
    var checkboxes = document.getElementsByName('monthsSel');
    var valStr = "";
    for(var i=0;i<checkboxes.length;i++){
        if(checkboxes[i].checked){
            valStr += checkboxes[i].value + ",";
        }
    }
    valStr = valStr.substring(0,valStr.length-1);
    return valStr;
};

/* Returns the label of any checked month in a concatenated string (CSV) */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.getLabelValue = function () {
    var checkboxes = document.getElementsByName('monthsSel');
    var valStr = "";
    for(var i=0;i<checkboxes.length;i++){
        if(checkboxes[i].checked){
            valStr += this.months[checkboxes[i].value] + ",";
        }
    }
    valStr = valStr.substring(0,valStr.length-1);
    return valStr;
};

/* clear the selections */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.clear = function () {
    var checkboxes = document.getElementsByName('monthsSel');
    for(var i=0;i<checkboxes.length;i++){
        checkboxes[i].checked = false;
    }
}

/* reset the selections */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.reset = function () {
    this.clear(); // for the moment.....
}

/* disable the selector */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.disable = function () {
    this.disabled = true;
    this.monthRadio.checked = false;
    /* this.listContainer.style.display = 'none'; */
    /* this.listContainer.style.width = ''; */
    this.listContainer.setAttribute('class','listContainer');
    var textInput = document.getElementById('seasonalTextEntry');
    textInput.value = "";
    //this.listContainer.style.border = '1px solid #ccc';
    //var checkboxes = document.getElementsByName('monthsSel');
    //for(var i=0;i<checkboxes.length;i++){
    //    checkboxes[i].disabled = true;
    //    document.getElementById('monthsLabel'+checkboxes[i].value).setAttribute('class','monthsLabelDisabled');
    //}
}

/* enable the selector */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.enable = function () {
    this.disabled = false;
    this.monthRadio.checked = true;
    //this.listContainer.style.display = 'inline-block';
    //this.listContainer.style.visibility = 'visible';
    //this.listContainer.style.width = '10em';
    this.listContainer.setAttribute('class','listContainer listContainerVisible');
    var textInput = document.getElementById('seasonalTextEntry');
    textInput.value = this.getLabelValue();
    //this.listContainer.style.border = '1px solid #bbb';
    //var checkboxes = document.getElementsByName('monthsSel');
    //for(var i=0;i<checkboxes.length;i++){
    //    checkboxes[i].disabled = false;
    //    document.getElementById('monthsLabel'+checkboxes[i].value).setAttribute('class','monthsLabel');
    //}
}

/* Return the state of the selector - disabled or enabled */
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.getDisabled = function () {
    return this.disabled;
}

giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.setInControl = function () {
    this.inControl = true;
}
giovanni.widget.SeasonalDatePicker.MonthsSelector.prototype.isInControl = function () {
    return this.inControl;
}

/* Build season selector */
giovanni.widget.SeasonalDatePicker.SeasonsSelector = function (picker,container,config) {
    this.picker = picker;
    this.container = container;
    this.config = config;
    this.disabled = true;
    this.seasonRadio = undefined;
    this.listContainer = undefined;
    this.defaultSeason = '01';
    this.currentValue = "DJF";
    this.seasons = {
	'01':'DJF',
	'02':'MAM',
	'03':'JJA',
	'04':'SON'
    };
    this.render();
};

/* Renders the seasons selector component */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.render = function () {
    // build the seasonal radio button (month selector has one as well)
    this.seasonRadio = document.createElement('input');
    this.seasonRadio.setAttribute('type','radio');
    this.seasonRadio.setAttribute('name','seasonalMode');
    this.seasonRadio.setAttribute('id','seasonalModeSeasons');
    this.seasonRadio.setAttribute('title','Select Seasons');
    this.seasonRadio.setAttribute('class','seasonalMode');
    this.seasonRadio.setAttribute('checked',false);
    this.seasonRadio.setAttribute('tabIndex','-1');
    // add the season radio button to the radio controls container
    document.getElementById('seasonalRadioControls').appendChild(this.seasonRadio);
    // create the label for the radio button
    var label = document.createElement('span');
    label.innerHTML = 'Seasons';
    // add the label to the radio container
    document.getElementById('seasonalRadioControls').appendChild(label);
    // add a listener for the radio button
    YAHOO.util.Event.addListener('seasonalModeSeasons',"click",this.picker.handleSelectionAsSeasons,{},this.picker);
    // build and add the month selector component
    this.listContainer = document.createElement('div');
    this.listContainer.setAttribute('id','seasonsListContainer');
    this.listContainer.setAttribute('class','listContainer');
    // for each key in the seasons array, create a checkbox 
    for( var key in this.seasons ){
        var cb = document.createElement('input');
        cb.setAttribute('type','checkbox');
        cb.setAttribute('id',this.seasons[key]+'Sel');
        cb.setAttribute('name','seasonsSel');
        cb.setAttribute('value',this.seasons[key]);
        cb.setAttribute('title',this.getTitle(this.seasons[key]));
        cb.setAttribute('tabIndex','-1');
        this.listContainer.appendChild(cb);
	YAHOO.util.Event.addListener(cb,"click",this.handleCBClick,{},this);
        var label = document.createElement('span');
	var title = this.getTitle(this.seasons[key]);
        label.innerHTML = "<span id='seasonsLabel"+this.seasons[key]+"' class='seasonsLabel' title='"+title+"'>"+this.seasons[key]+"</span>";
        this.listContainer.appendChild(label);
        this.listContainer.appendChild(document.createElement('br'));
    }
    // add the container of the controls to the selector container (the popup panel, ultimately)
    this.container.appendChild(this.listContainer);
};

/**
 * Given a click on a months checkbox, gather all of the checked values and set them
 * in the seasonTextEntry input field
 *
 * @this {giovanni.widget.SeasonalDatePicker.SeasonsSeletor)}
 * @params (YAHOO.util.Event, Object}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.handleCBClick = function (e,o) {
    if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
    var str = "";
    var cb = null;
    for( var key in this.seasons ){
        cb = document.getElementById(this.seasons[key] + 'Sel');
        str += cb.checked ? this.seasons[key] + "," : "";
    }
    if(str.length>0) str = str.substring(0,str.length-1);
    this.picker.setTextValue(str);
    
    this.picker.parentClass.fire();

}

giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.getTitle = function (season) {
     var title = "";
     switch (season){
         case "DJF":
             var yearTitle = ".  December is from ";
	     if(this.picker!=null&&this.picker.yearRangeSelector!=undefined&&this.picker.yearRangeSelector.startYear!=""){
	         yearTitle +=
                     (parseInt(this.picker.yearRangeSelector.startYear) - 1)
                     + ", the year prior to the currently selected beginning year ("+this.picker.yearRangeSelector.startYear+")";
             }else{
	         yearTitle += "the year prior to the selected beginning year";
             }
             title = "Average of December-January-February"  + yearTitle;
         break;
         case "MAM":
             title = "Average of March-April-May";
         break;
         case "JJA":
             title = "Average of June-July-August";
         break;
         case "SON":
             title = "Average of September-October-November";
         break;
         default:
     }
     return title;
}

/* Sets the value of the whole component (handles multi-value) */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.setValue = function (valStr) {
    var vals = valStr.split(",");
    // clear current values
    this.clear();
    // parse incoming values and set checkboxes accordingly
    for(var i=0;i<vals.length;i++){
        for(var key in this.seasons){
	    if(vals[i]==this.seasons[key]){
	        document.getElementById(this.seasons[key]+'Sel').checked = true;
	    }
        }
    }
};

/* Returns the value of any checked month in a concatenated string (CSV) */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.getValue = function () {
    var checkboxes = document.getElementsByName('seasonsSel');
    var valStr = "";
    for(var i=0;i<checkboxes.length;i++){
        if(checkboxes[i].checked){
            valStr += checkboxes[i].value + ",";
        }
    }
    valStr = valStr.substring(0,valStr.length-1);
    return valStr;
};

/* Returns the value of any checked month in a concatenated string (CSV) */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.getLabelValue = function () {
    var checkboxes = document.getElementsByName('seasonsSel');
    var valStr = "";
    for(var i=0;i<checkboxes.length;i++){
        if(checkboxes[i].checked){
            valStr += checkboxes[i].value + ",";
        }
    }
    valStr = valStr.substring(0,valStr.length-1);
    return valStr;
};

/* clear the selections */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.clear = function () {
    var checkboxes = document.getElementsByName('seasonsSel');
    for(var i=0;i<checkboxes.length;i++){
        checkboxes[i].checked = false;
    }
}

/* reset the selections */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.reset = function () {
    this.clear(); // for the moment.....
}

/* disable the selector */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.disable = function () {
    this.disabled = true;
    this.seasonRadio.checked = false;
    /* this.listContainer.style.display = 'none'; */
    /* this.listContainer.style.width = ''; */
    this.listContainer.setAttribute('class','listContainer');
    var textInput = document.getElementById('seasonalTextEntry');
    textInput = "";
    //this.listContainer.style.border = '1px solid #ccc';
    //var checkboxes = document.getElementsByName('seasonsSel');
    //for(var i=0;i<checkboxes.length;i++){
    //    checkboxes[i].disabled = true;
    //    document.getElementById('seasonsLabel'+checkboxes[i].value).setAttribute('class','monthsLabelDisabled');
    //}
}

/* enable the selector */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.enable = function () {
    this.disabled = false;
    this.seasonRadio.checked = true;
    //this.listContainer.style.display = 'inline-block';
    //this.listContainer.style.width = '10em';
    this.listContainer.setAttribute('class','listContainer listContainerVisible');
    var textInput = document.getElementById('seasonalTextEntry');
    textInput.value = this.getLabelValue();
    //this.listContainer.style.border = '1px solid #bbb';
    //var checkboxes = document.getElementsByName('seasonsSel');
    //for(var i=0;i<checkboxes.length;i++){
    //    checkboxes[i].disabled = false;
    //    document.getElementById('seasonsLabel'+checkboxes[i].value).setAttribute('class','monthsLabel');
    //}
};

/* Return the state of the selector - disabled or enabled */
giovanni.widget.SeasonalDatePicker.SeasonsSelector.prototype.getDisabled = function () {
    return this.disabled;
}


/* Build year range selector */
giovanni.widget.SeasonalDatePicker.YearRangeSelector = function (picker,container,minBound,maxBound) {
    this.picker = picker;
    this.container = container;
    this.maxStartYearDefault = minBound;
    this.maxStopYearDefault = maxBound;
    this.maxStartYear = minBound;
    this.maxStopYear = maxBound;
    this.startYear = "";
    this.stopYear = "";
    this.startCal = undefined;
    this.stopCal = undefined;
    this.render();
}

/* render the year range component */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.render = function () {
    // create year range label
    //var yearRangeLabel = document.createElement('span');
    //yearRangeLabel.innerHTML = 'Year Range';
    //this.container.appendChild(yearRangeLabel);
    //this.container.appendChild(document.createElement('br'));
    // create start year container
    var startContainer = document.createElement('div');
    startContainer.setAttribute('id','startYearContainer');
    startContainer.setAttribute('class','seasonalDateContainer');
    // build and add start year text entry component
    var startYear = document.createElement('input');
    startYear.setAttribute('id',this.container.id+'_startYear');
    startYear.setAttribute('type','text');
    startYear.setAttribute('size','4');
    startYear.setAttribute('maxlength','4');
    startYear.setAttribute('value',this.startYear);
    startYear.setAttribute('class','textFieldInput yearRangeTextInput');
    //startYear.setAttribute('tabindex','2');
    startContainer.appendChild(startYear);
    // create calendar icon button
    var startCalendarLink = document.createElement('a');
    startCalendarLink.setAttribute('title','Select a beginning year using a calendar');
    //startCalendarLink.setAttribute('class','calendarLink');
    startCalendarLink.setAttribute('id','startDateCalendarLink');
    //startCalendarLink.setAttribute('href','');
    startCalendarLink.innerHTML = "<img id='startYearCalendarButton' alt='Select beginning year using calendar' src='./img/yui_calbtn.gif'/>";
    startContainer.appendChild(startCalendarLink);

    var startCalContainer = document.createElement('div');
    startCalContainer.setAttribute('id','startYearCalContainer');

    startContainer.appendChild(startCalContainer);

    this.container.appendChild(startContainer);

    //this.startCal = this.getCalendar('start');
        // add 'to'
        var toSpan = document.createElement('span');
        toSpan.setAttribute('id','yearRangeSeparator');
        toSpan.innerHTML = "&nbsp;to&nbsp;";
        this.container.appendChild(toSpan);
    // create stop year container
    var stopContainer = document.createElement('div');
    stopContainer.setAttribute('id','stopYearContainer');
    stopContainer.setAttribute('class','seasonalDateContainer');
    // build and add stop year text entry component
    var stopYear = document.createElement('input');
    stopYear.setAttribute('id',this.container.id+'_stopYear');
    stopYear.setAttribute('type','text');
    stopYear.setAttribute('size','4');
    stopYear.setAttribute('maxlength','4');
    stopYear.setAttribute('value',this.stopYear);
    stopYear.setAttribute('class','textFieldInput yearRangeTextInput');
    //startYear.setAttribute('tabindex','4');
    stopContainer.appendChild(stopYear);
    // create calendar icon button
    var stopCalendarLink = document.createElement('a');
    stopCalendarLink.setAttribute('title','Select an ending year using a calendar');
    //startCalendarLink.setAttribute('class','calendarLink');
    stopCalendarLink.setAttribute('id','stopDateCalendarLink');
    //startCalendarLink.setAttribute('href','');
    stopCalendarLink.innerHTML = "<img id='stopYearCalendarButton' alt='Select ending year using calendar' src='./img/yui_calbtn.gif'/>";
    stopContainer.appendChild(stopCalendarLink);

    var stopCalContainer = document.createElement('div');
    stopCalContainer.setAttribute('id','stopYearCalContainer');
    stopContainer.appendChild(stopCalContainer);

    this.container.appendChild(stopContainer);

    //this.stopCal = this.getCalendar('stop');

    // add listeners to handle year entry
    YAHOO.util.Event.addListener(startYear,"change",this.handleYearChange,{startYear:startYear.value,stopYear:stopYear.value},this);
    YAHOO.util.Event.addListener(stopYear,"change",this.handleYearChange,{startYear:startYear.value,stopYear:stopYear.value},this);

    // add calendar listeners
    //YAHOO.util.Event.addListener("startYearContainer","mouseenter",this.showStartCalendar,{},this);
    YAHOO.util.Event.addListener("startYearContainer","mouseenter",this.setInControl,{},this);
    YAHOO.util.Event.addListener("startYearContainer","mousemove",this.showStartCalendar,{},this);
    YAHOO.util.Event.addListener("startYearContainer","mouseleave",this.hideStartCalendar,{},this);
    YAHOO.util.Event.addListener(this.container.id+"_startYear","focusin",this.showStartCalendar,{'inPanel':false},this);
    YAHOO.util.Event.addListener(this.container.id+"_startYear","focusout",this.hideStartCalendar,{},this);

    YAHOO.util.Event.addListener("stopYearContainer","mouseenter",this.setInControl,{},this);
    YAHOO.util.Event.addListener("stopYearContainer","mousemove",this.showStopCalendar,{},this);
    YAHOO.util.Event.addListener("stopYearContainer","mouseleave",this.hideStopCalendar,{},this);
    YAHOO.util.Event.addListener(this.container.id+"_stopYear","focusin",this.showStopCalendar,{'inPanel':false},this);
    YAHOO.util.Event.addListener(this.container.id+"_stopYear","focusout",this.hideStopCalendar,{},this);
}

/* handle year change */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.handleYearChange = function (e,o) {
    //var msg = "";
    //var err = false;
    var startVal = o.startYear != "" ? o.startYear : document.getElementById(this.container.id+"_startYear").value;
    var stopVal = o.stopYear != "" ? o.stopYear : document.getElementById(this.container.id+"_stopYear").value;
    this.picker.setTextAsError(this.container.id+"_startYear",false);
    this.picker.setTextAsError(this.container.id+"_stopYear",false);

    // set the years so the parent picker can see them
    this.setValue(startVal,stopVal);

    // validate from the top (use the parent picker's validation routine)
    var resp = this.picker.validate();
    if(resp.isValid()){
        // sync with the select lists
        if(startVal!=""){
          this.syncListWithText(startVal,"startYearRangeList");
        }
        if(stopVal!=""){
          this.syncListWithText(stopVal,"stopYearRangeList");
        }
        // make parent class fire an update event
        this.picker.parentClass.fire();
    }
}

/* Get year range value */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.getValue = function () {
    return this.startYear + "," + this.stopYear;
};

/* Set year range value */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.setValue = function (start,stop) {
    this.startYear = start;
    this.stopYear = stop;
    document.getElementById(this.container.id+'_startYear').value = this.startYear;
    document.getElementById(this.container.id+'_stopYear').value = this.stopYear;
};

/*
 * Used by parent validate to do validation work at the year level
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.validate = function () {
    var startVal = document.getElementById(this.container.id+'_startYear').value;
    var startValid = (startVal.length == 4 || startVal == "") ? true : false; 
    var stopVal = document.getElementById(this.container.id+'_stopYear').value;
    var stopValid = (stopVal.length == 4 || stopVal == "") ? true : false; 
    var valid = ((startValid&&stopVal=="")||(stopValid&&startVal=="")||(startValid&&stopValid)) ? true : false; 

    var msg = "";
    var err = !valid;

    if(startValid && stopValid){

    if(startVal==""&&stopVal==""){ // blank; component
        msg += (msg!="") ? "  " : "";
        msg += "Please enter a year range";
        err = true;
    }else if(startVal==""&&stopVal!=""){
        msg += (msg!="") ? "  " : "";
        msg += "Please enter a beginning year";
        err = true;
	this.setValue(startVal,stopVal);
	//var today = new Date();
        //var testDateStr = today.getMonth()+1 + "/" + today.getDate() + "/" + o.stopYear;
        //if(today.parse(testDateStr)){
        //} 
    }else if(startVal!=""&&stopVal==""){
        msg += (msg!="") ? "  " : "";
        msg += "Please enter an ending year";
        err = true;
	this.setValue(startVal,stopVal);
    }else if(startVal!=""&&stopVal!=""){
        var start = parseInt(startVal);
        var stop = parseInt(stopVal);
	if(start > stop){
            msg += "Ending year ("+stop+") must be more recent than beginning year ("+start+")",true;
	    err = true;
            this.setValue(startVal,stopVal);
        }else{
            msg = "";
	    err = false;
	    // check against valid range
	    if( startVal < this.maxStartYear && stopVal < this.maxStartYear ||
                startVal > this.maxStopYear && stopVal > this.maxStopYear){
                msg += "Selected years ("+start+", "+stop+") must intersect the valid date range("+this.maxStartYear+", "+this.maxStopYear+")";
                err = true;
            }else if ( startVal > this.maxStopYear ){
                msg += "Beginning year ("+start+") cannot be more recent than the end of the valid date range ("+this.maxStopYear+")";
                err = true;
            }else if( stopVal < this.maxStartYear ){
                msg += "Ending year ("+stop+") cannot be older than the  beginning of the valid date range ("+this.maxStartYear+")";
                err = true;
            }
            this.setValue(startVal,stopVal);
        }
    }

    }else{
        err = true;
        msg += "Poorly formatted year entry.";
    }

    return new giovanni.widget.ValidationResponse(!err,msg);

    //this.picker.setStatus(msg,err);

    //var overallValidResponse = true;
    //if(valid && !err){
    //     return overallValidResponse = this.picker.validate();
    //}else{
//	return err;
    //}
         
}

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.clear = function () {
    this.startYear = "";
    this.stopYear = "";
    if(this.startCal!=undefined) this.startCal.setBounds();
    if(this.stopCal!=undefined) this.stopCal.setBounds();
    document.getElementById(this.container.id+'_startYear').value = this.startYear;
    document.getElementById(this.container.id+'_stopYear').value = this.stopYear;    
}

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.reset = function () {
}

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.syncListWithText = function (value,listId) {
    var list = document.getElementById(listId);
    if(list){
        var opts = list.options;
        var idx = undefined;
        for(var i=0;i<opts.length;i++){
            if(opts[i].value==value){
                idx = i;
                break;
            }
        }
        if(idx) list.selectedIndex = idx;
    }
}

/* show the start year calendar */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.showStartCalendar = function(e,o){
    if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
    // complete hack - remove once the fix is determined
    document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer');
    // set the focus style on the containing element
    document.getElementById('startYearContainer').setAttribute('class','seasonalDateContainer dateContainerFocus');
    // use the picker 'inControl' flag to let other methods know the mouse is over the control
    if(e!=undefined&&e.type=='focus') this.setInControl();
    var wto = window.setTimeout( function (x) {
        return function () {
            if(x.isInControl()){ 
                if (x.stopCal!=undefined){ x.stopCal.hide(); }
	        if(this.startCal==undefined){
	            // fetch the calendar
                    x.startCal = x.getCalendar('start');
                }
                // update the calendar bounds
                x.setBounds(x.maxStartYear,x.maxStopYear);
	        // set the calendar value....if there is one
                x.setCalValue('start',x.startYear);

                x.startCal.show(null,{'inPanel':false});

		giovanni.util.panelOpenEvent.fire(x);
            }
        }
    }(this),
    100);

};

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.hideStartCalendar = function (e,o) {
    document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer');
    document.getElementById('startYearContainer').setAttribute('class','seasonalDateContainer');
    this.picker.inControl = false;
    try {
    this.startCal.startHideCheck(undefined,{'inPanel':false});
    }catch(ex){}
}

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.hide = function () {
    if(this.stopCal!=undefined) this.stopCal.hide();
    if(this.startCal!=undefined) this.startCal.hide();
}

/* show the stop year calendar */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.showStopCalendar = function(e,o){
    // complete hack - remove once the fix is determined
    document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer');
    document.getElementById('stopYearContainer').setAttribute('class','seasonalDateContainer dateContainerFocus');

    if(e!=undefined&&e.type=='focus') this.setInControl();
    var wto = window.setTimeout( function (x) {
        return function () {
            if(x.isInControl()){
                if (x.startCal!=undefined){ x.startCal.hide(); }
                if(this.stopCal==undefined){
                    // fetch the calendar
                    x.stopCal = x.getCalendar('stop');
                }
                // update the calendar bounds
                x.setBounds(x.maxStartYear,x.maxStopYear);
                // set the calendar value....if there is one
                x.setCalValue('stop',x.stopYear);

                x.stopCal.show(null,{'inPanel':false});

		giovanni.util.panelOpenEvent.fire(this);
            }
        }
    }(this),
    100);

};

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.hideStopCalendar = function (e,o) {
    document.getElementById('seasonalTextEntryContainer').setAttribute('class','seasonalDateContainer');
    document.getElementById('stopYearContainer').setAttribute('class','seasonalDateContainer');
    try {
    this.stopCal.startHideCheck(undefined,{'inPanel':false});
    }catch(ex) {}
}

giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.getCalendar = function (type) {
    var cal = (type =='start') ? this.startCal : this.stopCal;
    // create panel
    if(cal==undefined){
            // create panel
	    var phrase = (type=='start') ? 'a beginning' : 'an ending';
	    var cfg = {
	        'containerId':type+'YearCalContainer',
	        'associateId':type+'YearCalButton',
	        'headerStr':'Select '+phrase+' year',
                'topMargin':'0'
	    }
            cal = new giovanni.ui.Panel(cfg);
	    cal.addElement(this.getCalendarHTML(type));
    }
    return cal;
};

/* 
 * Create the HTML string that populates the year 'calendar' 
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {String}
 * @return voiod
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.getCalendarHTML = function (type) {
    // create the calendar div
    var div = document.createElement('div');
    div.setAttribute('id',type+'YearCalContainerBody');
    // create the calendar list
    var list = document.createElement('select');
    list.setAttribute('id',type+'YearRangeList');
    list.setAttribute('class','yearList');
    //list.setAttribute('size','9');
    list.setAttribute('tabIndex','-1');
    // get the max start and stop years
    var start = parseInt(this.maxStartYear);
    var stop = parseInt(this.maxStopYear);
    var currentYear = stop;
    // set the selected year if there is one
    var selectedYear = undefined;
    if(type=='start' && this.startYear) selectedYear = this.startYear;
    if(type=='stop' && this.stopYear) selectedYear = this.stopYear;
    // build the year list
    var yearCount=0;
    for(var i=stop;i>=start;i--){
        var opt = document.createElement('option');
        opt.value = currentYear;
        opt.text = currentYear;
        opt.setAttribute('tabIndex','-1');
	if(selectedYear && currentYear == selectedYear) opt.setAttribute('selected',true);
        list.appendChild(opt);
        currentYear = currentYear - 1;
	yearCount++;
    }
    list.setAttribute('size',yearCount+1);
    div.appendChild(list);
    div.setAttribute('class','yearListContainer');
    YAHOO.util.Event.addListener(type+'YearRangeList',"change",this.handleYearSelect,{type:type},this);
    
    return div;
};

/*
 * Used to update the list of years (the popup calendar) when the selected variables change
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {String}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.updateCalendarHTML = function (type) {
    var parentDiv = document.getElementById(type+'YearCalContainerBody');
    var selectedYear = undefined;
    if(type=='start' && this.startYear) selectedYear = this.startYear;
    if(type=='stop' && this.stopYear) selectedYear = this.stopYear;
    if(parentDiv){
        var list = document.getElementById(type+'YearRangeList');
        if(list && list.options){
            list.innerHTML = "";
            var start = parseInt(this.maxStartYear);
            var stop = parseInt(this.maxStopYear);
            var currentYear = stop;
            for(var i=stop;i>=start;i--){
                var opt = document.createElement('option');
                opt.value = currentYear;
                opt.text = currentYear;
                opt.setAttribute('tabIndex','-1');
		if(selectedYear && currentYear == selectedYear) opt.setAttribute('selected',true);
                list.appendChild(opt);
                currentYear = currentYear - 1;
            }
        }
    }
}

/* 
 * Used to handle the selection event from the year list (updated the correct year value) 
 * 
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {YAHOO.util.Event,Object}
 * @return void
 * @author K. Bryant
*/
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.handleYearSelect = function (e,o) {
    if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
    var targ = giovanni.util.getTarget(e);
    var val = targ.options[targ.selectedIndex].value;
    if(o.type=='start'){
        this.startYear = val;
    }else if(o.type=='stop'){
        this.stopYear = val;
    }
    // forward the rest of the work onto handleYearChange (the function that handles
    // text entry - it is the text entries (start and stop year) that ultimately 
    // become the value of the year range selector
    this.handleYearChange(undefined,{startYear:this.startYear,stopYear:this.stopYear});
};

/*
 * Set the bounds (valid start and stop years)
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {Date,Date}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.setBounds = function (min,max) {
    // set the max start and stop years, account for null arguments
    this.maxStartYear = min ? 
         (min instanceof Date ? min.toISO8601DateTimeString().split('T')[0].split('-')[0] : min) : this.maxStartYearDefault;
    this.maxStopYear = max ? 
         (max instanceof Date ? max.toISO8601DateTimeString().split('T')[0].split('-')[0] : max) : this.maxStopYearDefault;

    // update the start and stop calendars as necessary
    this.updateCalendarHTML('start');
    this.updateCalendarHTML('stop');
}

/*
 * Set the selected value on the calendar
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {String,String}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.setCalValue = function (type,yr) {
    var yearList = document.getElementById(type+"YearRangeList");
    var opts = yearList.options;
    for(var i=0;i<opts;i++){
        if(opts[i].value==yr){
            opts[i].selected = true;
        }
    }
};

/*
 * Get days in a month - should be a Date or util method
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.getDaysInMonth = function (inYear,inMon) {
    var maxDays = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
    if(!inYear) inYear = new Date().getFullYear();
    var year = parseInt(inYear);
    if(!inMon) inMon = new Date().getMonth() + 1;
    var monNum = parseInt(inMon);
    if (monNum == 2) {
        // Test for leap year only if month is Feb
        if (year % 4) {
            // Case of year not divisible by 4; not a leap year
        } else {
            // Case of year divisible by 4
            if (year % 100) {
                // Case of year divisible by 4 but not by 100; a leap year
                maxDays[1] = 29;
            } else {
                // Case of year divisible by 4 and by 100; not a leap year
                if (year % 400) {
                    // Case of year not divisible by 400; not a leap year
                } else {
                    // Case of year divisible by 400; a leap year
                     maxDays[1] = 29;
                }
            }
        }
    }
    return monNum > 0 ? maxDays[monNum-1] : 0;
};

/*
 * Get the formatted date string, using hours or not - should be a higher level method....
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {Date}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.getDateTimeString = function (d) {
    return this.useHours ? d.toISO8601DateHourString() : d.toISO8601DateString();
};

/*
 * Sets whether the focus is in the control panel
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {YAHOO.util.Event,Object}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.setInControl = function (e,o) {
    this.inControl = true;
}
/*
 * Tracks whether the focus is in the control panel
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {YAHOO.util.Event,Object}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.isInControl = function () {
    return this.inControl;
}
/*
 * Gets the id of the HTML container
 *
 * @this {giovanni.widget.SeasonalDatePicker.YearRangeSelector}
 * @params {YAHOO.util.Event,Object}
 * @return void
 * @author K. Bryant
 */
giovanni.widget.SeasonalDatePicker.YearRangeSelector.prototype.getId = function () {
    return this.container.id;
}

