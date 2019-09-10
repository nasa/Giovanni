/*
 ** $Id: Result.js,v 1.47 2015/08/06 16:29:40 mpetrenk Exp $
 ** -@@@ Giovanni, Version $Name:  $
 */

// establish the component namespace
giovanni.namespace("app");

/**
 * Constructor
 *
 * @this {giovanni.app.Result}
 * @param {Object}
 * @author Chocka
 */

giovanni.app.Result = function (config) {
    config = (config == null ? {} : config);
    this.queryData = config.queryData;
    if (this.queryData == undefined || this.queryData == null) {
        var msg = 'giovanni.app.Result: Cannot create a Result object. Config parameter does not have a valid query string.';
        console.log(msg);
        document.getElementById('statusContainer').innerHTML = msg;
        return;
    }

    this.sessionId = config.sessionId;
    if (this.sessionId == undefined || this.sessionId == null) {
        var msg = 'giovanni.app.Result: Cannot create a Result object. Config parameter does not have a valid Session ID.';
        console.log(msg);
        document.getElementById('statusContainer').innerHTML = msg;
        return;
    }

    this.portal = config.portal;
    if (this.portal == undefined || this.portal == null) {
        var msg = 'giovanni.app.Result: Cannot create a Result object. Config parameter does not have a valid portal name.';
        console.log(msg);
        document.getElementById('statusContainer').innerHTML = msg;
        return;
    }

    // this is the url prefix which will be suffixed with the query data to form the full service query 
    this.urlPrefix = config.urlPrefix;
    if (this.urlPrefix == undefined || this.urlPrefix == null) {
        var msg = 'giovanni.app.Result: Cannot create a Result object. Config parameter does not have a valid service manager URL prefix.';
        console.log(msg);
        document.getElementById('statusContainer').innerHTML = msg;
        return;
    }

    this.restoreFlag = config.restoreFlag;

    // unique id - not displayed
    this.count = giovanni.app.Result.index++;
    this.id = 'result' + (this.count);
    // displayable title
    this.title = (config.title == undefined ? "Untitled" : config.title);

    // longer displayable title
    this.description = (config.description == undefined) ? "Untitled" : config.description;

    // overall caption
    this.caption = (config.caption == undefined) ? "" : config.caption;

    this.status = new giovanni.app.Result.Status(0, "Created", 0);

    this.resultSetId = null;
    this.resultId = null;
    this.groupedPlots = null;
    this.plots = null;
    this.dataFiles = null;
    this.plotOptions = null;
    this.agreements = null;
    this.lineage = null;
    this.imageCollection = null;
    this.criteria = null;
    this.debugUrl = null;
    this.deleteUrl = null;

    this.resultUpdateEvent = new YAHOO.util.CustomEvent('ResultUpdateEvent', this);
    this.plotUpdateEvent = new YAHOO.util.CustomEvent('PlotUpdateEvent', this);
    this.enableReplot = new YAHOO.util.CustomEvent('EnableReplot', this);
    this.UPDATE_INTERVAL = 500; /*milliseconds*/

    this.cancelled = false;

    // TEMP flag to indicate that the 75% completion level has been reached
    // and therefore a 'visualization status' request has been made
    this.vizRequested = false;

    this.rePlotFlag = false;
    if (this.restoreFlag) {
      this.updateResult(config.queryResult, config.resultSetIdx);
    } else {
      // initiate service request
      this.initiateServiceRequest();
    }
};

giovanni.app.Result.index = 1;

/**
 * Submits the initial service request query to the service manager.
 *
 * @this {giovanni.app.Result}
 * @author Chocka
 */
