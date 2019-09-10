/*
** $Id: DataSelector.js,v 1.39 2014/09/13 23:09:41 dedasilv Exp $
** -@@@ Giovanni, Version $Name:  $
*/

// establish the component namespace
giovanni.namespace("ui");

/**
 * Constructor 
 * 
 * @this {giovanni.ui.DataSelector}
 * @author Chocka 
 */
giovanni.ui.DataSelector = function (id, config) {
  // store container id
  this.containerId = id;
  // retrieve and store the container HTML element
  this.container = document.getElementById(this.containerId);
  if (this.container==null) {
    alert("Error [giovanni.ui.DataSelector]: element '"+this.containerId+"' not found!");
    return;
  }
  
  // store config object
  this.config = config==null?{}:config;

  // panel stub - panel holds the pickers and is used for displaying them both in the initial
  // data selection screen and via the workspace later on
  this.panel = null;
  // picker stubs to reference the available pickers, if created
  this.servicePicker = null;
  this.datePicker = null;
  this.boundingBoxPicker = null;
  this.variablePicker = null;
  this.toolbar = null;
  this.shapePicker = null;

  // to hold the widgets created for every DataSelector instance
  this.widgets = [];

  this.render();

  REGISTRY.register(this.containerId,this);
};

giovanni.ui.DataSelector.SERVICE_PICKER = 1;
giovanni.ui.DataSelector.DATE_PICKER = 2;
giovanni.ui.DataSelector.BOUNDING_BOX_PICKER = 3;
giovanni.ui.DataSelector.SHAPE_PICKER = 4;
giovanni.ui.DataSelector.VARIABLE_PICKER = 5;
giovanni.ui.DataSelector.TOOLBAR = 6;

/**
 * Renders the data selector specific UI 
 * 
 * @this {giovanni.ui.DataSelector}
 * @author Chocka/K. Bryant 
 */
giovanni.ui.DataSelector.prototype.render = function () {

  // don't show the panel while building it...
  this.container.style.display = "none"; 
  // resize the panel to conform to the window
  //this.resize();
  // make the panel visible
  this.container.style.display = "block";
  // add window resize listener to make panel size conform to the window
  //YAHOO.util.Event.addListener(window,"resize",this.resize,{},this);

};

/**
 * Resizes the data selector 'panel' according to the window size
 *
 * @this {giovanni.ui.DataSelector}
 * @author K. Bryant
 */
giovanni.ui.DataSelector.prototype.resize = function () {
  	// calculate panel dimensions
	var height = giovanni.util.getWinSize()[1];
	var width = giovanni.util.getWinSize()[0];
  	var heightMargin = 120;
  	var widthMargin = 35;
	// resize panel
	this.container.style.height = (height - heightMargin) + "px";
	this.container.style.width = (width - widthMargin) + "px";
	//this.panel.cfg.setProperty("height", (height - heightMargin) + "px" );
	//this.panel.cfg.setProperty("width", (width - widthMargin) + "px");
	// also set the toolbar y-position
	//document.getElementById(this.containerId+"Toolbar").setAttribute('class','dataSelectorToolbar');
}

/**
 * Adds a UI widget to this DataSelector component 
 * 
 * @this {giovanni.ui.DataSelector}
 * @param {int (DataSelector constant), String or Function, Object}
 * @author Chocka 
 */
