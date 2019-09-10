//$Id: TableView.js,v 0.1 2014/06/17


giovanni.namespace("widget");


giovanni.widget.TableView = function(containerId, shapefileData) {
    //Get the ID of the container element
    this.container = document.getElementById(containerId);

    if (this.container == null) {
        alert("Error [giovanni.widget.TableView]: element '" + containerId + "' not found!");
        return;
    }
    //Store the container's ID
    this.containerId = containerId;
    this.doneEvent = new YAHOO.util.CustomEvent("DoneEvent", this);
    this.clearEvent = new YAHOO.util.CustomEvent("ClearEvent", this);

    /**
     * onSelectionEvent : YAHOO.util.CustomEvent
     *
     * This event is fired when a shape is picked through this table. It is fired
     * with one argument: an identifier for the shape that should go in the URL.
     * eg, "countryArea/shp_107".
     */
    this.onSelectionEvent = new YAHOO.util.CustomEvent("onSelectionEvent", this);

    //Create a div to hold everything
    var mainContainer = document.createElement('div');
    mainContainer.setAttribute('id', this.containerId + 'mainContainer');
    mainContainer.setAttribute('class', 'mainContainer');

    ////////////  Create all the elements in the Table Viewing Area  /////////////

    //Create a div for the Table Viewing Area
    var TableViewingArea = document.createElement('div');
    TableViewingArea.setAttribute('id', this.containerId + 'tableViewingArea');
    TableViewingArea.setAttribute('class', 'tableViewingArea');
       
    //shapefiles table
    var userShapefilesTable = document.createElement('div');
    userShapefilesTable.setAttribute('id', 'userShapefilesTable');
    userShapefilesTable.setAttribute('class', 'userTable');

    //Shapes table
    var userShapesTable = document.createElement('div');
    userShapesTable.setAttribute('id', 'userShapesTable');
    userShapesTable.setAttribute('class', 'userTable');

    // Source line
    sourceContainer = document.createElement('div');
    sourceContainer.setAttribute('id', this.containerId+'SourceContainer');
    sourceContainer.setAttribute('style', 'margin: 5px;');
    sourceContainer.innerHTML = 'Source: ';
    
    var sourceLabel = document.createElement('span');
    sourceLabel.setAttribute('id', this.containerId+'SourceLabel');   
    
    // Buttons 
    var buttonContainer = document.createElement('div');
    buttonContainer.setAttribute('id', this.containerId+'ButtonContainer');
    buttonContainer.setAttribute('class', 'shapePickerButtonContainer');
    
    var doneButton = giovanni.util.createButton('shapePickerDoneButton', 
                                                buttonContainer,
                                                'Done');

    var clearButton = giovanni.util.createButton('shapePickerClearButton',
                                                 buttonContainer,
                                                 'Clear Shape Selection');

    var self = this;
    doneButton.subscribe('click', function() { self.doneEvent.fire() });
    clearButton.subscribe('click', function() { self.clearEvent.fire(); });

    ///////////////////////////////END Table viewing area////////////////////////

    // Append fileView elements to container
    TableViewingArea.appendChild(userShapefilesTable);
    TableViewingArea.appendChild(userShapesTable);

    mainContainer.appendChild(TableViewingArea);
    mainContainer.appendChild(sourceContainer);
    sourceContainer.appendChild(sourceLabel);
    mainContainer.appendChild(buttonContainer);

    this.container.appendChild(mainContainer);
    
    this.parseUserFilesData(shapefileData);
};


giovanni.widget.TableView.prototype.parseUserFilesData = function(jsonData) {
    //Input is server json of user files data
    //Format/validate data

    //when finished parsing and validating
    if (jsonData["error"]) {
    	console.log("NO JSON DATA FOR THIS USERID, DELETING CURRENT TABLE")
    	$("#userShapefilesTable")[0].innerHTML = ""
    	$("#userShapesTable")[0].innerHTML = ""
    	console.log(jsonData["error"]);
    } else {
        this.createShapefileTable(jsonData);
    }
}


