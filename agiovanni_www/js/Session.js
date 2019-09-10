/*
 ** $Id: Session.js,v 1.46 2015/02/12 21:10:14 dedasilv Exp $
 ** -@@@ Giovanni, Version $Name:  $
 */

// establish the component namespace
giovanni.namespace("app");
// constructor
giovanni.app.Session = function (id, config) {
    // store container id
    this.containerId = id;
    if (this.containerId == null) {
        console.log('giovanni.app.Session: container id cannot be null');
        return;
    }
    // get the container element
    this.container = document.getElementById(this.containerId);
    if (this.container == null) {
        console.log('giovanni.app.Session: container element with id ' +
            this.containerId + 'not found');
        return;
    }

    config = (config == null ? {} : config);

    // set service manager URL - this is how the front end communicates with the
    // back end
    this.serviceManagerURL = (config.serviceManagerURL == undefined || config.serviceManagerURL == null) ? 
      "./daac-bin/service_manager.pl?" : config.serviceManagerURL;
    this.portal = (config.portal == undefined || config.portal == null) ? 
      "GIOVANNI" : config.portal;
    this.sessionId = null;

    var portalConfig = {
        portal: this.portal,
        urlPrefix: this.serviceManagerURL,
        session: this
    };

    this.rendered = false;

    this.history = new giovanni.app.History(portalConfig);

    // message board initialization
    var msgBoardId = this.containerId + "MsgBoard";
    var msgBoardElem = document.createElement('div');
    msgBoardElem.id = msgBoardId;
    msgBoardElem.setAttribute('class', 'messageBoard');
    this.container.appendChild(msgBoardElem);
    this.msgBoard = new giovanni.ui.MessageBoard(msgBoardId,
        './daac-bin/getNewsItems.pl', 5, this.portal);

    // data selector initialization
    var dataSelId = this.containerId + "DataSel";
    var dataSelElem = document.createElement('div');
    dataSelElem.id = dataSelId;
    this.container.appendChild(dataSelElem);
    this.dataSelector = new giovanni.ui.DataSelector(dataSelId, portalConfig);

    this.workspace = null;

    // projection config
    $.get('./daac-bin/getMapConfig.pl', 
        function(data, textStatus, jqXHR) { 
            giovanni.app.projectionConf = data;
    });

    // render the session
    this.render();

    // to keep track of the period when a query is loading
    // either from a URL or by the user from the result/history view
    this.loadInProgress = false;

    JSONEditor.defaults.editors.number = JSONEditor.defaults.editors.string.extend({
      sanitize: function(value) {
        return value;
      },
      getNumColumns: function() {
        return 2;
      },
      getValue: function() {
        return this.value*1;
      }
    });

    JSONEditor.defaults.custom_validators.push(function(schema, value, path) {
        var errors = [];
        if(schema.type==="number") {
          if(String(value).match(/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/g) == null) {
            // Errors must be an object with `path`, `property`, and `message`
            if (errors.length == 0) {
              errors.push({
                path: path,
                property: 'float',
                message: 'Must be a float number'
              });
            }
          }
        }
        return errors;
    });
};

/*
 * render the session specific UI
 */
