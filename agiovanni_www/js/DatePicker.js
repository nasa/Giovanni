//$Id: DatePicker.js,v 1.76 2015/03/16 15:02:34 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $

/*
 * Create the datepicker object to represent date and time
 */

giovanni.namespace("widget");

/**
 * Modifies min/max bounds set in the constructor
 * 
 * @constructor
 * @this {Giovanni.widget.DatePicker}
 * @param {String, Configuration}
 * @returns {giovanni.widget.DatePicker}
 * @author T. Joshi 
 */
giovanni.widget.DatePicker=function(containerId,url,config)
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
	
	this.minBounds = [new Date('01/01/1970')];
	this.maxBounds = [new Date()];
  
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
	    if (!this.minBounds[0].parse(config.minBound)){
	        this.minBounds[0] = new Date('01/01/1970');
	        alert("Could not load date bounds : " + config.minBound);
	    }
	    else {
		// Keeps a default min bound for when the min bound is made null by a data accessor response
		// (usually by removing all of the variables).  This allows us to set a configured default
		// min bound at construction and keep it even in the absense of data
		this.defaultMinBound = this.minBounds[0];
	    }
	}
	if(config.maxBound !== undefined){
	    if (!this.maxBounds[0].parse(config.maxBound)){
	        this.maxBounds[0] = new Date();
	        alert("Could not load date bounds : " + config.maxBound);
	    }
	    else{
		this.defaultMaxBound = this.maxBounds[0];
	    }
	}

	this.minMinBound = this.minBounds[0];
	this.maxMaxBound = this.maxBounds[0];
	
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
        
        // add this class to the config for the child pickers
        config.parentClass = this;
        this.config = config;
        
        this.selectionEvent=new YAHOO.util.CustomEvent("SelectionEvent",this);

	this.currentPicker = null;
        this.dateRangePicker = null;
        this.seasonalDatePicker = null;

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
	// values loaded from a bookmarked URL
	this.urlStartDateStr = "";
	this.urlEndDateStr = "";
	this.useHours = false;
	this.monthDataOnly = false;
	this.startHours = null;
	this.endHours = null;
	this.startDateTF = null;
	this.endDateTF = null;
	// calendar min/max bound date string
	this.calMinBound = this.minBounds[0].toISO8601DateString();
	this.calMaxBound = this.maxBounds[0].toISO8601DateString();
	this.render();
};

/**
 * Creates the GUI for giovanni.widget.DatePicker and registers the component
 * 
 * @this {Giovanni.widget.DatePicker}
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.render = function(){

    var fieldset = document.createElement('fieldset');
    var legend = document.createElement('legend');
    legend.setAttribute('id','datePickerLegend');
    legend.innerHTML='Select Date Range (UTC)';
    fieldset.appendChild(legend);

    var ctrlContainer = document.createElement('div');
    ctrlContainer.setAttribute('class','pickerContent');

    // date range picker ocntainer
    var dateRangeContainer = document.createElement('div');
    dateRangeContainer.setAttribute('id','dateRangeContainer');
    //dateRangeContainer.setAttribute('class','pickerContent');
    ctrlContainer.appendChild(dateRangeContainer);
    // seaonal picker container
    var seasonalContainer = document.createElement('div');
    seasonalContainer.setAttribute('id','pickerContent');
    //seasonalContainer.setAttribute('class','pickerContent');
    seasonalContainer.style.display = 'none';
    ctrlContainer.appendChild(seasonalContainer);

    // create usage hint
    //var hint = document.createElement('div');
    //hint.setAttribute('id','datePickerHint');
    //hint.setAttribute('class','hint');
    //hint.innerHTML = "Format: YYYY-MM-DD.";
    //ctrlContainer.appendChild(hint);
    // create picker controls container
    //var rangePickerContainer = document.createElement('div');
    //rangePickerContainer.setAttribute('class','datePickerContainer');
    //ctrlContainer.appendChild(rangePickerContainer);    

    // create bounds message
    var boundsDisp = document.createElement('div');
    boundsDisp.setAttribute('id', 'dateRangeDisplay');
    boundsDisp.setAttribute('class','validDateRange');
    ctrlContainer.appendChild(boundsDisp);

    fieldset.appendChild(ctrlContainer);

    this.container.appendChild(fieldset);
    //this.container.appendChild(document.createElement('br'));
    var statusDiv = document.createElement('div');
    statusDiv.setAttribute('class','pickerStatus');
    statusDiv.setAttribute('id','datePickerStatus');
    statusDiv.innerHTML =""+this.statusStr+"&nbsp;";
    this.container.appendChild(statusDiv);

    // build child pickers
    this.dateRangePicker = 
        new giovanni.widget.DateRangePicker(dateRangeContainer.id,this.dataSourceUrl,this.config,this);
    // by default, the 'current' picker is the date range picker, so set it here
    this.currentPicker = this.dateRangePicker;
    this.seasonalPicker = new giovanni.widget.SeasonalDatePicker(seasonalContainer.id,this.dataSourceUrl,this.config,this);
    this.seasonalPicker.selectionEvent.subscribe(this.handleSeasonalSelectionEvent,this);

    // REGISTRY is a global variable declared in REGISTRY.js
    if(REGISTRY){
        REGISTRY.register(this.id,this);
        REGISTRY.markComponentReady(this.id);
    }
    else{
	alert("no REGISTRY so could not register DatePicker");
    }

    this.showValidDateRange();

};

/*
giovanni.widget.DatePicker.prototype.focusStartCalendar = function (e,o) {
    if(this.startDateCal!=undefined&&this.startDateCal.dialog!=null){
        this.startDateCal.dialog.focus();
    }
};
*/