giovanni.ui.DataSelector.prototype.addWidget = function (name, url, config) {
  var addedWidget = null;
  var addedWidgetId = this.containerId;
  var addedWidgetDiv = document.createElement("div");
  //var panelBody = document.getElementById(this.container.id+"Panel");
  
  switch(name) {
  case giovanni.ui.DataSelector.SERVICE_PICKER:
    addedWidgetId += "SvcPk";
    addedWidgetDiv.id = addedWidgetId;
    this.container.appendChild(addedWidgetDiv);
    //panelBody.appendChild(addedWidgetDiv);
    config.portal = this.config.portal;
    addedWidget = new giovanni.widget.Services.Picker(addedWidgetId, url, config);
    this.servicePicker = addedWidget;
    break;
  case giovanni.ui.DataSelector.DATE_PICKER:
    addedWidgetId += "DtPk";
    addedWidgetDiv.id = addedWidgetId;
    this.container.appendChild(addedWidgetDiv);
    //panelBody.appendChild(addedWidgetDiv);
    addedWidget = new giovanni.widget.DatePicker(addedWidgetId, url, config);
    this.datePicker = addedWidget;
    break;
  case giovanni.ui.DataSelector.BOUNDING_BOX_PICKER:
    addedWidgetId += "BbPk";
    addedWidgetDiv.id = addedWidgetId;
    this.container.appendChild(addedWidgetDiv);
    //panelBody.appendChild(addedWidgetDiv);
    addedWidget = new giovanni.widget.BoundingBoxPicker(addedWidgetId, url, config);
    this.boundingBoxPicker = addedWidget;
    break;
  case giovanni.ui.DataSelector.SHAPE_PICKER:
    addedWidgetId += "ShPk";
    addedWidgetDiv.id = addedWidgetId;
    this.container.appendChild(addedWidgetDiv);
    //panelBody.appendChild(addedWidgetDiv);
    addedWidget = new giovanni.widget.ShapefilePicker(addedWidgetId, "", config);
    this.shapePicker = addedWidget;
    break;
  case giovanni.ui.DataSelector.VARIABLE_PICKER:
    addedWidgetId += "VarPk";
    addedWidgetDiv.id = addedWidgetId;
    this.container.appendChild(addedWidgetDiv);
    //panelBody.appendChild(addedWidgetDiv);
    if (config == undefined || config == null) config = {};
    config.allowMultiple = false;
    addedWidget = new giovanni.widget.VariablePicker(addedWidgetId, url, config);
    this.variablePicker = addedWidget;
    break;
  case giovanni.ui.DataSelector.TOOLBAR:
    addedWidgetId += "Toolbar";
    addedWidgetDiv.id = addedWidgetId;
    addedWidgetDiv.setAttribute('class','dataSelectorToolbar');
    this.container.appendChild(addedWidgetDiv);
    //panelBody.appendChild(addedWidgetDiv);
    addedWidget = new giovanni.widget.Toolbar(addedWidgetId,"",config);
    this.toolbar = addedWidget;
    //TODO temp fix - remove this - but make sure validate() is using a different 
    //list of 'validatable' widgets and not the general this.widgets array to which the toolbar will be added
    /*********************/
    //this.panel.render();
    return addedWidget;
    /*********************/
    break;
  default:
    return null;
  }
  this.widgets.push(addedWidget);
  //this.panel.render();
  return addedWidget;
};

/**
 * Aggregates values of all the picker components 
 * 
 * @this {giovanni.ui.DataSelector}
 * @author Chocka 
 */
giovanni.ui.DataSelector.prototype.getValue = function () {
  var value = "";
  if (this.widgets.length > 0) {
    var index = 0;
    var widgetValues = [];
    for (var i=0; i<this.widgets.length; i++) {
      var temp = this.widgets[i].getValue();
      if (temp!=null && temp!='') {
        widgetValues[index++] = temp;
      }
    }
    value = widgetValues.join("&");
  }
  return value;
};

giovanni.ui.DataSelector.prototype.validate = function () {
//  var registeredComps = REGISTRY.compRegistry;
//  var comp = null;
//  var valResp = new giovanni.widget.ValidationResponse(true, null);
//  for(var i=0;i<registeredComps.length;i++) {
//    comp = registeredComps[i];
//    if(comp != null) {
//      if(comp.obj.validate instanceof Function) {
//        valResp = comp.obj.validate();
//      } else { 
//        valResp = new giovanni.widget.ValidationResponse(false, "No validation method available for "+comp.name);
//      }
//      if(!valResp.isValid()) {
//        alert(valResp.msg);
//        break;
//      }
//    }
//  }
//  return valResp;
  
  // use this if REGISTRY component registration is changed or deprecated in any way
  // but the toolbar is also a widget and doesn't have a validation method (also no getId())
  // should have a separate list of 'validatable' widgets
  var valResp = new giovanni.widget.ValidationResponse(true, null);
  for (var i=0; i<this.widgets.length; i++) {
    if (this.widgets[i].validate instanceof Function) {
      valResp = this.widgets[i].validate();
    } else {
      valResp = new giovanni.widget.ValidationResponse(false, "No validation method available for "+this.widgets[i].getId());
    }
    if (!valResp.isValid()) {
      alert(valResp.getMessage());
      break;
    }
  }
  return valResp;
};

