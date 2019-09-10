//$Id: Services.js,v 1.36 2015/08/11 19:47:13 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $


// establish the component namespace
giovanni.namespace("widget.Services.Picker");
/**
 * Reads (from an XML DOM response), displays, and allows selection of services
 * which are grouped for exploration and presentation to the user
 *
 * @constructor
 * @this {Giovanni.widget.Services}
 * @param {String, String, Configuration}
 * @returns {giovanni.widget.Services}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker = function(id, url, config) {

    // id of the HTML element that this class will populate
    this.containerId = id;
    if (this.containerId == null) {
        alert("Error [giovanni.wigdet.Services]: element '" + id + "' is null!");
        return;
    }
    // address to the source of XML data that will provide the context for this class
    this.dataSourceURL = url;
    if (this.dataSourceURL == null) {
        alert("Error [giovanni.widget.Services]: data source URL is null!");
        return;
    }
    // HTML control element name
    this.controlName = this.containerId + "Ctrl";
    // HTML control element container
    this.containerName = this.controlName + "Container";
    // data source (holds the services XML DOM)
    this.dataSource = null;
    // service descriptions
    this.descriptions = [];
    // group objects - an array of Services.Group objects
    this.groupObjs = [];
    // stored services (from the initial accessor load - XML DOM objects)
    this.services = new Array();
    // default service - if there is one specified via the data source
    this.defaultService = "";
    // current points - points calculated as part of the maxpoints allowed function
    // to inform users where their selections are too large for an interactive 
    // scatter plot - this functionality should be moved....
    this.points = 0;
 
    this.maxPoints = null;
  
    // register - in order to talk to the other AG components, this component must 
    // register itself with in the global registry
    try {
        REGISTRY.register(this.containerId, this);
        REGISTRY.markComponentReady(this.containerId);
    } catch (ex) {
        console.log("Services.Picker:  Could not find the registry....building one....");
        REGISTRY = giovanni.util.Registry();
        REGISTRY.register(this.containerId, this);
        REGISTRY.markComponentReady(this.containerId);
    }
    this.onComplete = new YAHOO.util.CustomEvent("complete", this);

    // Check to make sure that the login object exists. Note that it may not have been
    // initialized yet at the time we are checking, but expect it to at least contain a
    // loginEvent that can be subscribed to.
    if (login) {
        // Subscribe to loginEvent, so that any change in login status will change the
        // criteria used by validation.
        login.loginEvent.subscribe(this.handleLoginEvent, this);
    }
    this.render();
};

/**
 * Renders the component - calls the catalog to get the services XML and then 
 * builds HTML elements and adds them to the container
 *
 * @this {giovanni.widget.Services.Picker}
 * @param {}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.render = function render() {

    if (this.dataSourceURL != "" && this.dataSourceURL != null && (typeof this.dataSourceURL == "function")) {
            // call the function to get the catalog in xml format and load the service
            // information from it
            var catalog = this.dataSourceURL();
            this.services = this.loadFromCatalog(catalog);
            // can we just call build ?? since loadFromCatalog() happens there in case
            // of dataSourceURL being a function
            this.build();
    } else {
        alert("Error:  giovanni.widget.Services.Picker:  Incorrectly typed data source");
    }
};

/**
 * Builds the HTML elements
 *
 * @this {giovanni.widget.Services.Picker}
 * @param {}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.build = function() {
    // get container
    var container = document.getElementById(this.containerId);
    // create hint
    //var  hint = document.createElement('div');
    //hint.setAttribute('class', 'hint');
    //hint.setAttribute('id', this.containerId + "Hint");
    //hint.innerHTML = "Choose a plot type.";
    // create control container
    var ctrlContainer = document.createElement('div');
    ctrlContainer.setAttribute('id', this.containerName);
    ctrlContainer.setAttribute('class', 'pickerContent');
    // create status display element
    var statusDisplay = document.createElement('div');
    statusDisplay.setAttribute('id', this.containerId + "Status");
    statusDisplay.setAttribute('class', 'status');
    statusDisplay.innerHTML = "&nbsp;";
    // create fieldset (not visible by initial style); used as primary container
    var fs = document.createElement("fieldset");
    fs.setAttribute('id','serviceFieldset');
    var l = document.createElement("legend");
    l.innerHTML = "Select Plot";
    fs.appendChild(l);
    //fs.appendChild(hint);
    fs.appendChild(ctrlContainer);
    fs.appendChild(statusDisplay);
    container.appendChild(fs);
    // update the component
    if (typeof this.dataSourceURL == "function") {
        // call the function to get catalog in xml format 
        // and load the service information from it
        if(this.services.length==0){
            var catalog = this.dataSourceURL();
            this.services = this.loadFromCatalog(catalog);
        }
        // build the service groups 
        // and popup panel and corresponding services
        this.buildServiceGroups(this.services);
    }

    // after building, check the login and
    // set the max frames/points messages accordingly
    this.services.map(this.setMaxFramesMessage);
    // once the component is complete, 
    // tell anyone who is listening
    this.onComplete.fire();
};

/**
 * Retrieve the value of the component (i.e., the service name)
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @return {String}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.getValue = function() {
    // get the group controls - relies on the name attribute....
    var ctrls = document.getElementsByName('group');
    var group = "";
    var service = "";
    // look through the service groups to find out which one is checked
    for(var i=0;i<ctrls.length;i++){
        if(ctrls[i].checked){
            group = ctrls[i].value;
            break;
        }
    }
    // get the services for the selected group - also relies on the 
    // name attribute....
    var services = document.getElementsByName('service_'+group);
    // look through the list of services for the selected group to
    // find out which one is checked
    for(var i=0;i<services.length;i++){
        if(services[i].checked){
            service = services[i].value;
            break;
        }
    }
    // strip the group name from the services name (server side does not use it)
    service = service.replace(group+'+','');
    
    // return the service name
    return "service="+service;
};

/**
 * Return the currently selected service label
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @returns {String}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.getValueLabel = function() {
    var v = this.getValue();
    v = v.split("=")[1];
    var label = v;
    var sNodes = this.dataSource.getElementsByTagName("service");
    for ( var i = 0; i < sNodes.length; i++) {
        if (sNodes[i].getAttribute("name") == v) {
          label = sNodes[i].getAttribute("label");
          break;
        }
    }
    return label;
};

/**
 * Validates the currently selected value; defines a sequence of validation
 * functions and then executes them in order, ANDing the results.
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @returns {boolean}
 * @author D. da Silva
 */
