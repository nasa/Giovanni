//Calendar.js,v 1.3 2011/03/15 15:51:07 mhegde Exp
//-@@@ SSW, Version SSW_0_08
/**
 * Create Calendar for date or date-time selection
 */
giovanni.namespace("widget");

/**
 * Creates the Giovanni.widget.Calendar object.
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {String, Configuration}
 * @returns {Giovanni.widget.Calendar} 
 * @author M. Hegde 
 */
giovanni.widget.Calendar=function(containerId,config)
{
	
	//Get the ID of the container element
	this.container=document.getElementById(containerId);
	if (this.container==null){
                this.container=document.createElement('div');
                this.container.setAttribute('id',containerId);
		document.body.appendChild(this.container);
	}
	//Store the container's ID
	this.containerId=containerId;
	//Default configuration settings
	var defaults={
		//Set today's date-time as the default	
		dateTime:new Date(),
		//Set the default selection mode as "datetime"
		type:"DateTime",
		//Set the default title to "Pick a date-time"
		title:"Pick a date-time",
		interval: 60000,
		minBound: new Date('01/01/1970'),
		maxBound: new Date(),
		callback:undefined,
		arguments:undefined,
		monthDataOnly:false
			
	};
	if (config===undefined){
		config={};
	}

	this.timeInSecs = new Object();	
	this.timeInSecs["hrs"] = 3600000;
	this.timeInSecs["mins"] = 60000;
	this.timeInSecs["secs"] = 1000;

	this.defaultMinBound = defaults.minBound;
	this.defaultMaxBound = defaults.maxBound;

	defaults.title=(config.type==="Date")?"Pick a date":defaults.title;
	this.interval=(config.interval===undefined?defaults.interval:config.interval);
	this.minBound=(config.minBound===undefined?defaults.minBound:config.minBound);
	this.maxBound=(config.maxBound===undefined?defaults.maxBound:config.maxBound);
	this.dateTime=(config.dateTime===undefined?defaults.dateTime:config.dateTime);
	this.type=(config.type===undefined?defaults.type:config.type);
	this.title=(config.title===undefined?defaults.title:config.title);
	this.callback=(config.callback===undefined?defaults.callback:config.callback);
	this.arguments=(config.arguments===undefined?defaults.arguments:config.arguments);
	this.monthDataOnly = (config.monthDataOnly===undefined?defaults.monthDataOnly:config.monthDataOnly);

	if (this.interval >= this.timeInSecs["hrs"]){
	    this.level = "hrs";
	}
        else if (this.interval >= this.timeInSecs["mins"]){
	    this.level = "mins";
	} 
	else {
	    this.level = "secs";
        }


	this.onComplete = new YAHOO.util.CustomEvent("complete",this);

};

/**
 * Modifies min/max bounds set in the constructor
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {Date, Date} d1 is the Minimum Bound, d2 is the Max Bound
 */
giovanni.widget.Calendar.prototype.setBounds = function(d1,d2,start){
    if(this.calendar !== undefined){
		if(d1 !== null){
	    		this.calendar.cfg.setProperty("mindate",new Date(d1).clone(),false);
			//this.calendar.cfg.setProperty("selected",d1.clone(),false);
			//this.calendar.cfg.setProperty("pagedate",d1.clone(),false); 
			this.minBound = new Date(d1);
		} else {
	    		this.calendar.cfg.setProperty("mindate",this.defaultMinBound,false);
			this.minBound = this.defaultMinBound;
		}
		this.calendar.render();
		if(d2 !== null){
	    		this.calendar.cfg.setProperty("maxdate",new Date(d2).clone(),false);
			////this.calendar.cfg.setProperty("selected",d2.clone(),false);
                        //if(!start){
                        //        this.calendar.cfg.setProperty("pagedate",d2.clone(),false);
                        //}
                        this.maxBound = new Date(d2);
		} else {
	    		this.calendar.cfg.setProperty("maxdate",this.defaultMaxBound,false);
                        this.maxBound = this.defaultMaxBound;
		}
		this.calendar.render();
    }

};

/**
 * Fetches the selected datetime in Giovanni.widget.Calendar
 * 
 * @this {Giovanni.widget.Calendar}
 * @returns {String} the selected datetime ISO8601 formatted
 * @author T. Joshi 
 */