/***** other functions from the 'Component' interface that might need to be included *****/

// setValue

// validate

//loadFromCatalog
//loadFromQuery

// get id
giovanni.ui.DataSelector.prototype.getId = function () {
  return this.containerId;
};

//updateComponent
giovanni.ui.DataSelector.prototype.updateComponent = function () {
  this.setBookmarkURL();
};

// set bookmark
giovanni.ui.DataSelector.prototype.setBookmarkURL = function (){
  var values = this.getValue();
  window.history.replaceState({}, undefined, '#' + values);
};

//clearSelections
giovanni.ui.DataSelector.prototype.clearSelections = function () {
  for (var i=0; i<this.widgets.length; i++) {
    try {
      this.widgets[i].clearSelections();
    } catch (err) {
      console.log(err.message);
    }
  }
};

//resetSelections
giovanni.ui.DataSelector.prototype.resetSelections = function () {
  for (var i=0; i<this.widgets.length; i++) {
    try {
      this.widgets[i].resetSelections();
    } catch (err) {
      console.log(err.message);
    }
  }
};

giovanni.ui.DataSelector.prototype.hide = function () {
  this.container.style.visibility = "hidden";
  this.container.style.display = "none";
}

giovanni.ui.DataSelector.prototype.show = function () {
  this.container.style.display = "block";
  this.container.style.visibility = "visible";
}

giovanni.ui.DataSelector.prototype.showPanel = function (noshow, areThereResults) {
  if(this.toolbar.getControl('back')===undefined && areThereResults){
    var buttonConfig = {
        'type':'button',
        'name':'back',
        'label':'Go to Results',
        'title':'Go back to the workspace without plotting or changing any currently shown entries on the data selector',
        'action':this.config.session.showWorkspace,'source':this.config.session
    };
    this.toolbar.addButton(buttonConfig);
  }
  if (!noshow) this.show();
/*
  var p = this.getPanel();
  p.show();
*/
};

giovanni.ui.DataSelector.prototype.hidePanel = function () {
  //this.getPanel().hide();
  this.hide();
  // clean up calendars and map if they're still open; would rather use events for this, but
  // BoundingBoxPicker and DatePicker don't know anything about DataSelector, so it's hard for 
  // them to get a DataSelector event.
  for (var i=0;i<this.widgets.length;i++){
    if(this.widgets[i].hide instanceof Function){
      this.widgets[i].hide();
    }
  }
};

giovanni.ui.DataSelector.prototype.warnUser = function () {
  // service picker warnings:
  //   check the number of time steps;
  //   if it's larger than the configured number found for the service 
  //   (in giovanni_services.xml), then give the user the choice to modify the
  //   query; if they choose to proceed, warn them to perhaps get a cup of coffee
  var maxSteps = this.servicePicker.getMaxTimeSteps();
  var proceed = true;
  if(maxSteps){
    var timeStepsAndInterval = giovanni.util.getTimeSteps();
    var currentSteps = timeStepsAndInterval[0];
    if(currentSteps!=0 && currentSteps > maxSteps){
      proceed = confirm("This request could take a while (> 10 minutes).  Do you still want to proceed?");
      if(proceed) alert("Ok.  You might want to go get some coffee!");
    }
  }
  return proceed;
}

giovanni.ui.DataSelector.prototype.plotData = function () {
  session.initiatePlotData();
}