/**
 * Fires an event in the registry when the component value is changed
 * 
 * @this {Giovanni.widget.DatePicker}
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.fire = function(){
    if(REGISTRY){
	REGISTRY.fire(this);
    }
    else{
	alert("no REGISTRY so no event REGISTRY event to fire");
    }

};

/**
 * Sets the date input field value from the calendar for startDate
 * 
 * @this {giovanni.widget.DatePicker}
 * @param {YAHOO.util.Event, Object} o is a YAHOO.util.event object, args contains a reference to the calling giovanni.widget.DatePicker object
 * @author T. Joshi 
 */
/*
giovanni.widget.DatePicker.prototype.setStartDate = function(o,args) {
	// Set the date input field value from the calendar
	var cDate = args.self.getString(o.dateTime).split("T")[0];
	var cTime = args.self.getHours('startHours');
	args.self.startDateTF.setValue(cDate);
	if(args.self.monthDataOnly){
	    args.self.startDateTF.enableDay(false);
	}
	args.self.setValue({startDateStr:cDate + "T" + cTime + "Z"});
	//id.focus();
	//id.select();
};
*/

/**
 * Sets the date input field value from the calendar for endDate
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} o is a YAHOO.util.Event object, args contains a reference called {self} to the calling giovanni.widget.DatePicker object
 * @author T. Joshi 
 */
/*
giovanni.widget.DatePicker.prototype.setEndDate = function(o,args){
	// Set the date input field value from the calendar
	var eDate = args.self.getString(o.dateTime).split("T")[0];
	var eTime = args.self.getHours('endHours');
	args.self.endDateTF.setValue(eDate);
	if(args.self.monthDataOnly){
	    args.self.endDateTF.enableDay(false);
	}
        //id.value = eDate;
	//id.value = (args.self.getString(o.dateTime)).split("T")[0]; 
        args.self.setValue({endDateStr:eDate + "T" + eTime + "Z"});
	//args.self.setValue({endDateStr:id.value});
	//id.focus();
	//id.select();
};
*/


/**
 * Initializes then displays a giovanni.widget.Calendar for startDate
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} evt is a YAHOO.util.Event object, self is a reference to the calling giovanni.widget.DatePicker object
 * @author T. Joshi 
 */
