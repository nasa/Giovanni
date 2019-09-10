/**
 * $Id: ResultView.js,v 1.179 2015/08/11 16:42:04 mpetrenk Exp $
 * -@@@ aGiovanni, $Name:  $
 * 
 * Creates a view of the giovanni.app.Result. It renders the 
 * snapshot of the *currently selected* Giovanni Result as selected
 * from giovanni.app.History via giovanni.ui.HistoryView
 */

giovanni.namespace('giovanni.ui.ResultView');

/**
 * Constructor
 * 
 * @constructor
 * @this {giovanni.ui.ResultView}
 * @param {String, containerId}
 * @returns {giovanni.ui.ResultView}
 * @author K. Bryant
 */
giovanni.ui.ResultView = function (containerId, historyObj, workspace)

{
    // set the container id
    this.containerId = containerId;
    // set the container
    this.container = document.getElementById(this.containerId);
    // check to see if the container was indeed set; return if otherwise
    if (this.container === null) {
        console.log("Error [giovanni.ui.ResultView]: element '" + this.containerId + "' was not found!");
        return;
    }
    // set the history object reference
    this.history = historyObj;
    if (this.history === null) {
        console.log("Error [giovanni.ui.ResultView]: history object is null");
        return;
    }
    // hold the latest result
    this.currentResult = null;
    // hold plot option default values
    this.defaults = [];
    // hold whether a result has been re-plotted or not
    this.resultReplotted = [];
    // hold the status msg
    this.statusMsg = "";
    this.cancelled = false;

    // workspace reference  
    this.workspaceRef = workspace;

    // handle login events
    if (login && login.enabled) {
        login.loginEvent.subscribe(this.handleLoginEvent, this);
    }

    // hold asynchronous request status for intereactive maps
    this.mapRequests = [];

    // hold the plotted plots (plot.src is the key)
    this.plotted = [];
    this.refreshed = [];

    // hold the users selections (plot options, etc.)
    this.userSelections = [];

    this.displayedUserInput = false;

    this.interactiveObjects = [];
    this.interactiveStates = [];

    // current view
    this.currentView = null;
    // view content - used to compare content fetched from
    // the server so we're not constantly updating during
    // active results processing
    this.viewContent = [];
    this.viewContent['lineageLength'] = 0;

    // progress bar
    this.pb = undefined;
};

/**
 * Renderer for ResultView
 * 
 * @this {giovanni.ui.ResultView}
 * @param {}
 * @returns {}
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.render = function () {
    // result view container (displays the results of clicking on a HistoryView node)
    this.resultViewContainer = document.createElement('div');
    //this.resultViewContainer.setAttribute('class','resultViewContainer');
    this.resultViewContainer.setAttribute('id', 'resultViewContainer');
    // add container children
    this.statusContainer = document.createElement('div');
    this.statusContainer.setAttribute('id', 'statusContainer');
    this.resultViewContainer.appendChild(this.statusContainer);

    this.container.appendChild(this.resultViewContainer);

    this.resultContainer = document.createElement('div');

    //this.resultContainer.setAttribute('class','resultViewContainer');
    this.resultContainer.setAttribute('id', 'resultContainer');
    this.resultViewContainer.appendChild(this.resultContainer);

    // overall caption element
    this.overallCaption = document.createElement('div');
    this.overallCaption.setAttribute('id', 'overallCaption');
    this.resultViewContainer.appendChild(this.overallCaption);

    // set window resize listener
    YAHOO.util.Event.addListener(window, 'load', this.resize, {}, this);
    YAHOO.util.Event.addListener(window, 'resize', this.resize, {}, this);
};

/**
 * Handles the addition of a result
 *
 * @this {giovanni.ui.ResultView}
 * @param {Object}
 * @returns void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.addResult = function (res) {
    if (!res) return;
    this.currentResult = res;
    this.clearStatus();
    this.clearView();
    this.setView('Status');
    this.currentResult.resultUpdateEvent.subscribe(this.handleResultUpdateEvent, this);
};

/**
 * Switches the result being viewed given the selection event from ui.HistoryView
 *
 */
giovanni.ui.ResultView.prototype.handleResultSelectionEvent = function (historyViewNode, res) {
    if (this.currentResult !== null) {
        this.currentResult.resultUpdateEvent.unsubscribe(this.handleResultUpdateEvent, this);
    }
    this.currentResult = res;
    if (historyViewNode.type != 'Debug') {
        this.clearStatus();
        this.clearView();
    }
    this.currentResult.resultUpdateEvent.subscribe(this.handleResultUpdateEvent, this);
    this.update(historyViewNode, this.currentResult);
};

/**
 * called every time there is a result update
 *
 * @this {YAHOO.util.CustomEvent}
 * @param {Event(String),Array,Object)
 * @returns void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.handleResultUpdateEvent = function (type, args, o) {
    o.update(null, this);
};

giovanni.ui.ResultView.prototype.handleLoginEvent = function (type, args, o) {
    if (o.currentView === 'Downloads' ||
        o.currentView === 'Lineage') {
        if (login && login.enabled && login.isLoggedIn) {
            $("#resultContainer").removeClass("disabledElement");
            $('#dataAccessWarning').remove();
        } else {
            $("#resultContainer").addClass("disabledElement");
            if (!$('#dataAccessWarning').length) {
                $('#sessionWorkspaceResultView').append(
                    '<div id="dataAccessWarning" class="dataAccessWarning">\
                         Please \
                     <a href="#" id="dataAccessLogin">login to Earthdata</a> \
                     to download data\
                   </div>');
                $('#dataAccessLogin').click(login.checkLogin.bind(login));
            }
        }
    }
}
/**
 * Updates the rendered view of the result based on the app.Result update event
 * 
 * @this {giovanni.ui.ResultView}
 * @param {Object}
 * @returns void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.update = function (historyViewNode, res) {
    // if 'res' is null, use the ResultView's current result
    if (!res && this.currentResult)
        res = this.currentResult;
    // if the historyViewNode is null, create a stand-in object
    var view;
    if (!historyViewNode) {
        view = !this.currentView ? 'Status' : this.currentView;
        historyViewNode = {
            type: view,
            id: res.getId()
        };
    } else { // otherwise, set the view using the history node type
        view = historyViewNode.type;
    }
    // if the history view node type is 'Plots', change it to 'Status' since
    // that's how the rest of the code will treat an incomplete result
    if (historyViewNode.type == 'Plots' && res.getStatus().getPercentComplete() < 100)
        historyViewNode.type = 'Status';
    // make sure history view context is set....really for 'Plot Options' behavior...
    //if (!this.workspaceRef.restoreFlag && this.workspaceRef.historyView.getContext() && view !== 'Delete')
    //    this.workspaceRef.historyView.setContext(res.getId(), historyViewNode.type);
    // set the current history view node reference
    this.currentHistoryViewNode = {
        type: historyViewNode.type,
        id: historyViewNode.id
    };
    // set page title
    document.title = "Giovanni - " + res.getTitle();

    // route the view update
    switch (view) {
    case "Status":
        this.displayStatus(res);
        break;
    case "User Input":
        this.displayUserInput(res);
        break;
    case "Plots":
        this.displayPlots(res);
        break;
    case "Downloads":
        this.displayDownloads(res);
        break;
    case "Lineage":
        this.displayLineage(res);
        break;
    case "Debug":
        this.displayDebug(res);
        break;
    case "Delete":
        this.deleteResult(res);
        break;
    default:
        console.log("Error [giovanni.ui.ResultView:update()]: unknown result type: " + historyViewNode.type);
        // since the node type is null, see if we can check the status
        this.displayStatus(res);
    }
};

/*
 * Setter/getter for current result
 *
 */