giovanni.widget.Calendar.prototype.getValue = function(){
	return this.dateTime.toISO8601DateString();
};

/**
 * Sets the selected datetime to the passed in string
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {String} recognizable date formatted string
 * @returns {Boolean} whether it was successfully able to set value or not
 * @author T. Joshi 
 */

//giovanni.widget.Calendar.prototype.setValue=function(dateTimeStr)
giovanni.widget.Calendar.prototype.setValue=function(datetime)
{
	var status=false;
	//Parse the input date time string
	var t=new Date();
	//if (t.parse(dateTimeStr)){
    	if (datetime !== null && this.dateTime !== datetime) {
		//If successful, set the dateTime 
		//t.setMinutes(t.getMinutes()+t.getTimezoneOffset());
		//this.dateTime.setTime(t.getTime());
		this.dateTime = datetime;
		if(this.type === "DateTime"){
		    if( document.getElementById(this.containerId+"TimeSelect") !== null){
    		    document.getElementById(this.containerId+"TimeSelecthrs").value = this.padDigits(this.dateTime.getHours(),2);
    		    document.getElementById(this.containerId+"TimeSelectmins").value = this.padDigits(this.dateTime.getMinutes(),2);
    		    document.getElementById(this.containerId+"TimeSelectsecs").value = this.padDigits(this.dateTime.getSeconds(),2);
		    }
	        }
		status=true;
		if(this.calendar !== undefined){
			/* unsubscribe the selectDateHandler so we don't hide the calendar due to the select event */
			this.calendar.selectEvent.unsubscribe(this.selectDateHandler,this);
			this.dateTime = (this.dateTime instanceof Array) ? this.dateTime[0] : this.dateTime;
                        var dateString = (this.dateTime.getUTCMonth()+1) + '/' + this.dateTime.getUTCDate() + '/' + this.dateTime.getUTCFullYear();
			// if the date touchs the bounds, set the selected data on the calendar
			if(this.touchesBounds(this.dateTime)){
			    this.calendar.select(dateString);
			    this.calendar.setMonth(this.dateTime.getUTCMonth());
			    this.calendar.setYear(this.dateTime.getUTCFullYear());
                        }
			this.calendar.render();
			/* restore the selectDateHandler subscription to selectEvent */
			this.calendar.selectEvent.subscribe(this.selectDateHandler,this);
	    	}

	}
	return status;
};

/**
 * Updates the calendar year and month given a user-selected date
 * 
 * @this {giovanni.widget.Calendar}
 * @param {Date} Javascript Date Object
 * @returns {} noting
 * @author K. Bryant
 */
giovanni.widget.Calendar.prototype.updatePage = function (datetime) {
	this.dateTime = datetime;
	if(this.calendar !== undefined && this.dateTime !== null){
		this.calendar.setMonth(this.dateTime.getUTCMonth());
		this.calendar.setYear(this.dateTime.getUTCFullYear());
		this.calendar.render();
	}	
}

/**
 * Determines if the incoming datetime touches the current calendar bounds
 * 
 * @this {giovanni.widget.Calendar}
 * @param {Date} Javascript Date Object
 * @returns {boolean} true or false
 * @author K. Bryant
 */
giovanni.widget.Calendar.prototype.touchesBounds = function (datetime) {
    var min = this.minBound.getTime();
    var max = this.maxBound.getTime();
    var cur = datetime.getTime();
    var touch = false;
    if(cur >= min && cur <= max){
        touch = true;
    }
    return touch;
}

/**
 * Creates a YUI Calendar widget with time added to the bottom if type='DateTime'
 * 
 * @this {Giovanni.widget.Calendar}
 * @author T. Joshi 
 */

