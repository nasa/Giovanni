/*
 ** $Id: Workspace.js,v 1.58 2015/02/12 21:10:14 dedasilv Exp $
 ** -@@@ Giovanni, Version $Name:  $
 */

//establish the component namespace
giovanni.namespace("ui");

/** 
 * Construct the Workspace object - Workspace is responsible for creating the view
 * to the results.  It includes the ability to navigate through the elements of any
 * result and to keep the user informed of current result status.  It also allows 
 * standard housekeeping operations like getting help, sending feedback, and displaying
 * the data selection panel (so users can request new searches).  Workspace holds the 
 * HTML elements for ui.ResultView, ui.HistoryView and a ui.Toolbar; it also holds the 
 * objects themselves.  Workspace subscribes to app.History for UPDATE events to show 
 * the status of new requests.
 * 
 * @constructor
 * @this {giovanni.ui.Workspace}
 * @param {String,Object}
 * @returns {giovanni.ui.Workspace}
 * @author K. Bryant
 */
giovanni.ui.Workspace = function (id, config) {
	// store container id
	this.containerId = id;
	// retrieve and store the container HTML element
	this.container = document.getElementById(this.containerId);
	// if the container is nowhere to be found, show the error and return
	if (this.container==null) {
		console.log("Error [giovanni.ui.Workspace]: element '"+this.containerId+"' not found!");
		return;
	}

	// store config object
	this.config = config==undefined?{}:config;
	
	// session reference
	this.session = this.config.session==undefined?null:this.config.session;
	if (this.session==null){
		console.log("Error [giovanni.ui.Workspace]: session is null!");
	}

	this.resultView = null;
	this.toolbar = null;

	// panel height margins; used by resize()	
	//this.historyViewHeightMargin = 175;
	//this.resultViewHeightMargin = 165;
	this.historyViewHeightMargin = 243
	this.resultViewHeightMargin = 213;

	// currently selected history view node
	this.currentHistoryViewNode = null;
	// currently displayed result object
	this.currentResult = null;

	// show/hide events
	this.showEvent = new YAHOO.util.CustomEvent("WorkspaceShowEvent",this);
	this.hideEvent = new YAHOO.util.CustomEvent("WorkspaceHideEvent",this);

	this._plotCache = [];

        this.restoreFlag = false;

	this.render();

	// Session creates Workspace
	// Workspace renders the HTML elements necessary for display; uses CSS/DIV to do layout
	// Workspace creates HisotryView, ResultView and Toolbar
	// Workspace subscribs to app.History:UPDATE event to learn that there is a result to monitor
	// Workspace subscribes to app.Result:UPDATE event to enable adding of results to HistoryView
	// Workspace subscribes to ui.HistoryView clicks to update ResultView

};