giovanni.ui.ResultView.prototype.setResult = function (res) {
    this.currentResult = res;
};
giovanni.ui.ResultView.prototype.getResult = function () {
    return this.currentResult;
};
giovanni.ui.ResultView.prototype.setView = function (view) {
    this.currentView = view;
};
giovanni.ui.ResultView.prototype.getView = function () {
    return this.currentView;
};

/* 
 * Called in response to a result selection event (registered via Workspace)
 *
 * @this {giovanni.ui.ResultView}
 * @params {Object,giovanni.app.Result}
 * @return {}
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.getStatus = function () {
    var node = this.currentHistoryNode;
    // if the stored node is null, create a default node
    if (node === null) {
        node = {};
        node.id = res.getId();
        node.type = this.currentView !== null ? this.currentView : 'Status';
    }

    // if the node type is 'User Input', use the saved view (aka type)
    if (node.type === 'User Input') node.type = this.currentView;
    // update the view
    this.update(node, res);
};

/**
 * Display the status of a result; if the status is complete (==100%),
 * display the plot
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return void
 * @author K. Bryant
 **/
giovanni.ui.ResultView.prototype.displayStatus = function (res) {
    // result argument can be null, so check
    if (res === null) {
        res = this.currentResult;
    } else if (res !== this.currentResult) {
        return;
    }
    var self = this;
    // set the view
    // for now we don't show view elements while we're displaying
    // status, so clear the view.  This should be re-designed so 
    // status can be part of the HistoryView as called for in the
    // original design.
    if (this.currentView !== 'Plots' && this.currentView !== 'Status')
        this.clearView();

    this.currentView = 'Status';
    // need to track whether we've 'displayed' the user input 
    // previously (since it takes the UI back to data selection;
    // this is a hack which should be updated.  User input should
    // be displayed as part of the HistoryView tree/list
    this.displayedUserInput = false;
    // get status percent and code
    var percent = new Number(res.getStatus().getPercentComplete()).valueOf();
    var code = new Number(res.getStatus().getCode()).valueOf();
    // fetch status message - we're going to use it as a check for updating status
    // as well as simply assigning to output 
    var msg = this.statusMsg = res.getStatus().getMessage() || "";
    // if there is no status error, check percent complete; 
    if (code === 0) {
        // if it's < 100, keep going; else unsubscribe from updates
        if (percent < 100) {
            // if the progress bar (pb) is undefined, create it
            if (this.pb === undefined) { // set up the progress bar
                var progressBarContainer = document.createElement('div');
                var bar = document.createElement('div');
                bar.setAttribute('id', 'progressBar');
                var text = document.createElement('div');
                text.setAttribute('id', 'statusText');
                var progressImage = document.createElement('img');
                progressImage.setAttribute('src', './img/progress.gif');
                progressImage.setAttribute('id', 'progressSpinner');
                progressBarContainer.appendChild(bar);
                var cancelButton = document.createElement('button');
                cancelButton.innerHTML = 'Cancel';
                cancelButton.setAttribute('id', 'cancelButton');
                cancelButton.disabled = true;
                cancelButton.onclick = function () {
                    // stop listening while the user decides to cancel
                    res.resultUpdateEvent.unsubscribe(self.handleResultUpdateEvent, self);
                    if (confirm("Do you want to cancel the execution of this service?")) {
                        document.getElementById('statusText').innerHTML = "Cancelling service now ...";
                        res.cancelServiceRequest();
                        // start listening again now that the cancel request has been issued
                        res.resultUpdateEvent.subscribe(self.handleResultUpdateEvent, self);
                        self.cancelled = true;
                    } else {
                        // no cancel, start listening again
                        res.resultUpdateEvent.subscribe(self.handleResultUpdateEvent, self);
                    }
                };
                progressBarContainer.appendChild(cancelButton);
                progressBarContainer.appendChild(progressImage);
                this.statusContainer.appendChild(progressBarContainer);
                this.statusContainer.appendChild(text);
                this.statusContainer.style.display = 'block';
                this.pb = new YAHOO.widget.ProgressBar();
                this.pb.set('width', 400);
                this.pb.set('height', 20);
                this.pb.set('minValue', 0);
                this.pb.set('maxValue', 100);
                this.pb.set('anim', true);
                this.pb.render('progressBar');
                // use animation to make the rendering between percent updates a little smoother
                var anim = this.pb.get('anim');
                this.pb.duration = 3;
                anim.method = YAHOO.util.Easing.easeOut;
                this.pb.set('value', parseInt(res.getStatus().getPercentComplete()));
                text.innerHTML = this.statusMsg;
            } else { // progress bar already exists so just update it
                // don't animate if the value is zero (another result is using the
                // progress bar and animation make it's look like the bar is moving
                // backwards when the results are switched
                if (percent === 0) {
                    this.pb.set('anim', false);
                } else {
                    this.pb.set('anim', true);
                }
                this.pb.set('value', percent);
                document.getElementById('statusText').innerHTML = this.statusMsg;
                if (res.resultId && $('#cancelButton').prop('disabled')) {
                    $('#cancelButton').prop('disabled', false);
                }
            }
        } else { // plot is finished
            // stop updates
            res.resultUpdateEvent.unsubscribe(this.handleResultUpdateEvent, this);
            // reset progress bar
            this.pb = undefined;
            // cleanup statusDiv
            if (code > 0) {
                this.showStatus(this.statusMsg);
            }
        }
    } else if (code === -1) {
        res.resultUpdateEvent.unsubscribe(this.handleResultUpdateEvent, this);
        this.showStatus("Plot request cancelled or deleted");
        this.pb = undefined;
    } else { // there's an error of some sort
        // stop the updates
        res.resultUpdateEvent.unsubscribe(this.handleResultUpdateEvent, this);
        // reset progress bar
        this.pb = undefined;
        // show the status message/error
        this.showStatus(this.statusMsg);
    }
    // regardless of status, check to see if there are results and display them;
    // this handles the 'interim' results condition in which some plots are completed
    if (res.hasPlots() && percent < 100 && !this.cancelled) {
        this.displayPlots(res, "interim");
    } else if (res.hasPlots() && percent === 100 && !this.cancelled) {
        // this handles default selection of the history parent node which
        // will always enter ResultView.update as 'Status' - so when the results
        // are all done, we need something to display the plots despite the
        // fact that the request is one for 'Status'
        this.displayPlots(res);
    }

    // keep the size of the result view container consistent
    this.resize();
};


/**
 * Displays the user input by navigating back to the data selection screen.
 * Yes, this a bit kludgy.  The original design calls for user criteria to
 * be shown in the HistoryView tree.  Hopefully, that's what will happen
 * in the future...at which point the contents of this method can be retired.
 * 
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return void
 * @author K. Bryant
 **/
giovanni.ui.ResultView.prototype.displayUserInput = function (res) {
    if (res.hasCriteria()) {
        var crit = res.getCriteria();
        var query = crit.query[0].value;
        var comps = REGISTRY.getUIComponents();
        for (var i = 0; i < comps.length; i++) {
            if (comps[i].loadFromQuery instanceof Function) {
                comps[i].loadFromQuery(query);
            }
        }
        this.workspaceRef.showDataSelector(null, null);
        this.displayedUserInput = true;
    } else {
        this.clearStatus();
        this.resultContainer.innerHTML = " user input information for " + res.getTitle() + " (id=" + res.getId() + ") is not available";
    }
};