giovanni.widget.Calendar.prototype.render=function()
{	
	//Show the dialog and return if the dialog exists.	
	if (this.dialog!==undefined){
    		if (this.dateTime!==undefined){
			//2011-11-23 X. Hu this will cause an auto filling the min/max date value to the start/end date field
			//this.calendar.select(this.dateTime.clone()); 
			this.calendar.setMonth(this.dateTime.getUTCMonth());
			this.calendar.setYear(this.dateTime.getUTCFullYear());
			this.calendar.render();
    		}
		//if(this.dialog.cfg.getProperty("visible")){
		//	this.dialog.hide();
		//}else{
			this.dialog.show();
		//}
		return;
	}
	//Buttons for the dialog
	var buttons;	
	//If the dialog doesn't exist, create a new one
	if (this.type==="DateTime"){
		buttons=[ {text:"&nbsp;Save&nbsp;", handler:{fn:this.saveCalendar, obj:this}, isDefault:true},
		          {text:"&nbsp;Cancel&nbsp;", handler:{fn:this.closeCalendar, obj:this}, isDefault:false}];
	/* REMOVED cancel button for 'Date' type
	}else{
		buttons=[  
		          {text:"&nbsp;Cancel&nbsp;", handler:{fn:this.closeCalendar, obj:this}, isDefault:true}];
	*/
	}
	//Create a dialog to hold the calendar
    var dialog = new YAHOO.widget.Dialog(this.containerId+"CalendarDialog", {
	width:"200px",
        visible:false,
        context:[this.containerId+"TimeContainer", "tl", "bl",[],[5,0]],
        buttons:buttons,
        draggable:true,
        close:true
    });
    YAHOO.util.Dom.addClass(this.containerId+"CalendarDialog",'yui-skin-sam');
    YAHOO.util.Dom.addClass(this.containerId+"CalendarDialog",'datebox-buttons');
    //Set the title of the dialog
    dialog.setHeader(this.title);
    dialog.showEvent.subscribe(function() {
    	dialog.fireEvent("changeContent");
    });
    //Create a place holder for the calendar. The ID is derived based
    //on the ID of the container.
    var calId=this.containerId+"Calendar";
    var timeHtml = "";
    if (this.type==="DateTime"){
        var timeId = this.containerId+"TimeSelect";
        timeHtml = (this.type==="DateTime")?this.getTimeHtml(timeId):"";
    }
    var dialogBodyHTML='<div id="'+calId+'"></div>'+timeHtml;
    dialog.setBody(dialogBodyHTML);
    //Render the dialog; has to happen before adding calendar.
    dialog.render(this.container);
    //Create the calendar
    var calendar = new YAHOO.widget.Calendar(calId, {navigator:false,mindate:this.minBound.clone(),maxdate:this.maxBound.clone()});
    //Set the selected date if one exists already
    if (this.dateTime!==undefined){
      this.dateTime = (this.dateTime instanceof Array) ? this.dateTime[0] : this.dateTime;
      var dateString = 
	'' + (this.dateTime.getUTCMonth()+1) 
	+ '/' + this.dateTime.getUTCDate() 
	+ '/' + this.dateTime.getUTCFullYear();
      calendar.select(dateString);
      calendar.setMonth(this.dateTime.getUTCMonth());
      calendar.setYear(this.dateTime.getUTCFullYear());
    }
    if (this.type==="Date"){
    	calendar.selectEvent.subscribe(this.selectDateHandler,this);
    }
    else{
	calendar.selectEvent.subscribe(this.updateDateTime,this);
    }
    YAHOO.util.Dom.addClass(calId,'yui-skin-sam');

    if(this.monthDataOnly){
        calendar.Style.CSS_WEEKDAY_ROW = 'nobody';
        calendar.Style.CSS_BODY = 'nobody';
    }
    
    //Render the calendar
    calendar.render();
    //On rendering the calendar, fire a dialog event to convey
    //change in content
    calendar.renderEvent.subscribe(function(){
    	dialog.fireEvent("changeContent");
    });
    this.calendar=calendar;

    dialog.show();
    this.dialog=dialog;

        this.onComplete.fire();
};