giovanni.widget.Services.Picker.prototype.validate = function() {
    /**
     * This defines a sequence of functions to execute and aggregate results
     # over for the overall validation. Executing of functions does not stop
     * after a failure so all error messages are visiable, though items in 
     * in this sequence may set a 'blocks' flag which causes that behaviour.
     */ 
    var validationSeq = [
        // Check that a value is selected. If this fails, no further validation
        // checks are performed
        {
            blocks: true,
            func: function() {
                var flag = Boolean(this.getValue().split('=')[1]);
                var msg = flag ? '' : "Please select a value for the plot.";                
                return new giovanni.widget.ValidationResponse(flag, msg);
            }            
        },
        
        // Check that a shape is not selected with a vector field. This is
        // temporary, as the feature is currently unimplemented.
        {
            blocks: false,
            func: this.checkShapeAndVectorField,
        },
        
        // Check that the selection does not exceed the maximum allowed points
        // for the given service.
        {
            blocks: false,
            func: this.checkMaxPoints,
        },
        // Check that the selection does not exceed the maximum allowed time steps
        // for the given service.
        {
            blocks: false,
            func: this.checkMaxTimeSteps,
        },
        // Check that a climatology variable is not being compared to a non-
        // climatology variable.
        {
            blocks: false,
            func: this.checkClimAndNonClimComparison,
        }
    ];
        
    /**
     * Execute the sequence defined above.
     */ 
    var isValid = true;
    var msg = [];

    for (var i = 0; i < validationSeq.length; i++) {
        var item = validationSeq[i];        
        var result = item.func.apply(this);
     
        try {
            isValid = isValid && result.isValid();
        } catch (err) {
            console.log(err.message);
            console.log(err.stack);
            continue;
        }

        if (result.getMessage()) {
            msg.push(result.getMessage());
        }

        if (item.blocks && ! result.isValid()) {
            break;
        }
    }

    var statusMsg = giovanni.util.map(msg, function(s) {return '&nbsp;'+s}).join('<br>');
    this.setStatus(statusMsg, !isValid);

    var validateMsg = giovanni.util.map(msg, function(s) {return '- '+s}).join('\n');
    return new giovanni.widget.ValidationResponse(isValid, validateMsg);
};

/**
 * To call this method to get a list of services; equivalent to getData()
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {DOM Object}
 * @returns {Array}
 * @author Chocka
 */
giovanni.widget.Services.Picker.prototype.loadFromCatalog = function(catalog) {
    var servicesArray = new Array();
    var snl = catalog.getElementsByTagName("service");
    for ( var i = 0; i < snl.length; i++) {
        servicesArray.push(snl[i]);
    }
    this.dataSource = catalog;

    return servicesArray;
};

/**
 * Retrieve the services data via URL - old method being retained for
 * backwards compatibility
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.getData = function() {
    if (this.dataSourceURL != "") {
        YAHOO.util.Connect.initHeader("content-type", "text/xml");
        YAHOO.util.Connect.asyncRequest("GET", this.dataSourceURL, {
            success : this.handleSuccess,
            failure : this.handleFailure,
            argument : [ this, "" ]
        });
    }
};

/**
 * Handle the successful fetch of the services data; used by 'getData()'
 *
 * @this {YAHOO.util.Event}
 * @params {Object}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.handleSuccess = function(o) {
    var classObj = o.argument[0];
    classObj.dataSource = o.responseXML;
    classObj.build();
};

/**
 * Handle a services data fetch failure; used by 'getData()'
 *
 * @this {YAHOO.util.Event}
 * @params {Object}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.handleFailure = function(o) {
    console.log("Services.Picker:  failure fetching data source");
};

giovanni.widget.Services.Picker.prototype.handleLoginEvent = function(type, args, o) {
    // When the login state changes, validate against a different set of limits
    if(o.validate().isValid()) {
      // if validation succeeds and there is a logged in user,
      // remove the guest limit message
      o.services.map(o.setMaxFramesMessage);
    }
}

/**
 * Update the component with new context; mainly used to check 
 * constraints
 * 
 * @this {giovanni.widget.Services.Picker}
 * @params {String}
 * @returns {}
 */
giovanni.widget.Services.Picker.prototype.updateComponent = function() {
    try {
        // Determine the services to enable/disable using the ServicesFilter
        // class made for this purpose.
        var servicesFilter = new giovanni.ui.ServicesFilter(this,
                                                            session.dataSelector);
        var allowedServices = servicesFilter.execute();
        var serviceNodes = this.getServiceNodes(allowedServices.join(','))
        this.enableServices(serviceNodes);
    } catch(err) {
        console.log("giovanni.widget.Services.updateComponent: error when trying to read variable to enable/disable services");
        console.log(err.stack);
    }
 
    // call validate to show warning about selecting map
    // (if it wasn't already selected) 
    this.validate();
};


giovanni.widget.Services.Picker.prototype.getServiceNodes = function(service) {
  var snl = this.dataSource.getElementsByTagName("service");
  var sA = service.split(",");
    if(service=="ALL"){
        return snl;
    }else{
        var nodes = [];
        for ( var s = 0; s < sA.length; s++) {
          for ( var i = 0; i < snl.length; i++) {
            if (snl[i].getAttribute("name") == sA[s]) {
              nodes.push(snl[i]);
            }
          }
        }
        return nodes;
    }
};


/**
 * Get an array containing all service names.
 *
 * @this {giovanni.widget.Services.Picker}
 * @returns {Array} contains every service name
 * @author D. da Silva
 */
giovanni.widget.Services.Picker.prototype.getServiceNames = function() {
    var serviceNames = [];   // return value
    var groups = this.getGroups();

    for (var i = 0; i < groups.length; i++) {
        var services = groups[i].getServiceObjects()

        for (var j = 0; j < services.length; j++) {
            serviceNames.push(services[j].service.getAttribute("name"));
        }
    }
    
    return serviceNames;
};