/**************** temporarily disabled - required functionality - do not delete ******************/
/**
giovanni.ui.ResultView.prototype.displayUserInput = function (res) {
  // clear the container
  this.resultViewContainer.innerHTML = "";
  // retrieve and display user inputs, from the result, in the ResultView container
  if(res.hasCriteria()){
    var crit = res.getCriteria();
    var query = crit.query[0].value;
    //session=ED9817F0-16D6-11E2-9606-2B95EA853B8F                not required to be displayed
    //service=SPACE_TIME_AVERAGE                                  Plot Type
    //starttime=2005-01-01                                        Date Range from
    //endtime=2005-01-05T23:59:59Z                                Date Range to
    //bbox=-180,-90,180,90                                        Bounding Box
    //data=OMTO3d_003_UVAerosolIndex                              Data Variables
    //variableFacets=parameterMeasurement%3AAerosol%20Index%3B    not required to be displayed
    //dataKeyword=Aerosol%20Index                                 not required to be displayed
    //portal=GIOVANNI                                             not required to be displayed
    //format=json                                                 not required to be displayed
    var parms=query.split('&');
    var svc='';
    var start='';
    var end='';
    var box='';
    var datavar='';
    for (var i=0; i<parms.length; i++) {
      var parm = parms[i].split('=');
      switch(parm[0]) {
      case 'service': svc = parm[1]; break;
      case 'starttime': start=parm[1]; break;
      case 'endtime': end=parm[1].split('T')[0]; break;
      case 'bbox': box=parm[1]; break;
      case 'data': datavar=decodeURIComponent(parm[1]);break;
      }
    }
    
    var htmlStr = '';
    htmlStr += '<tr><td>Plot Type</td><td>'+svc+'</td></tr>';
    htmlStr += '<tr><td>Date Range</td><td>'+start+' to '+end+'</td></tr>';
    htmlStr += '<tr><td>Bounding Box</td><td>'+box+'</td></tr>';
    htmlStr += '<tr><td>Date Variable</td><td>'+datavar+'</td></tr>';

    var table = document.createElement('table');
    table.class = 'criteria_display_table';
    table.innerHTML = htmlStr;
    this.resultViewContainer.appendChild(table);
    this.resultViewContainer.appendChild(document.createElement('br'));
    
    var loadButton = document.createElement('input');
    loadButton.id='loadCriteriaBtn';
    loadButton.type='button';
    loadButton.value='Load';
    loadButton.title='Load this input onto the data selection page';
    this.resultViewContainer.appendChild(loadButton);
    YAHOO.util.Event.addListener(loadButton,'click',function(event, parms) {
      var query = parms[0];
      var workspaceRef = parms[1];
      var comps = REGISTRY.getUIComponents();
      for (var i=0; i < comps.length; i++) {
        if(comps[i].loadFromQuery instanceof Function) {
          comps[i].loadFromQuery(query);
        }
      }
      workspaceRef.showDataSelector(event, null);
    },[query,this.workspaceRef] ,this);
  } else {
    this.resultViewContainer.innerHTML = "User input information for " + res.getTitle() + " (id=" + res.getId() + ") is not available";
  }
};
**/

