
//DateRangePicker.js,v 1.38 2015/07/21 20:37:41 kbryant Exp 
//-@@@ Giovanni, Version HEAD

/*
 * Create the datepicker object to represent date and time
 */

giovanni.namespace("widget");

/**
 * Modifies min/max bounds set in the constructor
 * 
 * @constructor
 * @this {Giovanni.widget.DateRangePicker}
 * @param {String, Configuration}
 * @returns {giovanni.widget.DateRangePicker}
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker=function(containerId,url,config,parentClass)
{
	//Get the ID of the container element
	this.container=document.getElementById(containerId);
	if (this.container==null){
		this.setStatus("Error [giovanni.widget.DateRangePicker]: element '"+containerId+"' not found!");
		return;
	}
	this.id = containerId;
	//Store the container's ID
	this.containerId=containerId;

	//Get the data source URL
	this.dataSourceUrl = url;
	if (this.dataSourceUrl==null){
		alert("Error [giovanni.widget.DateRangePicker]: data source URL is null");
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
        this.minBound = this.minBounds[0];
        this.maxBound = this.maxBounds[0];
	
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

	this.parentClass = parentClass;
        
        this.selectionEvent=new YAHOO.util.CustomEvent("SelectionEvent",this);

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
        this.useMinutes = false;
	this.monthDataOnly = false;
	this.startHours = null;
	this.endHours = null;
        this.startMinutes = null;
        this.endMinutes = null;
	this.startDateTF = null;
	this.endDateTF = null;
	// calendar min/max bound date string
	this.calMinBound = this.minBounds[0].toISO8601DateString();
	this.calMaxBound = this.maxBounds[0].toISO8601DateString();
        // track whether the picker is handling climatology or not
        this.climFound = false;
        this.allClim = false;
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
        // render the picker
	this.render();
};

/**
 * Creates the GUI for giovanni.widget.DateRangePicker and registers the component
 * 
 * @this {Giovanni.widget.DateRangePicker}
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.render = function(){

/*
    var ctrlContainer = document.createElement('div');
    ctrlContainer.setAttribute('class','pickerContent');

    var fieldset = document.createElement('fieldset');
    var legend = document.createElement('legend');
    legend.innerHTML='Select Date Range (UTC)';
    fieldset.appendChild(legend);
*/

    // create usage hint
    var hint = document.createElement('span');
    hint.setAttribute('id','datePickerHint');
    hint.setAttribute('class','hint');
    //hint.innerHTML = "Enter date(s) as YYYY-MM-DD or use calendars.";
    hint.innerHTML = "YYYY-MM-DD.";
    this.container.appendChild(hint);
    // create usage hint
    var timehint = document.createElement('span');
    timehint.setAttribute('id','timePickerHint');
    timehint.setAttribute('class','hint');
    timehint.innerHTML = "HH:mm";
    this.container.appendChild(timehint);
    // create picker controls container
    var rangePickerContainer = document.createElement('div');
    rangePickerContainer.setAttribute('class','datePickerContainer');
    this.container.appendChild(rangePickerContainer);    

    // create startTimeContainer
    var startDateTimeContainer = document.createElement('div');
    startDateTimeContainer.setAttribute('id','startDateTimeContainer');
    startDateTimeContainer.setAttribute('class','dateTimeContainer');
    rangePickerContainer.appendChild(startDateTimeContainer);

    // create startContainer
    var startDateContainer = document.createElement('span');
    startDateContainer.setAttribute('id','startDateContainer');
    startDateContainer.setAttribute('class','dateContainer');
    startDateTimeContainer.appendChild(startDateContainer);

    // create date input
    this.startDateTF = new giovanni.widget.DateRangePicker.TextField(this,startDateContainer);
    
    // create calendar icon button
    var startCalendarLink = document.createElement('a');
    startCalendarLink.setAttribute('title','Select start date using calendar');
    startCalendarLink.setAttribute('id','startDateCalendarLink');
    startCalendarLink.innerHTML = "<i class='fa fa-calendar calIcon' aria-hidden='true'></i>";
    startDateContainer.appendChild(startCalendarLink);
    this.startDateCal = new giovanni.widget.Calendar("startDate", {type : this.type,callback : this.setStartDateFromCalendar, interval:this.interval, minBound: this.minMinBound, maxBound:this.maxMaxBound, dateTime:this.minMinBound, title:'Pick a start date', arguments:{self:this},monthDataOnly:this.monthDataOnly});
    // create startContainer
    var startTimeContainer = document.createElement('span');
    startTimeContainer.setAttribute('id','startTimeContainer');
    startTimeContainer.setAttribute('class','dateContainer');
    startDateTimeContainer.appendChild(startTimeContainer);
    this.startTimeTF = new giovanni.widget.DateRangePicker.TimeTextField(this,startTimeContainer,"00:00");

    // register listeners
    YAHOO.util.Event.addListener(startCalendarLink,"click",this.showStartCalendar,this);

    if(this.range === true){
        // add 'to'
	var toSpan = document.createElement('div');
	toSpan.setAttribute('id','dateRangeSeparator');
	toSpan.innerHTML = "&nbsp;to&nbsp;";
	startDateTimeContainer.appendChild(toSpan);
        // add date input and calendar container
        // create end datetime Container
	var endDateTimeContainer = document.createElement('div');
	endDateTimeContainer.setAttribute('id','endDateTimeContainer');
	endDateTimeContainer.setAttribute('class','dateTimeContainer');
	rangePickerContainer.appendChild(endDateTimeContainer);
        // create end date container
        var endContainer = document.createElement('span');
	endContainer.setAttribute('id','endContainer');
        endContainer.setAttribute('class','dateContainer');
	endDateTimeContainer.appendChild(endContainer);

        // create end date input
        this.endDateTF = new giovanni.widget.DateRangePicker.TextField(this,endContainer);

        // create end date calendar linke
    	var endCalendarLink = document.createElement('a');
    	endCalendarLink.setAttribute('title','Select end date using calendar');
    	endCalendarLink.setAttribute('id','endDateCalendarLink');
    	endCalendarLink.innerHTML = "<i class='fa fa-calendar calIcon' aria-hidden='true'></i>";
        endContainer.appendChild(endCalendarLink);
        // create end datetime YUI calendar
        this.endDateCal = new giovanni.widget.Calendar("endDate", {type : this.type,callback : this.setEndDateFromCalendar,interval:this.interval, minBound:this.minMinBound,maxBound:this.maxMaxBound, dateTime:this.maxMaxBound, title:'Pick an end date', arguments:{self:this},monthDataOnly:this.monthDataOnly,allClim:this.allClim});
        // create hours selector
        var endTimeContainer = document.createElement('span');
        endTimeContainer.setAttribute('id','endTimeContainer');
        endTimeContainer.setAttribute('class','dateContainer');
        endDateTimeContainer.appendChild(endTimeContainer);
        this.endTimeTF = new giovanni.widget.DateRangePicker.TimeTextField(this,endTimeContainer,"23:59");

	// add listeners
        YAHOO.util.Event.addListener(endCalendarLink,"click",this.showEndCalendar,this);
    }

    // handle panel open events from other panels
    giovanni.util.panelOpenEvent.subscribe(
      giovanni.util.handlePanelOpenEvent,
      {
        callingObject:this,
        callback:this.hide
      },
      this
    );

};

giovanni.widget.DateRangePicker.prototype.focusStartCalendar = function (e,o) {
    if(this.startDateCal!=undefined&&this.startDateCal.dialog!=null){
        this.startDateCal.dialog.focus();
    }
};

/*
 * Used for climatology condition
 */
giovanni.widget.DateRangePicker.prototype.getMonthLabel = function (mon) {
    var monStr = mon < 10 ? new String('0'+mon) : new String(mon);
    return this.months[monStr];
}