giovanni.app.Session.prototype.render = function () {
    if (this.rendered) return;
    /* build the pickers */
    var dataSelector = this.getDataSelector();
    var servicePicker = dataSelector.addWidget(giovanni.ui.DataSelector.SERVICE_PICKER, giovanni.portal.serviceDataAccessor, {
        "view" : "radio"
    });

    var datePicker = dataSelector.addWidget(giovanni.ui.DataSelector.DATE_PICKER, giovanni.portal.dateRangeDataAccessor, {
        "range" : true,
        "minBound" : '1948-01-01T00:00:00',
        "type" : "Date",
        "maxRange" : 0
    });

    var locationPicker = dataSelector.addWidget(giovanni.ui.DataSelector.BOUNDING_BOX_PICKER, 
        giovanni.portal.locationDataAccessor, {
          "maxWidth" : 360,
          "maxHeight" : 180,
          "register" : true,
          "bounds" : []
    });

    var variablePicker = dataSelector.addWidget(giovanni.ui.DataSelector.VARIABLE_PICKER, 
        giovanni.portal.variablesDataAccessor, null);

    var toolbar_config = [ {
        'type' : 'button',
        'name' : 'reset',
        'label' : 'Reset',
        'title' : 'Reset selections to their defaults',
        'action' : dataSelector.resetSelections,
        'source' : dataSelector
      }, {
        'type' : 'button',
        'name' : 'plot',
        'label' : 'Plot Data',
        'title' : 'To generate a plot, fill out the form above and click this button!',
        'action' : dataSelector.plotData,
        'source' : dataSelector,
        'cssClass' : 'plotButton'
    } ];
    // create toolbar  
    var toolbar = dataSelector.addWidget(giovanni.ui.DataSelector.TOOLBAR, "", toolbar_config);
    // perform required dependency registrations (source,consumer(s))
    REGISTRY.addEventListener(servicePicker.getId(), variablePicker.getId(), datePicker.getId(),dataSelector.getId());
    REGISTRY.addEventListener(variablePicker.getId(), datePicker.getId(), servicePicker.getId(),locationPicker.getId(), dataSelector.getId());
    REGISTRY.addEventListener(datePicker.getId(), servicePicker.getId(),dataSelector.getId());
    REGISTRY.addEventListener(locationPicker.getId(), servicePicker.getId(),dataSelector.getId());
    // jQuery script for enabling collapsible facets
    // DO THIS BEFORE processing the URL bookmark string # in the next step
    // so that the facets can be opened or collapsed as required while processing the URL
    REGISTRY.addAllReadyCallback(function() {
      try {
        $('.collapsible').collapsible({
          //place to add config items for initializing the collapsible panel
          cookieName:'', // disable cookies
          speed: 300, // 300 ms to complete the slide up or down animation
          animateClose: function (elem, opts) {
            // do the close animation and display collapsed state info for the facet
            elem.next().slideUp(opts.speed, function() { 
              var header = elem[0];
              var facets = session.dataSelector.variablePicker.fs.facets;
              for (var i=0; i<facets.length; i++) {
                if (facets[i].getCollapsibleHeaderId() == header.id) {
                  facets[i].showCollapsedInfo();
                  break;
                }
              }
            });
          },
          animateOpen: function (elem, opts) {
            // clear collapsed state info before expanding the facet  
            var header = elem[0];
            var facets = session.dataSelector.variablePicker.fs.facets;
            for (var i=0; i<facets.length; i++) {
              if (facets[i].getCollapsibleHeaderId() == header.id) {
                facets[i].clearCollapsedInfo();
                break;
              }
            }
            // do the open animation
            elem.next().slideDown(opts.speed);
          }
        });
        for (var i=0; i<2; i++) {
          var fac = variablePicker.fs.facets[i];
          var locator = '#'+fac.getCollapsibleHeaderId();
          $(locator).collapsible('open');
        }
      } catch(err) {
        console.log("Error while initiating collapsible facets : " + err.message);
      }
    });
    // process bookmark string # and load UI components appropriately
    var queryString = window.location.hash.substring(1);
    if(queryString.length>0){
      REGISTRY.addAllReadyCallback(function() {
        var comps = REGISTRY.getUIComponents();
        if (setLoadInProgress instanceof Function) setLoadInProgress(true);
        for (var i=0; i < comps.length; i++) {
          if(comps[i].loadFromQuery instanceof Function){
             comps[i].loadFromQuery(queryString);
          }
        }
        if (setLoadInProgress instanceof Function) setLoadInProgress(false);
      });
    };
    this.rendered = true;
};

giovanni.app.Session.prototype.setSessionId = function (sessionId) {
    this.sessionId = sessionId;
}