/*
 * Handles the rendering of plots when a user clicks on a 'Plots' child node in HistoryView;
 * plots should be images....unless they are typed as interactive
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.displayPlots = function (res, fromstatus) {
    if (res === null) res = this.currentResult;
    if (this.currentView === 'Downloads' ||
        this.currentView === 'Lineage') {
        this.clearView();
    }
    if (res.getStatus().getPercentComplete() == 100) {
        this.clearStatus();
        this.clearView();
        // if the result has no status code, return
        var resStatusCode = res.getStatus().getCode();
        if (resStatusCode && parseInt(resStatusCode) === -1) 
          return;
    }
    this.currentView = 'Plots';
    this.overallCaption.innerHTML = res.getCaption() === undefined ? "" : res.getCaption();
    var interim = fromstatus ? true : false;

    // temporary reset of interactive time series object - a bit of a HACK to handle
    // this kind of plot grouping - need to rework
    this.its = undefined;

    // append to the ResultView container....
    if (res.hasPlots()) {
        //var plotKeys = this.getSorted(res.getPlots());
        var groupedPlots = res.getGroupedPlots();
        // determine if plots are truly grouped (needing group print and synch'd options
        var areGrouped = this.areGrouped(res);
        for (var g in groupedPlots) {

            // build a group container if there isn't one already
            var groupContainer = document.getElementById('groupContainer' + g);
            var decorations = res.getGroupDecorations()[g];
            var newContainer = false;
            if (groupContainer === null) {
                newContainer = true;
                groupContainer = document.createElement('div');
                groupContainer.setAttribute('id', 'groupContainer' + g);
                groupContainer.setAttribute('class', 'groupContainer');
                this.resultContainer.appendChild(groupContainer);

                // if there is a group title, add it      
                if (decorations.title) {
                    var groupTitle = document.createElement('div');
                    groupTitle.setAttribute('class', 'groupTitle');
                    groupTitle.innerHTML = decorations.title;
                    groupContainer.appendChild(groupTitle);
                    // if really grouped, build toolbar
                    if (areGrouped) {
                        var groupToolbar = document.createElement('div');
                        groupToolbar.setAttribute('class', 'groupToolbar');
                        groupContainer.appendChild(groupToolbar);
                    }
                }
            }

            // build plots
            //var plotKeys = this.getSanitizedPlotKeys(groupedPlots[g],res,g);
            var plotKeys = groupedPlots[g];
            var plotContainerName = 'plotContainer';

            // loop through giovanni.app.Result.Plot objects
            for (var i in plotKeys) {
                // get the plots from the result
                //var plot = res.getPlots()[i];
                var plot = res.getGroupedPlots()[g][i];
                // create the plot container id - used only to make sure plot ids are different?
                var plotId;
                // if the plot has already been plotted, don't do it again
                if (this.isPlotted(plot.getSource(), g)) {
                    plotId = this.getPlotted(plot.getSource(), g);
                    if (document.getElementById(plotId) === undefined) {
                        var frameDiv = document.createElement('div');
                        frameDiv.setAttribute('class', 'imageFrame');
                        var plotDiv = document.createElement('div');
                        plotDiv.setAttribute('name', plotContainerName);
                        plotDiv.setAttribute('id', plotId);
                        plotDiv.innerHTML =
                            "<span class='error' style='width:100px; max-width:100px;'>" +
                            "Rendering " +
                            giovanni.util.extractQueryValue("layer") +
                            " variable..." +
                            "<img src='./img/progress.gif'/>" +
                            "</span>";
                    }
                } else { // add current plot to list of plotted plots - what about failures?
                    plotId = plotContainerName + Math.floor(Math.random() * 1000000);
                    this.setPlotted(plot.getSource(), plotId, g);

                    var oldSource = this.interactiveObjects['_current'];
                    var oldPlot = oldSource ? this.interactiveObjects[oldSource] : null;
                    if (oldPlot && oldPlot.exportState) {
                        this.interactiveStates[oldSource] = oldPlot.exportState();
                    }
                    this.interactiveObjects['_current'] = res.getId() + "_" + plot.getSource();
                    /* if type is interactive scatter plot, handle separately */
                    /* regardless of plot type, create frame... */
                    var frameDiv = document.createElement('div');
                    frameDiv.setAttribute('class', 'imageFrame');
                    /* create map div...because we most often display maps */
                    var plotDiv = document.createElement('div');
                    plotDiv.setAttribute('name', plotContainerName);
                    plotDiv.setAttribute('id', plotId);
                    plotDiv.innerHTML =
                        "<span class='error' style='width:100px; max-width:100px;'>" +
                        "Rendering " +
                        giovanni.util.extractQueryValue(plot.getSource(), "layer") +
                        " variable..." +
                        "<img src='./img/progress.gif'/>" +
                        "</span>";
                }

                /* build plot objects based on plot type */
                switch (plot.getType()) {
                case 'INTERACTIVE_SCATTER_PLOT':
                    var crit = res.getCriteria();
                    var query = crit.query[0].value;
                    this.addInteractiveScatter(
                        plotId,
                        plot.getSource(),
                        //this.resultContainer,
                        groupContainer,
                        query);
                    break;
                case 'INTERACTIVE_OVERLAY_MAP':
                    if (i == 0) {
                        // if we're at zero, this is a refreshed
                        // result set, so clear the refreshed state
                        if (!$('.overlayImageFrame').length) {
                            // add the plot div
                            frameDiv.appendChild(plotDiv);
                            // handling for new overlay map
                            frameDiv.setAttribute('class', 'overlayImageFrame');
                            // create the overlay map...for now
                            plotDiv.innerHTML = "";
                            /* add frame to container */
                            groupContainer.appendChild(frameDiv);
                        }
                        var mapCache = this.workspaceRef.pullFromCache(g + res.id);
                        var map = mapCache ? mapCache : undefined;
                        if (!map) {
                            // create new map
                            map = new giovanni.widget.OverlayMap(
                                plotId, {
                                    'userBbox': giovanni.util.extractQueryValue(res.getCriteria().query[0].value, 'bbox'),
                                    'savedState': null,
                                    'maxPlots': res.getPlots().length,
                                    'multiLayer': true,
                                    'plotData': {
                                        'resultId': res.resultId,
                                        'sessionId': res.sessionId,
                                        'resultSetId': res.resultSetId,
                                        'queryData': res.queryData
                                    },
                                    'enableReplot': res.enableReplot,
                                    'workspaceRef': this.workspaceRef
                                }
                            );
                            map.addLayerData(plot);
                            this.workspaceRef.addToPlotCache(g + res.id, map);
                        } else {
                            if (!interim || newContainer) {
                                map.refresh(plotId);
                            }
                            // check to see if the current plot has been added
                            if (!map.addedVariables[plot.getSource()]) {
                                map.addLayerData(plot);
                            }
                        }
                    } else { // don't build another map; add layer data if necessary
                        var mapCache = this.workspaceRef.pullFromCache(g + res.id);
                        var storedMap = mapCache ? mapCache : undefined;
                        if (storedMap) {
                            storedMap.addLayerData(plot);
                            // check to see if the current plot has been added
                            if (!storedMap.addedVariables[plot.getSource()]) {
                                storedMap.addLayerData(plot);
                            }
                        } else {
                            console.log("ResultView.displayPlot():  Could not find plot object with id: " + storedMap.containerId);
                        }
                    }
                    break;
                case 'INTERACTIVE_MAP':
                    // max plots is 1 - one layer per interactive map - even though we're driving it with OverlayMap
                    var mapCache = this.workspaceRef.pullFromCache(g + res.id + plot.getSource());
                    var map = mapCache ? mapCache : undefined;
                    if (!map) {
                        // add the plot div
                        frameDiv.appendChild(plotDiv);
                        // handling for new overlay map
                        frameDiv.setAttribute('id', plotId + "Frame");
                        frameDiv.setAttribute('class', 'overlayImageFrame');
                        // create the overlay map...for now
                        plotDiv.innerHTML = "";
                        /* add frame to container */
                        groupContainer.appendChild(frameDiv);
                        // create new map
                        map = new giovanni.widget.OverlayMap(
                            plotId, {
                                'userBbox': giovanni.util.extractQueryValue(res.getCriteria().query[0].value, 'bbox'),
                                'savedState': null,
                                'maxPlots': 1,
                                'multiLayer': false,
                                'plotData': {
                                    'resultId': res.resultId,
                                    'sessionId': res.sessionId,
                                    'resultSetId': res.resultSetId,
                                    'queryData': res.queryData
                                },
                                'enableReplot': res.enableReplot,
                                'workspaceRef': this.workspaceRef
                            }
                        );
                        map.addLayerData(plot);
                        this.workspaceRef.addToPlotCache(g + res.id + plot.getSource(), map);
                    } else {
                        if (!interim || newContainer) {
                            map.refresh(plotId, groupContainer);
                        }
                        // check to see if the current plot has been added
                        if (!map.addedVariables[plot.getSource()]) {
                            map.addLayerData(plot);
                        }
                    }
                    break;
                case 'MAP_ANIMATION':
                    //frameDiv.appendChild(plotDiv);
                    /* add frame to container */
                    //frameDiv.setAttribute('class', 'animationImageFrame');
                    //groupContainer.appendChild(frameDiv)
                    var mapCache = this.workspaceRef.pullFromCache(g + res.id + plot.getSource());
                    var animatedMap = mapCache ? mapCache : undefined;
                    if (!animatedMap) {
                        // add the plot div
                        frameDiv.appendChild(plotDiv);
                        // handling for new overlay map
                        frameDiv.setAttribute('id', plotId + "Frame");
                        //
                        frameDiv.setAttribute('class', 'animationImageFrame');
                        // add image frame to group container
                        groupContainer.appendChild(frameDiv);
                        // create the overlay map...for now
                        plotDiv.innerHTML = "";
                        /* add frame to container */                            
                        groupContainer.appendChild(frameDiv);
                        // create new animated map
                        animatedMap = new giovanni.widget.MapAnimation(
                            plotId, 
                            {
                                'userbbox': giovanni.util.extractQueryValue(res.getCriteria().query[0].value, 'bbox'),
                                'savedState': null,
                                'plotData': {
                                    'resultId': res.resultId,
                                    'sessionId': res.sessionId,
                                    'resultSetId': res.resultSetId,
                                    'queryData': res.queryData
                                },                                    
                                'enableReplot': res.enableReplot,
                                'workspaceRef': this.workspaceRef
                            }
                        );
                        animatedMap.addLayerData(plot);
                        this.workspaceRef.addToPlotCache(g + res.id + plot.getSource(), animatedMap);
                    } else {
                        if (!interim || newContainer) {
                            animatedMap.refresh(groupContainer);
                        }
                        // check to see if the current plot has been added
                        if (!animatedMap.addedVariables[plot.getSource()]) {
                            animatedMap.addLayerData(plot);
                        }
                    }
                    break;
                case 'VERTICAL_PROFILE':
                    plotDiv.setAttribute('class', 'imageFrame');
                    /* add frame to container */
                    groupContainer.appendChild(plotDiv);
                    /* create plot class */
                    var vp = new giovanni.widget.VerticalProfile(plotDiv.id, plot.getSource());
                    break;
                case 'INTERACTIVE_TIME_SERIES':
                    /* if the grouped-plot instance (in this case, interactive time series plot)
                     * has not been created, create it, along with the appropriate image frame, etc.
                     */
                    if (this.its === undefined) {

                        /* add frame to container */
                        groupContainer.appendChild(plotDiv);
                        /* create plot class */
                        var clientBox = document.getElementById('resultViewContainer').getBoundingClientRect();
                        var width = this.resultViewContainer.parentNode.style.width !== undefined ?
                            this.resultViewContainer.parentNode.style.width.replace('px', '') : clientBox.width;
                        // resultViewContainer height is no longer set by resizing the page.
                        // Get the client height if possible just in case; otherwise, use the default
                        var height = clientBox.height ? clientBox.height : 600;
                        this.its = new giovanni.widget.InteractiveTimeSeries(plotDiv.id,
                            width - 100, /* the '100' should go away when the new layout is implementated */
                            height - 45); /* the height term should away entirely when the new layout is implemented */

                    }
                    this.its.addSeries(plot.getSource());
                    break;
                default:
                    /* default image rendering behavior */
                    frameDiv.appendChild(plotDiv);
                    groupContainer.appendChild(frameDiv);
                    if(plot.source) {
                      /*
                       * Create a static plot - the default plotting class.
                       * Includes building the config object and creating the class.
                       * The class takes care of rendering itself using the id of the
                       * HTML container (frameDiv) passed as the first arg.
                       */
                      var staticPlot = new giovanni.widget.StaticPlot(plotId, {
                        // giovanni.widget.Result.Plot
                        "plotObject": plot,
                        "res": res,
                        "workspaceRef": this.workspaceRef
                      });
                    } else {
                      plotDiv.innerHTML = '<span style="color:#993300; border:none; background:transparent; font-style:italic;">Incomplete or missing plot source. Please <a href="javascript:void(0)" onclick="session.sendFeedback(event, \'pageSelection\')">report the error</a></span>';
                      console.log("ResultView.displayPlot():  (static) plot source is null, result id:  " + res.getId());
                    }
                } // end of plot type 'switch' 
            } // end of plot 'for' loop
            // check for, and add if appropriate, captions
            if (groupContainer !== undefined) {
                var elmTest = document.getElementById('groupCaption' + g);
                if (elmTest === undefined) {
                    var groupCaption = document.createElement('div');
                    groupCaption.setAttribute('id', 'groupCaption' + g);
                    groupCaption.setAttribute('class', 'groupCaption');
                    groupCaption.innerHTML = decorations.caption;
                    groupContainer.appendChild(groupCaption);
                }
            }
        } // end of group 'for' loop
    } // end of 'hasPlots' check
    if (res.getStatus().getPercentComplete() < 100) {
        this.displayStatus(res, true);
    } else {
        res.enableReplot.fire();
    }
};