giovanni.app.Result.prototype.initiateServiceRequest = function () {
    var url = this.urlPrefix // http://s4ptu-ts2.ecs.nasa.gov/daac-bin/service_manager.pl?
        +
        'session=' + this.sessionId // session=3267C2FC-F6D1-11E1-AC2B-78D069B977CC
        +
        '&' + this.queryData // &bbox=-180,-90,180,90&data=MYD0 ...<the query data>
        +
        '&portal=' + this.portal // &portal=GIOVANNI
        +
        '&format=json'; // &format=json
    YAHOO.util.Connect.asyncRequest('GET', url, {
        success: this.parseServiceManagerResponse,
        failure: function () {
            var msg = "giovanni.app.Result: Initiate service request failed";
            console.log(msg);
            document.getElementById('statusContainer').innerHTML = msg;
        },
        scope: this
    });
};

/**
 * Submits the re-plot request, when the user changes plot options, to the service manager.
 *
 * @this {giovanni.app.Result}
 * @author K. Bryant/Chocka
 */
giovanni.app.Result.prototype.initiateRePlot = function (optionsURL) {
    this.rePlotFlag = true;
    var url = this.urlPrefix // http://s4ptu-ts2.ecs.nasa.gov/daac-bin/service_manager.pl?
        +
        'session=' + this.sessionId // session=3267C2FC-F6D1-11E1-AC2B-78D069B977CC
        +
        '&resultset=' + this.resultSetId // &resultset=<some result set id like above>
        +
        '&result=' + this.resultId // &result=<some result id like above>
        +
        '&' + optionsURL // &<plot options>
        +
        '&portal=' + this.portal // &portal=GIOVANNI
        +
        '&format=json'; // &format=json
    YAHOO.util.Connect.asyncRequest('GET', url, {
        success: this.parseServiceManagerResponse,
        failure: function () {
            var msg = "giovanni.app.Result: Re-plot request failed";
            console.log(msg);
            document.getElementById('statusContainer').innerHTML = msg;
        },
        scope: this
    });
};

/**
 * Submits a status check query to the service manager.
 *
 * @this {giovanni.app.Result}
 * @param {giovanni.app.Result}
 * @author Chocka
 */
giovanni.app.Result.prototype.checkStatus = function (self) {
    // if cancelled flag is set, stop checking status
    if (self.cancelled) return;
    var url = self.urlPrefix // http://s4ptu-ts2.ecs.nasa.gov/daac-bin/service_manager.pl?
        +
        'session=' + self.sessionId // session=3267C2FC-F6D1-11E1-AC2B-78D069B977CC
        +
        '&resultset=' + self.resultSetId // &resultset=<some result set id like above>
        +
        '&result=' + self.resultId // &result=<some result id like above>
        +
        '&portal=' + self.portal // &portal=GIOVANNI
        +
        '&format=json'; // &format=json
    YAHOO.util.Connect.asyncRequest('GET', url, {
        success: self.parseServiceManagerResponse,
        failure: function () {
            var msg = "Sorry, but the visualizer may be taking too long.  Please select a smaller spatial region or time range.";
            document.getElementById('statusContainer').innerHTML = msg;
        },
        scope: self
    });
};

/**
 * Submits the cancel service request query to the service manager.
 *
 * @this {giovanni.app.Result}
 * @author Chocka
 */
giovanni.app.Result.prototype.cancelServiceRequest = function () {
    var url = this.urlPrefix // http://s4ptu-ts2.ecs.nasa.gov/daac-bin/service_manager.pl?
        +
        'session=' + this.sessionId // session=3267C2FC-F6D1-11E1-AC2B-78D069B977CC
        +
        '&resultset=' + this.resultSetId // &resultset=<some result set id like above>
        +
        '&result=' + this.resultId // &result=<some result id like above>
        +
        '&portal=' + this.portal // &portal=GIOVANNI
        +
        '&cancel=1' // request to cancel this service
        +
        '&format=json'; // &format=json
    YAHOO.util.Connect.asyncRequest('GET', url, {
        success: this.parseServiceManagerResponse,
        failure: function () {
            var msg = "giovanni.app.Result: Cancel service request failed";
            console.log(msg);
            document.getElementById('statusContainer').innerHTML = msg;
        },
        scope: this
    });
};