/**
 * create the HTML elements necessary to display the workspace components; 
 * add the components
 * 
 * @this {giovanni.ui.Workspace}
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.render = function () {
        this.container.style.visibility = 'hidden';	
	// clear all button
        var clearAllBtn = document.createElement('button');
        clearAllBtn.id = 'sessionWorkspaceClear';
        clearAllBtn.setAttribute('title','Clear ALL results');
        clearAllBtn.innerHTML = 'Clear';
	// create history view div
	var historyViewDiv = document.createElement('div');
	historyViewDiv.id = this.containerId + "HistoryView";
	historyViewDiv.setAttribute('class','historyView');
        historyViewDiv.appendChild(clearAllBtn);
	this.container.appendChild(historyViewDiv);
	// create results view div
	var resultViewDiv = document.createElement('div');
	resultViewDiv.id = this.containerId + "ResultView";
	resultViewDiv.setAttribute('class','resultView');
	this.container.appendChild(resultViewDiv);
	// create toolbar div
	var toolbarDiv = document.createElement('div');
	toolbarDiv.id = this.containerId + "Toolbar";
	toolbarDiv.setAttribute('class','workspaceToolbar');

	this.container.appendChild(toolbarDiv);

	// create ResultView
	this.resultView = new giovanni.ui.ResultView(resultViewDiv.id,this.session.getHistory(), this);
	this.resultView.render();
	// create History View
	this.historyView = new giovanni.ui.HistoryView(historyViewDiv.id,this.session.getHistory());
	this.historyView.render();
	// create Toolbar
	var toolbarConfig = [
		{'type':'link','name':'ackPolicy','label':'Acknowledgment Policy',
			'title':'Policy regarding publication using Giovanni data',
			'action':'','source':this,
			'cssClass':'ackPolicy',
			'args':{
				'url':'https://giovanni.gsfc.nasa.gov/giovanni/doc/UsersManualworkingdocument.docx.html#h.765ut7soz9is',
				'target':'giovanniAckPolicy',
				'newWindow':false
			       }
		},
                {'type':'button','name':'selectData','label':'Back to Data Selection',
                        'title':'Make new data selections to generate a new plot',
                        'action':this.showDataSelector,'source':this}
                     
	];
	this.toolbar = new giovanni.widget.Toolbar(toolbarDiv.id,"",toolbarConfig);
	toolbarDiv.setAttribute('class','workspaceToolbar');
	// subscribe to history:UPDATE event
	this.session.getHistory().resultAddEvent.subscribe(this.handleResultAddEvent,this);
	// subscribe to historyView:CLICK event
	this.historyView.resultSelectionEvent.subscribe(this.handleResultSelectionEvent,this);
        // clear all button
        var self = this;
        $('#sessionWorkspaceClear').click(function () {
          if (confirm('Removes all results.  Are you sure?')) {
            /* since we're going to remove all results, stop listening to current result */
            self.getCurrentResult().resultUpdateEvent.unsubscribe(self.resultView.handleResultUpdateEvent, self.resultView);
            /* clear the result view */
            self.resultView.clearView();
            /* show a quick status message */
            //self.resultView.showStatus("Clearing all results...<i class='fa fa-spinner fa-spin' aria-hidden='true'></i>");
            self.resultView.showStatus("Clearing all results...<i class='fa fa-spinner fa-spin' aria-hidden='true'></i>");
            /* hide/delete all results */
            var url = './daac-bin/service_manager.pl?';
            var sessionId = session.sessionId;
            if(sessionId){
              /* great, we've a sessionId; use that to get the session and all results therein  */
              $.ajax({
                url: url + 'session=' + sessionId + '&format=json&random=' + new Date().getTime(),
                success: function (o) {
                  if (typeof(Storage) !== "undefined") {
                    var user = sessionManager.getUser() ? sessionManager.getUser() : giovanni.util.getGuest();
                    sessionStorage.removeItem(user+'CurrentResult');
                  }
                  var resultSetCount = o.session.resultset ? o.session.resultset.length : 0;
                  for(var i=0;i<resultSetCount;i++){
                    var result = self.historyView.historyObject.results[i];
                    if (result && result.getStatus() && result.getStatus().getCode() &&
                        parseInt(result.getStatus().getCode()) >= 0) {
                      result.hide();
                    }
                  }
                  self.resultView.showStatus("");
                  //self.clear();
                },
                beforeSend: function (o) {
                  showProgress();
                },
                complete: function (o) {
                  hideProgress();
                },
                error: function (o) {
                  console.log("Workspace.clearAll: problem getting results to hide/delete: " + o);
                },
                context: this,
                async:true
              });
            }
          }
        });
};


giovanni.ui.Workspace.prototype.getToolbar = function() {
    return this.toolbar;
}

/* Handle the history update event (same as 'ResultAddEvent')
 *  
 *  @params {YAHOO.util.Event,Object}
 *  @author K. Bryant
 */
giovanni.ui.Workspace.prototype.handleResultAddEvent = function (type,args,self) {
    var results = self.session.getHistory().getResults();
    var res = results[results.length-1];
    // notify history view that history has been updated
    var nodeAdded = self.historyView.addResultNode(res);
    // if there is a node added AND the restore flag is set to false
    // add the result to the ResultView.  The restoreFlag is set by
    // Session based on whether a restore operation is occurring (true) or
    // whether a plot initiation is occurring (false)
    if (nodeAdded && !self.restoreFlag) { 
      // add a result to result view
      self.resultView.addResult(res);
    }
    if (results.length > 0) {
      // show the workspace instead of the data selector
      var view = sessionManager.getUserView();
      if (view === 'workspace') {
          self.show();
      } else if (view === 'dataSelection') {
          self.hide();
          session.dataSelector.showPanel(false,true);
      } else {
          // no view?
          sessionManager.setUserView('workspace');
          session.dataSelector.showPanel(true,true);
          self.show();
      }
    }
};