/**
 * For a given service, enable that service (while disabling all the rest);
 * used when constraining services given the selection of a particular variable
 * or type of variable
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {String}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.enableServices = function (services) {
    // if services == 'ALL', enable all service groups and services
    if(services=='ALL'){
	var groups = this.getGroups();
        for(var i=0;i<groups.length;i++){
            groups[i].enable(true);
            var serviceObjs = groups[i].getServiceObjects();
            for(var j=0;j<serviceObjs.length;j++){
                serviceObjs[j].enable(true);
            }
        }
    }else{ // enable only the services passed in and their corresponding groups
        // get the group objects
	var groups = this.getGroups();
        // get the currently selected service
        var selectedService = this.getUserSelectedService();
        // whether the selected service is valid or not
        var validServiceSelected = false;
        // check the groups - if they have services on the valid list
        // make sure they are enabled; look through the services within
        // the group and do the same
        for(var i=0;i<groups.length;i++){
            var enableGroup = false; // assume the group is not enabled by default
            var serviceObjs = groups[i].getServiceObjects(); // get the group's service objects
            for(var j=0;j<serviceObjs.length;j++){ // loop through the service objects
                for(var k=0;k<services.length;k++){ // loop through the valid services
                    // if the service is valid, enable it's group
                    if(serviceObjs[j].service.getAttribute('name')==services[k].getAttribute('name')){
                        serviceObjs[j].enable(true);
                        enableGroup = true;
                        // if the service is one of the valid services and it's 
                        // selected, make sure it stays that way
                        if(services[k].getAttribute('name')==selectedService){
                          validServiceSelected=true;
                          serviceObjs[j].setChecked(true,false);
                        }
			break; // if we get a valid service hit, check the next valid service
                    }else{ // service is not valid; disable and uncheck it
                        serviceObjs[j].enable(false);
                        serviceObjs[j].setChecked(false);
                    }
                }
            }
            groups[i].enable(enableGroup);
	    if(!enableGroup){
                var groupCtrl = document.getElementById(groups[i].groupName);
                if(groupCtrl.checked){
                    groupCtrl.checked = false;
                    document.getElementById(groups[i].groupName+'GroupCtrl').
                      setAttribute('class','groupControl');
                    document.getElementById('groupServiceText'+groups[i].groupName).innerHTML =
                      '<span class="groupServiceLabel groupServiceLabelUnselected">Select...</span>';
                }
            }else{
                // if the group is selected, de-select it
                var groupCtrl = document.getElementById(groups[i].groupName);
                if(groupCtrl.checked && !validServiceSelected){
                    groupCtrl.checked = false;
                    document.getElementById(groups[i].groupName+'GroupCtrl').
                      setAttribute('class','groupControl');
                    document.getElementById('groupServiceText'+groups[i].groupName).innerHTML =
                      '<span class="groupServiceLabel groupServiceLabelUnselected">Select...</span>';
                }
            }
        }
    }
}


/**
 * Validates against the presence of a shape and a vector field.
 * @this {gioavnni.widget.Services.Picker}
 * @params {}
 * @returns {giovanni.widget.ValidationResponse}
 * @author D. da Silva
 */
giovanni.widget.Services.Picker.prototype.checkShapeAndVectorField = function() {
    var sFilter = new giovanni.ui.ServicesFilter(self, session.dataSelector);
    
    if (sFilter.isShapePresent() && sFilter.isVectorFieldSelected()) {
        var msg = "Shape subsetting with vector field variables is not currently supported.";
        return new giovanni.widget.ValidationResponse(false, msg);
    } else {
        return new giovanni.widget.ValidationResponse(true, '');
    }
};


/*
 * Validates the current number of data points against the max
 * 
 * @this {giovanni.widget.Services.Picker} 
 * @params {}
 * @returns {giovanni.widget.ValidationResponse}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.checkMaxPoints = function() {
  var maxPoints = this.getMaxPoints();
  var maxAllowedPoints;
  var maxAllowedPointsLoggedIn = maxPoints[0];
  var maxAllowedPointsGuest = maxPoints[1];
  if (login) {
    if (login.enabled && !login.isLoggedIn) {
      maxAllowedPoints = maxAllowedPointsGuest;
    } else {
      maxAllowedPoints = maxAllowedPointsLoggedIn;
    }
  }
  var msg = "";
  var isError = false;
  var lbl = this.getValueLabel();
  var points = giovanni.util.getDataPointsCount(); 
  if(!points){
    console.log("Services.checkMaxPoints: could not make calculation; points was null");
  }else if(!isNaN(maxAllowedPoints) && points > parseInt(maxAllowedPoints)){
    msg = "Sorry.  The current number of data values (" + points + ") exceeds the maximum ("
        + maxAllowedPoints.toString() + ") we can process for " + lbl + ".  Try reducing your region size or date range.";
    if (login && login.enabled && !login.isLoggedIn) {
      if (maxAllowedPointsLoggedIn) {
        msg += ' (If you log in, the maximum number of allowed points will increase from '
            + maxAllowedPointsGuest + ' to ' + maxAllowedPointsLoggedIn + '.)';
      } else {
        msg += ' (If you log in, this limit on the number of allowed points will be removed.)';
      }
    }
    isError = true;
  }
  this.setStatus(msg, isError);
  return new giovanni.widget.ValidationResponse(!isError, msg);
};

giovanni.widget.Services.Picker.prototype.checkMaxTimeSteps = function () {
  var maxSteps = this.getMaxTimeSteps();
  var maxAllowedSteps;
  var maxAllowedStepsLoggedIn = maxSteps[0];
  var maxAllowedStepsGuest = maxSteps[1];
  if (login) {
    if (login.enabled && !login.isLoggedIn) {
      maxAllowedSteps = maxAllowedStepsGuest;
    } else {
      maxAllowedSteps = maxAllowedStepsLoggedIn;
    }
  }
  var timeStepsAndInterval = giovanni.util.getTimeSteps();
  var querySteps = timeStepsAndInterval[0];
  var timeInterval = timeStepsAndInterval[1];
  var msg = "";
  var isError = false;
  var lbl = this.getValueLabel();
  if(!querySteps){
    console.log("Services.checkMaxTimeSteps: could not make calculation; steps was null");
  }else if(!isNaN(maxAllowedSteps) && querySteps > parseInt(maxAllowedSteps)){
      msg = "Sorry.  The current number of time steps (" + querySteps + " " + timeInterval + ") exceeds the maximum (" 
        + maxAllowedSteps.toString() + ") we can process for " + lbl + ".  Try reducing your date range.";
    if (login && login.enabled && !login.isLoggedIn) {
      if (maxAllowedStepsLoggedIn) {
        msg += ' (If you log in, the maximum number of allowed time steps will increase from '
            + maxAllowedStepsGuest + ' to ' + maxAllowedStepsLoggedIn + '.)';
      } else {
        msg += ' (If you log in, this limit on the number of allowed time steps will be removed.)';
      }
    }
    isError = true;
  }

  // set max frames messages
  this.services.map(this.setMaxFramesMessage);

  this.setStatus(msg, isError);
  return new giovanni.widget.ValidationResponse(!isError, msg);
}

/*
 * A check to see if a climatology variable and a non-climatology variable
 * are being compared.
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @return {String}
 * @author D. da Silva
 */