/**
 * Sets the date input field value from the calendar for startDate
 * 
 * @this {giovanni.widget.DateRangePicker}
 * @param {YAHOO.util.Event, Object} o is a YAHOO.util.event object, args contains a reference to the calling giovanni.widget.DateRangePicker object
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setStartDateFromCalendar = function(o,args) {
	// Set the date input field value from the calendar
	//var cDate = args.self.getString(o.dateTime).split("T")[0];
	var sDateStr = args.self.getString(o.dateTime);
	//args.self.startDateTF.setValue(sDate.split("T")[0]);
	//args.self.startDateTF.setValue(sDate.split("T")[1]);
	if(args.self.monthDataOnly){
	    args.self.startDateTF.enableDay(false);
	}
	//args.self.setValue({startDateStr:cDate + "T" + this.startTimeTF.getValue() + "Z"});
	args.self.setValue({startDateStr:sDateStr.split("T")[0]+"T00:00:00"});
};

/**
 * Sets the date input field value from the calendar for endDate
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} o is a YAHOO.util.Event object, args contains a reference called {self} to the calling giovanni.widget.DateRangePicker object
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setEndDateFromCalendar = function(o,args){
	// Set the date input field value from the calendar
	var eDateStr = args.self.getString(o.dateTime);
	//var eTime = args.self.getHours('endHours');
	//args.self.endDateTF.setValue(eDateStr.split("T")[0]);
        // Calendar should NOT set time at this point...unless it's empty?
	//args.self.endTimeTF.setValue(eDate.split("T")[1]);
	if(args.self.monthDataOnly){
	    args.self.endDateTF.enableDay(false);
	}
        args.self.setValue({endDateStr:eDateStr.split("T")[0]+"T23:59:59"});
};


/**
 * Initializes then displays a giovanni.widget.Calendar for startDate
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} evt is a YAHOO.util.Event object, self is a reference to the calling giovanni.widget.DateRangePicker object
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.showStartCalendar = function(evt,self){
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
	    giovanni.util.panelOpenEvent.fire(self);
	}
};

/**
 * Initializes then displays a giovanni.widget.Calendar for endDate
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} o is a YAHOO.util.Event object, self is a reference to the calling giovanni.widget.DateRangePicker object
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.showEndCalendar = function(evt,self){
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
	    giovanni.util.panelOpenEvent.fire(self);
	}
};

/**
 * Handles input elements focus events
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} - self is a reference to the calling giovanni.widget.DateRangePicker object
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.handleFocus = function (evt,self) {
        // show the appropriate calendar
        if(evt.target.id=='t1'){
                self.showStartCalendar(evt,self);
	}else if(evt.target.id=='t2'){
                self.showEndCalendar(evt,self);
	}
	//YAHOO.util.Event.stopEvent(evt);
};

/**
 * Handles input element blur (loss of focus) events
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} - self is a reference to the calling giovanni.widget.DateRangePicker object
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.handleBlur = function (evt,self) {
    self.hide();  // hide the calendars
};

/**
 * Handles input keypress events
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} - self is a reference to the calling giovanni.widget.DateRangePicker object
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.handleKeyPress = function (evt,self) {
    if(evt.keyCode==13){ // if carriage return, hide the calendars
            self.hide();
    }
};

/**
 * Updates the calendar bounds; used when the component receives an updated date range
 * from an external component (e.g., variable picker)
 *
 * @this (giovanni.widget.DateRangePicker)
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.updateCalendarBounds = function (min,max) {
	if(min==null){
	    min = new Date(this.defaultMinBound).toISO8601DateString();
	}
        min = min.toString().split("T")[0];
        if(min.indexOf("-")>-1){
            var minA = min.split("-");
            min = new Number(minA[1]).toString() + "/" + new Number(minA[2]).toString() + "/" + minA[0];
        }
	this.calMinBound = min;

	if(max==null){
	    max = new Date(this.defaultMaxBound).toISO8601DateString();;
	}	
        max = max.toString().split("T")[0];
        if(max.indexOf("-")>-1){
            var maxA = max.split("-");
            max = new Number(maxA[1]).toString() + "/" + new Number(maxA[2]).toString() + "/" + maxA[0];
        }
	this.calMaxBound = max;
        if(this.startDateCal){
		//if(this.startDate==null&&min!==null){
		if(min!==null){
			this.startDateCal.updatePage(new Date(min));
		}
                this.startDateCal.setBounds(min,max);
        }
        if(this.endDateCal){
		//if(this.endDate==null&&max!==null){
		if(max!==null){
			this.endDateCal.updatePage(new Date(max));
		}
                this.endDateCal.setBounds(min,max);
        }

};

/**
 * Returns the date as a string with or without time depending on this.type
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @param {Date} the date to be converted
 * @returns {String} formatted in ISO8601 date/datetime format
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.getString = function(d) {
    return d.toISO8601DateTimeString() + "Z";
};

/**
 * Returns the date string used in error messages; string format depends
 * on whether hours ar being used
 * 
 * @this {giovanni.widget.DateRangePicker}
 * @params {Date} the date to be converted
 * @return {String} formatted either in ISO8601 (Date only) or as the
 * user entered it (ISO8601 Date + hh 'hrs')
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.getDateTimeString = function (d) {
    var isoStr = d.toISO8601DateString();
    if(this.useHours && !this.useMinutes)
        isoStr = d.toISO8601DateHourString();
    else if (this.useMinutes)
        isoStr = d.toISO8601DateTimeString();
    return isoStr;
};

/**
 * Validates startDate and endDate
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @returns {giovanni.widget.ValidationResponse} true or false depending on if the date meets predetermined conditions with an explanation 
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.validate = function(){
	if (this.disabled === true){
            	this.setStatus("",false);
            	return new giovanni.widget.ValidationResponse(true,this.statusStr);
    	}
    	var nonEmptyStringTest = /\S+/;

    	// get the max and min temp res among the selected variables
    	// required when variables of diferent temporal resolutions are used in a service
      var maxTempResMinutes = session.dataSelector.variablePicker.getMaxTempRes();
      var minTempResMinutes = session.dataSelector.variablePicker.getMinTempRes();
    	
    	// Get start and end dates
    	var startDate = undefined;
    	var startDateStr = this.startDateTF.getValue();
        var startTimeStr = this.startTimeTF.getValue();
        if(startDateStr != ""){
	        startDateStr = startDateStr + "T" + startTimeStr;
        }
    	if (nonEmptyStringTest.test(startDateStr)) {
        	// Case of date field containing non-white space characters
        	// Parse the date
        	startDate = new Date();
        	if (!startDate.parse(startDateStr)) {
            		// For dates that are invalid, setStatus and return
			var msg = startDateStr + ' is not a valid date';
                        // report time errors
                        //if(this.startTimeTF.errMsg != ""){
                        //     msg = msg + ", " + this.startTimeTF.errMsg;
                        //}
            		this.setStatus(msg,true);
			this.hide();
			return new giovanni.widget.ValidationResponse(false,this.statusStr);
		}
    	}
        if (startDate === undefined) {
            // Start date is mandatory; make sure it exists. 
            if(this.maxRange != null && this.maxRange != 0){
                switch (maxTempResMinutes) {
                case 30: var numOfHalfHours = this.maxRange/1800/2;
                    this.setStatus("Please specify a start date. Maximum range is " + numOfHalfHours + " hour" + (numOfHalfHours > 1 ? 's' : ''),true);
                    break;
                case 60: var numOfHours = this.maxRange/3600;
                    this.setStatus("Please specify a start date. Maximum range is " + numOfHours + " hour" + (numOfHours > 1 ? 's' : ''),true);
                    break;
                case 180: var numOf3Hours = this.maxRange/10800;
                    this.setStatus("Please specify a start date. Maximum range is " + numOf3Hours + " 3-hour interval" + (numOf3Hours > 1 ? 's' : ''),true);
                    break;
                case 1440: var numOfDays = this.maxRange/86400;
                    this.setStatus("Please specify a start date. Maximum range is " + numOfDays + " day" + (numOfDays > 1 ? 's' : ''),true);
                    break;
                case 11520: var numOf8Days = this.maxRange/691200;
                    this.setStatus("Please specify a start date. Maximum range is " + numOf8Days + " 8-day interval" + (numOf8Days > 1 ? 's' : ''),true);
                    break;
                case 43800: var numOfMonths = this.maxRange/2628028;
                    this.setStatus("Please specify a start date. Maximum range is " + numOfMonths + " month" + (numOfMonths > 1 ? 's' : ''),true);
                    break;
                }
            }else{
                this.setStatus('Please specify a start date.',true);
            }
            return new giovanni.widget.ValidationResponse(false,this.statusStr);
        }

	if (this.range === false){
	    if (startDate !== undefined && this.minBound !== null && startDate < this.minMinBound){
	        this.setStatus("The start date must be " + this.getDateTimeString(this.minMinBound) + " or later",true);
		this.hide();
	        return new giovanni.widget.ValidationResponse(false,this.statusStr);
	    } 
	    if (startDate !== undefined && this.maxBounds !== null && startDate > this.maxMaxBound){
	        this.setStatus("The start date must be " + this.getDateTimeString(this.maxMaxBound) + " or earlier",true);
		this.hide();
	        return new giovanni.widget.ValidationResponse(false,this.statusStr);
	    }
        }

	var endDate = undefined;
	if (this.range === true) {
            var endDateStr = this.endDateTF.getValue();
	    if(endDateStr != ""){
	        //endDateStr = endDateStr + "T" + this.getHours('endHours') + ":00:00";
	        endDateStr = endDateStr + "T" + this.endTimeTF.getValue();
	    }
            if (nonEmptyStringTest.test(endDateStr)) {
                // Case of date field containing non-white space characters
                // Parse the date
                endDate = new Date();
                if (!endDate.parse(endDateStr)) {
			var msg = endDateStr + ' is not a valid date';
                        // report time errors
                        //if(this.endTimeTF.errMsg != ""){
                        //     msg =  msg + ", " + this.endTimeTF.errMsg;
                        //}
                        // For dates that are invalid, setStatus and return
                    	this.setStatus(msg,true);
		        return new giovanni.widget.ValidationResponse(false,this.statusStr);
	        } 
            }
            if (endDate === undefined) {
            	// If end date is not defined, warn and return
                if(this.maxRange != null && this.maxRange != 0){
                    switch (maxTempResMinutes) {
                    case 30: var numOfHalfHours = this.maxRange/1800/2;
                        this.setStatus("Please specify an end date. Maximum range is " + numOfHalfHours + " half hour" + (numOfHalfHours > 1 ? 's' : ''),true);
                        break;
                    case 60: var numOfHours = this.maxRange/3600;
                        this.setStatus("Please specify an end date. Maximum range is " + numOfHours + " hour" + (numOfHours > 1 ? 's' : ''),true);
                        break;
                    case 180: var numOf3Hours = this.maxRange/10800;
                        this.setStatus("Please specify an end date. Maximum range is " + numOf3Hours + " 3-hour interval" + (numOf3Hours > 1 ? 's' : ''),true);
                        break;
                    case 1440: var numOfDays = this.maxRange/86400;
                        this.setStatus("Please specify an end date. Maximum range is " + numOfDays + " day" + (numOfDays > 1 ? 's' : ''),true);
                        break;
                    case 11520: var numOf8Days = this.maxRange/691200;
                        this.setStatus("Please specify an end date. Maximum range is " + numOf8Days + " 8-day interval" + (numOf8Days > 1 ? 's' : ''),true);
                        break;
                    case 43800: var numOfMonths = this.maxRange/2628028;
                        this.setStatus("Please specify an end date. Maximum range is " + numOfMonths + " month" + (numOfMonths > 1 ? 's' : ''),true);
                        break;
                    }
                }else{
                   this.setStatus('Please specify an end date.',true);
                }
		return new giovanni.widget.ValidationResponse(false,this.statusStr);
            }

            // before we get to a lot of range validation, check to see whether all of the variables are climatology.
            // If so, we don't need an any range validation at this point.
            if(this.climFound && this.allClim){
                this.setStatus("",true);
	        return new giovanni.widget.ValidationResponse(true,"Climatology Only - no date range validation necessary at present");
            }

            // If start date is after end date, warn and return
            if (startDate !== undefined && endDate !== undefined && startDate > endDate) {
                this.setStatus("The start date " + this.getDateTimeString(startDate) 
                            + " cannot be later than the end date.",true);
			return new giovanni.widget.ValidationResponse(false,this.statusStr);
            }
	    if (endDate !== undefined) {
	      // setting minBound according to ServicePicker.isComparisonService() in setBounds(), so don't loop through the bounds here
	      //for (var i=0; i<this.minBounds.length; i++) {
	        if (endDate < this.minBound) {
	          this.setStatus("The end date must be " + this.getDateTimeString(this.minBound) + " or later",true);
	          return new giovanni.widget.ValidationResponse(false,this.statusStr);
	        }
	      //}
	    }
	    if (startDate !== undefined) {
	      // setting maxBound according to ServicePicker.isComparisonService() in setBounds(), so don't loop through the bounds here
	      //for (var i=0; i<this.maxBounds.length; i++) {
	        if (startDate > this.maxBound) {
	          this.setStatus("The start date must be " + this.getDateTimeString(this.maxBound) + " or earlier",true);
	          return new giovanni.widget.ValidationResponse(false,this.statusStr);
	        }
	      //}
	    }
	    
      // If max range is enforced, verify
	    var maxTempResSeconds = maxTempResMinutes * 60;
	    var totalRange = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * maxTempResSeconds)) * maxTempResSeconds;

	    // for monthly data, to handle cases where February is in the selected range of months, 
	    // add 2 days to the total range to compensate for February being less than average when calculated in minutes/seconds
	    if ( (maxTempResMinutes == 43800) | (minTempResMinutes == 43800) ) {  
	      totalRange += 2 * 24 * 60 * 60;
	    }
	    if ( this.maxRange !== 0 && totalRange > this.maxRange ) {
	      switch (maxTempResMinutes) {
	        case 30: var numOfHalfHours = this.maxRange/1800;
	          this.setStatus("The selected date range must be at most " + numOfHalfHours + " half-hour" + (numOfHalfHours > 1 ? 's' : ''),true);
	          break;
	        case 60: var numOfHours = this.maxRange/3600;
	          this.setStatus("The selected date range must be at most " + numOfHours + " hour" + (numOfHours > 1 ? 's' : ''),true);
	          break;
	        case 180: var numOf3Hours = this.maxRange/10800;
	          this.setStatus("The selected date range must be at most " + numOf3Hours + " 3-hour interval" + (numOf3Hours > 1 ? 's' : ''),true);
	          break;
	        case 1440: var numOfDays = this.maxRange/86400;
	          this.setStatus("The selected date range must be at most " + numOfDays + " day" + (numOfDays > 1 ? 's' : ''),true);
	          break;
	        case 11520: var numOf8Days = this.maxRange/691200;
	          this.setStatus("The selected date range must be at most " + numOf8Days + " 8-day interval" + (numOf8Days > 1 ? 's' : ''),true);
	          break;
	        case 43800: var numOfMonths = this.maxRange/2628028;
	          this.setStatus("The selected date range must be at most " + numOfMonths + " month" + (numOfMonths > 1 ? 's' : ''),true);
	          break;
	      }
	      return new giovanni.widget.ValidationResponse(false,this.statusStr);
	    }
	    // If min range is enforced, verify
	    if ( this.minRange !== 0 && totalRange < this.minRange ) {
        switch (minTempResMinutes) {
        case 30: var numOfHalfHours = this.minRange/1800/2;
          this.setStatus("The selected date range must be at least " + numOfHalfHours + " hour" + (numOfHalfHours > 1 ? 's' : ''),true);
          break;
        case 60: var numOfHours = this.minRange/3600;
          this.setStatus("The selected date range must be at least " + numOfHours + " hour" + (numOfHours > 1 ? 's' : ''),true);
          break;
        case 180: var numOf3Hours = this.minRange/10800;
          this.setStatus("The selected date range must be at least " + numOf3Hours + " 3-hour interval" + (numOf3Hours > 1 ? 's' : ''),true);
          break;
        case 1440: var numOfDays = this.minRange/86400;
          this.setStatus("The selected date range must be at least " + numOfDays + " day" + (numOfDays > 1 ? 's' : ''),true);
          break;
        case 11520: var numOf8Days = this.minRange/691200;
          this.setStatus("The selected date range must be at least " + numOf8Days + " 8-day interval" + (numOf8Days > 1 ? 's' : ''),true);
          break;
        case 43800: var numOfMonths = this.minRange/2628028;
          this.setStatus("The selected date range must be at least " + numOfMonths + " month" + (numOfMonths > 1 ? 's' : ''),true);
          break;
        }
        return new giovanni.widget.ValidationResponse(false,this.statusStr);
	    }
	}

        if(this.climFound && !this.allClim){
	    var startMon = this.startDateTF.getMonth();
            var endMon = this.endDateTF.getMonth();
            this.setStatus("Climatology variables will use only the selected month range, " +
		this.getMonthLabel( startMon )  + " (" + (startMon < 10 ? '0' + startMon : startMon) + ")" +
		" to " + 
		this.getMonthLabel( endMon ) + " (" + (endMon < 10 ? '0' + endMon : endMon) + ")", false);
        }else{ 
	    this.setStatus("",false);
        }

	return new giovanni.widget.ValidationResponse(true,this.statusStr);
};

/**
 * Returns the value of the start time and end time
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @returns {String} formatted in ISO8601 date/datetime standard and returned as 'starttime=&endtime='
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.getValue = function(start,end){
    var returnString = "";
    if(this.disabled === false ){
        if(!start && !end){
        	returnString = "starttime=&endtime=";
		if(this.type==="Date"){
			var startDateStr = this.startDateTF.getValue() + "T" + this.startTimeTF.getValue();
			this.startDate = startDateStr.split("T")[0] == "" ? null : this.setStartTime(startDateStr);
		}
	    	if(this.range === true){
		    // Make sure the end date ends at 23:59:59 (hh:mm:ss) 
            		if(this.type === "Date") { 
				var endDateStr = this.endDateTF.getValue() + "T" + this.endTimeTF.getValue();
				this.endDate = endDateStr.split("T")[0] == "" ? null : this.setEndTime(endDateStr);
			}		
			returnString = this.startDate==null ? "starttime=" : "starttime=" + this.getString(this.startDate);
			returnString += this.endDate==null ? 
				"&endtime=" : "&endtime=" + this.getString(this.endDate);
	    	}else{
			returnString = this.startDate==null ? "starttime=&endtime=" : "starttime=" + this.getString(this.startDate) + "&endtime=";
	    	}
        }else if(start) {
            returnString = this.startDateTF.getValue() + "T" + this.startTimeTF.getValue();
        }else if(end) {
            returnString = this.endDateTF.getValue() + "T" + this.endTimeTF.getValue();
        } 
    }
    return returnString;
};

giovanni.widget.DateRangePicker.prototype.getDaysInMonth = function (inYear,inMon) {
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
 * @this {giovanni.widget.DateRangePicker}
 * @param {Object} object contains two strings, startDateStr, endDateStr representing the start and end times to set, respectively 
 * @returns {giovanni.widget.ValidationResponse} whether the date validates or not with an explanation;
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setValue = function(dates) {
  var dateArr = new Array();
  var dStr, tStr = "";
  if (dates.startDateStr !== undefined && dates.startDateStr != "") {
    dateArr = dates.startDateStr.split("T");
    dStr = dateArr[0];
    if(dateArr.length <= 1){
      tStr = "00:00";
    }else if (dateArr.length > 1) {
      tStr = dateArr[1] ? dateArr[1] : "00:00";
    }
    this.startDateTF.setValue(dStr);
    this.startTimeTF.setValue(tStr);
    this.startDate = this.setStartTime(dates.startDateStr);
  }
  if (this.range === true && dates.endDateStr !== undefined && dates.endDateStr != "") {
    dateArr = dates.endDateStr.split("T");
    dStr = dateArr[0];
    if(dateArr.length <= 1){
      tStr = "23:59";
    }else if (dateArr.length > 1) {
      tStr = dateArr[1] ? dateArr[1] : "23:59";
    }
    this.endDateTF.setValue(dStr);
    this.endTimeTF.setValue(tStr);
    this.endDate = this.setEndTime(dates.endDateStr);
  }
  var valResp = this.validate();
  if (valResp.isValid()) {
    this.parentClass.fire();
    this.selectionEvent.fire();
  }
  return valResp;
};

/**
 * Sets the picker state back to it's initialization values
 *
 * @this (giovanni.widget.DateRangePicker}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.clearSelections = function () {
	// set text fields to blank
	this.startDateTF.clear();
	this.endDateTF.clear();
	// set calendar dates to min/max bounds respectively
	this.startDateCal.setValue(this.defaultMinBound);
	this.endDateCal.setValue(this.defaultMaxBound);
	// set hours handling
	this.useHours = false;
	//this.setHours('startHours','00');
	//this.setHours('endHours','23'); 
	this.startTimeTF.clear();
	this.endTimeTF.clear();
};

/**
 * Sets the picker value back to it's initialization values
 *
 * @this (giovanni.widget.DateRangePicker}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.resetSelections = function () {
  // if a URL was loaded, reload that value upon reset
  // if not, load the default value for the giovanni page
  var start = this.urlStartDateStr ? this.urlStartDateStr : this.defaultStartDateStr;
  var end = this.urlEndDateStr ? this.urlEndDateStr : this.defaultEndDateStr;
	this.setValue({'startDateStr':start,'endDateStr':end});
};

/**
 * sets dates given a query string
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @param {String} qs is in the format of starttime=&endtime= 
 * @returns {giovanni.widget.ValidationResponse} whether dates validate or not with an explanation
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.loadFromQuery = function(qs){
    var startDate = "";
    var endDate = "";
    startDate = giovanni.util.extractQueryValue(qs,"starttime");
    if (this.range === true && giovanni.util.extractQueryValue(qs,"endtime") !== "") {
        endDate  = giovanni.util.extractQueryValue(qs,"endtime");
    }
    this.setValue({"startDateStr":startDate,"endDateStr":endDate});
    
    this.urlStartDateStr = startDate;
    this.urlEndDateStr = endDate;
};

/**
 * Updates the component bounds based on dependencies in the registry
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @param {String} specifies additional parameters for the data source url to be fetched from in format starttime=&endtime= 
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.updateComponent = function(qs){
    if (typeof this.dataSourceUrl == "function") {
      this.dataSourceUrl(this, qs);
    } else if (typeof this.dataSourceUrl == "string") {
      var dataSourceUrl = this.dataSourceUrl + "?" + qs;
      this.setStatus("Updating date range based on data changes ... ",true);
  
      YAHOO.util.Connect.asyncRequest('GET', dataSourceUrl,
      { 
        success:giovanni.widget.DateRangePicker.fetchDataSuccessHandler,
        failure:giovanni.widget.DateRangePicker.fetchDataFailureHandler,
        argument: {self:this,format:"xml"}
      } );
    }
};

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 *      
 * @this {Giovanni.widget.DateRangePicker}
 * @param {String, String} contains the minBound and the maxBound
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setBounds = function(minBounds,maxBounds){

  var mindate = null;
  var maxdate = null;

  if(minBounds != null && maxBounds != null){ 
    if(minBounds.length > 1){
      var currentMin = minBounds[0];
      var currentMax = maxBounds[0];
      var isCompSvc = session.dataSelector.servicePicker.isComparisonService();
      if(isCompSvc){ // use INTERSECTION range for digital comparisons
        for(var i=0;i<minBounds.length;i++){
          if(minBounds[i] > currentMin){
	    currentMin = minBounds[i];
          }
        }
        for(var i=0;i<maxBounds.length;i++){
          if(maxBounds[i] < currentMax){
	    currentMax = maxBounds[i];
          }
        }
      }else{ // use UNION range for no comparisons OR visual comparision
             // BUT services are not yet read for UNION, so for now, this
             // will also be INTERSECTION
        for(var i=0;i<minBounds.length;i++){
          if(minBounds[i] > currentMin){ 
	    currentMin = minBounds[i];
          }
        }
        for(var i=0;i<maxBounds.length;i++){
          if(maxBounds[i] < currentMax){ 
	    currentMax = maxBounds[i];
          }
        }
      }
      mindate = currentMin;
      maxdate = currentMax;
    }else{
      mindate = minBounds[0];
      maxdate = maxBounds[0];
    }
  }

  var minparsetest = mindate ? new Date(mindate).parse(mindate) : null;
  var maxparsetest = maxdate ? new Date(maxdate).parse(maxdate) : null;

  if(mindate !== null) {
    if(!minparsetest){
      alert("Could not parse lower bound for date!");
    } else {
      if(this.type === "Date") {
        this.minBound = this.setStartTime(mindate);
      }
    }
  } else {
      this.minBound = this.defaultMinBound;
  }

  if(maxdate !== null) {
    if(!maxparsetest) {
      alert("Could not parse upper bound for date!");
    } else {
      if(this.type === "Date") {
        this.maxBound = this.setEndTime(maxdate);
      }
    }
  } else {
      this.maxBound = new Date();
  }

  if(this.startDate === null && this.minBound !== null) {
    this.startDate = this.minBound;
  }
  if(this.endDate === null && this.maxBound !== null) {
    this.endDate = this.maxBound;
  }

  this.updateCalendarBounds(mindate,maxdate);

  // set minMinBound and maxMaxBound?  Why are they different from minBound/maxBound?
  this.minMinBound = this.minBound;
  this.maxMaxBound = this.maxBound;

  this.showValidDateRange();

  return this.validate();
};

/** Shows the valid date range given the min/max bounds
 *
 * @this {Giovanni.widget.DateRangePicker}
 * @author Chocka/K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.showValidDateRange = function () {
  document.getElementById("dateRangeDisplay").innerHTML = (this.minMinBound==null?"":" Valid Range: "+(this.minMinBound.toISO8601DateTimeString().split('T')[0]+' to ')) +
                (this.maxMaxBound==null?"":this.maxMaxBound.toISO8601DateTimeString().split('T')[0]);
};

/**
 * sets the max range (in seconds) of the selectable dates
 *      
 * @this {Giovanni.widget.DateRangePicker}
 * @param {Number} the maxRange, in seconds, to set the selection to
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setMaxRange = function(maxRange){
    this.maxRange = (maxRange !== null)? maxRange:0;
    return this.validate();
};

/**
 * sets the min range (in seconds) of the selectable dates
 *      
 * @this {Giovanni.widget.DateRangePicker}
 * @param {Number} the minRange, in seconds, to set the selection to
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setMinRange = function(minRange){
    this.minRange = (minRange !== null)? minRange:0;
    return this.validate();
};

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.Connect}
 * @param {YAHOO Response Object} contains responseText and responseXML from remote request, and specified arguments
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation on if the start and end date were set based on the responseXML
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.fetchDataSuccessHandler = function(o){
    var self=o.argument["self"];
    try {
        var startDates = null;
    	var endDates = null;
        // if format is JSON
    	if(o.argument.format === "json") {
    	  var jsonData=YAHOO.lang.JSON.parse(o.responseText);
    	  startDates = (jsonData.startDate !== undefined)? jsonData.startDate:self.minBounds;
    	  endDates = (jsonData.endDate !== undefined)? jsonData.endDate:self.maxBounds;
          // set hour picker state
          self.setTimePickerState(jsonData.hourRequired,jsonData.minutesRequired);
          // set date picker state
	  self.setDatePickerState('json',jsonData);

    	} else { // if format is XML
    	  var xmlData = o.responseXML;
    	  var dateRange = xmlData.getElementsByTagName('dateRange')[0]; 
    	  startDates = (dateRange.attributes.getNamedItem("STARTDATE"))? dateRange.attributes.getNamedItem("STARTDATE").value : self.minBounds;
    	  endDates = (dateRange.attributes.getNamedItem("ENDDATE"))? dateRange.attributes.getNamedItem("ENDDATE").value : self.maxBounds; 
          var hoursRequired = dateRange.attributes.getNamedItem("HOURREQUIRED");
          var minutesRequired = dateRange.attributes.getNamedItem("MINUTESREQUIRED");
          // set hour picker state
          self.setTimePickerState(hoursRequired,minutesRequired);
          // set date picker state
          self.setDatePickerState('xml',dateRange);
    	}
    	self.setBounds(startDates,endDates);
    }
    catch(x)
    {
      alert("giovanni.widget.DateRangePicker:  Failed to load dates: " + x.message);
    }
};

/**
 * Handles the failure of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.connect}
 * @param {YAHOO Response Object} contains reason for the failure
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.fetchDataFailureHandler = function(o){
    alert("Could not retrieve data from specified data URL!");
};

/**
 * Set the data source url for retrieving updates to the bounds from updateComponent
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @param {String} url to set the dataSourceUrl property to
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setDataSourceUrl = function(url){
    this.dataSourceUrl = url;
};

/**
 * Returns the data source url for retrieving updates to the bounds from updateComponent
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @returns {String} the data source url
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.getDataSourceUrl = function(){
    return this.dataSourceUrl;
};

/**
 * Set the current status of the component
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @param {String, Boolean} the status string and whether it is an error or not 
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.setStatus = function(s,isError){
    this.statusStr = s;
    var statusDiv = document.getElementById('datePickerStatus');
    statusDiv.style.color = (isError === true)? "red":"green";
    statusDiv.innerHTML = "" + s + "&nbsp;";
};

/**
 * Fetches the current status of the component
 *      
 * @this {giovanni.widget.DateRangePicker}
 * @returns {String} the status string
 * @author T. Joshi 
 */