/*
 * Attempt to fetch the session 'tree'.  This is the structure of the sesssion
 * represented by the session::resultset:;result hierarchy.  The response to 
 * this request contains limited information about the session nodes (e.g.,
 * the result node contents are not populated
 */
giovanni.app.Session.prototype.restoreSessionTree = function (sessionId,mergeSessionId) {
    // make sure we're showing progress modal at this point
    showProgress();
    // set getSummarySession url
    var url = this.serviceManagerURL.replace('service_manager','getSummarySession');
    if (mergeSessionId) console.log("Session.restoreSessionTree():  got session id to merge: " + mergeSessionId);
    // if there is a session id, use it
    if (sessionId) {
      this.setSessionId(sessionId);
      $.ajax({
        url: url + 'session=' + sessionId + '&format=json&random=' + new Date().getTime(),
        success: this.handleRestoreSessionTreeSuccess,
        error: function (obj) {
          console.log("Session.restoreSessionTree():  Couldn't find session id: " + sessionId);
          alert("Sorry for the inconvenience, but we cannot find your session.  It may have been deleted (by policy sessions are deleted periodically).  We are creating a new session...");
          /* call sessionManager.getNewSession(); 'sessionManager' is a global variable set on app load */
          sessionManager.getNewSession();
        },
        dataType: 'json',
        context: this
      });
    } else {
      // very unusual at this stage
      console.log("Session.restoreSessionTree():  no sessionId");
      hideProgress();
    }
};

/*
 * A convenience object to store resultset and result ids
 */
giovanni.app.Session.ResultObject = function (resultSetId, resultId) {
    this.resultset = resultSetId;
    this.result = resultId;
}

giovanni.app.Session.prototype.showView = function () {
  if (sessionManager.getUserView() === 'workspace') {
    this.workspace.show();
  } 
}

/*
 * Use the session tree to then request result content, one at a time
 */