giovanni.widget.Services.Picker.prototype.checkClimAndNonClimComparison = function() {
    // Validate positive if the selected service is not a comparison service
    var serviceName = this.getValue().split('=')[1];
    if (! this.isComparisonService(serviceName)) {
        return new giovanni.widget.ValidationResponse(true, '');
    }
    
    // Validate positive if there is no mix of climatology and non-climatology
    var selectedVars = session.dataSelector.variablePicker.fs.selectedVariables;    

    var foundClim = false;
    var foundNonClim = false;

    for (var i = 0; i < selectedVars.length; i++) {
        if (selectedVars[i].isClimatology) {
            foundClim = true;
        } else {
            foundNonClim = true;
        }
    }
    
    if (! foundClim || ! foundNonClim) {
        return new giovanni.widget.ValidationResponse(true, '');
    }

    // Validate negative, we have confirmed we are the red zone
    var msg = "Climatology variables cannot be compared to non-climatology variables";    
    return new giovanni.widget.ValidationResponse(false, msg);
};

/**
 * Collect the groups from the service data source; for each group, create an HTML element
 * and populate it
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {Array,String}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.buildServiceGroups = function (services,selectedService) {
  var srvA = services;
  var groups = [];
  var groupLbls = [];
  var oldGroup = "";
  var group = "";
  var exists = false;
  var defaultGroup = "";
  // loop through the services to extract the groups
  for (var i = 0; i < srvA.length; i++) {
    group = srvA[i].getAttribute('group');

    if(srvA[i].getAttribute('groupDefault')!=null && srvA[i].getAttribute('groupDefault') == "true"){
      defaultGroup = group;
      // the service that defines the default group also defines the default service by convention
      this.defaultService = srvA[i].getAttribute('name');
    }

    if (group != oldGroup) {
      oldGroup = group;
      // check to see if the group has already been added
      exists = false;
      for(var j=0;j<groups.length;j++){
        if(groups[j]==group){
          exists = true;
          break;
        }
      }
      if(!exists){
        groups.push(group);
        groupLbls.push(srvA[i].getAttribute('groupLbl'));
      }  
    }
    // set the default service from the dataSource
    //if(srvA[i].getAttribute('default')=="true"){
    //  this.defaultService = srvA[i].getAttribute('group') + "+" + srvA[i].getAttribute('name');
    //}
  }

  // render the HTML and build the service objects
  //this.populateServiceGroups(groups,groupLbls,services); 
  for(var i=0;i<groups.length;i++){
    // build group class
    this.addServiceGroup( groups[i], groupLbls[i], services );
  }
  // show the defaultGroup as selected
  for(var i=0;i<this.groupObjs.length;i++){
    if(this.groupObjs[i].groupName == defaultGroup){
      this.groupObjs[i].setSelected(undefined,[defaultGroup]);
      break;
    }
  }
}

giovanni.widget.Services.Picker.prototype.addServiceGroup = function ( groupName, groupLabel, services ) {
    var groupObj = new giovanni.widget.Services.Group( this.containerName, groupName, groupLabel, null );
    for(var j=0;j<services.length;j++){
      if(groupName == services[j].getAttribute('group')){
        // add to group class
        groupObj.addService( services[j] );
      }
    }
    this.groupObjs.push( groupObj );
    groupObj.showGroupPanelEvent.subscribe(this.handleShowGroupPanelEvent,{},this);
    groupObj.valueChangedEvent.subscribe(this.handleGroupValueChangedEvent,{},this);
}

giovanni.widget.Services.Picker.prototype.handleGroupValueChangedEvent = function (e,o) {
  REGISTRY.fire(this);
}

/**
 * Get the list of group objects
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @returns {Array}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.getGroups = function () {
  return this.groupObjs;
}

/**
 * From the bookmarkable URL, load the service value
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {String}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.loadFromQuery = function(query) {
  var qstr = giovanni.util.getParamValueByName("service", query);
  if (qstr != "") {
    var val = qstr instanceof Array ? qstr[0] : qstr;
    if (val != null && val != "") {
      this.setValue(val);
    }
  }
};

/**
 * Given a service name, set that value on the component
 * and notify the listening components
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {Object}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.setValue = function(service) {
  /* get the sevices, find the match, set it as 'checked'
   * no group info in the query yet so if there are redundant
   * services in the component (i.e., repeated between service groups)
   * we won't know which one to set; for now, set the first that we
   * come to in the list of services
   */
  var groups = this.getGroups();
  var services = null;
  var found = false;
  for(var i=0;i<groups.length;i++){
    services = groups[i].getServiceObjects();
    for(var j=0;j<services.length;j++){
      if(services[j].service.getAttribute('name')==service){
        services[j].setChecked(true,true);
        found = true;
        break;
      }
    }
    if(found) break;
  }
  REGISTRY.fire(this);
};