/*
giovanni.widget.DatePicker.prototype.showStartCalendar = function(evt,self){
        self.endDateCal.hide();
	var shown = false;
	if(self.startDateCal.dialog){
	    shown = self.startDateCal.dialog.cfg.getProperty("visible");
	}
	if(shown){
	    self.startDateCal.hide();
	}else{
	    self.startDateCal.render();
	    self.startDateCal.setBounds(self.calMinBound,self.calMaxBound,true);
	    self.startDateCal.setValue(self.startDate);  
	}
};
*/

/**
 * Initializes then displays a giovanni.widget.Calendar for endDate
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} o is a YAHOO.util.Event object, self is a reference to the calling giovanni.widget.DatePicker object
 * @author T. Joshi 
 */
/*
giovanni.widget.DatePicker.prototype.showEndCalendar = function(evt,self){
        self.startDateCal.hide();
	var shown = false;
	if(self.endDateCal.dialog){
	    shown = self.endDateCal.dialog.cfg.getProperty("visible");
	}
	if(shown){
	    self.endDateCal.hide();
	}else{
	    self.endDateCal.render();
	    self.endDateCal.setBounds(self.calMinBound,self.calMaxBound);
	    self.endDateCal.setValue(self.endDate);
	}
};
*/

/**
 * Handles input elements focus events
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} - self is a reference to the calling giovanni.widget.DatePicker object
 * @author K. Bryant
 */
/*
giovanni.widget.DatePicker.prototype.handleFocus = function (evt,self) {
        // show the appropriate calendar
        if(evt.target.id=='t1'){
                self.showStartCalendar(evt,self);
	}else if(evt.target.id=='t2'){
                self.showEndCalendar(evt,self);
	}
	//YAHOO.util.Event.stopEvent(evt);
};
*/

/**
 * Returns the date as a string with or without time depending on this.type
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {Date} the date to be converted
 * @returns {String} formatted in ISO8601 date/datetime format
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.getString = function(d,hoursId) {
    //if( this.useHours ){
        return d.toISO8601DateTimeString() + "Z";
    //} else {
//	if( hoursId == 'endHours' ){
 //           return d.toISO8601DateTimeString() + "Z";
//	}else{
 //           return d.toISO8601DateString();
//	}
 //   }
};

/**
 * Returns the date string used in error messages; string format depends
 * on whether hours ar being used
 * 
 * @this {giovanni.widget.DatePicker}
 * @params {Date} the date to be converted
 * @return {String} formatted either in ISO8601 (Date only) or as the
 * user entered it (ISO8601 Date + hh 'hrs')
 * @author K. Bryant
 */
giovanni.widget.DatePicker.prototype.getDateTimeString = function (d) {
    return this.useHours ? d.toISO8601DateHourString() : d.toISO8601DateString();
};

/**
 * Validates startDate and endDate
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {giovanni.widget.ValidationResponse} true or false depending on if the date meets predetermined conditions with an explanation 
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.validate = function(){
    return this.currentPicker ? this.currentPicker.validate() : 
               new giovanni.widget.ValidationResponse(false,"Please select a date range");
};

/**
 * Returns the value of the start time and end time
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {String} formatted in ISO8601 date/datetime standard and returned as 'starttime=&endtime='
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.getValue = function(){
    if(this.currentPicker!=null){
    return this.currentPicker.getValue();
    }
};

giovanni.widget.DatePicker.prototype.getDaysInMonth = function (inYear,inMon) {
    var maxDays = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
    var year = parseInt(inYear);
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

/**
 * Sets the selected value of the start time and end time
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {Object} object contains two strings, startDateStr, endDateStr representing the start and end times to set, respectively 
 * @returns {giovanni.widget.ValidationResponse} whether the date validates or not with an explanation;
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.setValue = function(dates) {
    this.dateRangePicker.setValue(dates);
    this.seasonalPicker.setValue(dates);
};

/**
 * Sets the picker value back to it's initialization values
 *
 * @this (giovanni.widget.DatePicker}
 * @author K. Bryant
 */
giovanni.widget.DatePicker.prototype.clearSelections = function () {
    this.dateRangePicker.clearSelections();
    if(this.seasonalPicker){
        this.seasonalPicker.clearSelections();
    }
};

/**
 * Sets the picker value back to it's initialization values
 *
 * @this (giovanni.widget.DatePicker}
 * @author K. Bryant
 */