/*
 * Given a plot, determine if it has been plotted in ResultsView already
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result.Plot}
 * @return boolean
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.isPlotted = function (plotSrc, g) {
    return this.plotted[g + plotSrc] !== undefined ? true : false;
};

/*
 * Add a plot to the 'plotted' list; list holds the HTML plot container element id;
 * the 'plotted' list key is the source of the plot image
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result.Plot,String}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.setPlotted = function (plotSrc, plotId, g) {
    this.plotted[g + plotSrc] = plotId;
};
giovanni.ui.ResultView.prototype.getPlotted = function (plotSrc, g) {
    return this.plotted[g + plotSrc];
};

/*
 * Compare the old and new plot lists; for those items that have been plotted AND
 * appear in the new list. IF they appear in both lists, keep them, 
 * ELSE delete the old items and return the keys
 * for the new plot list so we can run through them in the update loop.
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return {Array}
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.getSanitizedPlotKeys = function (arr, res, g) {
    // get the sorted 'new' list ('new' is the list of plots as of catching the latest
    // giovanni.app.Result update event
    var newList = this.getSorted(arr);
    // the oldList is what giovanni.ui.RessultView has already plotted (and remembered);
    // grab the oldList from this.plotted
    var alreadyPlottedList = [];
    for (var key in this.plotted) {
        alreadyPlottedList.push(key);
    }
    // loop through the old list and delete unmatched plots
    var gps = res.getGroupedPlots();
    var gp = gps[parseInt(g)];
    for (var j = 0; j < alreadyPlottedList.length; j++) {
        var keep = true; // keep the old one
        var alreadyPlottedKey = alreadyPlottedList[j];
        // loop through the new list to find matches
        for (var i = 0; i < newList.length; i++) {
            if (alreadyPlottedKey === g + gp[i].getSource()) {
                keep = false;
                break;
            }
        }
        var elemToRemove = document.getElementById(this.getPlotted(alreadyPlottedKey, g));
        if (!keep && elemToRemove !== null) {
            var parentNode = elemToRemove.parentNode;
            parentNode.removeChild(elemToRemove);
            delete this.getPlotted(alreadPlottedKey, g);
        }
    }
    return newList;
};

/*
 * Return sorted keys for an associative array
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return {Array}
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.getSorted = function (arr) {
    var keys = [];
    for (var key in arr) {
        keys.push(key);
    }
    return keys.sort();
};

/*
 * Display the download links panel
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.displayDownloads = function (res) {
    // set title
    this.currentView = 'Downloads';
    // clean up the container
    $(this.resultContainer).children().detach();
    this.resultContainer.innerHTML = "";

    if (login && login.enabled) {
        this.handleLoginEvent(null, null, this);
    }

    // append the data links to the ResultView container
    if (res.hasData()) {
        var links = res.getData();
        // TEMP HACK: format test
        var csvFlag = links[0].getLabel().indexOf('csv') > -1 ? true : false;
        // download header
        var dCaption = document.createElement('div');
        dCaption.setAttribute('id', 'downloadCaption');
        dCaption.innerHTML = "Click on file links to download.  Files contain data portrayed in the plot images.";
        var dHeader = document.createElement('div');
        dHeader.setAttribute('id', 'downloadHeader');
        if (csvFlag) {
            dHeader.innerHTML = "ASCII CSV: ";
        } else {
            dHeader.innerHTML = "<a href='http://www.unidata.ucar.edu/software/netcdf/' target='_blank'>NetCDF</a>:";
        }
        var dContainer = document.createElement('div');
        dContainer.setAttribute('id', 'downloadContainer');
        // download container
        if (res.getPlots()[0].type === 'MAP_ANIMATION') {
            var link = document.createElement('a');
            var DATAFIELDNAME = 2;
            link.innerHTML = res.getPlots()[0].dataFieldLabel.split('.')[DATAFIELDNAME] + ' animation file links';
            link.setAttribute('title','Click to download file containing links to all NetCDF files used to create the animation');
            var url = './daac-bin/lineageText.pl?step=postprocess+sMpAn' +
                '&session=' + res.sessionId +
                '&resultset=' + res.resultSetId +
                '&result=' + res.resultId;
            link.setAttribute('href',url);
            dContainer.appendChild(link);
        } else {
            for (var i = 0; i < links.length; i++) {
                var link = document.createElement('a');
                link.innerHTML = links[i].getLabel();
                link.setAttribute('href', links[i].getUrl());
                //link.setAttribute('target','_blank');
                dContainer.appendChild(link);
                dContainer.appendChild(document.createElement('br'));
            }
        }
        this.resultContainer.appendChild(dCaption);
        this.resultContainer.appendChild(dHeader);
        this.resultContainer.appendChild(dContainer);

        // If the result has plots, create image download links for those plots
        if (res.hasPlots()) {
            var plots = res.getPlots();
            var type = undefined;
            for (var i=0;i<plots.length;i++) {
              if (plots[i].getType()) {
                type = plots[i].getType();
                break;
              }
            }
            // get the user's selected bounding box
            // build the links using plots, the result link(s) (for now) and the user's bbox
            this.buildImageDownloadLinks(res, links, plots, type);
            // all files into one csv using mfst.combine on INTERACTIVE_TIME_SERIES
            // instead of per file like above:
            this.buildCombinedCSVDownloadLink(res, links, type);
        }
    } else {
        $(this.resultContainer).children().detach();
        this.resultContainer.innerHTML = "No file links available for " + res.getTitle() + ".";
    }
};

giovanni.ui.ResultView.prototype.buildCombinedCSVDownloadLink = function (res, links, type) {

    // Currently only Interannual time series has this INTERACTIVE_TIME_SERIES monicker
    if (type != "INTERACTIVE_TIME_SERIES") {
        return;
    }
    var dContainer = document.createElement('div');
    dContainer.setAttribute('id', 'downloadContainer');
    var dHeader = document.createElement('div');
    dHeader.setAttribute('id', 'downloadHeader');
    dHeader.innerHTML = "Combined ASCII: ";
    var dCaption = document.createElement('div');
    dCaption.setAttribute('id', 'downloadCaption');

    var link = document.createElement('a');
    link.innerHTML = "Combined";
    sampleLabel = links[0].getLabel();

    if (sampleLabel.indexOf('MONTH') > -1) {
        sampleLabel = sampleLabel.replace(/\.MONTH_\d\d/, '');
    } else {
        sampleLabel = sampleLabel.replace(/\.SEASON_\w\w\w/, '');
    }

    sampleLabel = sampleLabel.replace(/.nc.*$/, '.csv')
    if (sampleLabel.length > 1) {
        link.innerHTML = sampleLabel;
    } else {
        link.innerHTML = "Combined_Months.csv";
    }
    // the server 'looks for' the mfst.combine file using the session id
    // Now re-adding extra URL items for metrics
    // PLEASE KEEP FILENAME IN URL, although it is not used in the code,
    // metrics needs it for data download tracking
    link.setAttribute('href', "daac-bin/serializer.pl?FILENAME=" + sampleLabel +
        "&SESSION=" + res.sessionId + "&RESULTSET=" +
        res.resultSetId + "&RESULT=" + res.resultId);
    dContainer.appendChild(link);
    dContainer.appendChild(document.createElement('br'));
    this.resultContainer.appendChild(dCaption);
    this.resultContainer.appendChild(dHeader);
    this.resultContainer.appendChild(dContainer);
}
/*
 * Build the image links for the download panel
 *
 * @this {giovanni.ui.ResultView}
 * @params {Array,Array,String}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.buildImageDownloadLinks = function (res, links, plots, type) {
    var multiPlot = type === 'INTERACTIVE_OVERLAY_MAP' ? true : false;
    // in theory 'multiPlot' could apply to any plot object having multiple
    // plot sources, but we don't describe this anywhere in our results
    // or visualization metadata....we need to....
    var addHostFlag = false; // shouldnt need this, but plot source URLs are different based on plot types

    if (type != "INTERACTIVE_SCATTER_PLOT" && type != "INTERACTIVE_TIME_SERIES" &&
        type != "VERTICAL_PROFILE") {

        var bbox = giovanni.util.extractQueryValue(res.getCriteria().query[0].value, 'bbox');
        var imgTypes = ["PNG"];
        var fileFormats = ["png"];
        if (type === "INTERACTIVE_MAP" || type === "INTERACTIVE_OVERLAY_MAP") {
            imgTypes = ['PNG', 'GEOTIFF', 'KMZ'];
            fileFormats = ['png', 'tif', 'kmz'];
            addHostFlag = true;
        } else if (type == "MAP_ANIMATION") {
            imgTypes = ['GIF'];
            fileFormats = ['gif'];
            addHostFlag = true;
        }


        $(this.resultContainer).append(
          '<div id="noCachedPlotMsg" class="downloadMsg"></div>\
          <div id="missingPlotMsg" class="downloadMsg"></div>'
        );

        //there are three types of downloads:  PNG, GEOTIFF and KMZ
        for (var it = 0; it < imgTypes.length; it++) {
             
            // if there are no correctly populated plots,
            // don't show the header
            var sourceCount = 0;
            for (var i=0;i<plots.length;i++) {
              if (plots[i].getSource() !== null) 
                sourceCount++;
            }
            
            if (sourceCount > 0) { 
              // build the section header for GeoTIFFs
              var iHeader = document.createElement('div');
              //iHeader.setAttribute('id','imageDownloadHeader');
              iHeader.setAttribute('class', 'imageDownloadHeader');
              iHeader.innerHTML = type !== "MAP_ANIMATION" ? imgTypes[it] + ":" : "ZIP: ";
              this.resultContainer.appendChild(iHeader);
              // build the section container for current image type 
              var iContainer = document.createElement('div');
              //iContainer.setAttribute('id','imageDownloadContainer');
              iContainer.setAttribute('class', 'imageDownloadContainer');
              this.resultContainer.appendChild(iContainer);
            }
            // loop through the plots and create links based on what's in the JSON response
            var plotSource = null;
            if (!multiPlot && type != "MAP_ANIMATION" && type !== undefined) {
                for (var i = 0; i < plots.length; i++) {
                    // grab plot source      
                    plotSource = plots[i].getSource();
                    if ((imgTypes[it] === 'GEOTIFF' || imgTypes[it] === 'KMZ') ||
                        (plotSource && plotSource.indexOf('png') < 0 && plotSource.indexOf('gif') < 0 && plotSource.indexOf('jpg') < 0)) {
                        plotSource = null;
                    }
                    if (plotSource !== null) {
                        var link;
                        var downloadUrl = "./daac-bin/downloadPlot.pl?";
                        // create an HTML anchor (link)
                        link = document.createElement('a');
                        var label = links[i].getLabel().replace('.csv', '.' + fileFormats[it]).replace('.nc', '.' + fileFormats[it]);
                        link.innerHTML = label;
                        // add to download url
                        plotSource = addHostFlag ? "http://" + location.host + location.pathname + "/" + plotSource : plotSource;
                        // check for debug URL
                        plotSource = plotSource.replace("index-debug.html/", "");
                        // add plot source to download URL
                        downloadUrl += "image=" + encodeURIComponent(plotSource) + "&";
                        // add format
                        downloadUrl += "format=" + imgTypes[it] + "&";
                        // set link href attribute
                        // add caption if avaiable
                        if (plots[i].showTitle) {
                          downloadUrl += "title=" + encodeURIComponent(plots[i].title)  + "&";
                        }
                        if (plots[i].showCaption && plots[i].caption !== null) {
                          downloadUrl += "caption=" + encodeURIComponent(plots[i].caption) + "&";
                        }
                        
                        link.setAttribute('href', downloadUrl);
                        // set link label
                        link.setAttribute('download', label);
                        // add link to container
                        iContainer.appendChild(link);
                    } else { // if the plot is interactive, 
                        link = document.createElement('span');
                        link.setAttribute('class', 'imageDownloadFakeLink');
                        iContainer.appendChild(link);
                        // this is the object created by giovanni.app.Result
                        var respObjPlot = plots[i];
                        // this is the object cached when plotting
                        var cachedPlotObj = this.workspaceRef.pullFromCache(0 + res.id + plots[i].getSource());
                        if (respObjPlot && respObjPlot.getSource()) {
                          // pull the file name from the source
                          var label = respObjPlot.getSource();
                          label = 
                            label.substring(label.lastIndexOf("/") + 1, 
                              label.indexOf(".map.json") > -1 ? label.indexOf('.map.json') : label.length);
                          // tack on the image file format
                          label += "." + fileFormats[it];
                          link.innerHTML = label;
                          if (cachedPlotObj) {
                            YAHOO.util.Event.addListener(link, 'click', cachedPlotObj.download, {
                              'view': 'downloads',
                              'name': imgTypes[it]
                            }, cachedPlotObj);
                          } else {
                            link.innerHTML = "";
                            $('#noCachedPlotMsg').text("Please click 'Plots' in order to generate the image download links");
                          } 
                        } else {
                          link.innerHTML = "";
                          if ($('#noCachedPlotMsg').text() === "")
                            $('#missingPlotMsg').text("Please note, there are missing image download links (e.g., PNG) due to plot errors");
                        }
                    }
                    $(iContainer).append($('<br/>'));
                }
            } else if (type == "MAP_ANIMATION") {
                if (plots.length === 0 || plots.length > sourceCount) {
                  $('#missingPlotMsg').text("Please note, there are missing image download links (e.g., PNG) due to plot errors");
                } else {
                  var plotObj = this.workspaceRef.pullFromCache(0 + res.id + plots[0].getSource());
                  if (plotObj.layerData) {
                    var link = $('<a></a>').attr('href',plotObj.getAnimationDownloadUrl())
                      .html(links[0].getLabel().replace('.nc', '.zip').replace('.csv', '.' + '.zip'))
                      .addClass('imageDownloadFakeLink')
                      .appendTo(iContainer);
                  } else {
                      $('#noCachedPlotMsg').text("Please click 'Plots' in order to generate the image download links");
                      iHeader.innerHTML = "";
                  }
                }
                $(iContainer).append($('<br/>'));
            } else if (multiPlot) { // more than one plot per plot overlay (right now, an overlay map)
                var plotObj = this.workspaceRef.pullFromCache(0 + res.id);
                // '0' is for the group of plots, of which there is only one currently
                // the request below add is a 'view' attribute to the download options menu config so 
                // overlay map can tell this is an external request - this is currently necessary because
                // the external configuration passed to the function is different than the internal one
                if (plots.length >= sourceCount++) {
                  if (plotObj && plotObj.plotCount === plots.length) {
                    var link = document.createElement('a');
                    link.setAttribute('class', 'imageDownloadFakeLink');
                    link.innerHTML = links[0].getLabel().replace('.nc', '.' + fileFormats[it]).replace('.csv', '.' + fileFormats[it]);
                    if (iContainer) iContainer.appendChild(link);
                    YAHOO.util.Event.addListener(
                      link, 'click',
                      plotObj.downloadOptions.download,
                      $.extend(plotObj.downloadOptions.getMenuItem(imgTypes[it]).getConfig(), {
                        'view': 'downloads'
                    }),
                    plotObj.downloadOptions);
                  } else {
                    $('#noCachedPlotMsg').text("Please click 'Plots' in order to generate the image download links");
                  }
                } else {
                  $('#missingPlotMsg').text("Please note, there are missing image download links (e.g., PNG) due to plot errors");
                }
            } else { // undefined
                $('#missingPlotMsg').text("Please note, there are missing image download links (e.g., PNG) due to plot errors");
            }
        }
    }
};

/*
 * Display the lineage panel
 *
 * @this {giovanni.ui.ResultView}
 * @params {giovanni.app.Result}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.displayLineage = function (res) {
    /* check the current view; if it's not lineage, cleanup the child elements */
    if (this.currentView != 'Lineage') {
        $(this.resultContainer).children().detach();
    }
    /* set the view after the check to detach child */
    this.currentView = 'Lineage';
    /* request the actual lineage content if there is any */
    if (res.hasLineage()) {
        if (login && login.enabled) {
            this.handleLoginEvent(null, null, this);
        }
        this.setLineage(res);
    } else {
        this.resultContainer.innerHTML = "No lineage for " + res.getTitle() + " yet";
    }
};