giovanni.app.Result.prototype.hide = function () {
    var url = this.urlPrefix // http://s4ptu-ts2.ecs.nasa.gov/daac-bin/service_manager.pl?
        +
        'session=' + this.sessionId // session=3267C2FC-F6D1-11E1-AC2B-78D069B977CC
        +
        '&resultset=' + this.resultSetId // &resultset=<some result set id like above>
        +
        '&result=' + this.resultId // &result=<some result id like above>
        +
        '&portal=' + this.portal // &portal=GIOVANNI
        +
        '&delete=1' // request to cancel this service
        +
        '&format=json'; // &format=json
    YAHOO.util.Connect.asyncRequest('GET', url, {
        success: this.parseServiceManagerResponse,
        failure: function () {
            var msg = "giovanni.app.Result: Hide request failed";
            console.log(msg);
            document.getElementById('statusContainer').innerHTML = msg;
        },
        scope: this
    });
}

/**
 * Executed when an asynchronous query to the service manager is successful.
 * Parses the JSON response text into a JavaScript object, and calls the 
 * update method.
 *
 * @this {giovanni.app.Result}
 * @param {giovanni.app.Result}
 * @author Chocka
 */
giovanni.app.Result.prototype.parseServiceManagerResponse = function (o) {
    try {
        var respObj = YAHOO.lang.JSON.parse(o.responseText);
        this.updateResult(respObj);
    } catch (x) {
        console.log("giovanni.app.Result.parseServiceManagerResponse: " + x.message);
        console.log(o.responseText);
        document.getElementById('statusContainer').innerHTML = "giovanni.app.Result.parseServiceManagerResponse: " + x.message;
    }
};

/**
 * Goes thru the response object obtained from the service manager response, 
 * and rebuilds the object collections (plot images and their data file links)
 * required for rendering this Result on the UI. Publishes a 'ResultUpdateEvent' 
 * after a successful update. Schedules a status check, until the result is complete
 * or encounters an error.
 *
 * @this {giovanni.app.Result}
 * @param {Object}
 * @author Chocka
 */