/**
 * Clears the service selections back the default service value
 * 
 * @this {giovanni.widget.Service}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.clearSelections = function() {
  this.setValue(this.defaultService);
};

/**
 * Resets selections back the default service value
 * 
 * @this {giovanni.widget.Service}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.resetSelections = function() {
  // calls clearSelections() for now since it's the same functionality for a set
  // of radio buttons
  this.clearSelections();
};

giovanni.widget.Services.Picker.prototype.setStatus = function(msg, isError) {
  var elm = document.getElementById(this.containerId + "Status");
  if (elm != null) {
    elm.innerHTML = msg;
    var cname = isError == false ? "status" : "statusError";
    elm.setAttribute('class', cname);
  }
};

giovanni.widget.Services.Picker.prototype.setMaxFramesMessage = function (service) {
  var max_frames = service.getAttribute('max_frames');
  var max_frames_guest = service.getAttribute('max_frames_guest');
  var max_points = service.getAttribute('max_points');
  var max_points_guest = service.getAttribute('max_points_guest');
  var loggedIn = login && login.enabled && login.isLoggedIn;
  var name = '#'+service.getAttribute('name')+'-service-note';
  // clear the message
  $(name).html('');
  // set the message based on the login status and the max stats (frames and points) in giovanni_services.xml
  if (!loggedIn && (max_frames_guest || max_points_guest)) {
    // max frames|points guest message
    $(name).html('<sup id="groupNote">&#x2731;</sup> Guest user limited to ' + (max_frames_guest ? max_frames_guest + ' time steps' :
      max_points_guest + ' points'));
  } else if (!loggedIn && !max_frames_guest && (max_frames || max_points)) {
    // max frames|points message ... as a guest user
    $(name).html('<sup id="groupNote">&#x2731;</sup> Guest user limited to ' + (max_frames ? max_frames + ' time steps' :
      max_points + ' points'));
  } else if (loggedIn && (max_frames || max_points)) {
    // max frames|points message
    if (max_frames) { 
      $(name).html('<sup id="groupNote">&#x2731;</sup> Limited to ' + max_frames + ' time steps');
    } else if (max_points && (name.indexOf('IaSc')>-1 || name.indexOf('TmAvSc')>-1)) {
      $(name).html('<sup id="groupNote">&#x2731;</sup> Limited to ' + max_points + ' points');
    }
  } else {
    // nothing
    $(name).html('');
  }
}

/**
 * Returns the ID for this picker, which is the ID of the HTML element
 * containing this picker
 * 
 * @this {giovanni.widget.Services.Picker}
 * @author Chocka
 */
giovanni.widget.Services.Picker.prototype.getId = function() {
  return this.containerId;
};

/**
 * To check if the user selected service is a digital comparison service
 * 
 * @this {giovanni.widget.Services.Picker}
 * @param {String} Name of service (Optional, default to selected service).
 * @author Chocka, D. da Silva, K. Bryant
 */
giovanni.widget.Services.Picker.prototype.isComparisonService = function(serviceName) {
  serviceName = serviceName || this.getUserSelectedService();

  switch(serviceName) {
  //case 'CORRELATION_MAP':
  case 'CoMp': return true;
  // Difference of Area-Averaged Time Series
  case 'DiArAvTs': return true;
  //case 'SCATTER_PLOT':
  case 'StSc': return true;
  //case 'TIME_AVERAGED_SCATTER_PLOT':
  case 'TaSc': return true;
  //case 'INTERACTIVE_SCATTER_PLOT': return true;
  case 'IaSc': return true;
  // Difference of Time-Averaged Map
  case 'DiTmAvMp': return true;
  //case 'TIME_AVERAGED_MAP':
  case 'TmAvMp': return false;
  //case 'MAP_ANIMATION':
  case 'MpAn': return false;
  //case 'INTERACTIVE_MAP':
  case 'IaMp': return false;
  case 'TmAvOvMp': return false;
  //case 'AREA_AVERAGED_TIME_SERIES': return false;
  case 'ArAvTs': return false;
  default: return null;
  }
};

/**
 * To check if the user selected service is a difference comparison service
 * 
 * @this {giovanni.widget.Services.Picker}
 * @param {String} Name of service (Optional, default to selected service).
 * @author Chocka, D. da Silva, K. Bryant
 */
giovanni.widget.Services.Picker.prototype.isDifferenceService = function(serviceName) {
  serviceName = serviceName || this.getUserSelectedService();
  switch(serviceName) {
      case 'DiArAvTs': return true;
      case 'DiTmAvMp': return true;
      default: return null;
  }
};


/**
 * To check if the user selected service is 3D service
 * 
 * @this {giovanni.widget.Services.Picker}
 * @author Chocka
 */
giovanni.widget.Services.Picker.prototype.is3DService = function() {
  switch(this.getUserSelectedService()) {
  case 'VtPf': return true;
  case 'CrLn': return true;
  case 'CrLt': return true;
  case 'CrTm': return true;
  case 'CoMp':
  case 'StSc':
  case 'TmAvSc':
  case 'IaSc': 
  case 'TmAvMp':
  case 'TmAvOvMp':
  case 'MpAn':
  case 'IaMp':
  case 'ArAvTs': return false;
  default: return null;
  }
};