/*
 * Fetch the lineage HTML and set it in the lineage container
 *
 * @this {giovanni.ui.ResultView}
 * @params {HTML Element,URL}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.setLineage = function (result) {
    var status = YAHOO.util.Connect.asyncRequest('GET', result.getLineage(), {
        success: giovanni.ui.ResultView.handleLineageSuccess,
        failure: giovanni.ui.ResultView.handleLineageFailure,
        scope: '',
        argument: {
            obj: this,
            res: result
        }
    });
};

/*
 * Handles successful fetch of lineage content
 * 
 * @this {YAHOO.util.Event}
 * @params {Object}
 * @return void
 * @author K. Bryant
 **/
giovanni.ui.ResultView.handleLineageSuccess = function (o) {
    var co = o.argument.obj;
    var res = o.argument.res;
    var elm = co.resultContainer;
    if (res.getStatus().getPercentComplete() < 100) {
        /* if the responseText is different from what was
           last fetched, render it */
        var contentLength = co.viewContent['lineageLength'] ? co.viewContent['lineageLength'] : 0;
        if (contentLength != o.responseText.length) {
            co.clearStatus();
            co.clearView();
            if (co.viewContent['lineageLength'] === 0) {
                elm.innerHTML = "Loading lineage...";
            } else {
                elm.innerHTML = "Updating lineage...";
            }
            elm.innerHTML = o.responseText;
        }
    } else {
        co.clearStatus();
        elm.innerHTML = o.responseText;
    }
    /* store the content length so we can decide whether to render for the next request;
       FUTURE - should use content diff instead a line length check!! */
    co.viewContent['lineageLength'] = o.responseText.length;
};