giovanni.app.Result.prototype.updateResult = function (resp) {
    if (!resp.session) return;
    var session = resp.session;
    if (session.error) {
        console.log(session.error[0].value);
        var msg = "Oops! We encountered an unexpected problem trying to finish your request. " +
            "\nPlease <span class=\"inlineFeedbackLink\" onclick=\"session.sendFeedback(event,'workspace');\">send us feedback</span> " +
            "and we'll investigate.  Thanks!";
        document.getElementById('statusContainer').innerHTML = msg;
        return;
    }
    if (session.id != this.sessionId) {
        console.log('Warning: Service Manager returned a different Session ID');
    }

    var resultSet = session.resultset[0];
    //var idx = rsIdx ? rsIdx : 0;
    //var resultSet = session.resultset[idx];
    this.resultSetId = resultSet.id;

    var result = resultSet.result[0];
    this.resultId = result.id;

    // set the criteria (used by giovanni.ui.ResultView immediately)
    if (result.criteria instanceof Array && result.criteria.length != 0) {
        this.criteria = result.criteria[0];
    }

    this.title = result.title;
    this.description = result.description;
    this.caption = result.caption;

    var stat = result.status[0];
    this.status.code = (stat.code[0].value == undefined ? 0 : stat.code[0].value);
    this.status.msg = stat.message ? stat.message[0].value : "";
    this.status.percentComplete = stat.percentComplete ? (stat.percentComplete[0].value == undefined ? 0 : stat.percentComplete[0].value) : 0;

    if (result.hasOwnProperty("lineage")) {
        // Set lineage only if exists
        this.lineage = result.lineage[0].value;
    }
    if (result.hasOwnProperty("debug")) {
        // Set debug URL only if exists
        this.debugUrl = result.debug[0].value;
    }

    this.deleteUrl = "daac-bin/service_manager.pl?session=" + this.sessionId + "&resultset=" + this.resultSetId + "&result=" + this.resultId;
    // empty the plots and supporting arrays - they will be re-built from the current response
    this.dataFiles = [];
    this.groupedPlots = [];
    this.groupDecorations = [];
    this.plots = [];
    this.plotOptions = [];
    var plotCount = 0; // used by this.plots associated array (so the client can get an ordered array)

    if (result.data instanceof Array && result.data.length != 0) { // strictly required. In result schema, data is (0..*)
        for (var i = 0; i < result.data.length; i++) {
            var data = result.data[i];
            if (data.fileGroup instanceof Array && data.fileGroup.length != 0) { // NOT strictly required. In result schema, fileGroup is (1..*)   
                for (var j = 0; j < data.fileGroup.length; j++) {
                    var fileGroup = data.fileGroup[j];
                    // if there is a group title, store it
                    this.groupDecorations[i] = {
                        "title": fileGroup.title ? fileGroup.title : "",
                        "caption": fileGroup.caption ? fileGroup.caption : ""
                    };
                    if (fileGroup.dataFile instanceof Array && fileGroup.dataFile.length != 0) { // NOT strictly required. In result schema. dataFile is (1..*)
                        for (var k = 0; k < fileGroup.dataFile.length; k++) {
                            var dataFile = fileGroup.dataFile[k];
                            // create the data file info for download - has a URL and a label
                            this.dataFiles.push(new giovanni.app.Result.DataFile(dataFile.dataUrl[0].value, dataFile.dataUrl[0].label));
                            if (dataFile.status[0].value == 'Failed') {
                                var imageId;
                                dataFile.image ? imageId = dataFile.image[0].id[0].value : imageId = null;
                                var newPlot =
                                    new giovanni.app.Result.Plot(
                                        this.getId(),
                                        null,
                                        imageId,
                                        null,
                                        null,
                                        null,
                                        null,
                                        dataFile.dataUrl[0].label,
                                        dataFile.message[0].value);
                                this.plots[plotCount] = newPlot;
                                plotCount++;
                                var d = new giovanni.app.Result.plotData(newPlot);
                                this.plotUpdateEvent.fire(d);
                            } else if (dataFile.status[0].value == 'Succeeded' && dataFile.image instanceof Array && dataFile.image.length != 0) { // strictly required. In result schema, image is (0..*)
                                for (var l = 0; l < dataFile.image.length; l++) {
                                    var image = dataFile.image[l];
                                    // create the plot info for display - has a plot type, source, and optionally, a plot data file url, and caption 
                                    var dataFileUrl = (image.imgDataUrl != undefined && image.imgDataUrl.length != 0 ? image.imgDataUrl[0].value : null);
                                    if(!dataFileUrl && image.type === "MAP_ANIMATION") {
                                        dataFileUrl = dataFile.dataUrl[0].value;
                                    }
                                    var caption = (image.caption != undefined && image.caption.length != 0 ? image.caption[0].value : null);
                                    var title = (image.title && image.title[0].value != undefined ? image.title[0].value : null);
                                    //this.plots.push(new giovanni.app.Result.Plot(image.type, image.src[0].value, dataFileUrl, caption));
                                    var newPlot =
                                        new giovanni.app.Result.Plot(
                                            this.getId(),
                                            image.type,
                                            image.id[0].value,
                                            image.src[0].value,
                                            title,
                                            dataFileUrl,
                                            caption,
                                            dataFile.dataUrl[0].label,
                                            image.options[0]);
                                    this.plots[plotCount] = newPlot;
                                    plotCount++;
                                    var d = new giovanni.app.Result.plotData(newPlot);
                                    this.plotUpdateEvent.fire(d);
                                }
                            }
                        }
                    }
                } // end of fileGroup loop
                // add plots into class-level grouped plots array
                this.groupedPlots[i] = this.plots;
            }

            if (data.agreementList instanceof Array && data.agreementList.length != 0) { // strictly required. In result schema, agreementList is (0..1)
                var agreementList = data.agreementList[0];
                if (agreementList.agreement instanceof Array && agreementList.agreement.length != 0) { // strictly required. In result schema, agreement is (0..*)
                    for (var m = 0; m < agreementList.agreement.length; m++) {
                        var agreement = agreementList.agreement[m];
                        // create the user agreements to be displayed for this result - has the text content and an optional boolean called 'mandatory', 
                        // to decide if the user has to agree to the contents of the agreement
                        var mand = (agreement.mandatory == undefined) ? false : (agreement.mandatory == 'true' ? true : false);
                        this.agreements.push(new giovanni.app.Result.Agreement(agreement.value, mand));
                    }
                }
            }
        }
    }

    if (result.imageCollection instanceof Array && result.imageCollection.length != 0) {
        this.imageCollection = result.imageCollection[0].value;
    }



    // view object collections have been rebuilt - fire an update event
    if (!this.rePlotFlag)  { 
      this.resultUpdateEvent.fire({restore:this.restoreFlag});
    }
    // check if further status checks are required
    // stop checking when percent complete is 100 or status code is non-zero 
    // (for eg: -1 for cancelled, or positive integers for specific error cases)
    if (this.status.percentComplete < 100 && this.status.code == 0) {
        var self = this;
        if (this.status.percentComplete >= 75 && !this.vizRequested) {
            this.vizRequested = true;
            setTimeout(function () {
                self.checkStatus(self);
            }, 500);
        } else {
            setTimeout(function () {
                self.checkStatus(self);
            }, this.UPDATE_INTERVAL);
        }
        this.UPDATE_INTERVAL += 250; // subsequent status checks grow less frequent, in increments of 0.25 seconds
        if (this.UPDATE_INTERVAL >= 2000) {
            this.UPDATE_INTERVAL = 2000;
        }
    } else if (this.status.code == -1 || (this.status.code > 0 && this.status.msg.indexOf("cancel") > -1)) {
        this.cancelled = true;
    } else if (this.status.percentComplete == 100 && this.status.code == 0) {
        this.enableReplot.fire();
    }
};