giovanni.app.Session.prototype.handleRestoreSessionTreeSuccess = function (o) {
    var self = this;
    // make sure we're still showing progress
    showProgress();
    // array in which to store results information (used to then fetch
    // session results themselves)
    var results = [];
    // make sure we've got a workspace
    self.restoreWorkspace();
    // clear history and result views in preparation for the restored results
    // this needs to be called here or old results will not be cleared from the session
    // when, for example, being loaded as a response to the login of a resgistered user
    self.clear();
    // get (and then set on client) the result count from service-side session data
    var resultSetCount = o.session.resultset ? o.session.resultset.length : 0;
    this.currentResultSetCount = resultSetCount;
    console.log("Session.handleRestoreSessionTreeSuccess():  total result set count: " +resultSetCount);
    var restoreStart =  new Date().getTime();
    if (resultSetCount > 0) {
        // show the clear button
        $('#sessionWorkspaceClear').css('display','block');
        // make sure we show 'back to results' button in the data selection view
        var backBtn = self.getDataSelector().toolbar.getControl('back');
        if (backBtn) {
          var backBtnElem = $('#'+backBtn._button.id);
          backBtnElem.css('display','block');
        }
        // see if there is a stored result
        var storedResultNode = undefined;
        if (typeof(Storage) !== undefined) {
          var user = sessionManager.getUser() ? sessionManager.getUser() : giovanni.util.getGuest();
          storedResultNode = sessionStorage.getItem(user+'CurrentResult');
          if (storedResultNode) storedResultNode = JSON.parse(storedResultNode);
        }
        var matchingResultNode = undefined; // history view node that is a match to the stored result node
        var matchingIdx = undefined; // index of the matching result node in the history objects list
        var activeResultsCount = 0; // results that have not been 'deleted' or canceled
        // populate results array and see if there is a criteria match (stored vs anything in the history tree)
        for (var i=0;i<resultSetCount;i++) {
          var resultset = o.session.resultset[i];
          var result = resultset.result[0];
          if (parseInt(result.status[0].code[0].value.valueOf()) >= 0 && result.criteria) {
              // populate the HistoryView node first
              self.buildHistoryTree(o,i);
              // add to a results config array for processing as a promise
              results.push( new giovanni.app.Session.ResultObject(resultset,result) );
              // is there a criteria match?  if so, store it locally for comparison
              if (storedResultNode && storedResultNode.criteria === result.criteria[0].query[0].value) {
                  matchingResultNode = storedResultNode;
                  matchingIdx = activeResultsCount;
              }
              activeResultsCount++;
          }
        }
        console.log("Session.handleRestoreSessionTreeSuccess():  active result set count: " + activeResultsCount);
        // if there is no previous user selection of a result node,
        // matchingIdx and matchingResultNode will be undefined,
        // so use the most recent result from History (e.g., historyObj)
        var resultToRestore = matchingIdx !== undefined ?
          self.workspace.historyView.historyObject.results[matchingIdx] :
          self.workspace.historyView.historyObject.results[self.workspace.historyView.historyObject.results.length-1];
        // if there is a matching result node, update it's id to that of the appropriate History result object
        if (matchingResultNode)
          matchingResultNode.id = resultToRestore.id;
        // When the last result has been added to the summary (i.e.,pruned) tree,
        // set the context in the HistoryView.  If matchingResultNode is undefined, the context
        // will be set to the most recent result
        if (resultToRestore) { // once the last result is added to the history list,
          // set the appropriate node
          var firedStatusSelect = false;
          var checkExist = setInterval(function() {
            if (resultToRestore.status.percentComplete === '100' || resultToRestore.status.code !== '0') {
              // if we're all done with the selected result, set the context
              self.workspace.historyView.setContextUsingCriteria(matchingResultNode);
              // make sure the result view is sized properly - mainly for map and lineage
              self.workspace.resultView.resize();
              // fire selection event to sync the result view with history view
              if (matchingResultNode) 
                self.workspace.historyView.resultSelectionEvent.fire({id:matchingResultNode.id,type:matchingResultNode.type});
              else 
                self.workspace.historyView.resultSelectionEvent.fire({id:resultToRestore.id,type:'Status'});
              // clear the interval
              clearInterval(checkExist);
            } else {
              if (!firedStatusSelect) {
                firedStatusSelect = true;
                self.workspace.historyView.resultSelectionEvent.fire({id:resultToRestore.id,type:'Status'});
              }
            }
          }, 100);
        }
        // we're all done; hide the progress icon
        hideProgress();
    } else { // end of resultSetCount check
      // results count is zero
      if (this.workspace) this.workspace.showDataSelector();
      sessionManager.setUserView('dataSelection');
      hideProgress();
      console.log("Session.handleRestoreSessionTreeSuccess():  result count is zero");
    }
};

/* initial history tree construction */
giovanni.app.Session.prototype.buildHistoryTree = function (tree, index) {
    /* create the result branch */
    var branch = tree.session.resultset.slice(index,index+1);
    /* create the prunced object (full tree path, but only a single result) */
    var pruned = {};
    pruned.session = {};
    pruned.session.id = tree.session.id;
    pruned.session.resultset = {};
    /* add the branch to the pruned full path */
    pruned.session.resultset = branch;
    /* set title */
    var title = branch[0].result[0].title;
    /* set query */
    var query = branch[0].result[0].criteria[0].query[0].value;
    /* restore the full result */
    var restored = this.history.restoreResult(tree.session.id, title, query, pruned);
}