giovanni.widget.DateRangePicker.prototype.getStatus = function(){
    return this.statusStr;
};

giovanni.widget.DateRangePicker.prototype.setStartTime = function(dateStr) {
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
                var minutes = sdate.getUTCMinutes();
		sdate = new Date(Date.UTC(yr, mon, day, hour, minutes, 0,0));
	}
	return sdate;
};

giovanni.widget.DateRangePicker.prototype.setEndTime = function(dateStr) {
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
                var minutes = sdate.getUTCMinutes();
		sdate = new Date(Date.UTC(yr, mon, day, hour, minutes, 59,999));
	}  
	return sdate;
};

/**
 * Returns the ID for this picker, which is the ID of the HTML element 
 * containing this picker
 *
 * @this {giovanni.widget.DateRangePicker}
 * @author Chocka
 */
giovanni.widget.DateRangePicker.prototype.getId = function () {
  return this.containerId;
};

/*
 * If any of the calendars are displayed, hide them; used when switching back to the data selector
 *
 * @this {giovanni.widget.DateRangePicker}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.hide = function () {
  if(this.startDateCal != null && this.startDateCal.dialog != undefined && this.startDateCal.dialog.cfg.getProperty("visible")){
      this.startDateCal.hide();
  }
  if(this.endDateCal != null && this.endDateCal.dialog != undefined && this.endDateCal.dialog.cfg.getProperty("visible")){
      this.endDateCal.hide();
  }
};

/*
 * Sets whether hours selection is enabled or disabled; if the hours are disabled, sets
 * the appropriate start and end hour values for non-hourly data (00 and 23, respectively)
 *
 * @this {giovanni.widget.DateRangePicker}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.setTimePickerState = function (enableHours,enableMinutes) {
    this.startTimeTF.setState(enableHours,enableMinutes);
    this.endTimeTF.setState(enableHours,enableMinutes);
};

/*
 * Configures the picker to select monthly data (hours and days disabled); sets appropriate
 * values for disabled start and end days, based on selected month in the case of end days
 *
 * @this {giovanni.widget.DateRangePicker}
 * @params {boolean}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.prototype.setDatePickerState = function (type,data) {
    // find out if we need to enabel the 'month-only' mode
    var monthEnable = type == 'json' ? data.monthOnlyRequired : data.attributes.getNamedItem("MONTHREQUIRED");
    if(monthEnable==undefined) monthEnable = false;
    this.monthDataOnly = monthEnable;

    // determine if climatology is selected
    var climCount = 0;
    var climFound = false;
    var allClim = false;
    var minBasePeriod = null;
    var maxBasePeriod = null;

    // grab the variable picker from the session (NEED A UI STATE config object here instead)
    // and find out if 
    //   a) any of the selected variables is a climatology variable and 
    //   b) if ALL of the selected variables are climatology variables
    // ALSO, set the base period range just in case we need it to set the picker date range value
    var selectedVars = session.dataSelector.variablePicker.fs.selectedVariables;
    if(selectedVars){ // loop through the selected variables
        for (var i = 0; i < selectedVars.length; i++) {
            // the climatology flag is located under data.dataProductSpecialFeatures, if present
	    if( selectedVars[i].data.dataProductSpecialFeatures &&
                selectedVars[i].data.dataProductSpecialFeatures.constructor === Array  &&
                selectedVars[i].data.dataProductSpecialFeatures.length > 0 ){
                var specialFeatures = selectedVars[i].data.dataProductSpecialFeatures;
                for(var j=0;j<specialFeatures.length;j++){
                    if(specialFeatures[j]=='climatology'){
                        climCount++; // increment climatology count
                        // set the min and max base periods
                        if( !minBasePeriod || new Date(selectedVars[i].data.dataProductBeginDateTime).getTime() < minBasePeriod.getTime() )
                            minBasePeriod = new Date( selectedVars[i].data.dataProductBeginDateTime );
                        if( !maxBasePeriod || new Date(selectedVars[i].data.dataProductEndDateTime).getTime() > maxBasePeriod.getTime() )
                            maxBasePeriod = new Date( selectedVars[i].data.dataProductEndDateTime );
                    }
                }
            }
        }
    }
    // set the climatology flags baesd on climCount
    if(climCount>0) climFound = true;
    if(climFound && (climCount == selectedVars.length)) allClim = true;
    // update the class climatology variables so we can use them in validate()
    this.climFound = climFound;
    this.allClim = allClim;

    if(this.startDateCal) this.startDateCal.setMonthOnly(monthEnable);
    if(this.endDateCal) this.endDateCal.setMonthOnly(monthEnable);
    // set date picker state accordingly
    if(monthEnable){ 
        // set month flag on calendars
        //this.startDateCal.setMonthOnly(monthEnable);
        //this.endDateCal.setMonthOnly(monthEnable);
        this.startDateTF.enableDay(!monthEnable);
        this.endDateTF.enableDay(!monthEnable);
        // change hint to show 'YYYY-mm' as the valid format
        document.getElementById('datePickerHint').innerHTML = "YYYY-MM";
	// change valid range?
        // set picker value to the appropriate date for start and end values
        if(this.startDate){
	    this.startDate.setUTCDate('01');
	    //this.setHours('startHours','00');
	    this.startDate.setUTCHours('00');
            this.startDate.setUTCMinutes('00');
	}
	if(this.endDate){
	    this.endDate.setUTCDate(this.getDaysInMonth(this.endDateTF.getYear(),this.endDateTF.getMonth()));
	    //this.setHours('endHours','23');
            this.endDate.setUTCHours('23');
            this.endDate.setUTCMinutes('59');
	}
	// set picker value
	if(this.startDate&&this.endDate){
            this.setValue({'startDateStr':this.getString(this.startDate),'endDateStr':this.getString(this.endDate)});
	    if(this.startDateCal){
	        this.startDateCal.setValue(this.startDate);
                //this.startDateCal.setMonthOnly(enable);
	    }
	    if(this.endDateCal){
	        this.endDateCal.setValue(this.endDate);
                //this.endDateCal.setMonthOnly(enable);
	    }
	}
        // validation should allow entry without day/date
        // set calendar to use only year and month
    }else{
        document.getElementById('datePickerHint').innerHTML = "YYYY-MM-DD";
        this.startDateTF.enableYear(true);
        this.endDateTF.enableYear(true);
        this.startDateTF.enableDay(true);
        this.endDateTF.enableDay(true);
	document.getElementById("startDateCalendarLink").style.visibility = "visible";
	document.getElementById("endDateCalendarLink").style.visibility = "visible";
	if(this.startDateCal){
	    this.startDateCal.setValue(this.startDate);
            //this.startDateCal.setMonthOnly(enable);
	}
	if(this.endDateCal){
	    this.endDateCal.setValue(this.endDate);
            //this.endDateCal.setMonthOnly(enable);
	}
    }

    // set the UI based on climatology flags
    if(allClim){ // all variables are climatology
        this.startDateTF.enableYear(false);
        this.endDateTF.enableYear(false);
        this.startDateTF.enableDay(false);
        this.endDateTF.enableDay(false);
        //if(this.startDateCal) this.startDateCal.enableYear(false);
        //if(this.endDateCal) this.endDateCal.enableYear(false);
	document.getElementById("startDateCalendarLink").style.visibility = "hidden";
	document.getElementById("endDateCalendarLink").style.visibility = "hidden";
        document.getElementById('datePickerHint').innerHTML = "MM";

        // if there is no date range set, use the union of the variable base periods
        //if(this.startDateTF.getValue() == "") {
	//    this.startDateTF.setValue( minBasePeriod.toISO8601DateString() );
        //}
        //if(this.endDateTF.getValue() == "") {
        //    this.endDateTF.setValue( maxBasePeriod.toISO8601DateString() );
        //}

    }else if(climFound&&!allClim){ // some but not all selected variables are climatology
        this.startDateTF.enableYear(true);
        this.endDateTF.enableYear(true);
        //if(this.startDateCal) this.startDateCal.enableYear(true);
        //if(this.endDateCal) this.endDateCal.enableYear(true);
	document.getElementById("startDateCalendarLink").style.visibility = "visible";
	document.getElementById("endDateCalendarLink").style.visibility = "visible";
        // if there are non-monthly variables, make sure the day text field is enabled
	if(!monthEnable){
            this.startDateTF.enableDay(true);
            this.endDateTF.enableDay(true);
            document.getElementById('datePickerHint').innerHTML = "YYYY-MM-DD";
        }else{
            document.getElementById('datePickerHint').innerHTML = "YYYY-MM";
	}
    }

};

giovanni.widget.DateRangePicker.prototype.setDisabled = function (disabled) {
    this.disabled = disabled;
    if(disabled){
      this.container.style.display = 'none';
    }else{
      this.container.style.display = 'inline-block';
    }
    this.hide();
}


/* 
 * Create the picker text field, a multi-part control containing three HTML <input> elements,
 * one each for year, month, and day
 *
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {giovanni.widget.DateRangePicker,HTML Element, String}
 * @return {giovanni.widget.DateRangePicker.TextField}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField = function (picker,container,dateStr) {
    this.datePicker = picker;
    this.container = container;
    this.dateStr = dateStr;
    this.year = "";
    this.month = "";
    this.day = "";
    var dArr = [];
    if(dateStr!=null&&dateStr!=""){
	dArr = dateStr.split("-");
        this.year = dArr[0];
	this.month = dArr[1];
	this.day = dAr[2];
    } 
    this.render();
};

/*
 * Build the controls; includes adding the appropriate listeners to handle keyboard input
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.render = function () {
    var yElm = document.createElement("input");
    yElm.setAttribute('id',this.container.id+'_year');
    yElm.setAttribute('type','text');
    yElm.setAttribute('size','4');
    yElm.setAttribute('maxlength','4');
    yElm.setAttribute('value',this.year);
    yElm.setAttribute('class','textFieldInput');
    yElm.style.width = '2.5em';
    var mElm = document.createElement("input");
    mElm.setAttribute('id',this.container.id+'_month');
    mElm.setAttribute('type','text');
    mElm.setAttribute('size','2');
    mElm.setAttribute('maxlength','2');
    mElm.setAttribute('value',this.month);
    mElm.setAttribute('class','textFieldInput');
    mElm.style.width = '1.5em';
    var dElm = document.createElement("input");
    dElm.setAttribute('id',this.container.id+'_day');
    dElm.setAttribute('type','text');
    dElm.setAttribute('size','2');
    dElm.setAttribute('maxlength','2');
    dElm.setAttribute('value',this.day);
    dElm.setAttribute('class','textFieldInput');
    dElm.style.width = '1.5em';
    var separator = document.createElement('div');
    separator.setAttribute('id',this.container.id+'_ym_sep');
    separator.setAttribute('class','dateFieldSeparator');
    separator.innerHTML = "-";
    var separator1 = document.createElement('div');
    separator1.setAttribute('id',this.container.id+'_md_sep');
    separator1.setAttribute('class','dateFieldSeparator');
    separator1.innerHTML = "-";
    this.container.appendChild(yElm);
    this.container.appendChild(separator);
    this.container.appendChild(mElm);
    this.container.appendChild(separator1);
    this.container.appendChild(dElm);

    // add event handles to year field
    YAHOO.util.Event.addListener(this.container.id+"_year","change",this.handleYearChange,{datePicker:this.datePicker,self:this});
    YAHOO.util.Event.addListener(this.container.id+"_year","keyup",this.handleYearEntry,{datePicker:this.datePicker,self:this});
    YAHOO.util.Event.addListener(this.container.id+"_year","keydown",this.handleKeyDown,{datePicker:this.datePicker,self:this});
    // add event handlers to month field
    YAHOO.util.Event.addListener(this.container.id+"_month","change",this.handleMonthChange,{datePicker:this.datePicker,self:this});
    YAHOO.util.Event.addListener(this.container.id+"_month","keyup",this.handleMonthEntry,{datePicker:this.datePicker,self:this});
    YAHOO.util.Event.addListener(this.container.id+"_month","keydown",this.handleKeyDown,{datePicker:this.datePicker,self:this});
    // add event handlers to day field
    YAHOO.util.Event.addListener(this.container.id+"_day","change",this.handleDayChange,{datePicker:this.datePicker,self:this});
    YAHOO.util.Event.addListener(this.container.id+"_day","keydown",this.handleKeyDown,{datePicker:this.datePicker,self:this});
};

/*
 * Set the year value
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.setYear = function (year) {
    this.year = year;
};
/*
 * Set the month value
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.setMonth = function (month) {
    this.month = month;
};
/*
 * Set the day value
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.setDay = function (day) {
    this.day = day + "";
};
/*
 * Get the year value
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.getYear = function () {
    return parseInt(this.year);
};
/*
 * Get the month value
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.getMonth = function () {
    return parseInt(this.month);
};
/*
 * Get the day value
 * 
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.getDay = function () {
    return parseInt(this.day);
};

/*
 * Sets the value of the control 
 *
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @praams {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.setValue = function (dateStr) {
  if(dateStr!=""){
    var dArr = dateStr.split("-");
    this.year = dArr[0];
    this.month = dArr[1];
    this.day = dArr[2];
  }else{
    // UPDATE: if the date is to be set to empty, the individual
    // parts have to be set to empty
    this.year = '';
    this.month = '';
    this.day = '';
  }
  document.getElementById(this.container.id+"_year").value = this.year;
  document.getElementById(this.container.id+"_month").value = this.month;
  if(this.datePicker.monthDataOnly && this.month != ''){
    if(this.container.id.indexOf('start')>-1){
      this.day = "01";
    }else if(this.container.id.indexOf('end')>-1){
      this.day = this.datePicker.getDaysInMonth(this.year,this.month) + "";
    }
  }
  document.getElementById(this.container.id+"_day").value = this.day;
};

/*
 * Gets the value of the control 
 *
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @praams {}
 * @return {String}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.getValue = function () {
    var val = "";
    if(this.year != "" && this.month != "" && this.day != ""){
        val = this.year + "-" + this.month + "-" + this.day;
    }
    return val;
};

/*
 * Handles changes to the year field; fires after the maxlength is reached
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleYearChange = function(evt,o) {
    // Don't bother if date element is not defined
    var target = giovanni.util.getTarget(evt);
    if (target) {
        // Validate date
        o.self.setYear(target.value);
        // UPDATE: if the date is not complete (missing any of the 3, year/month/day)
        // don't set the picker's and caleandar's value yet
        var dateValue = o.self.getValue();
        if (dateValue) {
          if(target.id.indexOf('start')>-1){
              o.datePicker.setValue({startDateStr:dateValue+'T'+o.datePicker.startTimeTF.getValue()});
              o.datePicker.startDateCal.setValue(o.datePicker.startDate);
          }
          if(target.id.indexOf('end')>-1){
              o.datePicker.setValue({endDateStr:dateValue+'T'+o.datePicker.endTimeTF.getValue()});
              o.datePicker.startDateCal.setValue(o.datePicker.endDate);
          }
        }
    }
};

/*
 * Handles keystrokes in the year field
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleYearEntry = function (evt,o) {
    var target = giovanni.util.getTarget(evt);
    if (o.self.isNumber(evt) && target.value && target.value.length == target.size){
	//o.self.handleYearChange(evt,o);
        document.getElementById(o.self.container.id+"_month").focus();
    }
};

/*
 * Handles changes to the month field; fires after the maxlength is reached
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleMonthChange = function(evt,o) {
    // Don't bother if date is not defined
    var target = giovanni.util.getTarget(evt);
    if (target) {
        // Validate date
        o.self.setMonth(target.value);
        // UPDATE: if the date is not complete (missing any of the 3, year/month/day)
        // don't set the picker's and caleandar's value yet
        var dateValue = o.self.getValue();
        if (dateValue) {
          if(target.id.indexOf('start')>-1){
              // update parent (date range) picker value
              o.datePicker.setValue({startDateStr:dateValue+'T'+o.datePicker.startTimeTF.getValue()});
              // update calendar value
              o.datePicker.startDateCal.setValue(o.datePicker.startDate);
          }
          if(target.id.indexOf('end')>-1){
              o.datePicker.setValue({endDateStr:dateValue+'T'+o.datePicker.endTimeTF.getValue()});
              o.datePicker.startDateCal.setValue(o.datePicker.endDate);
          }
        }
    }
};

/*
 * Handles keystrokes in the month field
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleMonthEntry = function (evt,o) {
    var target = giovanni.util.getTarget(evt);
    if (o.self.isNumber(evt) && target.value && target.value.length == target.size) {

        if(o.datePicker.allClim){
          if(o.self.container.id.indexOf("start")>-1){
            o.self.setYear( new Date(o.datePicker.minBound.toISO8601DateString()).getUTCFullYear() );
            o.self.setDay( new Date(o.datePicker.minBound.toISO8601DateString()).getUTCDate() );
          }else{
            o.self.setYear( new Date(o.datePicker.maxBound.toISO8601DateString()).getUTCFullYear() );
            o.self.setDay( new Date(o.datePicker.maxBound.toISO8601DateString()).getUTCDate() );
          }
          if(o.self.container.id.indexOf("start")>-1){
            document.getElementById("endContainer_month").focus();
          }
        }else if(o.datePicker.monthDataOnly){
          document.getElementById(o.self.container.id+"_day").focus();
          if(o.self.container.id.indexOf('end')>-1){
            o.self.setDay( o.datePicker.getDaysInMonth(o.self.getYear(),o.self.getMonth()-1) );
            o.datePicker.setValue({endDateStr:o.self.getValue()});
            o.datePicker.startDateCal.setValue(o.datePicker.endDate);
          }else{
            o.self.setDay( '01' );
            o.datePicker.setValue({startDateStr:o.self.getValue()});
            o.datePicker.startDateCal.setValue(o.datePicker.startDate);
          }
        }else{
          document.getElementById(o.self.container.id+"_day").focus();
        }

    }
};

/*
 * Handles changes to the day field; fires after the maxlength is reached
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleDayChange = function(evt,o) {
    // Don't bother if date is not defined
    var target = giovanni.util.getTarget(evt);
    if (target) {
        // Validate date
        o.self.setDay(target.value);
        //var startStr = o.datePicker.startDate.toISO8601DateTimeString();
        //var endStr = o.datePicker.endDate.toISO8601DateTimeString();
        // set picker value and calendar value
        if(target.id.indexOf('start')>-1){
            o.datePicker.setValue({startDateStr:o.self.getValue()+'T'+o.datePicker.startTimeTF.getValue()});
	    //o.datePicker.startDate.setUTCDate(target.value);
            //o.datePicker.setValue({startDateStr:startStr+'Z'});
            o.datePicker.startDateCal.setValue(o.datePicker.startDate);
        }
        if(target.id.indexOf('end')>-1){
            //o.datePicker.setValue({endDateStr:o.self.getValue()});
            //o.datePicker.setValue({endDateStr:endStr+'Z'});
	    //o.datePicker.endDate.setUTCDate(target.value);
            o.datePicker.setValue({endDateStr:o.self.getValue()+'T'+o.datePicker.endTimeTF.getValue()});
            o.datePicker.endDateCal.setValue(o.datePicker.endDate);
        }
    }
};

/*
 * Handles keystrokes in the day field
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleDayEntry = function (evt,o) {
    var target = o.self.getTarget(evt);
    if (target.value && target.value.length == target.size) {
        document.getElementById(o.self.container.id+"_day").blur();
    }
};

/*
 * Handles keydown events, mainly by checking whether a particular key event is allowed. 
 * Used by the year, month and day text fields
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.handleKeyDown = function (evt,o) {
    // At this point, just check to make sure it's a number
    //if(!o.self.isNumber(evt)){
    if(evt.keyCode == 189){ // at this point, just check for dashes/hyphen's
        YAHOO.util.Event.stopEvent(evt);
    }
};

/* 
 * Makes sure this is a key event we want 
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event}
 * @return {boolean}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.isNumber = function (evt) {
    // check for numbers, cursor controls (left-arrow, etc.), tab, backspace, insert, delete, carriage return - everything else is bad
    //var whiteList = [ 13,16,37,38,39,40,45,46,48,49,50,51,52,53,54,55,56,57,96,97,98,99,100,101,102,103,104,105 ];
    var whiteList = [ 48,49,50,51,52,53,54,55,56,57,96,97,98,99,100,101,102,103,104,105 ];
    var good = false;
    for(var i=0;i<whiteList.length;i++){
        if(evt.keyCode == whiteList[i] ||
	   (evt.keyCode == whiteList[i] && evt.shiftKey) ) {
            good = true;
	    break;
        }
    }
    return good;
};

/*
 * Enables or disables the day field (based on whether the picker is set for monthly data only - 
 * this happens as the result of the user selecting only monthly data from the variable picker
 *
 * @this {giovanni.widget.DateRangePicker.TextField}
 * @params {boolean}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.enableDay = function (bool) {
    if(bool){
        document.getElementById(this.container.id+"_day").readOnly = false;
        document.getElementById(this.container.id+"_day").style.color = '#000';
        document.getElementById(this.container.id+"_day").style.backgroundColor = '#fff';
	document.getElementById(this.container.id+"_md_sep").style.color = "#000"; 
    }else{
        document.getElementById(this.container.id+"_day").readOnly = true;
        document.getElementById(this.container.id+"_day").style.color = '#bbb';
        if(this.datePicker.allClim) document.getElementById(this.container.id+"_day").style.backgroundColor = '#bbb';
	document.getElementById(this.container.id+"_md_sep").style.color = "#aaa"; 
    }
};

giovanni.widget.DateRangePicker.TextField.prototype.enableYear = function (bool) {
    if(bool){
        document.getElementById(this.container.id+"_year").readOnly = false;
        document.getElementById(this.container.id+"_year").style.color = '#000';
        document.getElementById(this.container.id+"_year").style.backgroundColor = '#fff';
	document.getElementById(this.container.id+"_ym_sep").style.color = "#000"; 
    }else{
        document.getElementById(this.container.id+"_year").readOnly = true;
        document.getElementById(this.container.id+"_year").style.color = '#bbb';
        document.getElementById(this.container.id+"_year").style.backgroundColor = '#bbb';
	document.getElementById(this.container.id+"_ym_sep").style.color = "#aaa"; 
    }
};

/*
 * Sets the year, month, and day fields to be blank
 *
 * @this {giovanni.widget.DateRangePicker.TextField} 
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.clear = function () {
    this.year = "";
    this.month = "";
    this.day = "";
    document.getElementById(this.container.id+"_year").value = this.year;
    document.getElementById(this.container.id+"_month").value = this.month;
    document.getElementById(this.container.id+"_day").value = this.day;
};


giovanni.widget.DateRangePicker.TimeTextField = function (picker,container,timeStr) {
    this.datePicker = picker;
    this.container = container;
    this.timeStr = timeStr;
    this.hours = "";
    this.minutes = "";
    this.seconds = "00";
    var tArr = [];
    if(timeStr!=null&&timeStr!=""){
        tArr = timeStr.split(":");
        this.hours = tArr[0];
        this.minutes = tArr[1];
        this.seconds = tArr[2] ? tArr[2] : '00';
    }
    this.errMsg = "";
    this.render();
};

giovanni.widget.DateRangePicker.TimeTextField.prototype.render = function () {
    var hElm = document.createElement("input");
    hElm.setAttribute('id',this.container.id+'_hours');
    hElm.setAttribute('type','text');
    hElm.setAttribute('size','2');
    hElm.setAttribute('maxlength','2');
    hElm.setAttribute('value',this.hours);
    hElm.setAttribute('class','textFieldInput textFieldInputDisabled');
    hElm.setAttribute('disabled',true);
    hElm.style.width = '1.5em';
    var mElm = document.createElement("input");
    mElm.setAttribute('id',this.container.id+'_minutes');
    mElm.setAttribute('type','text');
    mElm.setAttribute('size','2');
    mElm.setAttribute('maxlength','2');
    mElm.setAttribute('value',this.minutes);
    mElm.setAttribute('class','textFieldInput textFieldInputDisabled');
    mElm.setAttribute('disabled',true);
    mElm.style.width = '1.5em';
    //mElm.setAttribute('title','Valid values: 00, 30');
    var separator = document.createElement('div');
    separator.setAttribute('id',this.container.id+'_hm_sep');
    separator.setAttribute('class','dateFieldSeparator');
    separator.innerHTML = ":";
    this.container.appendChild(hElm);
    this.container.appendChild(separator);
    this.container.appendChild(mElm);

    // add event handles to hours field
    YAHOO.util.Event.addListener(this.container.id+"_hours","change",this.handleChange,{datePicker:this.datePicker,self:this});
    //YAHOO.util.Event.addListener(this.container.id+"_hours","keyup",this.handleEntry,{datePicker:this.datePicker,self:this});
    //YAHOO.util.Event.addListener(this.container.id+"_hours","keydown",this.handleKeyDown,{datePicker:this.datePicker,self:this});
    // add event handlers to minutes field
    YAHOO.util.Event.addListener(this.container.id+"_minutes","change",this.handleChange,{datePicker:this.datePicker,self:this});
    //YAHOO.util.Event.addListener(this.container.id+"_minutes","keyup",this.handleEntry,{datePicker:this.datePicker,self:this});
    //YAHOO.util.Event.addListener(this.container.id+"_minutes","keydown",this.handleKeyDown,{datePicker:this.datePicker,self:this});

}

/*
 * Set the hours value
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.setHours = function (hours) {
    this.hours = hours;
    document.getElementById(this.container.id+"_hours").value = hours;
};
/*
 * Set the minutes value
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.setMinutes = function (minutes) {
    this.minutes = minutes;
    document.getElementById(this.container.id+"_minutes").value = minutes;
};

/*
 * Set the seconds value
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.setSeconds = function (seconds) {
    this.seconds = seconds + "";
};

/*
 * Get the hours value
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.getHours = function () {
    return parseInt(this.hours);
};
/*
 * Get the minutes value
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.getMinutes = function () {
    return parseInt(this.minutes);
};
/*
 * Get the seconds value
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TextField.prototype.getSeconds = function () {
    return parseInt(this.seconds);
}

/*
 * Sets the value of the control
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @praams {String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.setValue = function (timeStr) {
  if(timeStr!=""){
    var tArr = timeStr.split(":");
    this.hours = tArr[0];
    this.minutes = tArr[1];
    this.seconds = '00';
  }else{
    // UPDATE: if the date is to be set to empty, the individual
    // parts have to be set to empty
    this.hours = '';
    this.minutes = '';
    this.seconds = '00';
  }

  this.setHours(this.hours);
  this.setMinutes(this.minutes);;

}

/*
 * Gets the value of the control
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @praams {}
 * @return {String}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.getValue = function () {
    var val = "";
    if(this.hours != "" && this.minutes != "" && this.seconds != ""){
        val = this.hours + ":" + this.minutes + ":" + this.seconds;
    }
    return val;
};

/*
 * Handles changes to the year field; fires after the maxlength is reached
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.handleChange = function(evt,o) {
    // Don't bother if date is not defined
    //var target = o.self.getTarget(evt);
    o.self.errMsg = "";
    var target = giovanni.util.getTarget(evt);
    var targetName = target.id.split("_")[1];
    if (target) {

        // check to see if value is ok; if so, process, if not, show status
        var tval = target.value;
        if( tval != null && !isNaN(tval) ){
           // pad with a leading zero if necessary
           if(tval.length == 1){
               tval = '0' + tval;
               target.value = tval;
           }
        }else{
            // is not a valid entry - grab the last part of the element id to show minutes or hours in the message
            if(o.self.errMsg=="")
                o.self.errMsg = target.value + " is not a valid entry for "+target.id.split("_")[1];
            else
                o.self.errMsg = o.self.errMsg + ", " + target.value + " is not a valid entry for "+target.id.split("_")[1];
        
        }

           // set class member values
           if(targetName=='hours')
               o.self.setHours(tval);
           else if(targetName=='minutes')
               o.self.setMinutes(tval);

           // fetch value and set on overal date
           var val = o.self.getValue();
           //val = parseInt(val) < 10 && val.length == 1 ? '0' + val : val;
           //o.self.setValue(val);
           if(target.id.indexOf('start')>-1){
               var startDate;
               if(o.datePicker.startDate) {
                   startStr = o.datePicker.startDate.toISO8601DateString();
                   o.datePicker.setValue({startDateStr:startStr+'T'+val});
               }else{
                   startStr = o.datePicker.getValue(true);
                   o.datePicker.setValue({startDateStr:startStr});
               }

               //o.datePicker.startDateCal.setValue(o.datePicker.startDate);
           }
           if(target.id.indexOf('end')>-1){
               var endStr;
               if(o.datePicker.endDate) {
                   endStr = o.datePicker.endDate.toISO8601DateString(); // get the start date
                   o.datePicker.setValue({endDateStr:endStr+'T'+val});
                   // from the internal classes (TextField and TimeTextField respectively)
               }else{
                   endStr = o.datePicker.getValue(false,true); // get the end date
                   o.datePicker.setValue({endDateStr:endStr});
                   // from the internal classes (TextField and TimeTextField respectively)
               }

               //o.datePicker.startDateCal.setValue(o.datePicker.endDate);
           }
    }
};

/*
 * Handles keystrokes in the text fields
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.handleEntry = function (evt,o) {
    var target = giovanni.util.getTarget(evt);

    // what about BAD keystrokes?
    if (o.self.isNumber(evt) && target.value && target.value.length <= target.size && target.value.length > 0){
        if(target.id.indexOf('hours')>-1){
            if(!isNaN(target.value) && parseInt(target.value) >= 0 && parseInt(target.value) <= 23){
                o.self.setHours(target.value);
                target.style.color = 'black';
                o.self.handleChange(evt,o);
            }else{
                o.self.datePicker.setStatus(target.value + " is not a valid entry for hours",true);
                //target.value = o.self.getHours() < 10 ? '0' + o.self.getHours() : o.self.getHours();
            }
        }else if(target.id.indexOf('minutes')>-1){
            if(!isNaN(target.value) && parseInt(target.value) >= 0 && parseInt(target.value) <= 60){
                o.self.setMinutes(target.value);
                o.self.handleChange(evt,o);
            }else{
                o.self.datePicker.setStatus(target.value + " is not a valid entry for minutes",true);
                //target.value = o.self.getMinutes() < 10 ? '0' + o.self.getMinutes() : o.self.getMinutes();
            }
	}
    }
};

/*
 * Handles keydown events, mainly by checking whether a particular key event is allowed.
 * Used by the year, month and day text fields
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.handleKeyDown = function (evt,o) {
    // At this point, just check to make sure it's a number
    //if(!o.self.isNumber()){
    if(o.self.isNumber() && evt.keyCode == 189) {
        YAHOO.util.Event.stopEvent(evt);
    }else{
      // status?
      o.self.datePicker.setStatus(target.value + " is not a valid entry for minutes",true);
    }
};

/*
 * Makes sure this is a key event we want
 *
 * @this {YAHOO.util.Event}
 * @params {YAHOO.util.Event}
 * @return {boolean}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.isNumber = function (evt) {
    var whiteList = [ 48,49,50,51,52,53,54,55,56,57,96,97,98,99,100,101,102,103,104,105 ];
    var good = false;
    for(var i=0;i<whiteList.length;i++){
        if(evt.keyCode == whiteList[i] ||
           (evt.keyCode == whiteList[i] && evt.shiftKey) ) {
            good = true;
            break;
        }
    }
    return good;
};

/*
 * Sets the year, month, and day fields to be blank
 *
 * @this {giovanni.widget.DateRangePicker.TimeTextField}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.DateRangePicker.TimeTextField.prototype.clear = function () {
    this.hours = "";
    this.minutes = "";
    this.seconds = "";
    document.getElementById(this.container.id+"_hours").value = this.year;
    document.getElementById(this.container.id+"_minutes").value = this.month;
};


giovanni.widget.DateRangePicker.TimeTextField.prototype.setState = function (enableHours,enableMinutes) {
    var hElm = document.getElementById(this.container.id+"_hours");
    var mElm = document.getElementById(this.container.id+"_minutes");
    if(enableHours){
        this.datePicker.useHours = true;
        hElm.readOnly = false;
        hElm.disabled = false;
        hElm.style.color = '#000';
        hElm.style.backgroundColor = '#fff';
    }else{
        this.datePicker.useHours = false;
        hElm.readOnly = true;
        hElm.disabled = true;
        hElm.style.color = '#bbb';
    }

    if(enableMinutes){
        this.datePicker.useMinutes = true;
        mElm.readOnly = false;
        mElm.disabled = false;
        mElm.style.color = '#000';
        mElm.style.backgroundColor = '#fff';
        document.getElementById(this.container.id+"_hm_sep").style.color = "#000";
    }else{
        this.datePicker.useMinutes = false;
        mElm.readOnly = true;
        mElm.disabled = true;
        mElm.style.color = '#bbb';
        document.getElementById(this.container.id+"_hm_sep").style.color = "#aaa";
    }
};