giovanni.widget.DatePicker.prototype.resetSelections = function () {
    this.dateRangePicker.resetSelections();
    if(this.seasonalPicker){
        this.seasonalPicker.resetSelections();
    }
};

/**
 * sets dates given a query string
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String} qs is in the format of starttime=&endtime= 
 * @returns {giovanni.widget.ValidationResponse} whether dates validate or not with an explanation
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.loadFromQuery = function(qs){
    this.dateRangePicker.loadFromQuery(qs);
    this.seasonalPicker.loadFromQuery(qs);
};

/**
 * Updates the component bounds based on dependencies in the registry
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String} specifies additional parameters for the data source url to be fetched from in format starttime=&endtime= 
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.updateComponent = function(qs){
    var queryStr = qs instanceof Array ? qs[0] : qs;
    if(queryStr.indexOf("QuCl")>-1
       ||queryStr.indexOf('InTs')>-1
       ||queryStr.indexOf('InMp')>-1){
        this.currentPicker = this.seasonalPicker;
        document.getElementById('datePickerLegend').innerHTML =
            "Select Seasonal Dates";
        this.dateRangePicker.setDisabled(true);
        this.seasonalPicker.setDisabled(false);
    }else{
        this.currentPicker = this.dateRangePicker;
        document.getElementById('datePickerLegend').innerHTML =
            "Select Date Range (UTC)";
        this.seasonalPicker.setDisabled(true);
        this.dateRangePicker.setDisabled(false);
    }
    if (typeof this.dataSourceUrl == "function") {
      this.dataSourceUrl(this.currentPicker, qs);
    } else if (typeof this.dataSourceUrl == "string") {
      var dataSourceUrl = this.dataSourceUrl + "?" + qs;
      this.setStatus("Updating date range based on data changes ... ",true);
  
      YAHOO.util.Connect.asyncRequest('GET', dataSourceUrl,
      { 
        success:giovanni.widget.DatePicker.fetchDataSuccessHandler,
        failure:giovanni.widget.DatePicker.fetchDataFailureHandler,
        argument: {self:this,format:"xml"}
      } );
    }
};

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 *      
 * @this {Giovanni.widget.DatePicker}
 * @param {String, String} contains the minBound and the maxBound
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.setBounds = function(minBounds,maxBounds){
    this.dateRangePicker.setBounds(minBounds,maxBounds);
    this.seasonalPicker.setBounds(minBounds,maxBounds);
};

/** Shows the valid date range given the min/max bounds
 *
 * @this {Giovanni.widget.DatePicker}
 * @author Chocka/K. Bryant
 */
giovanni.widget.DatePicker.prototype.showValidDateRange = function () {
  document.getElementById("dateRangeDisplay").innerHTML = (this.minMinBound==null?"":" Valid Range: "+(this.minMinBound.toISO8601DateTimeString().split('T')[0]+' to ')) +
                (this.maxMaxBound==null?"":this.maxMaxBound.toISO8601DateTimeString().split('T')[0]);
};

giovanni.widget.DatePicker.prototype.handleSeasonalSelectionEvent = function (e,o) {
    o.fire();
}

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.Connect}
 * @param {YAHOO Response Object} contains responseText and responseXML from remote request, and specified arguments
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.fetchDataSuccessHandler = function(o){
    var self=o.argument["self"];
    try {
        var startDates = null;
    	var endDates = null;
    	if(o.argument.format === "json") {
    	  var jsonData=YAHOO.lang.JSON.parse(o.responseText);
    	  startDates = (jsonData.startDate !== undefined)? jsonData.startDate:self.minBounds;
    	  endDates = (jsonData.endDate !== undefined)? jsonData.endDate:self.maxBounds;
          //if(startDates&&endDates){
            self.dateRangePicker.setHourPickersState(jsonData.hourRequired);
          //}
	  self.dateRangePicker.setDatePickerState('json',jsonData);
    	} else {
    	  var xmlData = o.responseXML;
    	  var dateRange = xmlData.getElementsByTagName('dateRange')[0]; 
    	  startDates = (dateRange.attributes.getNamedItem("STARTDATE"))? dateRange.attributes.getNamedItem("STARTDATE").value : self.minBounds;
    	  endDates = (dateRange.attributes.getNamedItem("ENDDATE"))? dateRange.attributes.getNamedItem("ENDDATE").value : self.maxBounds; 
          var hoursRequired = dateRange.attributes.getNamedItem("HOURREQUIRED");
          //if(startDates&&endDates){
            self.dateRangePicker.setHourPickersState(hoursRequired);
	  //}
          self.dateRangePicker.setDatePickerState('xml',xmlData);
    	}
    
    	self.dateRangePicker.setBounds(startDates,endDates);
    	self.seasonalPicker.setBounds(startDates,endDates);
//      // moved back to render method
//    	if(REGISTRY) {
//     	  REGISTRY.markComponentReady(self.id);
//    	}
    }
    catch(x)
    {
      alert("giovanni.widget.DatePicker:  Failed to load dates: " + x.message);
    }
};