giovanni.widget.TableView.prototype.setCurrentShapefile = function(shapefileName, shapefile) {
    this.currentShapefile = shapefileName;
   
    // Update the source line in the UI dialog
    var el = null;
    if (shapefile.sourceURL && shapefile.sourceName) {
        el = $('<a>')
        el.text(shapefile.sourceName);
        el.attr('href', shapefile.sourceURL);
        el.attr('target', '_Blank');
    } else if (shapefile.sourceName) {
        el = $('<span>').text(shapefile.sourceName);
    }
    
    var labelSelector = $('#' + this.containerId + 'SourceContainer');
    var container = $('#' + this.containerId + 'SourceLabel');
    container.empty();
    
    if (el == null) {
        labelSelector.hide();
    } else {        
        container.append(el);
        labelSelector.show();
    }
}


giovanni.widget.TableView.prototype.createShapefileTable = function(jsonData) {
    // Create the list of shapefiles on the left hand side. Each item holds
    // its identifier and it's display name.
    var columnDefs = [{
        key: "title",
        label: "Shape Files",
        resizeable: false,
        sortable: true,
    }];

    var resultDS = new YAHOO.util.LocalDataSource(giovanni.util.map(jsonData.available, function(prefix) {
        return {
            shapefileName: prefix,
            title: jsonData.info[prefix].title || '<Title missing>',
        };
    }));

    resultDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSARRAY;
    resultDS.responseSchema = {fields: ["shapefileName", "title"]};

    // create the data table
    this.shapefilesTable = new YAHOO.widget.ScrollingDataTable("userShapefilesTable", columnDefs, resultDS, {
        width: '100%',
        height: '200px'
    });

    // initialize selectedShape
    this.shapefilesTable.selectedShapefile = null;

    // Enables cell highlighting
    this.shapefilesTable.subscribe("rowMouseoverEvent", this.shapefilesTable.onEventHighlightRow);
    this.shapefilesTable.subscribe("rowMouseoutEvent", this.shapefilesTable.onEventUnhighlightRow);
    this.shapefilesTable.subscribe("rowClickEvent", this.shapefilesTable.onEventSelectRow);

    // Enables row selection, set listener to change shapesTable data
    var parent = this;

    this.shapefilesTable.subscribe("rowClickEvent", function(oArgs) {
        var target = oArgs.target;
        var column = this.getColumn(target);
        var record = this.getRecord(target);
        var shapefileName = record.getData("shapefileName");

        // Don't refresh table unless it's a different shape
        if (shapefileName == parent.selectedShapefile) {
            console.log("Already showing this shapefile, nothing to do");
            return;
        }
        
        var shape = jsonData.info[shapefileName];
        parent.setCurrentShapefile(shapefileName, shape);

        // Re-populate the shapes table using the shapefile = shapefileName
        if (! shape) {
            console.log("Couldn't find shape:", shape, "in shapefiles");
            $("#userShapesTable")[0].innerHTML = "No data for this shapefile!";
            return;
        }
        
        // Set current shapefile folder
        parent.currentShapefileFolder = jsonData.info[shapefileName]["parentDir"];
        parent.createShapeTable(shape);
    });

    // Start with the first shapefile open
    var shapefileName = jsonData.available[0];
    var shapefile = jsonData.info[shapefileName];
    
    this.shapefilesTable.selectRow(this.shapefilesTable.getTrEl(0));    
    this.setCurrentShapefile(shapefileName, shapefile);
    this.currentShapefileFolder = shapefileName;

    parent.createShapeTable(shapefile, null)
}

giovanni.widget.TableView.prototype.getSelectedShapeInfo = function(){
    // Returns the "/" concatted string of shapefileFolder, shapeID, shapefileID
    return this.currentShapefile+"/"+this.currentShapeID;
}

giovanni.widget.TableView.prototype.setCurrentShape = function(shape, shapeID,shapeDisplayName) {
    this.currentShape = shape;
    this.currentShapeID = shapeID;
    this.currentShapeDisplayName = shapeDisplayName;
}