/* callback method for get plots button */
giovanni.app.Session.prototype.initiatePlotData = function () {
    if (this.sessionId == null) {
        alert("No session with the server. Please try later or reload the page.");
        return;
    }
    if(!this.workspace){
        var workspaceId = this.containerId + "Workspace";
        var workspaceElem = document.createElement('div');
        workspaceElem.id = workspaceId;
        this.container.appendChild(workspaceElem);
        this.workspace = new giovanni.ui.Workspace(workspaceId, {
            session: this
        });
    }
    // since we're plotting something new, make sure the
    // workspace restore flag is false
    this.workspace.restoreFlag = false;
    // make sure the validation process is functioning
    if (!this.dataSelector.validate().isValid()) {
        return; // validation failed - return now - appropriate alert msg should
        // have been displayed in dataSelector.validate()
    }
    // any warnings?
    if (!this.dataSelector.warnUser())
        return; // user didn't like something and wants to re-group
    // set the query from data selector; add width and height if it's an animation
    var query = this.dataSelector.getValue();
    //if(this.dataSelector.servicePicker.getValue().indexOf('MpAn')){
    //    this.animationDims = {'width':1024,'height':512};
    //    query += '&options=[{"options":{"width":'+this.animationDims.width+',"height":'+this.animationDims.height+'}}]';
    //}
    // create the result object that will hold the eventual plot results
    var res = this.history.createResult(this.sessionId, null, query);
    // show the workspace
    this.showWorkspace();
};

giovanni.app.Session.prototype.restoreWorkspace = function () {
    if (this.sessionId == null) {
        console.log("Session.restoreWorkspace():  Can't find a session id. Please try later or reload the page.");
    }
    if (!this.workspace){
        var workspaceId = this.containerId + "Workspace";
        if (!$('#'+workspaceId).length) {
            $(this.container).append('<div id="'+workspaceId+'"></div>');
        }
        this.workspace = new giovanni.ui.Workspace(workspaceId, {
            session: this
        });
    }
    this.workspace.restoreFlag = true;
};

giovanni.app.Session.prototype.getAnimationDims = function () {
  return this.animationDims;
}

/**
 * returns the dataSelector
 */
giovanni.app.Session.prototype.getDataSelector = function () {
    return this.dataSelector;
};

/**
 *  * returns the history object
 *   */
giovanni.app.Session.prototype.getHistory = function () {
    return this.history;
};

/**
 *  * Display the Giovanni help page
 *   */
giovanni.app.Session.prototype.displayHelp = function () {
    alert('will display help');
};

/**
 *  Sends user feedback via email. NOTE: there are different flavors of the
 *  feedback message that are dependent upon which page the request is made from
 *   
 *  @this {giovanni.app.Session}
 *  @param {YAHOO.util.Event,Object}
 *  @author K. Bryant
 **/
giovanni.app.Session.prototype.sendFeedback = function (e) {
    var headerStr = "%0D%0D%0D------------------- Portal Data (used by the Giovanni team) -------------------";
    var hostMatchPattern = /^giovanni/i;
    var mailtoURL = hostMatchPattern.test(window.location.host) ? "mailto:gsfc-help-disc@lists.nasa.gov?subject=Error%20Report" :
        "mailto:gsfc-agiovanni-dev-disc@lists.nasa.gov?subject=Error%20Report";
    mailtoURL += "&subject=Error%20Report&body=" + headerStr;
    var page = $('#sessionDataSel').is(":visible") ? 'dataSelection' : 
      $('#sessionWorkspace').is(':visible') ? 'workspace' : 'dataSelection';
    switch (page) {
    case "dataSelection":
        // since we're on the data selection page, just
        // document the portal information
        mailtoURL += "%0D%0DPortal%20URL%3A%20%20%0D";
        mailtoURL += encodeURIComponent(window.location.href);
        // add component values if they're there
        mailtoURL += "%0D%0DCriteria Values%3A%20%20%0D";
        mailtoURL += this.getSelectionComponentValues();
        break;
    case "workspace":
        // add the result URL (service_manager.pl) info
        var result = this.workspace.resultView.getCurrentResult();
        var url = window.location.protocol + "//" + window.location.hostname + "/giovanni/";
        url += this.serviceManagerURL + "session=" + this.sessionId;
        if (result.resultSetId) url += "%26resultset=" + result.resultSetId;
        if (result.resultId) url += "%26result=" + result.resultId;
        mailtoURL += "%0D%0DResult%20URL%3A%20%20%0D" + url;
        // add the portal info
        mailtoURL += "%0D%0DPortal%20URL%3A%20%20%0D";
        mailtoURL += encodeURIComponent(window.location.href);
        // if avaiable, use the criteria from the results
        if (result) {
            var query = this.getCriteria(result);
            window.history.replaceState({}, undefined, '#' + query);
        }
        break;
    default:
        mailtoURL += "%0D%0DPortal%20URL%3A%20%20%0D";
        mailtoURL += encodeURIComponent(window.location.href);
    }
    // attach user agent info
    mailtoURL += "%0D%0DUser%20Agent%3A%20%20%0D";
    mailtoURL += encodeURIComponent(navigator.userAgent);
    // open mail window
    var mailWin = window.open(mailtoURL, "agMailWindow",
         'location=no,menubar=0,toolbar=0,status=0,titlebar=0,top=0,left=3000,height=1,width=1');
    // close brower mail window since it will spawn the mail client
    setTimeout(function () {
        mailWin.close();
        }, 500);
};