/*
 * Handles failure to fetch lineage content
 * 
 * @this {YAHOO.util.Event}
 * @params {Object}
 * @return void
 * @author K. Bryant
 **/
giovanni.ui.ResultView.handleLineageFailure = function (o) {
    o.argument.obj.clearStatus();
    o.argument.obj.viewContent['lineageLength'] = 0;
    o.argument.obj.resultContainer.innerHTML = "Failed to load lineage";
};

/*
 *  Display the session viewer
 *  
 *  @this {giovanni.ui.ResultView}
 *  @params {giovanni.app.Result}
 *  @return void
 *  @author K. Bryant
 **/
giovanni.ui.ResultView.prototype.displayDebug = function (res) {
    /* requeset the actual lineage content if there is any */
    if (res.getDebugUrl()) {
        var w = window.open(res.getDebugUrl(), '_blank');
    } else {
        alert("No debug URL for " + res.getTitle() + " yet...try again in a few seconds.");
    }
};

/**
 *  * Clear the result view and hide the result on the server
 *   */
giovanni.ui.ResultView.prototype.deleteResult = function (res) {
    if (res.getDeleteUrl()) {
        // hide the result on the server side
        res.hide();
        // if this result is the current result, remove it from local storage
        if (typeof(Storage) !== "undefined") {
            var user = sessionManager.getUser() ? sessionManager.getUser() : giovanni.util.getGuest();
            var storedResult = sessionStorage.getItem(user+'CurrentResult');
            // does the stored current result?
            if (storedResult) {
                var compCriteria = res.criteria.query[0].value;
                if (storedResult.criteria === compCriteria) {
                    sessionStorage.removeItem(user+'CurrentResult');
                }
            }
        }
    }
};

/*
 * Resizes resultViewContainer height and width - DEPENDS on height of 
 * resultViewContainer parent
 */
giovanni.ui.ResultView.prototype.resize = function () {
    var contWidth = giovanni.util.getWinSize()[0] - 260;
    this.resultViewContainer.parentNode.style.width = contWidth + 'px';
};

giovanni.ui.ResultView.prototype.addInteractiveScatter = function (id, dataUrl, container, query) {
    // create table for plot and map (specialized for scatter plot for now)
    var t = document.createElement("table");
    t.setAttribute('id', 'interactiveScatterPlotContainer');
    t.style.width = "98%";
    // graph + map row
    var row = t.insertRow(-1);
    var col1 = row.insertCell(0);
    col1.style.verticalAlign = "top";
    col1.style.width = "75%";
    var col2 = row.insertCell(1);
    col2.style.verticalAlign = "top";
    col2.style.width = "25%";
    // add table to container
    container.appendChild(t);

    // graph title/subtitle div
    var graphHdr = document.createElement('div');
    graphHdr.setAttribute('id', this.container.id + 'GraphHdr');
    graphHdr.setAttribute('class', 'graphHdr');
    graphHdr.innerHTML = "Drag bounding box on plot to subset data";
    col1.appendChild(graphHdr);
    // map title/subtitle div
    var mapHdr = document.createElement('div');
    mapHdr.setAttribute('id', this.container.id + 'GraphHdr');
    mapHdr.setAttribute('class', 'graphHdr');
    mapHdr.innerHTML = "Drag bounding box on map to subset data";
    col2.appendChild(mapHdr);

    // create graph div
    var graphDiv = document.createElement("div");
    graphDiv.setAttribute('id', id + 'graph');
    graphDiv.setAttribute('class', 'interactivePlot scatterGraph');
    // create map div
    var mapDiv = document.createElement("div");
    mapDiv.innerHTML = "<div id='" + id + "map' class='scatterMap interactivePlot'></div>";
    var coordsDiv = document.createElement("div");
    coordsDiv.setAttribute('id', id + 'cursor');
    coordsDiv.setAttribute('class', 'mapCoords');
    coordsDiv.innerHTML = "&nbsp;";
    // add supporting divs to table
    col1.appendChild(graphDiv);
    mapDiv.appendChild(coordsDiv);
    col2.appendChild(mapDiv);
    // instantiate interactive class (should be the 'type')
    this.sp = null;
    try {
        // create the scatter plot
        this.sp = new giovanni.widget.InteractiveScatterPlot(id, dataUrl, query, this.workspaceRef.session);
        // add the reset button (not using the highcharts reset button for now)
        var reset = document.createElement("button");
        reset.innerHTML = "Reset Map and Chart";
        reset.setAttribute("title", "Reset Map and Chart");
        reset.setAttribute("type", "button");
        reset.setAttribute("class", "graphMapReset");
        mapDiv.appendChild(document.createElement('br'));
        mapDiv.appendChild(reset);
        YAHOO.util.Event.addListener(reset, "click", function () {
            this.sp.resetAll();
        }, {}, this);
        // add a listener to update the map when it's parent is scrolled
        YAHOO.util.Event.addListener(this.resultContainer, "scroll", this.sp.refreshMap, {}, this.sp);

    } catch (err) {
        var span = document.createElement("span");
        span.innerHTML = err;
        container.appendChild(span);
    }
};