/**
 * Returns the unique id for this result object 
 *
 * @this {giovanni.app.Result}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.prototype.getId = function () {
    return this.id;
};

giovanni.app.Result.prototype.getIndex = function () {
    return this.count;
}

giovanni.app.Result.plotData = function (data) {
    this.data = data;
}

/**
 * Returns the title for this result object 
 *
 * @this {giovanni.app.Result}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.prototype.getTitle = function () {
    return this.title;
};

/**
 * Sets the title for this result object 
 *
 * @this {giovanni.app.Result}
 * @param {String}
 * @author Chocka
 */
giovanni.app.Result.prototype.setTitle = function (title) {
    this.title = title;
};

/*
 * Sets the description (long title) for the result
 */
giovanni.app.Result.prototype.setDescription = function (description) {
    this.description = description;
}

/*
 * Returns the description (long title) for the result
 */
giovanni.app.Result.prototype.getDescription = function () {
    return this.description;
}

/*
 * Sets the overall caption for the result
 */
giovanni.app.Result.prototype.setCaption = function (caption) {
    this.caption = caption;
}

/* 
 * Returns the overall caption for the result
 */
giovanni.app.Result.prototype.getCaption = function () {
    return this.caption;
}

/**
 * Returns the plot images received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {Array of giovanni.app.Result.Plot}
 * @author Chocka
 */
giovanni.app.Result.prototype.getPlots = function () {
    return this.plots;
};

giovanni.app.Result.prototype.getGroupedPlots = function () {
    return this.groupedPlots;
}