/**
 * Retrieves the values for each selection compoment and stuff them into a
 * string. Used by 'sendFeedback()'
 * 
 * @this {giovanni.app.Session}
 * @params {}
 * @return {String}
 * @author K. Bryant
 */
giovanni.app.Session.prototype.getSelectionComponentValues = function () {
    var uic = REGISTRY.getUIComponents();
    var str = "";
    for (var i = 0; i < uic.length; i++) {
        if (uic[i].loadFromQuery instanceof Function &&
            uic[i].getValue instanceof Function && 
            uic[i].getValue() && uic[i].getValue() != "") {
            try {
                str += "%20%20%20%20-%20" + encodeURIComponent(uic[i].getValue()) +
                    "%0D";
            } catch (err) {
                str += "Error occurred in 'getValue' for " + uic[i].getId() +
                    " component";
            }
        }
    }
    return str;
}

/*
 * Show the workspace
 * 
 * @this {giovanni.app.Session} @author K. Bryant
 */
giovanni.app.Session.prototype.showWorkspace = function () {
    sessionManager.setUserView('workspace');
    this.workspace.show();
};

giovanni.app.Session.prototype.getWorkspace = function () {
    return this.workspace;
};

/**
 * Shows GIOVANNI help page
 * 
 * @this {giovanni.app.Session}
 * @params {YAHOO.util.Event,Object}
 * @author K. bryant
 */
giovanni.app.Session.prototype.showHelp = function (e, o) {
    var url = "./doc/UsersManualworkingdocument.docx.html";
    var target = "help";
    var config = "scrollbars,resizeable,width=1000,height=650";
    var helpwin = window.open(url, target, config);
    helpwin.focus();
};

giovanni.app.Session.prototype.showMenu = function (e, menuClass) {
  var menu = $('.'+menuClass);
  if($(menu).is(":visible")){
    $(menu).hide();
  }else{
    $(menu).show();
  }
  e.stopPropagation();
}

/*
 * Returns the user input (criteria) for the given result
 * 
 * @this {giovanni.app.Session} @params {giovanni.app.Result} @returns {String}
 * @author K. Bryant
 */
giovanni.app.Session.prototype.getCriteria = function (res) {
    // Get the criteria query string, and remove session= from it.
    var query = "";
    if (res.hasCriteria()) {
        var str = res.getCriteria().query[0].value;
        var pairs = giovanni.util.map(str.split("&"), function (p) {
            return p.split("=");
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "session";
        });
        query = giovanni.util.map(pairs, function (p) {
            return p.join("=");
        }).join("&");
    }
    return query;
};

giovanni.app.Session.prototype.clear = function () {
  if (this.workspace) this.workspace.clear();
}