giovanni.ui.ResultView.prototype.hide = function () {
    if (this.sp !== undefined && this.sp !== null) {
        this.sp.boxLayer.setVisibility(false);
    }
};

giovanni.ui.ResultView.prototype.show = function () {
    if (this.sp !== undefined && this.sp !== null) {
        this.sp.boxLayer.setVisibility(true);
    }
    // make sure the current plot is up-to-date
    this.update();
};

giovanni.ui.ResultView.prototype.rePlot = function (e, o) {
    // set title
    this.titlePrefix.innerHTML = "Re-Plotting...";
    this.showStatus("Re-Plotting...<img src='./img/progress.gif'/>");
    this.overallCaption.innerHTML = o.result.getCaption() === undefined ? "" : o.result.getCaption();

    var opts = o.options;
    var val = "options=";
    var res = {};
    for (var i = 0; i < opts.length; i++) {
        opts[i].appendOptionValue(res);
    }
    res = encodeURIComponent(JSON.stringify(res));
    var val = "options=" + res;
    o.result.initiateRePlot(val);
    this.resultReplotted[o.result.getId()] = true;
    this.restoreDefaultsButton.set('disabled', false);
    this.currentResult = o.result;
    this.currentView = "Plots";
    o.result.resultUpdateEvent.subscribe(this.handleResultUpdateEvent, this);
    $(this.resultContainer).children().detach();
    this.resultContainer.innerHTML = "";
};

giovanni.ui.ResultView.prototype.restoreDefaults = function (e, o) {
    var opts = o.options;
    for (var i = 0; i < opts.length; i++) {
        optsDefault = this.defaults[o.result.getId() + opts[i].name];
        for (var optKey in this.optionsDictionary) {
            var elem = document.getElementById(opts[i].name + this.optionsDictionary[optKey].id);
            if (elem !== null) {
                if (elem.hasAttribute('disabled')) elem.removeAttribute('disabled'); // Re-enable all elements
                opts[i][optKey] = optsDefault[this.optionsDictionary[optKey].getter]();
                switch (this.optionsDictionary[optKey].type) {
                case 'text':
                    elem.value = opts[i][optKey];
                    break;
                case 'checkbox':
                    elem.checked = this.optionsDictionary[optKey].condition[opts[i][optKey]];
                    break;
                default:
                    // nothing to do
                }
            }
        }
    }
    this.rePlotButton.set('disabled', false);
};

/*
 * Set the title of the result
 *
 * @this {giovanni.ui.ResultView}
 * @params {String}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.setTitle = function (title) {
    var type = this.currentResult.getStatus().getPercentComplete();
    if (this.currentHistoryViewNode.type == "Status" && this.currentResult.getStatus().getPercentComplete() == 100) {
        type = "Plots";
    }
};

/*
 * Remove result HTML elements, plot history and user selections, if appropriate
 *
 * @this {giovanni.ui.ResultView}
 * @params {boolean}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.clearView = function (eraseUserSelections) {
    this.titlePrefix = "";
    this.showStatus("");
    $("#resultContainer").removeClass("disabledElement");
    $("#dataAccessWarning").remove();
    $(this.resultContainer).children().detach();
    $(this.resultContainer).innerHTML = "";
    this.plotted = [];
    this.cancelled = false;
    if (eraseUserSelections) {
        this.userSelections = [];
    }
    if (this.currentView != 'Lineage') {
        this.viewContent['lineageLength'] = 0;
    }
    // Cleanup unclosed dialogs by firing the workspace hide event;
    // probably should be called 'cleanupEvent' since that's really 
    // how it's handled by the ResultView components (e.g., maps)
    this.workspaceRef.hideEvent.fire();
};

giovanni.ui.ResultView.prototype.clearStatus = function () {
    this.statusContainer.innerHTML = "";
    this.statusContainer.style.display = "none";
    this.pb = undefined;
};

giovanni.ui.ResultView.prototype.showStatus = function (str) {
    this.statusContainer.innerHTML = str;
    this.statusContainer.style.display = str === "" ? 'none' : 'block';
};

/* 
 * Handle the store user selections event that can come from a plot object such as
 * giovanni.widget.Map. ResultView stores the selection object so it can be loaded
 * as the user navigates back to 'Plot' from other HistoryView nodes; it can also
 * be used to maintain persistence of user selections (plot option settings such as 
 * 'palette', 'min', and 'max') in between results.  Hopefully this is functionality
 * that can be transitioned to the server side in the future.
 * 
 * @this {YAHOO.util.CustomEvent}
 * @params {YAHOO.util.CustomEvent,Object,Object}
 * @return void
 * @author K. Bryant
 */
giovanni.ui.ResultView.prototype.handleStoreUserSelectionsEvent = function (evt, args, self) {
    var src = args[0];
    var map = args[1];
    self.interactiveStates[self.currentResult.getId() + "_" + src] = map.exportState();
};
giovanni.ui.ResultView.prototype.handleGetUserSelectionsEvent = function (evt, args, self) {
    var src = args[0];
    var mapObj = args[1];
    var storageObj = self.userSelections[self.currentResult.getId() + "_" + src];
    mapObj.restoreUserSelections(storageObj);
    mapObj.optionsPanel.show();
};

/*
 * Determine if the results are truly grouped, needing group print and synch'd options
 */
giovanni.ui.ResultView.prototype.areGrouped = function (res) {
    var grouped = false;
    var criteria = res.getCriteria().query[0].value;
    if (criteria.indexOf("QUASI") > -1 || criteria.indexOf("INTER_ANNUAL") > -1) {
        grouped = true;
    }
    return grouped;
};

giovanni.ui.ResultView.prototype.getTitle = function (res) {
    if (res === null) res = this.currentResult;
    var resTitle = "";
    var title = res.getTitle();
    var crit = res.getCriteria();
    if (res.getDescription() !== "") {
        var str = res.getDescription();
        if (str.indexOf("months or seasons") > -1) {
            str = crit.query[0].value.indexOf("seasons") < 0 ?
                str.replace("months or seasons", "months") :
                str.replace("months or seasons", "seasons");
        }
    }
    return res.getIndex() + ".  " + "<span style='text-decoration:underline;color:blue;'>" + title + "</span>";
};

giovanni.ui.ResultView.prototype.getCurrentResult = function () {
    return this.currentResult;
};

giovanni.ui.ResultView.prototype.getServiceHelp = function (e, o) {
    var service = giovanni.util.extractQueryValue(this.getCurrentResult().queryData, "service");
    // get session
    session.showHelp(null, {
        serviceName: service
    });
};