/**
 * Returns a string formatted in MM/DD/YYYY
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {Date} d is the date to be formatted
 * @returns {String} the passed in date formatted as MM/DD/YYYY
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.getFormattedDateString = function(d){
    var month = d.getMonth() + 1;
    var day = d.getDate();
    var year = d.getFullYear();
    var hours = d.getHours();
    var minutes = d.getMinutes();
    var seconds = d.getSeconds();

    return this.padDigits(month,2)+"/"+this.padDigits(day,2)+"/"+year;
};

/**
 * Creates textboxes and control arrows for time
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {String} id is the htmlid of the container div
 * @returns {String} html string containing the html to produce the time inputs
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.getTimeHtml = function(id){
    var downUrl = "http://sio7.jamstec.go.jp/j-cores/manual/CompositeLogViewer/img/icon/down-pointing-black-triangle12.gif";
    var upUrl = "http://sio7.jamstec.go.jp/j-cores/manual/CompositeLogViewer/img/icon/up-pointing-black-triangle12.gif";
    var hrs = 0;
    var mins = 0;
    var secs = 0;

    if( this.dateTime !== undefined ){
	hrs = this.padDigits(this.dateTime.getHours(),2);
	mins = this.padDigits(this.dateTime.getMinutes(),2);
	secs = this.padDigits(this.dateTime.getSeconds(),2);
    }

    var timeHtml = "<div style='display:block; width:125px; margin:0 auto;' class='TimeSelect' id='"+id+"'>";
    timeHtml += "<input type='text' id='"+id+"hrs' value='"+this.padDigits(hrs,2)+"'/><div class='scroller'><a id='"+id+"hrsScrollUp' ><img src='"+upUrl+"' /></a><a id='"+id+"hrsScrollDown' ><img src='"+downUrl+"' /></a></div>";
    timeHtml += "<input type='text' id='"+id+"mins' value='"+this.padDigits(mins,2)+"'/><div class='scroller'><a id='"+id+"minsScrollUp' ><img src='"+upUrl+"' /></a><a id='"+id+"minsScrollDown' ><img src='"+downUrl+"' /></a></div>";
    timeHtml += "<input type='text' id='"+id+"secs' value='"+this.padDigits(secs,2)+"'/><div class='scroller'><a id='"+id+"secsScrollUp' ><img src='"+upUrl+"' /></a><a id='"+id+"secsScrollDown' ><img src='"+downUrl+"' /></a></div>";
    timeHtml += "</div>";

    YAHOO.util.Event.addListener(id+"hrsScrollUp","click",this.incrementTime,{self:this,type:"hrs",myid:id});
    YAHOO.util.Event.addListener(id+"minsScrollUp","click",this.incrementTime,{self:this,type:"mins",myid:id});
    YAHOO.util.Event.addListener(id+"secsScrollUp","click",this.incrementTime,{self:this,type:"secs",myid:id});
    YAHOO.util.Event.addListener(id+"hrsScrollDown","click",this.decrementTime,{self:this,type:"hrs",myid:id});
    YAHOO.util.Event.addListener(id+"minsScrollDown","click",this.decrementTime,{self:this,type:"mins",myid:id});
    YAHOO.util.Event.addListener(id+"secsScrollDown","click",this.decrementTime,{self:this,type:"secs",myid:id});
    YAHOO.util.Event.addListener(id+"hrs","change",this.handleChange,{self:this,type:"hrs",myid:id+"hrs",mainid:id});
    YAHOO.util.Event.addListener(id+"mins","change",this.handleChange,{self:this,type:"mins",myid:id+"mins",mainid:id});
    YAHOO.util.Event.addListener(id+"secs","change",this.handleChange,{self:this,type:"secs",myid:id+"secs",mainid:id});

    return timeHtml;
};

/**
 * Increment hour, minute, or seconds by selected interval or 1 if that level of time is greater than the interval
 * 
 * @this {giovanni.widget.Calendar}
 * @param {Event,Object} o is the YAHOO.util.event object passed into every event handler, args consists of the [granularity of time being incremented, a reference to the calling Giovanni.widget.Calendar, and the ids of the objects being modified)
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.incrementTime = function(o,args){
    var self = args.self;
    var type = args.type;
    var id = args.myid;
    var selectedDate = self.dateTime;

    if( self.timeInSecs[type] < self.timeInSecs[self.level]){

    } 
    if( self.timeInSecs[type] > self.timeInSecs[self.level]){
	self.dateTime.setTime(self.dateTime.getTime() + self.timeInSecs[type]);
    }
    if( self.timeInSecs[type] === self.timeInSecs[self.level]){
    	self.dateTime.setTime(self.dateTime.getTime() + self.interval);
    }
    
    var hrsField = document.getElementById(id+"hrs");
    var minsField = document.getElementById(id+"mins");
    var secsField = document.getElementById(id+"secs");
    
    hrsField.value = self.padDigits(self.dateTime.getHours(),2);
    minsField.value = self.padDigits(self.dateTime.getMinutes(),2);
    secsField.value = self.padDigits(self.dateTime.getSeconds(),2);
};

/**
 * Decrement hour, minute, or seconds by selected interval or 1 if that level of time is greater than the interval
 * 
 * @this {giovanni.widget.Calendar}
 * @param {Event,Object} o is the YAHOO.util.event object passed into every event handler, args consists of the [granularity of time being decremented, a reference to the caller, and the ids of the objects being modified]
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.decrementTime = function(o,args){
    var self = args.self;
    var type = args.type;
    var id = args.myid;    

    if( self.timeInSecs[type] < self.timeInSecs[self.level]){
	
    }
    if( self.timeInSecs[type] > self.timeInSecs[self.level]){
	self.dateTime.setTime(self.dateTime.getTime() - self.timeInSecs[type]);
    }
    if( self.timeInSecs[type] === self.timeInSecs[self.level]){
	self.dateTime.setTime(self.dateTime.getTime() - self.interval);
    }
    
    var hrsField = document.getElementById(id+"hrs");
    var minsField = document.getElementById(id+"mins");
    var secsField = document.getElementById(id+"secs");

    hrsField.value = self.padDigits(self.dateTime.getHours(),2);
    minsField.value = self.padDigits(self.dateTime.getMinutes(),2);
    secsField.value = self.padDigits(self.dateTime.getSeconds(),2);


};

/**
 * Handles a manual change to the time [i.e. not using the increment/decrement buttons]
 * 
 * @this {giovanni.widget.Calendar}
 * @param {Event,Object} o is the YAHOO.util.event object passed into every event handler, args consists of the [granularity of the time being changed, a reference to the caler, and the ids of the objects being modified]
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.handleChange = function(o,args){
    var self = args.self;
    var type = args.type;
    var myid = args.myid;
    var id = args.mainid;
    var value = document.getElementById(myid).value;

    
    if(self.validateType(value,type) === true){

        if( self.timeInSecs[type] < self.timeInSecs[self.level]){
        
        }
        if( self.timeInSecs[type] > self.timeInSecs[self.level]){
            if( type === "hrs"){
	        self.dateTime.setHours(value);
	    }else if( type==="mins"){
	        self.dateTime.setMinutes(value);
	    }else if( type === "secs"){
	        self.dateTime.setSeconds(value);
	    }
        }
        if( self.timeInSecs[type] === self.timeInSecs[self.level]){
	    value = Math.floor(value*self.timeInSecs[type]/self.interval);
	    value = value * self.interval;
	    value = value/self.timeInSecs[type];
            if( type === "hrs"){
	        self.dateTime.setHours(value);
	    }else if( type === "mins"){
	        self.dateTime.setMinutes(value);
	    }else if( type === "secs"){
	        self.dateTime.setSeconds(value);
	    }
        }
    }

    var hrsField = document.getElementById(id+"hrs");
    var minsField = document.getElementById(id+"mins");
    var secsField = document.getElementById(id+"secs");

    hrsField.value = self.padDigits(self.dateTime.getHours(),2);
    minsField.value = self.padDigits(self.dateTime.getMinutes(),2);
    secsField.value = self.padDigits(self.dateTime.getSeconds(),2);
    
    document.getElementById(myid).focus();
    document.getElementById(myid).select();


};

/**
 * Pads the number passed in with leading zeros to the spaces specified
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {Number, Number} n is the number being modified, totalDigits signifies how many digits to pad 'n' withA
 * @returns {String} n padded to totalDigits
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.padDigits = function(n,totalDigits){
    n = n.toString();
    var pd = '';
    if (totalDigits > n.length)
    {
        for (i=0; i < (totalDigits-n.length); i++)
        {
            pd += '0';
        }
    }
    return pd + n.toString();
};

/**
 * Validates if the value passed in matches the type constraints (hours, minutes, seconds)
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {Number, Number} val is the value to be validated, type specifies what you are validating for (hours, minutes, seconds)
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.validateType = function(val, type){
    if(type === "hrs"){
	if(val < 24 && val >= 0){
	    return true;
        }
	else{
	    return false;
        }
    }
    else if(type === "secs" || type === "mins"){
	if(val < 60 && val >=0){
	    return true;
	}
	else {
	    return false;
	}
    }
};

/**
 * Updates the date time when a calendar date is changed to ensure it does not roll over to the next day
 * 
 * @this {Giovanni.widget.Calendar}
 * @param {YAHOO.util.Event, Object, giovanni.widget.Calendar) type is the event object passed to each YUI Event Handler, args contains the selected date, self is a reference to the calling giovanni.widget.calendar
 * @author T. Joshi 
 */