/*
 * Handle the history selection event (same as 'ResultSelectionEvent')
 * 
 * @params {YAHOO.util.Event,Object}
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.handleResultSelectionEvent = function (type,args,self) {
	// notify results view that it needs to update
	self.currentHistoryViewNode = args[0];
	var result = self.session.getHistory().getResultById(self.currentHistoryViewNode.id);
	//self.resultView.update(args[0],result);
	self.resultView.handleResultSelectionEvent(args[0],result);
};

/*
 * Resizes the workspace according to the window height
 * 
 * @params {YAHOO.util.Event,Object}
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.resize = function (e,o) {
//	document.getElementById(this.containerId+'ResultView').style.height = (giovanni.util.getWinSize()[1] - this.resultViewHeightMargin) + "px";
 //       document.getElementById(this.containerId+'HistoryView').style.height = (giovanni.util.getWinSize()[1] - this.historyViewHeightMargin) + "px";
};

/*
 * Show the data selector
 * 
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.showDataSelector = function (e,o) {
  // remember the view
  sessionManager.setUserView('dataSelection');
  // hide the workspace
  this.hide();
  // show the data selector
  var areThereResults = this.historyView && 
    this.historyView.historyObject && 
    this.historyView.historyObject.results &&
    this.historyView.historyObject.results.length > 0 ? true : false;
  this.session.getDataSelector().showPanel(false,areThereResults);
  // hide the 'back to results' button if there are no results
  var backBtn = this.session.getDataSelector().toolbar.getControl('back');
  if (backBtn) {
    var backBtnElem = $('#'+backBtn._button.id);
    if (areThereResults) {
      $(backBtnElem).css('display','block');
      $('#sessionWorkspaceClear').css('display','block');
    } else {
      $(backBtnElem).css('display','none');
      $('#sessionWorkspaceClear').css('display','none');
    }
  }
};

/**
 * Hide the workspace
 *
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.hide = function () {
	// hide html elements
	this.container.style.visibility = 'hidden';
	this.container.style.display = 'none';
	// clean up the result view
	this.resultView.hide();
	// set the page title
	document.title = "Giovanni - Data Selection";
	// fire the hide event
	this.hideEvent.fire();
}

/*
 * Show the workspace (and hide the data selector)
 * 
 * @this {giovanni.ui.Workspace}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.show = function() {
	// hide the data selector
	this.session.getDataSelector().hidePanel();
	// show the html elements
	this.container.style.visibility = 'visible';
	this.container.style.display = 'block';
	// show those result view elements were hidden
	this.resultView.show();
	// check the latest result to see if it's ongoing
	//this.checkLatestStatus();
	// set the page title to incorporate the latest result info
	document.title = "Giovanni - " + this.getCurrentResult().getTitle();
        // show the clear button for history tree
        $('#sessionWorkspaceClear').css('display','block');
        // and just in case it isn't gone, clear the splash
        clearSplash();
};

/*
 * Check the status of the latest result
 *
 * @this {giovanni.ui.Workspace}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.checkLatestStatus = function () {
	// get the results from history
	var results = this.session.getHistory().getResults();
	// find the 'current' result
	var res = results[results.length-1];
	// set the appropriate result view
	this.resultView.getStatus(res);
};

/*
 * Return the currently displayed result object
 */
giovanni.ui.Workspace.prototype.getCurrentResult = function () {
	return this.resultView.getCurrentResult();
};

/*
 * Display the result plots as PDF
 *
 * @this {giovanni.ui.Workspace}
 * @author K. Bryant
 */
giovanni.ui.Workspace.prototype.displayAsPDF = function () {
        var res = this.getCurrentResult();
    if(res.hasImageCollection()){
        var pdfUrl = res.getImageCollection();
        var width = 700;
        var height = 500;
        var ua = navigator.userAgent;
        if(ua.indexOf("Mac")>-1){
            width=1;
            height=1;
        }
        var imgwin = 
            window.open(pdfUrl,
            	"pdfDisplay",
            	"location=no,menubar=0,toolbar=0,status=0,titlebar=0,resizable=yes,scrollbars=yes,top=0,left=-5000,height="+height+",width="+width);
	}else if(this.resultView.sp!=undefined){
		this.resultView.sp.chart.exportChart({
			type: 'application/pdf',
			filename: 'my-pdf'
		});
    }else{
            alert("No PDF available for "+res.getTitle());
    }
};

giovanni.ui.Workspace.prototype.addToPlotCache = function (source, plotObj) {
	this._plotCache[ source ] = plotObj;
};
giovanni.ui.Workspace.prototype.pullFromCache = function (source) {
	return this._plotCache[ source ];
};
giovanni.ui.Workspace.prototype.clearCache = function () {
	this._plotCache = [];
};

giovanni.ui.Workspace.prototype.createHistoryView = function () {
        // re-create History View
        this.historyView = new giovanni.ui.HistoryView(this.containerId+"HistoryView",this.session.getHistory());
        this.historyView.render();
};

/* Used to clear session display in the event of a logout */
giovanni.ui.Workspace.prototype.clear = function () {
    // clear history and result views
    if (this.historyView) this.historyView.clear(); 
    if (this.resultView) this.resultView.clearView();
    $('#sessionWorkspaceClear').css('display','none');
}