giovanni.app.Result.prototype.getGroupDecorations = function () {
    return this.groupDecorations;
}

/**
 * Returns true if at least one plot has been received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {boolean}
 * @author Chocka
 */
giovanni.app.Result.prototype.hasPlots = function () {
    return (this.plots != null && this.plots.length > 0);
};

/**
 * Returns the data files received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {Array of giovanni.app.Result.DataFile}
 * @author Chocka
 */
giovanni.app.Result.prototype.getData = function () {
    return this.dataFiles;
};

/**
 * Returns true if at least one data file has been received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {boolean}
 * @author Chocka
 */
giovanni.app.Result.prototype.hasData = function () {
    return (this.dataFiles != null && this.dataFiles.length > 0);
};

/**
 * Returns the lineage info received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.prototype.getLineage = function () {
    return this.lineage;
};

/**
 * Returns the debug URL received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {String}
 * @author M. Hegde
 */
giovanni.app.Result.prototype.getDebugUrl = function () {
    return this.debugUrl;
};

giovanni.app.Result.prototype.getDeleteUrl = function () {
    return this.deleteUrl;
}

/**
 * Returns true if lineage info has been received from the service manager 
 *
 * @this {giovanni.app.Result}
 * @return {boolean}
 * @author Chocka
 */
giovanni.app.Result.prototype.hasLineage = function () {
    return (this.lineage != null && this.lineage.length > 0);
};

/**
 * Returns the plot options for this result object 
 *
 * @this {giovanni.app.Result}
 * @return {Array of giovanni.app.Result.PlotOption}
 * @author Chocka
 */
giovanni.app.Result.prototype.getPlotOptions = function () {
    return this.plotOptions;
};

/**
 * Returns true if there is at least one plot option available for this result object 
 *
 * @this {giovanni.app.Result}
 * @return {boolean}
 * @author Chocka
 */
giovanni.app.Result.prototype.hasPlotOptions = function () {
    return (this.plotOptions != null && this.plotOptions.length > 0);
};

/**
 * Returns the URL to a document containing all images for this result including captions 
 *
 * @this {giovanni.app.Result}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.prototype.getImageCollection = function () {
    return this.imageCollection;
};

/**
 * Returns true if image collection URL info has been received for this result object 
 *
 * @this {giovanni.app.Result}
 * @return {boolean}
 * @author Chocka
 */
giovanni.app.Result.prototype.hasImageCollection = function () {
    return (this.imageCollection != null && this.imageCollection.length > 0);
};

/**
 * Returns the result user input (criteria)
 * 
 * @this {giovanni.app.Result}
 * @return {Object}
 * @author K. Bryant
 */
giovanni.app.Result.prototype.getCriteria = function () {
    return this.criteria;
};

/**
 * Returns true if criteria object is available in this result object
 * 
 * @this {giovanni.app.Result}
 * @return {boolean}
 * @author Chocka
 */
giovanni.app.Result.prototype.hasCriteria = function () {
    return (this.criteria != null);
};

/**
 * Returns the status of this result object 
 *
 * @this {giovanni.app.Result}
 * @return {giovanni.app.Result.Status}
 * @author Chocka
 */
giovanni.app.Result.prototype.getStatus = function () {
    return this.status;
};

/**
 * Constructor for the internal 'Result.Status' class
 *
 * @this {giovanni.app.Result.Status}
 * @param {Integer, String, Integer}
 * @author Chocka
 */
giovanni.app.Result.Status = function (code, msg, percentComplete) {
    this.code = code;
    this.msg = msg;
    this.percentComplete = percentComplete;
};

/**
 * Returns the status code for the task represented by this status object
 *
 * @this {giovanni.app.Result.Status}
 * @return {Integer}
 * @author Chocka
 */
giovanni.app.Result.Status.prototype.getCode = function () {
    return this.code;
};