/**
 * Sets the focus of the AG UI on this picker; used when there is an error condition
 * that requires the users attention; includes scrolling/navigation to the topleft
 * corner of this picker
 *  
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @returns {}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.setFocus = function () {

}

giovanni.widget.Services.Picker.prototype.handleShowGroupPanelEvent = function (e,o) {
  var groups = this.getGroups();
  var shownGroup = o[0]; // first array element is the group name
  for(var i=0;i<groups.length;i++){
    if(groups[i].groupName!=shownGroup){
      groups[i].hide(null,{});
    }
  }
}

giovanni.widget.Services.Group = function (pickerId, groupName, groupLbl, selectedService, isSelected) {
  this.containerId = groupName + "GroupCtrl";
  this.pickerId = pickerId;
  this.container = null;
  this.groupName = groupName;
  this.groupLbl = groupLbl;
  this.isSelected = isSelected;
  this.selectedService = "";
  this.value = null;
  this.srvLbl = null;
  this.groupPanel = null;
  this.services = [];
  this.visible = false;
  this.inPanel = false;
  this.serviceTitle = "";
  this.serviceObjs = [];
  // set tag/class names
  this.moreElementId = 'groupServiceMore';
  // set custom events
  this.showGroupPanelEvent = new YAHOO.util.CustomEvent("GroupPanelShowEvent",this);
  this.valueChangedEvent = new YAHOO.util.CustomEvent("GroupValueChangedEvent",this);
  // render the group element
  this.render();
}

giovanni.widget.Services.Group.prototype.render = function () {
  // create group ctrl container
  var div = document.createElement('div');
  div.setAttribute('id',this.containerId);
  div.setAttribute('class','groupControl');
  // add it to the service picker container
  var pickerContainer = document.getElementById(this.pickerId);
  pickerContainer.appendChild(div);
  // set the div to the container
  this.container = div;
  // create group radio button
  var radio = document.createElement('input');
  radio.setAttribute('type','radio');
  radio.setAttribute('name','group');
  radio.setAttribute('id',this.groupName);
  radio.setAttribute('value',this.groupName);
  //radio.setAttribute('value',this.group+'Value');
  
  // add to the group container
  //this.container.appendChild(radio);
  // create group label
  var lbl = document.createElement('label');
  lbl.setAttribute('htmlFor',this.groupName);
  //lbl.setAttribute('class','groupLabel');
  //lbl.innerHTML = this.groupLbl + ": ";
  //var radioText = document.createTextNode(this.group);
  var radioText = document.createElement('span');
  radioText.setAttribute('id',this.groupName+'RadioText');
  radioText.setAttribute('class','groupLabel');
  radioText.innerHTML = '<span style="font-size:1.1em;">' + this.groupLbl + ": </span>"; 
  lbl.appendChild(radio);
  lbl.appendChild(radioText);
  // add to container
  this.container.appendChild(lbl);
  // create service label holder
  var srvLbl = document.createElement('div');
  srvLbl.innerHTML = this.selectedService;
  srvLbl.setAttribute('class','groupServiceLbl');
  this.container.appendChild(srvLbl);
  this.srvLbl = srvLbl;
  // create group panel
  var groupPanel = document.createElement('div');
  groupPanel.setAttribute('id',this.groupName+'Panel');
  groupPanel.setAttribute('class','groupPanel');
  pickerContainer.appendChild(groupPanel);
  this.setGroupPanelHTML(groupPanel,this.groupLbl);
  this.groupPanel = groupPanel;
  // listen to group control mouse enter/leave events
  YAHOO.util.Event.addListener(this.container,'mouseenter',this.show,{},this);
  YAHOO.util.Event.addListener(this.container,'mouseleave',this.startHideCheck,{},this);
  // listener to control click events
  YAHOO.util.Event.addListener(radio,'click',this.setSelected,{},this);
  // is the group selected?
  if (this.isSelected) {
    radio.setAttribute('checked',true);
    document.getElementById(this.containerId).
      setAttribute('class','groupControl groupControlSelected');
  }else{
    radioText.innerHTML = '<span class="groupServiceLabel groupServiceLabelUnselected">' + this.groupLbl + ": Select...</span>";
    document.getElementById(this.containerId).
      setAttribute('class','groupControl');
  }
};

/*
 * Set the selected group control; also can set the picker value if there is selected service within the group
 */
giovanni.widget.Services.Group.prototype.setSelected = function (e,o) {
  var targ = null;
  var groupName = "";
  var fireUpdate = false;
  var selectedService = undefined;
  // get the target element (find out where the click was from)
  if(e!=undefined){
    targ = giovanni.util.getTarget(e);
    fireUpdate = true;
  }else{
    if(o!=null) groupName = o[0];
    if(o!=null && o.length > 1) fireUpdate = o[1];
  }
  if(targ==null)
    if(o==null) 
      targ = document.getElementById(this.getUserSelectedIndex());
    else
      targ = document.getElementById(groupName);

  var ctrls = document.getElementsByName('group');
  // set all groups as un-selected first...
  for(var i=0;i<ctrls.length;i++){
    document.getElementById(ctrls[i].id+'GroupCtrl').
      setAttribute('class','groupControl');
    document.getElementById('groupServiceText'+ctrls[i].id).innerHTML = 
      '<span class="groupServiceLabel groupServiceLabelUnselected">Select...</span>';
  }
  // if the event comes from a service radio button rather than a group radio button,
  // make sure we get the correct id and then set the service title
  var groupId = targ.id;
  if(targ.id.indexOf('+')>-1){ // from group 
    groupId = targ.id.split('+')[0].split('_')[1];
    var title = targ.getAttribute('title');
    this.setServiceTitle( title );
  }else{ // from service radio
    var ctrls = document.getElementsByName("service_"+groupId);
    var foundSelectedService = false;
    for(var i=0;i<ctrls.length;i++){
      if(ctrls[i].checked){
        this.setServiceTitle( ctrls[i].getAttribute('title') );
        foundSelectedService = true;
        selectedService = this.serviceObjs[i].service;
        break;
      }
    }
    // if no selected service was found in the group, but there are services
    // pick the first one in the list to be selected
    if(ctrls.length > 0 && !foundSelectedService){
      ctrls[0].checked = true;
      this.setServiceTitle( ctrls[0].getAttribute('title') );
      selectedService = this.serviceObjs[0].service;
    }
  }

  // based on the 'groupId', set the style of the selected group element
  document.getElementById(groupId+'GroupCtrl').
    setAttribute('class','groupControl groupControlSelected');

  if(!document.getElementById(groupId).checked) document.getElementById(groupId).checked = true;

  document.getElementById('groupServiceText'+groupId).setAttribute('class','groupServiceLabel');
  document.getElementById('groupServiceText'+groupId).innerHTML = this.getServiceTitle();
  var max_frames = selectedService.getAttribute('max_frames') ? 
    selectedService.getAttribute('max_frames') : selectedService.getAttribute('max_frames_guest');
  if(max_frames != null){
    document.getElementById('groupServiceText'+groupId).innerHTML = this.getServiceTitle() + 
      '<sup id="groupAsterisk"> &#x2731;</sup>';
  }
  // let listeners know that the group element was selected...
  if(fireUpdate) this.valueChangedEvent.fire();
}


giovanni.widget.Services.Group.prototype.setGroupPanelHTML = function (container,groupLabel) {
  var groupHdr = document.createElement('div');
  groupHdr.setAttribute('class','groupPanelHeader');
  groupHdr.innerHTML = groupLabel + ' Choices'; 
  container.appendChild(groupHdr);
}

giovanni.widget.Services.Group.prototype.addService = function (service) {
  // store the RAW (XML) service object
  this.services.push(service);
  // if this is the first service, do some initialization work for the service group
  if(this.services.length == 1){
    document.getElementById(this.groupName+'RadioText').innerHTML = 
      '<span style="font-size:1.0em;">' + this.groupLbl + ": </span>" + 
      '<span id="groupServiceText'+this.groupName+'" class="groupServiceLabel groupServiceLabelUnselected">Select...</span>' +
      '<span id="'+this.moreElementId+this.groupName+'" class="'+this.moreElementId+'" title="More..."><i class="fa fa-caret-down"></i></span>';
    YAHOO.util.Event.addListener(this.groupPanel,'mouseenter',this.setInPanel,{},this);
    YAHOO.util.Event.addListener(this.groupPanel,'mouseleave',this.hide,{},this);
    YAHOO.util.Event.addListener(this.moreElementId+this.groupName,'click',this.toggle,{},this);
  }
  // build service object
  var serviceObj = new giovanni.widget.Services.Group.Service(this.groupName, service);
  // handle service radio button selection
  serviceObj.valueChangedEvent.subscribe(this.handleServiceValueChanged,{},this);
  // add the service object to group collection of service objects
  this.serviceObjs.push( serviceObj );
}