giovanni.widget.Calendar.prototype.updateDateTime = function(type,args,self){
    var myDate = self.calendar.toDate(args[0][0]);
    myDate.setHours(document.getElementById(self.containerId+"TimeSelecthrs").value);
    myDate.setMinutes(document.getElementById(self.containerId+"TimeSelectmins").value);
    myDate.setSeconds(document.getElementById(self.containerId+"TimeSelectsecs").value);
    self.dateTime = myDate;
};

/**
 * Sets the date for the Giovanni.widget.Calendar
 * @this {Giovanni.widget.Calendar}
 * @param {Event,Object}
 * @author M. Hegde 
 */
giovanni.widget.Calendar.prototype.selectDateHandler=function(type,args,self)
{
    self.dateTime=self.calendar.toDate(args[0][0]);
    if(!self.monthDataOnly){
        self.dialog.hide();
    }
    if (self.callback!==undefined){
    	self.callback(self,self.arguments);
    }
};

giovanni.widget.Calendar.prototype.hide=function(){
	if(this.dialog!==undefined){
		this.dialog.hide();
	}
}

/**
 * Saves the date for the Giovanni.widget.Calendar
 * @this {Giovanni.widget.Calendar}
 * @param {Event,Object}
 * @author M. Hegde 
 */
giovanni.widget.Calendar.prototype.saveCalendar=function(e,self)
{
	var dates=self.calendar.getSelectedDates();
	if (dates.length===1){
		self.dateTime=dates[0];
    		self.dateTime.setHours(document.getElementById(self.containerId+"TimeSelecthrs").value);
    		self.dateTime.setMinutes(document.getElementById(self.containerId+"TimeSelectmins").value);
    		self.dateTime.setSeconds(document.getElementById(self.containerId+"TimeSelectsecs").value);
		//Hide the dialog
	    self.dialog.hide();
	    if (self.callback!==undefined){
	    	self.callback(self,self.arguments);
	    }	    
	}else{
		alert("Please select a date!");
	}
};