giovanni.widget.TableView.prototype.createShapeTable = function(shapefile) {
    // Populate the shape table with info from the given shape
    var fields = shapefile['fields'];

    if (! fields) {
        console.log("No 'fields' value in the jsonData, debug!");
        return;
    }

    if (fields.length < 1) {
        console.log('No "values" in "fields"');
        return;
    }

    //Init the fieldDefs
    var fieldDefs = []

    fieldDefs.push({
        key: "radioButton",
        label: '',
        resizeable: false
    });

    fieldDefs.push({
        key: shapefile.bestAttr[0],
        label: 'Shape',
        sortable: true,
        width: '100%',
    });

    //Grab and validate shapes
    shapes = shapefile.shapes;

    if (! shapes) {
        console.log("No 'shapes' value in the shapefiles, debug!");
        return;
    }
	
    //Format the shapes.. maybe the _shpinfo.json should really be changed to a list..
    // TODO: move this into parseShapes or something so that it's only done once and NOT every time 
    // a shapefile is clicked on
    // TODO: at some point make sure bestAttr field comes first
    // in the list. Maybe alphabetize the rest?    
    modShapes = []
    keys = Object.keys(shapes)

    for (var i = 0; i < keys.length; i++) {
        var shape = shapes[keys[i]];
	var name = shape.values[shapefile.bestAttr[1]];        

        var currentShape = []
        currentShape.push('<input type="radio"/>');          
        currentShape.push(name);

        modShapes.push(currentShape);
    }
    
    modShapes.sort(function(a, b) {
        return a[1].localeCompare(b[1]);
    });

     var resultDS = new YAHOO.util.LocalDataSource(modShapes);

     resultDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSARRAY;
     resultDS.responseSchema = {
         fields: fieldDefs
     };


    this.shapesTable = new YAHOO.widget.ScrollingDataTable("userShapesTable", fieldDefs, resultDS, {
        width: '300px',
        height: '200px'
    });

    // Enables cell highlighting
    this.shapesTable.subscribe("rowMouseoverEvent", this.shapesTable.onEventHighlightRow);
    this.shapesTable.subscribe("rowMouseoutEvent", this.shapesTable.onEventUnhighlightRow);

    // Set click listener, set radio button, highlight on click, set the input box
    // in ShapefilePicker to the current shape.
    this.shapesTable.subscribe("rowClickEvent", this.shapesTable.onEventSelectRow);

    var parent = this;
    this.shapesTable.subscribe("rowClickEvent", function(oArgs) {

        var target = oArgs.target;
        var column = this.getColumn(target);
        var record = this.getRecord(target);
        var data = record.getData();

        //console.log(target, column, record, data)

        // deselect the old row radio button, if in the same table (otherwise it'll
        // already be cleared.)
        // don't deselect if it's the currently selected shape
        if (!(parent.currentShape == target)) {
            // deselect 
            if (parent.currentShape) {
                var oldRadioButton = parent.currentShape.getElementsByTagName("input")[0];
                if (oldRadioButton) {
                    oldRadioButton.checked = false;
                }
            }
            // select new radio button
            currentRadioButton = target.getElementsByTagName("input")[0];
            if (currentRadioButton) {
                currentRadioButton.checked = true;
            }
        }
        var displayAttr = shapefile["bestAttr"][0];
        //console.log(shapefile,displayAttr); 

        var shapeID;
        for (var key in shapefile.shapes) {
            var idx = shapefile["bestAttr"][1];
            var curName = shapefile.shapes[key].values[idx];
            var tarName = data[displayAttr];

            if (curName == tarName) {
                shapeID = key;
            }
        }

        var shapeDisplayName = data[displayAttr];

        parent.setCurrentShape(target,shapeID,shapeDisplayName);
        parent.onSelectionEvent.fire(parent.getSelectedShapeInfo());
    });
}


giovanni.widget.TableView.prototype.handleStatusChange = function(evt, args, self) {
    self.setStatus(args[0], args[1]);
}


giovanni.widget.TableView.prototype.setStatus = function(s, isError) {
    this.statusStr = s;
    var statusDiv = document.getElementById(this.containerId + 'Status');
    statusDiv.style.color = (isError === true) ? "red" : "green";
    statusDiv.innerHTML = "" + s + "";
};