/**
 * Handles the failure of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.connect}
 * @param {YAHOO Response Object} contains reason for the failure
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.fetchDataFailureHandler = function(o){
    alert("Could not retrieve data from specified data URL!");
};

/**
 * Set the data source url for retrieving updates to the bounds from updateComponent
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String} url to set the dataSourceUrl property to
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.setDataSourceUrl = function(url){
    this.dataSourceUrl = url;
};

/**
 * Returns the data source url for retrieving updates to the bounds from updateComponent
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {String} the data source url
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.getDataSourceUrl = function(){
    return this.dataSourceUrl;
};

/**
 * Set the current status of the component
 *      
 * @this {giovanni.widget.DatePicker}
 * @param {String, Boolean} the status string and whether it is an error or not 
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.setStatus = function(s,isError){
    this.statusStr = s;
    var statusDiv = document.getElementById('datePickerStatus');
    statusDiv.style.color = (isError === true)? "red":"green";
    statusDiv.innerHTML = "" + s + "&nbsp;";
};

/**
 * Fetches the current status of the component
 *      
 * @this {giovanni.widget.DatePicker}
 * @returns {String} the status string
 * @author T. Joshi 
 */
giovanni.widget.DatePicker.prototype.getStatus = function(){
    return this.statusStr;
};

giovanni.widget.DatePicker.prototype.setStartTime = function(dateStr) {
	var sdate = new Date();
	if (! sdate.parse(dateStr) ){
            sdate = null;
        }
	if (sdate !== null && this.type==="Date") { 
		var yr = sdate.getUTCFullYear();
		var mon= sdate.getUTCMonth();
		var day= sdate.getUTCDate();
		//var hour = this.getHours('startHours');
                var hour = sdate.getUTCHours();
		sdate = new Date(Date.UTC(yr, mon, day, hour, 0, 0,0));
	}
	return sdate;
};

giovanni.widget.DatePicker.prototype.setEndTime = function(dateStr) {
	var sdate = new Date();
	sdate.parse(dateStr);
	if (! sdate.parse(dateStr) ){
            sdate = null;
        }
    	if (sdate !== null && this.type==="Date") { 
		var yr = sdate.getUTCFullYear();
		var mon= sdate.getUTCMonth();
		var day= sdate.getUTCDate();
		//var hour = this.getHours('endHours');
                var hour = sdate.getUTCHours();
		sdate = new Date(Date.UTC(yr, mon, day, hour, 59, 59,999));
	}  
	return sdate;
};

/**
 * Returns the ID for this picker, which is the ID of the HTML element 
 * containing this picker
 *
 * @this {giovanni.widget.DatePicker}
 * @author Chocka
 */
giovanni.widget.DatePicker.prototype.getId = function () {
  return this.containerId;
};

/*
 * If any of the calendars are displayed, hide them; used when switching back to the data selector
 *
 * @this {giovanni.widget.DatePicker}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DatePicker.prototype.hide = function () {
    if(this.currentPicker!=null) this.currentPicker.hide();
};

giovanni.widget.DatePicker.prototype.getCurrentPicker = function () {
    return this.currentPicker;
}