/**
 * Closes Giovanni.widget.Calendar instance
 * @this {Giovanni.widget.Calendar}
 * @author M. Hegde 
 */
giovanni.widget.Calendar.prototype.closeCalendar=function(e,self)
{
	//Hide the dialog
	self.dialog.hide();
};

/*
 * Set monthly state on calendar.  Also hides (or shows, depending on state) the calendar
 * date selection table
 *
 * @this {giovanni.widget.Calendar}
 * @params {boolean}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.Calendar.prototype.setMonthOnly = function (bool) {
    this.monthDataOnly = bool;
    // set calendar to display dates or not
    if(this.calendar){
        if(bool){
	    this.calendar.Style.CSS_WEEKDAY_ROW = 'nobody';
	    this.calendar.Style.CSS_BODY = 'nobody';
        }else{
	    this.calendar.Style.CSS_WEEKDAY_ROW = 'calweekdayrow';
	    this.calendar.Style.CSS_BODY = 'calbody';
        }
        this.calendar.render();
    }
    // set date to dayStr if not null
}

/**
 * Sets the date for the Giovanni.widget.DatePicker
 * @this {YAHOO.widget.Calendar}
 * @param {Event,Object}
 * @author M. Hegde 
 */
YAHOO.widget.Calendar.prototype.buildMonthLabel=function()
{
	var shownDate=this.cfg.getProperty("pagedate");
	var monthList=this.cfg.getProperty("MONTHS_SHORT");
	var monthLabel=monthList[shownDate.getMonth()];
	var monthDataOnly = this.Style.CSS_BODY == 'nobody' ? true : false;

	//Create a selection list of months; come up with a unque id for attaching an event handler
	var monthId='monthCalendar_'+uid();
	var monthStr='<select id="' + monthId + '">';
	var curMonth=shownDate.getMonth();
	var monNumStr = "";
	for (i=0;i<12;i++){
		monNumStr = i < 9 ? '0' + (i+1) : (i+1);
		if(i==curMonth){
			monthStr+='<option value="'+monthList[i]+'" selected="true">'+monNumStr+" - "+monthList[i]+'</option>';
		}else{
			monthStr+='<option value="'+monthList[i]+'">'+monNumStr+" - "+monthList[i]+'</option>';
		}
	}
	monthStr+='</select>';
        this.monthSelectionHandler=function(e,obj){
		var deltaMonth=this.selectedIndex-obj.currentMonth;
                if (deltaMonth!==0){
			obj.calendar.addMonths(deltaMonth);
			if(obj.monthDataOnly){
                                obj.calendar.render();
                                // set date in date picker
                                //dateObj = dateObj.parse(dateObj.toISO8601DateTimeString());
                                //obj.selectDateHandler('select',dateArr,obj);
                                var dateArr = [];
                                dateArr.push( obj.calendar.cfg.getProperty("pagedate").getFullYear() );
                                dateArr.push( obj.calendar.cfg.getProperty("pagedate").getMonth() + 1 );
                                dateArr.push( 1 );
                                var args = [];
                                args.push(dateArr);
                                obj.calendar.selectEvent.fire(args);
			}
		}
        };
        YAHOO.util.Event.addListener(monthId,"change", this.monthSelectionHandler,{calendar:this,currentMonth:curMonth,monthDataOnly:monthDataOnly});

        //Create a selection list of years; come up with a unque id for attaching an event handler
	var startDate = this.cfg.getProperty("maxdate");
	var startYear = startDate.getFullYear();
	var stopYear = this.cfg.getProperty("mindate").getFullYear();
	var yearCount = startYear - stopYear;
 	var years = [];
 	for(var i=0;i<=yearCount;i++){
 		years.push(startYear-i);
 	}
        var yearId='yearCalendar_'+uid();
        var yearStr='<select id="' + yearId + '">';
        var curYear = shownDate.getFullYear();
        for (var i=0;i<years.length;i++){
                 if(years[i]===curYear){
                         yearStr+='<option selected="true">'+years[i]+'</option>';
                 }else{
                         yearStr+='<option>'+years[i]+'</option>';
                 }
        }
        yearStr+='</select>';
        var yearSelectionHandler=function(e,obj){
               	var deltaYear=obj.start-this.selectedIndex;
               	if (deltaYear!==0){
 			obj.calendar.setYear(deltaYear);
 			obj.calendar.render();
			if(obj.monthDataOnly){
				// set date in date picker
				//dateObj = dateObj.parse(dateObj.toISO8601DateTimeString());
				//obj.selectDateHandler('select',dateArr,obj);
				var dateArr = [];
				dateArr.push( deltaYear );
				dateArr.push( obj.calendar.cfg.getProperty("pagedate").getMonth() + 1 );
				dateArr.push( 1 );
				var args = [];
				args.push(dateArr);	
				obj.calendar.selectEvent.fire(args);
			}
               	}
        };
        YAHOO.util.Event.addListener(yearId,"change", yearSelectionHandler,{calendar:this,start:startYear,monthDataOnly:monthDataOnly});
 	return yearStr+'   '+monthStr;
};

/**
 * Overrides the next month navigation for Giovanni.widget.DatePicker.
 * Instead of jumping to next month, it jumps to next year.
 * @this {YAHOO.widget.Calendar}
 * @param {Event,Object}
 * @author M. Hegde 
 */
YAHOO.widget.Calendar.prototype.doNextMonthNav=function(e,cal)
{
	YAHOO.util.Event.preventDefault(e);
	//e.stopPropagation();
	YAHOO.util.Event.stopPropagation(e);
	//cal.nextYear();
};

/**
 * Overrides the previous month navigation for the 
 * Giovanni.widget.DatePicker. Instead of jumping to previous month,
 * it jumps to the previous year instead.
 * @this {YAHOO.widget.Calendar}
 * @param {Event,Object}
 * @author M. Hegde 
 */
YAHOO.widget.Calendar.prototype.doPreviousMonthNav=function(e,cal)
{
	YAHOO.util.Event.preventDefault(e);
	//e.stopPropagation();
	YAHOO.util.Event.stopPropagation(e);
	//cal.previousYear();
};