giovanni.widget.Services.Group.prototype.getSelectedIndex = function () {
  var ctrls = document.getElementsByName('group');
  var len = ctrls.length;
  var idx = 0;
  for(var i=0;i<ctrls.length;i++){
    if(ctrls[i].checked){
      idx = i;
      break;
    }
  }
  return idx;
}

giovanni.widget.Services.Group.prototype.handleServiceValueChanged = function (e,o) {
  this.setSelected(undefined,[o[0],true]);
}

giovanni.widget.Services.Group.prototype.getServiceObjects = function () {
  return this.serviceObjs;
}

/*
 * Shows group panel
 */
giovanni.widget.Services.Group.prototype.show = function (e,o) {
  // make sure all panels are hidden
  this.showGroupPanelEvent.fire(this.groupName);
  this.inPanel = false;
  this.groupPanel.setAttribute('class','groupPanel groupPanelVisible');
  var targ = giovanni.util.getTarget(e);
  if(targ.id.match(this.moreElementId)){
    var newTargId = targ.id.replace(this.moreElementId,'');
    newTargId += "GroupCtrl";
    targ = document.getElementById(newTargId);
  }
  var targBbox = targ.getBoundingClientRect();
  this.groupPanel.style.top = targBbox.top + 32 + 'px';
  this.groupPanel.style.left = targBbox.left + 'px';
}

/*
 * Handle the mouseover interaction between a group control and it's panel - 
 * time when to hide the panel
 */
giovanni.widget.Services.Group.prototype.startHideCheck = function (e,o) {
  // set time to check 'inPanel'; if not 'inPanel' by time up, hide the panel
  this.hideTimeout = window.setTimeout(
    function (x) {
      return function () {
        if(!x.isInPanel()){
          x.hide();
        }
      };
    }(this),
  100 );
}
/*
 * Is the cursor in the panel?
 */
giovanni.widget.Services.Group.prototype.isInPanel = function () {
  return this.inPanel;
}
/*
 * Set whether the cursor is over the panel
 */
giovanni.widget.Services.Group.prototype.setInPanel = function (e,o) {
  this.inPanel = true;
}
/*
 * Hide the panel
 */
giovanni.widget.Services.Group.prototype.hide = function (e,o) {
  // 'groupPanel' style is 'display:none' by default
  this.groupPanel.setAttribute('class','groupPanel');
}

/*
 * If the group panel is visible, hide it; if it's hidden, show it
 */
giovanni.widget.Services.Group.prototype.toggle = function (e,o) {
  var isVisible = 
    this.groupPanel.getAttribute('class').match(/Visible/g) ? true : false;
  if(isVisible){
    this.hide();
  }else{
    this.show();
  }
}

giovanni.widget.Services.Group.prototype.setServiceTitle = function (title) {
  this.serviceTitle = title;
}
giovanni.widget.Services.Group.prototype.getServiceTitle = function () {
  return this.serviceTitle;
}
giovanni.widget.Services.Group.prototype.setValue = function (value) {
  this.value = value;
}
giovanni.widget.Services.Group.prototype.getValue = function () {
  this.value;
}
giovanni.widget.Services.Group.prototype.getGroupPanel = function () {
  return this.groupPanel;
}

giovanni.widget.Services.Group.prototype.enable = function (bool) {
  var ctrl = document.getElementById(this.groupName);
  ctrl.disabled = !bool;
  document.getElementById(this.groupName+'RadioText').setAttribute('class', bool ? 'groupLabel' : 'groupLabel groupLabelDisabled'); 
}

giovanni.widget.Services.Group.prototype.getChecked = function () {
  return document.getElementById(this.groupName).checked;
}

/*
 * Build a service for a group
 */
giovanni.widget.Services.Group.Service = function (id, service) {
  this.containerId = id; // containerId is also the group name, by convention
  this.service = service;
  this.isSelected = false;
  this.radioButton = null;
  this.valueChangedEvent = new YAHOO.util.CustomEvent("ServiceValueChangedEvent",this);
  this.render();
}

/*
 * Renders the service HTML
 */
giovanni.widget.Services.Group.Service.prototype.render = function () {
  this.getServiceHTML();
}

/*
 * Set the service for the group; also sets the group as the selected group,
 * effectively setting the service for the picker
 */
giovanni.widget.Services.Group.Service.prototype.setGroupService = function (e,o) {
  var targ = giovanni.util.getTarget(e);
  var value = targ.value;
  var id = 'groupServiceText'+value.split("+")[0];
  document.getElementById(id).innerHTML = targ.getAttribute('title');
  this.isSelected = true;
  this.valueChangedEvent.fire(value.split("+")[0]);
}

/*
 * Build the service HTML
 */