/**
 * Returns the status message for the task represented by this status object
 *
 * @this {giovanni.app.Result.Status}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.Status.prototype.getMessage = function () {
    return this.msg;
};

/**
 * Returns the percentage of completion for the task represented by this status object
 *
 * @this {giovanni.app.Result.Status}
 * @return {Integer}
 * @author Chocka
 */
giovanni.app.Result.Status.prototype.getPercentComplete = function () {
    return this.percentComplete;
};

/**
 * Constructor for the internal 'Result.DataFile' class
 *
 * @this {giovanni.app.Result.DataFile}
 * @param {String, String}
 * @author Chocka
 */
giovanni.app.Result.DataFile = function (url, label) {
    this.url = url;
    this.label = label;
};

/**
 * Returns the URL for the data file
 *
 * @this {giovanni.app.Result.DataFile}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.DataFile.prototype.getUrl = function () {
    return this.url;
};

/**
 * Returns the display label for the data file
 *
 * @this {giovanni.app.Result.DataFile}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.DataFile.prototype.getLabel = function () {
    return this.label;
};

/**
 * Constructor for the internal 'Result.Plot' class
 *
 * @this {giovanni.app.Result.Plot}
 * @param {String, String, String, String}
 * @author Chocka
 */
giovanni.app.Result.Plot = function (resId, type, id, source, title, dataFileUrl, caption, dataFieldLabel, plotOptions) {
    this.resId = resId;
    this.id = id
    this.type = type;
    this.source = source;
    this.title = title;
    this.dataFileUrl = dataFileUrl;
    this.caption = caption;
    this.dataFieldLabel = dataFieldLabel;
    this.plotted = false;
    this.plotOptions = plotOptions;
    this.showTitle = true;
    this.showCaption = true;
};

giovanni.app.Result.Plot.prototype.getResultId = function () {
    return this.resId;
}

/**
 * Returns the plot type, STATIC or INTERACTIVE_SCATTER_PLOT
 *
 * @this {giovanni.app.Result.Plot}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.Plot.prototype.getType = function () {
    return this.type;
};

/**
 * Returns the url to plot image if STATIC, or url to plot data if INTERACTIVE_SCATTER_PLOT
 *
 * @this {giovanni.app.Result.Plot}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.Plot.prototype.getSource = function () {
    return this.source;
};

/**
 * Returns the url to the data file that went into producing this plot, if any
 *
 * @this {giovanni.app.Result.Plot}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.Plot.prototype.getDataFileUrl = function () {
    return this.dataFileUrl;
};

/**
 * Returns the caption for this plot, if any
 *
 * @this {giovanni.app.Result.Plot}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.Plot.prototype.getCaption = function () {
    return this.caption;
};

giovanni.app.Result.Plot.prototype.getLabel = function () {
    return this.dataFieldLabel;
};

giovanni.app.Result.Plot.prototype.toggleTitleView = function () {
    this.showTitle = !this.showTitle;
};

giovanni.app.Result.Plot.prototype.toggleCaptionView = function () {
    this.showCaption = !this.showCaption;
};

/**
 * Constructor for the internal 'Result.Agreement' class
 *
 * @this {giovanni.app.Result.Agreement}
 * @param {String, Boolean}
 * @author Chocka
 */
giovanni.app.Result.Agreement = function (content, mandatory) {
    this.content = content;
    this.mandatory = Boolean(mandatory);
};

/**
 * Returns the text content to be displayed for this user agreement
 *
 * @this {giovanni.app.Result.Agreement}
 * @return {String}
 * @author Chocka
 */
giovanni.app.Result.Agreement.prototype.getContent = function () {
    return this.content;
};

/**
 * Returns true if this agreement has to be mandatorily approved by the user
 *
 * @this {giovanni.app.Result.Agreement}
 * @return {Boolean}
 * @author Chocka
 */
giovanni.app.Result.Agreement.prototype.isMandatory = function () {
    return this.mandatory;
};