giovanni.widget.Services.Group.Service.prototype.getServiceHTML = function () {
  var row = document.createElement('div');
  row.setAttribute('class','row');
  var group_name = this.containerId;
  var service = this.service;

  var serviceLabel = service.getAttribute('label');
  // remove the group or principal service name
  // ((keep the descriptive portion)
  var groupLabel = service.getAttribute('groupLbl');
  serviceLabel = serviceLabel.replace(groupLabel+', ', ''); // removing group label
  serviceLabel = serviceLabel.replace(groupLabel.replace('s','')+', ', ''); //handles 'Maps' case

  // for each service, create a service selection element and add it to the container
  var radio = document.createElement('input');
  radio.setAttribute('type','radio');
  radio.setAttribute('name','service_'+group_name);
  radio.setAttribute('id','service_'+group_name+'+'+service.getAttribute('name'));
  radio.setAttribute('class','serviceRadio');
  radio.setAttribute('title',serviceLabel);
  radio.setAttribute('value',group_name+"+"+service.getAttribute('name'));
  this.radioButton = radio;


  var radioText = document.createElement('span');
  radioText.innerHTML = serviceLabel;

  var lbl = document.createElement('label');
  lbl.setAttribute('class','serviceLabel');
  lbl.appendChild(radio);
  lbl.appendChild(radioText);

  var radioRow = document.createElement('div');
  radioRow.appendChild(lbl);

  row.appendChild(radioRow);

  var desc = document.createElement('div');
  desc.setAttribute('class','serviceDesc');
  desc.innerHTML = service.getAttribute('description');
  row.appendChild(desc);

  // set the limit messaging - DO NOT check the login at this point;
  // we'll capture the event later
  var max_frames = service.getAttribute('max_frames');
  //var max_frames_guest = service.getAttribute('max_frames_guest');
  var note = document.createElement('div');
  note.setAttribute('class','serviceNote');
  note.setAttribute('id',service.getAttribute('name')+'-service-note');
  note.innerHTML = max_frames ? '<sup id="groupNote">&#x2731;</sup> Limited to ' + max_frames + ' time steps' : '';
  row.appendChild(note);

  var link = document.createElement('a');
  link.setAttribute('href',service.getAttribute('helplink'));
  link.setAttribute('target','help');
  link.setAttribute('class','serviceLink');
  link.innerHTML = 'Details...';
  row.appendChild(link);


  //var options = this.getOptions(service.getAttribute('name'));
  //if(options) row.appendChild(options);

  // for later when there is a giovanni.widget.ServiceOptions class available 
/*
    // add the icon link
    var optlink = document.createElement('div');
    optlink.setAttribute('class','optionsCtrlOpen');
    optlink.setAttribute('id',service.getAttribute('name')+'OptionsLink');
    optlink.setAttribute('title','Options');
    YAHOO.util.Event.addListener(service.getAttribute('name')+'OptionsLink','click',this.showOptions,{},this);
    //radioRow.appendChild(link);
    row.appendChild(optlink);
    var optarrow = document.createElement('div');
    optarrow.setAttribute('class','optionsArrowOpen');
    optarrow.setAttribute('id',service.getAttribute('name')+'OptionsArrow');
    optarrow.setAttribute('title','Options');
    row.appendChild(optarrow);
    YAHOO.util.Event.addListener(service.getAttribute('name')+'OptionsArrow','click',this.showOptions,{},this);
  //this.getServiceOptions(row,group_name,service,this);
*/

  // listen to user clicks
  YAHOO.util.Event.addListener(radio,'click',this.setGroupService,{},this);
  // add the row to the container (the group panel)
  document.getElementById(group_name+'Panel').appendChild(row); 

  // if the service is selected by default....
  if (service.getAttribute('default')=="true"){
    // check the radio button
    radio.setAttribute('checked',true);
    // set service name in group control
    var id = 'groupServiceText' + group_name;
    document.getElementById(id).innerHTML = service.getAttribute('label');
    //document.getElementById(group_name+'GroupCtrl').
    //   setAttribute('class','groupControl groupControlSelected');
    //document.getElementById(group_name).checked = true;
    this.isSelected = true;
  }
}

giovanni.widget.Services.Group.Service.prototype.setChecked = function (check,fire) {
  this.radioButton.checked = check;
  if(check&&fire) this.valueChangedEvent.fire(this.containerId);
}

giovanni.widget.Services.Group.Service.prototype.getChecked = function () {
  return this.radioButton.checked;
}

giovanni.widget.Services.Group.Service.prototype.enable = function (bool) {
  this.radioButton.disabled = !bool;
  this.radioButton.parentNode.setAttribute('class', bool ? 'serviceLabel' : 'serviceLabel serviceLabelDisabled');
}  

/*
 * Get the user selected service name
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * @returns {String}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.getUserSelectedService = function () {
  var groups = document.getElementsByName('group');
  var selectedGroup,selectedService="";
  for(var i=0;i<groups.length;i++){
    if(groups[i].checked){
      selectedGroup = groups[i].id;
      break;
    }
  }
  var services = document.getElementsByName('service_'+selectedGroup);
  for(var i=0;i<services.length;i++){
    if(services[i].checked){
      selectedService = services[i].value.replace(selectedGroup+'+','');
      break;
    }
  }
  return selectedService;
}

/*
 * Fetch the max time steps for a given service.  This information is stored
 * as a service attribute in giovanni_services.xml
 *
 * @this {giovanni.widget.Services.Picker}
 * @params {}
 * returns {Number}
 * @author K. Bryant
 */
giovanni.widget.Services.Picker.prototype.getMaxTimeSteps = function () {
  var maxSteps = 0;
  var maxStepsGuest = 0;
  var selectedServiceName = this.getUserSelectedService();
  for(var i=0;this.services.length;i++){
    if(this.services[i].getAttribute('name') == selectedServiceName){
      maxSteps = this.services[i].getAttribute('max_frames');
      maxStepsGuest = this.services[i].getAttribute('max_frames_guest');
      break;
    }
  }
  if(maxSteps){
    maxSteps = new Number(maxSteps);
  }
  if(maxStepsGuest){
    maxStepsGuest = new Number(maxStepsGuest);
  }
  return [maxSteps, maxStepsGuest];
}

giovanni.widget.Services.Picker.prototype.getMaxPoints = function () {
  var max = null;
  var max_guest = null;
  var selectedServiceName = this.getUserSelectedService();
  for(var i=0;this.services.length;i++){
    if(this.services[i].getAttribute('name') == selectedServiceName){
      max = this.services[i].getAttribute('max_points'); 
      max_guest = this.services[i].getAttribute('max_points_guest');
      break;
    }
  }
  if(max){
    max = new Number(max);
  }
  if(max_guest){
    max_guest = new Number(max_guest);
  }
  return [max, max_guest];
}

giovanni.widget.Services.Group.Service.prototype.getOptions = function (service) {
  var opt_element = null;
  if(service == 'TmAvMp'){
    opt_element = document.createElement('div');
    opt_element.setAttribute('class','service-options');
    var opt_cb = document.createElement('input');
    opt_cb.setAttribute('type','checkbox');
    opt_cb.setAttribute('id','displayAsOverlay');
    opt_cb.setAttribute('name','service_option');
    var opt_label = document.createElement('label');
    opt_label.innerHTML = "Display As Overlay";
    opt_element.appendChild(opt_cb);
    opt_element.appendChild(opt_label);
  }
  return opt_element;
}
