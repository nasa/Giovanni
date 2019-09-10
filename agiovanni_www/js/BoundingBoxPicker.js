/*
 * Create the datepicker object to represent date and time
 */

giovanni.namespace("widget");

var shapeCache = {};
var userInteracted = false;

/**
 * 
 * @constructor
 * @this {Giovanni.widget.BoundingBoxPicker}
 * @param {String, Configuration}
 * @returns {giovanni.widget.BoundingBoxPicker}
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker = function (containerId, url, config) {
    //Get the ID of the container element
    this.container = document.getElementById(containerId);
    if (this.container == null) {
        alert("Error [giovanni.widget.BoundingBoxPicker]: element '" + containerId + "' not found!");
        return;
    }
    this.id = containerId;
    //Store the container's ID
    this.containerId = containerId;

    //Get the data source URL for the component
    this.dataSourceUrl = url;
    if (this.dataSourceUrl == null) {
        alert("Error [giovanni.widget.BoundingBoxPicker]: data source URL is null!");
        return;
    }

    //Define an object for holding configuration 
    if (config === undefined) {
        config = {};
    }

    if (config.maxWidth === undefined) {
        config.maxWidth = null;
    }

    if (config.maxHeight === undefined) {
        config.maxHeight = null;
    }

    if (config.register === undefined) {
        config.register = true;
    }

    this.selectionEvent = new YAHOO.util.CustomEvent("SelectionEvent", this);
    this.setStatusEvent = new YAHOO.util.CustomEvent("StatusEvent", this);

    this.defaultBbox = [];
    this.defaultShape = null;
    this.prevBbox = null;
    this.bbox = this.defaultBbox.slice(0);
    this.usingNEFormat = false;
    this.shape = this.defaultShape;
    this.shapeCache = [];
    this.PRECISION = 4;
    this.MUL = Math.pow(10, this.PRECISION);
    if (config.bounds != undefined && config.bounds instanceof Array) {
        this.bbox = config.bounds;
        for (var i = 0; i < this.bbox.length; i++) {
            if (this.bbox[i] !== "") {
                this.bbox[i] = Math.round(this.bbox[i] * this.MUL) / this.MUL;
            }
        }
    }
    // a default value for the component; 
    // does not currently change as a result of updates from other components;
    // may do so in the future

    this.register = config.register;
    this.maxWidth = config.maxWidth;
    this.maxHeight = config.maxHeight;
    this.statusStr = "";
    this.disabled = false;
    this.userEdited = false;
    this.Map = undefined;
    this.render();
};

/**
 * Creates the GUI for giovanni.widget.BoundingBoxPicker and registers the component
 * 
 * @this {Giovanni.widget.BoundingBoxPicker}
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.render = function () {

    var fieldset = document.createElement('fieldset');
    var legend = document.createElement('legend');
    legend.innerHTML = "Select Region (Bounding Box or Shape)";
    fieldset.appendChild(legend);
    var ctrlContainer = document.createElement('div');
    ctrlContainer.setAttribute('id', this.container.id + "Ctrl");
    ctrlContainer.setAttribute('class', 'pickerContent');

    //var label = document.createElement('label');
    //label.setAttribute('for',ctrlContainer.id);
    //label.innerHTML = 'Select Bounding Box';
    //this.container.appendChild(label);

    // create usage hint
    var hint = document.createElement('div');
    hint.setAttribute('class', 'hint');
    //hint.innerHTML = "Please enter a bounding box (west,south,east,north) or select from the map.";
    hint.innerHTML = "Format: West, South, East, North";
    ctrlContainer.appendChild(hint);
    //this.container.appendChild(label);

    // create bounding box input (includes calendar icon button) control container
    var inputContainer = document.createElement('div');
    inputContainer.setAttribute('id', this.containerId + 'InputContainer');
    inputContainer.setAttribute('class', 'bboxInputContainer');
    ctrlContainer.appendChild(inputContainer);

    // create bounding box input
    var boundingBox = document.createElement('input');
    boundingBox.setAttribute('type', 'text');
    boundingBox.setAttribute('id', this.id + 'bbox');
    boundingBox.setAttribute('class', 'bboxInput');
    boundingBox.setAttribute('value', this.bbox.join(','));
    boundingBox.setAttribute('size', '50');
    inputContainer.appendChild(boundingBox);

    var mapLink = document.createElement('a');
    mapLink.innerHTML = '<i class="fa fa-map-o bboxSelIcon" aria-hidden="true"></i>';
    mapLink.setAttribute('title', 'Draw a bounding box on the map');
    mapLink.setAttribute('id', this.id + 'mapLink');
    inputContainer.appendChild(mapLink);

    var shapeLink = document.createElement('a');
    shapeLink.innerHTML = '<i class="fa fa-bookmark iconMorph" aria-hidden="true"></i>';
    shapeLink.setAttribute('title', 'Select a shape from the shape list and see it on the map');
    shapeLink.setAttribute('id', this.id + 'shapeLink');
    shapeLink.setAttribute('class','bboxSelIcon');
    inputContainer.appendChild(shapeLink);

    var clearbboxLink = document.createElement('a');
    clearbboxLink.innerHTML = '<i class="fa fa-close" aria-hidden="true"></i>';
    clearbboxLink.setAttribute('title', 'Clear');
    clearbboxLink.setAttribute('id', this.id + 'clearbboxLink');
    clearbboxLink.setAttribute('class','bboxSelIcon');
    inputContainer.appendChild(clearbboxLink);


    // add container and input element listeners
    YAHOO.util.Event.addListener(this.id + "bbox", "change", this.handleBboxInputChange, this);
    YAHOO.util.Event.addListener(mapLink, "click", this.showMap, {selfRef: this, showShapeList: false});
    YAHOO.util.Event.addListener(shapeLink, "click", this.showMap, {selfRef: this, showShapeList: true});
    YAHOO.util.Event.addListener(clearbboxLink, "click", this.clearSelections, {selfRef: this});
    //YAHOO.util.Event.addListener(boundingBox,"click",this.showMap,this);
    YAHOO.util.Event.addListener(boundingBox, "blur", this.hide, this);

    giovanni.util.panelOpenEvent.subscribe(
        giovanni.util.handlePanelOpenEvent, {
            callingObject: this,
            callback: this.hide
        },
        this
    );

    fieldset.appendChild(ctrlContainer);
    this.container.appendChild(fieldset);

    var statusDiv = document.createElement('div');
    statusDiv.setAttribute('class', 'pickerStatus');
    statusDiv.setAttribute('id', this.id + 'statusDiv');
    statusDiv.innerHTML = "" + this.statusStr + "&nbsp;";
    this.container.appendChild(statusDiv);

    // REGISTRY is a global variable declared in REGISTRY.js
    if (this.register === true) {
        if (REGISTRY) {
            REGISTRY.register(this.id, this);
        } else {
            alert("no REGISTRY so could not register BoundingBoxPicker");
        }
    }

    this.onShapefilesLoadEvent = new YAHOO.util.CustomEvent("onShapefilesLoadEvent", this);
    var self = this;
    $.ajax({
        type: "GET",
        url: "./daac-bin/getProvisionedShapefiles.py",
        success: function (shapefileData) {
            self.shapefileData = shapefileData;

            self.shapeUIModel = [];
            delete shapefileData.info['*'];
            Object.keys(shapefileData.info).forEach(function (fkey, i) {
                var file = shapefileData.info[fkey];
                var shapeNameIndex = file.bestAttr[1];
                self.shapeUIModel.push({
                    id: fkey,
                    searchIndex: file.title.toLowerCase(),
                    file: file,
                    children: Object.keys(file.shapes).map(function (skey, j) {
                        var shape = file.shapes[skey];
                        return {
                            id: fkey + '/' + skey,
                            text: shape.values[shapeNameIndex],
                            searchIndex: shape.values[shapeNameIndex].toLowerCase(),
                            sortIndex: parseInt(skey.split('_')[1], 10),
                            shape: shape,
                            file: file
                        };
                    }).sort(function (a, b) {
                        return a.searchIndex.localeCompare(b.searchIndex);
                    })
                });
            });

            self.onShapefilesLoadEvent.fire();

            if (self.register) {
                if (REGISTRY) {
                    REGISTRY.markComponentReady(self.id);
                } else {
                    console.log("no REGISTRY so could not mark BoundingBoxPicker ready");
                }
            }
        },
    });
};

/**
 * Fires an event in the registry when the component value is changed
 * 
 * @this {Giovanni.widget.BoundingBoxPicker}
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.fire = function () {
    this.selectionEvent.fire();
    if (this.register === true) {
        if (REGISTRY) {
            REGISTRY.fire(this);
        } else {
            alert("no REGISTRY so no event REGISTRY event to fire");
        }
    }
};

/**
 * Initializes then displays a giovanni.widget.MapDisplay
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} evt is a YAHOO.util.Event object, self is a reference to the calling giovanni.widget.BoundingBoxPicker object
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.showMap = function (evt, config) {
    var self = config.selfRef;
    var showShapeList = config.showShapeList;
    // keep the event from propagating
    YAHOO.util.Event.stopPropagation(evt);
    // if the panel is undefined, create it
    if (self.mapPanel === undefined) {
        // set the anchor points
        var panelCorner = "tr";
        var controlCorner = "br";
        var $mpBody = $("<div id='bboxBboxMapp' class='bboxMap'></div>");
        if (window.location.href.indexOf("aerostat") > -1) {
            panelCorner = "tl";
            controlCorner = "bl";
        }
        // create the panel, visibility set to false so we can use this method to toggle the map display
        self.mapPanel = new YAHOO.widget.Panel("mapPanel", {
            width: "600px",
            height: "360px",
            context: [self.containerId + "InputContainer", panelCorner, controlCorner],
            zindex: 9,
            close: true,
            visible: false,
            draggable: true,
            constraintoviewport: true
        });
        // set the panel's HTML body
        self.mapPanel.setBody($mpBody[0]);
        self.mapPanel.render(document.body);
        // if the map is undefined, create it
        if (self.Map === undefined) {
            self.Map = new giovanni.widget.MapDisplay("bboxBboxMapp", {
                "maxExtent": new OpenLayers.Bounds(-360, -90, 360, 90)
            });
            // set up bound box selection on the map
            self.Map.onSelectionEventOG.subscribe(self.handleMapSelection, self);
            self.setStatusEvent.subscribe(self.Map.handleStatusChange, self.Map);
            // if the current region is valid, set it's value on the map
            if (self.validate().isValid()) {
                if (!(self.bbox[0] == -180 && self.bbox[1] == -90 && self.bbox[2] == 180 && self.bbox[3] == 90)) {
                    //make sure bbox coords are in decimal degrees
                    self.bbox = giovanni.util.fromNEArray(self.bbox);
                    self.Map.setValueOG(self.bbox[0], self.bbox[1], self.bbox[2], self.bbox[3]);
                }
                if (self.shape) {
                    var tokens = self.shape.split('/');
                    self.Map.setShape(tokens[0], tokens[1]);
                }
            }
        }
        // handle panel hide events (can require map cleanup)
        self.mapPanel.hideEvent.subscribe(self.hide, self);
        // handle panel show events (shows map)
        self.mapPanel.showEvent.subscribe(self.hide, self);
        // subscribe to panel move events (refreshes map anchor coordinates)
        self.mapPanel.moveEvent.subscribe(giovanni.widget.BoundingBoxPicker.refreshMap, self);
        $.fn.select2.amd.require(['select2/data/array', 'select2/utils'], function (ArrayData, Utils) {
            function CustomData(elem, opts) {
                CustomData.__super__.constructor.call(this, elem, opts);
            }
            Utils.Extend(CustomData, ArrayData);
            CustomData.prototype.query = function (q, callback) {
                var filtered = self.shapeUIModel;
                var lcTerm;
                if (q.term && q.term !== '') {
                    lcTerm = q.term.toLowerCase();
                    filtered = [];
                    self.shapeUIModel.forEach(function (item) {
                        var children = [];
                        if (item.file) {
                            if (item.searchIndex.indexOf(lcTerm) >= 0) {
                                children = item.children;
                            } else {
                                children = item.children.filter(function (child) {
                                    return child.searchIndex.indexOf(lcTerm) >= 0;
                                });
                            }
                            if (children.length > 0) {
                                item = $.extend({}, item);
                                item.children = children;
                                filtered.push(item);
                            }
                        }
                    });
                }
                callback({
                    results: filtered.sort(function (a, b) {
                        return a.searchIndex.localeCompare(b.searchIndex);
                    }),
                    more: false
                });
                self.addCollapsibleGroups(q.term);
            };

            CustomData.prototype.current = function (callback) {
                var data;
                var shapeId = self.shape;

                if (shapeId) {
                    var fileId = shapeId.split('/')[0];
                    for (var i = 0, ilen = self.shapeUIModel.length; i < ilen; i++) {
                        if (self.shapeUIModel[i].id === fileId) {
                            for (var j = 0, jlen = self.shapeUIModel[i].children.length; j < jlen; j++) {
                                if (self.shapeUIModel[i].children[j].id === shapeId) {
                                    data = [self.shapeUIModel[i].children[j]];
                                    break;
                                }
                            }
                            if (data) {
                                break;
                            }
                        }
                    }
                }

                callback(data || []);
            };

            var $shapeSelect = self.$shapeSelect = $('<select style="width:41.6em;"></select>')
                .change(function () {
                    self.setShape(this.value);
                });
            $mpBody.prepend($shapeSelect);
            $shapeSelect.select2({
                allowClear: true,
                placeholder: 'Select a Shape...',
                dataAdapter: CustomData,
                templateResult: function (item) {
                    if (item.file && !item.shape) {
                        return $('<span class="collapse_status_icon">&#9656;</span><span>' + item.file.title + ' <span style="font-weight: normal">(source: <a href="' +
                            item.file.sourceURL + '">' + item.file.sourceName + '</a>)</span></span>');
                    }
                    return item.text; 
                }
            }).data('select2').$container.find('.select2-selection__clear').attr('title', 'clear selection');
            if(showShapeList){
                $shapeSelect.select2('open');    
            }
        });
    }

    // determine the visibility status of the map; display or hide as appropriate
    if (self.mapPanel.cfg.getProperty("visible")) {
        self.mapPanel.hide();
    } else {
        self.mapPanel.show();
        if( showShapeList && self.$shapeSelect ){
          self.$shapeSelect.select2('open');
        }
        giovanni.util.panelOpenEvent.fire(self);
    }

    

};

/**
 * Adds 'toggling' functionality to group of options in shape dropdown
 * 
 * @param { q.term }
 * @author A. Zasorin 
 **/

giovanni.widget.BoundingBoxPicker.prototype.addCollapsibleGroups = function (query) {
    if (query && query !== '') { 
        $("li[role='group'] > ul").show(); 
    } else { $("li[role='group'] > ul").hide(); } 

    $("li[role='group']").click(function(e){
        var clickedGroup = e.currentTarget; 
        $(clickedGroup).find('ul').toggle();
        var icon = $(clickedGroup).find('.collapse_status_icon');
        var iconCode = icon.html().codePointAt(0).toString(16);
        iconCode === '25b8' ? icon.html('&#9662;') : icon.html('&#9656;');
    });
}

/**
 *
 * @param {YAHOO.util.Event, Object}
 * @author K. Bryant 
 **/
giovanni.widget.BoundingBoxPicker.prototype.hide = function () {
    if (this.mapPanel != null && this.mapPanel.cfg.getProperty("visible") == true) {
        this.$shapeSelect.select2('close');
        this.mapPanel.hide();
    }
};

/**
 * Shows the MapDisplay marker layer when the panel is opened
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object, Object} evt is a YAHOO.util.Event object, args is any args passed by the custom event, self is a reference to the calling giovanni.widget.BoundingBoxPicker object
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.showSelectionBox = function (evt, args, self) {
    //YAHOO.util.Event.stopPropagation(evt);
    if (self.Map != undefined) {
        self.Map.show();
    }
};

/**
 * Causes the OpenLayers map to refresh after the panel has been moved
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object, Object} evt is a YAHOO.util.Event object, args is any arguments passed by the custom event, self is a reference to the calling giovanni.widget.BoundingBoxPicker object
 * @author K. Bryant 
 */
giovanni.widget.BoundingBoxPicker.refreshMap = function (evt, args, self) {
    YAHOO.util.Event.stopPropagation(evt);
    window.scrollBy(1, 1);
    self.Map.map.updateSize();
};

/**
 * Updates the value of the component when a selection is made on the map
 *      
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object, Object} o is a YAHOO.util.Event object, args contains the coordinates (w,s,e,n) passed by the MapDisplay custom event, self is a reference to the calling giovanni.widget.BoundingBoxPicker object
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.handleMapSelection = function (evt, args, self) {
    YAHOO.util.Event.stopPropagation(evt);
    if (args[0].toString().search(/NaN/) == -1) {
        self.setBbox(args[0]);
        self.userEdited = true;
    } else {
        self.setBbox([]);
    }
    userInteracted = true;
};


/**
 * Updates the value of the component when the user changes the text box value
 *
 * @this {YAHOO.util.Event}
 * @param {YAHOO.util.Event, Object} evt is a YAHOO.util.Event object, o contains a reference called {self} to the calling giovanni.widget.BoundingBoxPicker object      
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.handleBboxInputChange = function (evt, self) {
    YAHOO.util.Event.stopPropagation(evt);
    // clear the shape to start
    self.shape = null;
    // grab and massage the user value
    var userValue = document.getElementById(self.id + "bbox").value;
    userValue = userValue.replace(/:[\(\)\[\]\s+]/g, "");
    var points = userValue ? userValue.split(",") : [];
    // set the shape - order is important since a null shape
    // impacts the bbox logic
    var valid = false;
    var shapeStr = points[0] ? points[0] : "";
    if (shapeStr !== "") {
        shapeStr = shapeStr.toString().split(";")[0];;
        valid = self.setShape(self.shapeCache[shapeStr]);
    } else {
        if(self.$shapeSelect){
            self.$shapeSelect.val(shapeStr).change();
        }
    }
    // set the box
    valid = self.setBbox(points.length > 1 ? points : []);
    if (valid && self.Map) {
        // make sure points are converted to decimal degrees (+/-, no northing/easting)
        points = giovanni.util.fromNEArray(points);
        // set bbox value on map
        self.Map.setValueOG(points[0], points[1], points[2], points[3]);
    }

    if (valid) {
        self.userEdited = true;
    }

    userInteracted = true;
};

/**
 * Validates the bounding box coordinates to see if they are valid and validates them against any constraints
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @returns {giovanni.widget.ValidationResponse} true or false depending on if the date meets predetermined conditions with an explanation 
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.validate = function () {
    // WEST, SOUTH, EAST, NORTH
    this.setStatus("", false);

    var westIndex = 0;
    var southIndex = 1;
    var eastIndex = 2;
    var northIndex = 3;


    var facetedSelector = session.getDataSelector().variablePicker.fs;
    var selectedVariables = session.getDataSelector().variablePicker.fs.selectedVariables;
    var points = giovanni.util.fromNEArray(this.bbox);
    var is_a_point = false;
    if (points && points != [] && points.length > 0) {
        for (var i = 0; i < points.length; ++i) {
            points[i] = points[i] * 1;
        }
        if (points.length === 2) {
            // if the points leng is '2', assume the user is entering a point
            // and replicate the coordinates into the empty bbox coordinates
            points.push(points[0]);
            points.push(points[1]);
            this.setBbox(points);
        } else if (points.length === 4) {
            // if the coordinates equal each other, it's a point, and that's ok;
            // return as valid immediately.
            if (points[westIndex] == points[eastIndex] && points[southIndex] == points[northIndex]) {
                is_a_point = true;

                // is service compatible with points?
                var srv = session.dataSelector.servicePicker.getUserSelectedService();
                if (srv == "AcMp" ||
                    srv == "DiTmAvMp" ||
                    srv == "MpAn" ||
                    srv == "TmAvSc") {
                    this.setStatus("Plotting of single point not supported by " + session.dataSelector.servicePicker.getValueLabel(), true);
                    return new giovanni.widget.ValidationResponse(false, "Plotting of single point not supported by " + session.dataSelector.servicePicker.getValueLabel());
                }

            }
            if (!(points[westIndex] <= 180 && points[westIndex] >= -180 && points[eastIndex] <= 180 && points[eastIndex] >= -180)) {
                this.setStatus("West and east coordinates must be between -180 and 180", true);
                return new giovanni.widget.ValidationResponse(false, this.statusStr);
            }
            if (!(points[southIndex] <= 90 && points[southIndex] >= -90 && points[northIndex] <= 90 && points[northIndex] >= -90)) {
                this.setStatus("South and north coordinates must be between -90 and 90", true);
                return new giovanni.widget.ValidationResponse(false, this.statusStr);
            }

            if (!is_a_point) {
                if (points[westIndex] == points[eastIndex]) {
                    this.setStatus("The west coordinate may not be the same as the east coordinate", true);
                    return new giovanni.widget.ValidationResponse(false, this.statusStr);
                }
                if (points[northIndex] <= points[southIndex]) {
                    this.setStatus("The north coordinate must be greater than the south coordinate", true);
                    return new giovanni.widget.ValidationResponse(false, this.statusStr);
                }
            }
            if (this.maxHeight !== null) {
                if (!((points[northIndex] - points[southIndex]) <= this.maxHeight)) {
                    this.setStatus("The height of the bounding box must be less than " + this.maxHeight + " degrees", true);
                    return new giovanni.widget.ValidationResponse(false, this.statusStr);
                }
            }
            if (this.maxWidth !== null) {
                if (!((points[eastIndex] - points[westIndex]) <= this.maxWidth)) {
                    this.setStatus("The width of the bounding box must be less than " + this.maxWidth + " degrees", true);
                    return new giovanni.widget.ValidationResponse(false, this.statusStr);
                }
            }

            // check for intersection of user's bounding box with selected variables' spatial bounds
            // if there are more than one intersections, check for gaps in them 
            for (var j = 0; j < selectedVariables.length; j++) {
                var data = selectedVariables[j].data;
                var split_boxes = [];
                var splitResult = this.splitOverDateLine(points);
                for (var k = 0; k < splitResult.length; k++) {
                    split_boxes.push(splitResult[k]);
                }
                var dataPoints = [data.dataProductWest, data.dataProductSouth, data.dataProductEast, data.dataProductNorth];
                splitResult = this.splitOverDateLine(dataPoints);
                for (var k = 0; k < splitResult.length; k++) {
                    split_boxes.push(splitResult[k]);
                }
                var intersections = [];
                for (var i = 0; i < split_boxes.length - 1; i++) {
                    for (var k = i + 1; k < split_boxes.length; k++) {
                        var temp = this.calcIntersect(split_boxes[i], split_boxes[k]);
                        if (temp) {
                            intersections.push(temp);
                        }
                    }
                }
                if (intersections.length == 2) { // check for adjacent boxes along dateline and merge into one
                    if (intersections[0][westIndex] == -180 && intersections[1][eastIndex] == 180) {
                        intersections[0] = [intersections[1][westIndex], intersections[1][southIndex], intersections[0][eastIndex], intersections[1][northIndex]];
                        intersections.splice(1, 1);
                    } else if (intersections[1][westIndex] == -180 && intersections[0][eastIndex] == 180) {
                        intersections[0] = [intersections[0][westIndex], intersections[1][southIndex], intersections[1][eastIndex], intersections[1][northIndex]];
                        intersections.splice(1, 1);
                    }
                }
                if (intersections.length > 1) { // if still left with more than one box, the boxes are disjoint
                    this.setStatus("Please select a region that forms a contiguous intersection with the data region [" +
                        data.dataProductWest + ", " + data.dataProductSouth + ", " +
                        data.dataProductEast + ", " + data.dataProductNorth + "] for '" + data.dataFieldLongName + "'", true);
                    return new giovanni.widget.ValidationResponse(false, this.statusStr);
                }
                if (intersections.length == 0) { // if there are no intersecting regions, the user box is outside data coverage
                    this.setStatus("'" + data.dataFieldLongName + "' has no data for the selected bounding box. " +
                        "Please select a bounding box overlapping the region [" +
                        data.dataProductWest + ", " + data.dataProductSouth + ", " +
                        data.dataProductEast + ", " + data.dataProductNorth + "].", true);
                    return new giovanni.widget.ValidationResponse(false, this.statusStr);
                }
            }
        } else {
            this.setStatus("Invalid bounding box format. Please specify West, South, East, North coordinates.", true);
            return new giovanni.widget.ValidationResponse(false, this.statusStr);
        }
    }

    /* if we've haven't failed yet, check the interaction between
     * bounding box, shape, and variable selection  */
    facetedSelector.validateVariableConstraints();
    /* validate shape */
    if (this.shape) {
        var toks = this.shape.split('/');
        var shapefileExists1 = (this.shapefileData.available.indexOf(toks[0]) >= 0);
        var shapefileExists2 = this.shapefileData.info.hasOwnProperty(toks[0]);
        var shapeExists = this.shapefileData.info[toks[0]].shapes.hasOwnProperty(toks[1]);

        return new giovanni.widget.ValidationResponse(shapefileExists1 && shapefileExists2 && shapeExists, "");
    }

    // Everything looks good.
    return new giovanni.widget.ValidationResponse(true, this.statusStr);
};

giovanni.widget.BoundingBoxPicker.prototype.splitOverDateLine = function (points) {
    if (points[2] < points[0]) {
        return [[points[0], points[1], 180, points[3]], [-180, points[1], points[2], points[3]]];
    } else {
        return [points];
    }
};

/**
 * Calculate the intersection between two bounding boxes. The input bounding 
 * boxes may not cross the 180 meridian.
 *
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {Array, Array} two 4-element arrays representing bounding boxes in
 * W,S,E,N format 
 * @returns {Array} a 4-element array representing the bounding box of the 
 * intersection or null if there is no intersection.  
 */
giovanni.widget.BoundingBoxPicker.prototype.calcIntersect = function (box1, box2) {
    var westIndex = 0;
    var southIndex = 1;
    var eastIndex = 2;
    var northIndex = 3;

    // Check to see if box1 is a point, which will need to be treated a little 
    // differently to handle the 180 meridian correctly
    if ((box1[westIndex] == box1[eastIndex]) && (box1[southIndex] == box1[northIndex])) {
        var longitude = box1[westIndex];
        var latitude = box1[southIndex];

        if (latitude >= box2[southIndex] && latitude <= box2[northIndex] &&
            longitude >= box2[westIndex] && longitude <= box2[eastIndex]) {
            // the point is in box2
            return [longitude, latitude, longitude, latitude];
        } else {
            // no intersection
            return null;
        }

    }
    // Check to see if box2 is a point
    if ((box2[westIndex] == box2[eastIndex]) && (box2[southIndex] == box2[northIndex])) {
        // It is! So, call calcIntersect with box2 first.
        this.calcIntersect(box2, box1);
    }

    // Neither box is a point
    if (box1[eastIndex] <= box2[westIndex] || box1[westIndex] >= box2[eastIndex] ||
        box1[northIndex] <= box2[southIndex] || box1[southIndex] >= box2[northIndex]) {
        // no intersection
        return null;
    } else {
        var west = box1[westIndex] > box2[westIndex] ? box1[westIndex] : box2[westIndex];
        var south = box1[southIndex] > box2[southIndex] ? box1[southIndex] : box2[southIndex];
        var east = box1[eastIndex] < box2[eastIndex] ? box1[eastIndex] : box2[eastIndex];
        var north = box1[northIndex] < box2[northIndex] ? box1[northIndex] : box2[northIndex];
        return [west, south, east, north];
    }
};


/**
 * Returns the value of the component (bbox=west,south,east,north
 * or shape=shapefile/shape).
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @returns {String} either formatted in bbox=west,south,east,north
 *   or shape_file/shape
 * @author T. Joshi, D. da Silva
 */

giovanni.widget.BoundingBoxPicker.prototype.getValue = function () {
    // Return shape= and bbox=, where the bbox is the bounding box
    // of the shape.
    var toks;
    var bbox = '';
    var query = '';

    if (this.usingNEFormat && !this.bbox.join().match(/W|S|E|N/gi)) {
        var tmp = giovanni.util.toNEArray( this.bbox );
        this.bbox = tmp.concat([]);
    }

    if (this.shape) {
        toks = this.shape.split('/');
        bbox = (this.bbox && this.bbox.length === 4) ? this.bbox : "";
        query += 'shape=' + this.shape + '&';
    } else {
        bbox = this.bbox && this.bbox.length === 4 ? this.bbox : "";
    }

    return query + (bbox ? 'bbox=' + bbox : "");
};

/**
 * Sets the selected value of the component
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {String} string containing west,south,east,north coordinates
 * @returns {Boolean} whether the value validates or not
 * @author T. Joshi 
 */


giovanni.widget.BoundingBoxPicker.prototype.setValue = function (value) {
    this.setShape(value.shape);
    this.setBbox(value.bbox);
};

giovanni.widget.BoundingBoxPicker.prototype.getShapeString = function (id) {
    var toks = id.split('/');
    var shapefile = this.shapefileData.info[toks[0]];
    var shape = shapefile.shapes[toks[1]];
    var nameIdx = shapefile.bestAttr[1];
    return shapefile.title + " : " + shape.values[nameIdx];
};

giovanni.widget.BoundingBoxPicker.prototype.setBbox = function (value) {
    //this.bbox = (value || []).slice(0);
    this.bbox = (value || []);
    this.usingNEFormat = this.bbox.join().search(/W|S|E|N/gi) < 0 ? false : true;
    // bbox for display on the bbox text entry field
    var bboxDisplay = [];
    // when a shape string is in the first element
    if (this.bbox[0] && this.bbox[0].toString().indexOf(";") > -1) {
        this.bbox[0] = this.bbox[0].toString().split(";")[1];
    }
    /* Bounding Box */
    //var tempVal = this.value.slice(0); // use this if the display value alone needs to be truncated and formatted
    var tempVal = this.bbox.concat([]); // use this if the actual lat/lon value needs to be truncated too
    
    var str = '';
    var latitude = false;
    for (var i = 0; i < tempVal.length; i++) {
        if (tempVal[i] !== "") {
            tempVal[i] = giovanni.util.fromNE(tempVal[i]);
            tempVal[i] = Math.round(tempVal[i] * this.MUL) / this.MUL;
            latitude = i===1||i===3 ? true : false;
            bboxDisplay[i] = this.usingNEFormat ? giovanni.util.toNE(tempVal[i],latitude) : tempVal[i];
        }
    }

    if (this.shape) {
        str = this.getShapeString(this.shape) + ';';
    } else if (value && value[0] && value[0].toString().indexOf(":") > -1) {
        str = value[0];
    }

    str += bboxDisplay.join(',');

    document.getElementById(this.id + "bbox").value = str;

    this.bbox = tempVal;

    var valid = this.validate();

    if (valid.isValid()) {
        this.fire();
    }

    return valid.isValid();
};

giovanni.widget.BoundingBoxPicker.prototype.setShape = function (value) {
    var str = '';
    this.shape = value ? value.split(";")[0] : "";
    var toks = [];
    var shapefile;
    if (this.shape) {
        toks = this.shape.split('/');
        shapefile = this.shapefileData.info[toks[0]];
        var shape = shapefile.shapes[toks[1]];
        var nameIdx = shapefile.bestAttr[1];
        str = this.getShapeString(this.shape);
        // need to massage string for storage in shapeCache assoc array
        str = str.replace(/:[\(\)\[\]\s+]/g, "");
        this.shapeCache[str] = this.shape;
        // adding semi-colon to conform to displayed entry string format
        str += ";";
    }
    if (this.bbox) {
        str += this.bbox.join(',');
    }

    document.getElementById(this.id + "bbox").value = str;

    var valid = this.validate();

    if (valid.isValid()) {
        this.fire();
    }
    if (this.Map) {
        this.Map.setShape(toks[0], toks[1]);
    }
    return valid.isValid();
};


/*
 * Gets the region the user has selected. Returns an associative array. The 
 * 'bbox' key will be empty ('') if the user has not selected a bounding box. 
 * The 'shape' key will be empty ('') if the user has not selected a shape.
 *
 * @params {}
 * @returns {Associative Array, entries for 'bbox' and 'shape'} 
 * @author C. Smit
 */
giovanni.widget.BoundingBoxPicker.prototype.getRegionSelection = function () {
    var region = {};
    if (this.bbox != null && this.bbox.length == 4) {
        region.bbox = giovanni.util.fromNEArray(this.bbox);
    } else {
        region.bbox = '';
    }
    if (this.shape != null) {
        region.shape = this.shape;
    } else {
        region.shape = '';
    }

    return region;
}

/**
 * Gets the bounding box associated with a particular shape in an array.
 * 
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {String} shape in the form "<shapefile>/<shape id>". E.g. - 
 *   "state_dept_countries/shp_6"
 * @returns {Array} bounding box as an array of numbers, 
 *   [West,South,East,North] or an empty array
 * @author Christine Smit
 */
giovanni.widget.BoundingBoxPicker.prototype.getShapeBoundingBox = function (shape) {
    var splits = shape.split("/");
    var shapefile = splits[0];
    // id within shapefile
    var id = splits[1];

    if (!(shapefile in this.shapefileData.info)) {
        // Make sure we can find this shapefile
        console.log("ERROR: Unable to find shapefile " + shapefile);
        return [];
    }
    if (!(id in this.shapefileData.info[shapefile].shapes)) {
        // Make sure we can find this id
        console.log("ERROR: Unable to find id " + id + " in shapefile " + shapefile);
        return []
    }
    return this.shapefileData.info[shapefile].shapes[id].bbox;
}

/**
 * Gets the effective bounding box the user selected. The effective bounding 
 * box is the intersection of the user's bounding box (if selected) and the
 * shape's bounding box (if a shape was selected).
 * 
 * @this {giovanni.widget.BoundingBoxPicker}
 * @returns {Array} a four element array with West, South, East, North bounding
 *   box coordinates. Returns an empty array if the intersection of the
 *   bounding box and shape is null. Returns null if neither a bounding box nor 
 *   a shape has been selected.
 * @author Christine Smit
 */
giovanni.widget.BoundingBoxPicker.prototype.getEffectiveBoundingBox = function () {
    var allBboxes = [];
    // Figure out a bounding box.
    var region = this.getRegionSelection();
    if (region.bbox !== "") {
        allBboxes.push(region.bbox);
    }
    if (region.shape !== "") {
        // get out the bounding box associated with this shape
        var shapeBbox = this.getShapeBoundingBox(region.shape);
        allBboxes.push(shapeBbox);
    }

    if (allBboxes.length == 1) {
        return allBboxes[0];
    } else if (allBboxes.length > 1) {
        // There was bounding box and a shape
        var intersection = this.findIntersection(allBboxes);
        if (intersection == null) {
            // The bounding box and shape don't intersect
            return [];
        }
        return intersection;
    } else {
        // There were no region selections
        return null;
    }
}

/**
 * sets value given a query string
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {String} qs is in the format of bbox=west,south,east,north
 * @returns {giovanni.widget.ValidationResponse} whether dates validate or not with an explanation
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.loadFromQuery = function (qs) {
    var hasBBox = Boolean(giovanni.util.extractQueryValue(qs, "bbox"));
    var hasShape = Boolean(giovanni.util.extractQueryValue(qs, "shape"));

    if (hasShape) {
        var qVal = giovanni.util.extractQueryValue(qs, "shape");
        this.setShape(qVal);
    } else {
        this.setShape(this.defaultShape);
    }
    if (hasBBox) {
        var qVal = giovanni.util.extractQueryValue(qs, "bbox");
        var points = qVal ? qVal.split(",") : [];
        var valid = this.setBbox(points);
        userInteracted = true;

        if (valid) {
            // if a valid value is loaded from URL, its as good as the user entered value
            // do not make bbox changes based on selected variables anymore
            this.userEdited = true;
            if (this.Map) {
                // make sure coordinates are in decimal format
                points = giovanni.util.fromNEArray(points);
                this.Map.setValueOG(points[0], points[1], points[2], points[3]);
            }
        }
    } else {
        this.setBbox(this.defaultBbox);
    }
};

/**
 * Updates the component bounds based on dependencies in the registry
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {String} specifies additional parameters for the data source url to be fetched
 * @author T. Joshi 
 * @modified K. Bryant 08/21/2012
 */
giovanni.widget.BoundingBoxPicker.prototype.updateComponent = function (qs) {
    if (this.dataSourceUrl === null) {
        alert("There is no external data source url specified.  Cannot update component!");
        return false;
    }
    var dataSourceUrl = this.dataSourceUrl + "?" + qs;
    this.setStatus("Updating data map based on data changes ... ", true);
    if (typeof this.dataSourceUrl == "function") {
        this.dataSourceUrl(this, qs);
    } else if (typeof this.dataSourceUrl == "string") {
        YAHOO.util.Connect.asyncRequest('GET', dataSourceUrl, {
            success: giovanni.widget.BoundingBoxPicker.fetchDataSuccessHandler,
            failure: giovanni.widget.BoundingBoxPicker.fetchDataFailureHandler,
            argument: {
                self: this,
                format: "xml"
            }
        });
    }

};

/**
 * This function finds the intersection of an arbitrary number of bounding 
 * boxes. NOTE (from Christine Smit): This function cannot handle intersections
 * of bounding boxes that produce disjoint boxes.
 * 
 * @this {Giovanni.widget.BoundingBoxPicker}
 * @param {Array} boxes array of bounding boxes. Each bounding box is a four
 *   element array in [West,South,East,North] format.
 * @return {Array} a four element bounding box
 * @author ?
 */
giovanni.widget.BoundingBoxPicker.prototype.findIntersection = function (boxes) {

    var split_boxes = [];

    // if any of the boxes go across the dateline, split them and put them in a separate list
    for (var i = 0; i < boxes.length; i++) {
        if (boxes[i] == null) return null; // if any of the boxes is null, the intersection is null
        var west = boxes[i][0],
            south = boxes[i][1],
            east = boxes[i][2],
            north = boxes[i][3];
        if (west > east) { // crossing dateline
            boxes.splice(i, 1);
            split_boxes.push([[west, south, 180, north], [-180, south, east, north]]);
        }
    }

    var G = null; // the final resultant intersection of boxes

    if (boxes.length > 0) {
        // for boxes that don't cross dateline
        // intersection can be calculated as [largest west, largest south, smallest east, smallest north]
        // IF the above co-ordinates form a valid bounding box
        var westArray = [],
            southArray = [],
            eastArray = [],
            northArray = [];
        for (var i = 0; i < boxes.length; i++) {
            westArray.push(boxes[i][0]);
            southArray.push(boxes[i][1]);
            eastArray.push(boxes[i][2]);
            northArray.push(boxes[i][3]);
        }
        var west = Math.max.apply(null, westArray);
        var south = Math.max.apply(null, southArray);
        var east = Math.min.apply(null, eastArray);
        var north = Math.min.apply(null, northArray);

        if (west < east && south < north) {
            G = [west, south, east, north];
        } else {
            // if intersection of non-dateline crossing boxes is null
            // don't have to process the dateline crossing boxes at all
            // the intersection is going to be null anyways
            return null;
        }
    }

    if (split_boxes.length > 0) {
        // for boxes crossing intersection - split them into parts A and B across date line
        // find intersection of these parts with the already computed intersection G
        // G n (A u B) = (G n A) u (G n B)
        for (var i = 0; i < split_boxes.length; i++) {
            var partA = split_boxes[i][0];
            var partB = split_boxes[i][1];
            // when all boxes are crossing dateline, G will be null initially
            // then the first split box will be joined back to form G
            var intA = G ? this.findIntersection([G, partA]) : partA;
            var intB = G ? this.findIntersection([G, partB]) : partB;
            G = this.stitchBboxes(intA, intB);
        }
    }

    // return the computed intersection
    return G;
};

/**
 * This function stitches together two bounding boxes that (1) have the same north
 * and south extent and (2) touch at the 180 meridian.
 * @this {Giovanni.widget.BoundingBoxPicker}
 * @param {Array,Array} bbox1 and bbox2 are bounding boxes in 
 *   [West, South, East, North] format
 * @returns {Array} the stitched bounding box in [West, South, East, North] format
 * @author Christine Smit
 */
giovanni.widget.BoundingBoxPicker.prototype.stitchBboxes = function (bbox1, bbox2) {
    if (bbox1 == null && bbox2 == null) {
        console.log("Error: Trying to stitch two null boxes together.");
        return null;
    } else if (bbox1 == null) {
        return bbox2;
    } else if (bbox2 == null) {
        return bbox1;
    }

    var westIndex = 0;
    var southIndex = 1;
    var eastIndex = 2;
    var northIndex = 3;

    var north = bbox1[northIndex];
    var south = bbox1[southIndex];

    // print an error to the console if the north and south boundaries don't match. 
    if (bbox1[northIndex] !== bbox2[northIndex] || bbox1[southIndex] !== bbox2[southIndex]) {
        console.log("Error: bounding boxes passed to stitchBboxes should have the same north and south extent");
    }

    var west = -180;
    var east = 180;

    // figure out which bounding box is east of the 180 meridian and which is west.
    if (bbox1[eastIndex] === 180 && bbox2[westIndex] === -180) {
        west = bbox1[westIndex];
        east = bbox2[eastIndex];
    } else if (bbox1[eastIndex] === -180 && bbox[westIndex] === 180) {
        west = bbox2[westIndex];
        east = bbox1[eastIndex];
    } else {
        console.log("Error: bounding boxes passed to stitchBboxes should touch at the 180 meridian");
    }

    return [west, south, east, north];
}

/**
 * sets the max width and max height of the bounding box
 *      
 * @this {Giovanni.widget.BoundingBoxPicker}
 * @param {Number,Number} width is the horizontal size constraint, height is the vertical size constraint
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.setSize = function (width, height) {
    if (width !== null) {
        this.maxWidth = width;
    }
    if (height != null) {
        this.maxHeight = height;
    }

    return this.validate();
};

/**
 * handles the success of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.Connect}
 * @param {YAHOO Response Object} contains responseText and responseXML from remote request, and specified arguments
 * @returns {giovanni.widget.ValidationResponse} true or false with explanation 
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.fetchDataSuccessHandler = function (o) {
    var self = o.argument["self"];
    self.setStatus("");
    try {
        var width = null;
        var height = null;
        if (o.argument.format === "json") {
            var jsonData = YAHOO.lang.JSON.parse(o.responseText);
            width = (jsonData.width !== undefined) ? jsonData.width : null;
            height = (jsonData.height !== undefined) ? jsonData.height : null;
        } else {
            var xmlData = o.responseXML;
            var sizeConstraint = xmlData.getElementsByTagName('sizeConstraint');
            sizeConstraint = (sizeConstraint !== undefined) ? xmlData.getElementsByTagName('sizeConstraint')[0] : null;
            if (sizeConstraint) {
                width = (sizeConstraint.attributes.getNamedItem("WIDTH")) ? sizeConstraint.attributes.getNamedItem("WIDTH").value : null;
                height = (sizeConstraint.attributes.getNamedItem("HEIGHT")) ? sizeConstraint.attributes.getNamedItem("HEIGHT").value : null;
            }
        }
        self.setSize(width, height);
    } catch (x) {
        self.setStatus("Could not parse data accessor response!", true);
    }
};

/**
 * Handles the failure of fetching the specified data url with the components from updateComponent
 *      
 * @this {YAHOO.util.connect}
 * @param {YAHOO Response Object} contains reason for the failure
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.fetchDataFailureHandler = function (o) {
    o.argument["self"].setStatus("Could not retrieve data from specified data URL!", true);
};

/**
 * Set the data source url for retrieving updates to the bounds from updateComponent
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {String} url to set the dataSourceUrl property to
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.setDataSourceUrl = function (url) {
    this.dataSourceUrl = url;
};

/**
 * Returns the data source url for retrieving updates to the bounds from updateComponent
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @returns {String} the data source url
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.getDataSourceUrl = function () {
    return this.dataSourceUrl;
};

/**
 * Set the current status of the component
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @param {String, Boolean} the status string and whether it is an error or not 
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.setStatus = function (s, isError) {
    this.statusStr = s;
    if (s == "") {
        s = "&nbsp;";
    }
    var statusDiv = document.getElementById(this.id + 'statusDiv');
    statusDiv.style.color = (isError === true) ? "red" : "green";
    statusDiv.innerHTML = "" + s + "";
    if (this.Map) {
        this.setStatusEvent.fire(s, isError);
    }
};

/**
 * Fetches the current status of the component
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @returns {String} the status string
 * @author T. Joshi 
 */
giovanni.widget.BoundingBoxPicker.prototype.getStatus = function () {
    return this.statusStr;
};

/**
 * Clears bounding box selections 
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @author K. Bryant 
 */
giovanni.widget.BoundingBoxPicker.prototype.clearSelections = function (evt, config) {
    self = config.selfRef;

    self.setBbox([]);
    self.setShape(null);
    // set this flag to false so that the bounding box can be altered according 
    // to the selected variables, until the user makes an explicit bbox selection
    userInteracted = false;
    self.userEdited = false;

    if (self.Map) {
        self.Map.setValueOG("", "", "", "");
        self.Map.map.zoomToExtent(new OpenLayers.Bounds(-180, -90, 180, 90));
        self.Map.map.setCenter(new OpenLayers.LonLat(0, 0));
        self.Map.bboxControl.activate();
        self.Map.navControl.deactivate();
    }
};

/**
 * Resets the bounding box selections back to the default; 
 * default is currently static 
 *      
 * @this {giovanni.widget.BoundingBoxPicker}
 * @author K. Bryant 
 */
giovanni.widget.BoundingBoxPicker.prototype.resetSelections = function () {
    // also set this flag to false so that the bounding box can be altered according 
    // to the selected variables, until the user makes an explicit bbox selection
    userInteracted = false;
    this.userEdited = false;
    this.setShape(this.defaultShape);
    this.setBbox(this.defaultBbox);

    value = this.bbox;

    if (this.Map) {
        this.Map.setValueOG(value[0], value[1], value[2], value[3]);
        this.Map.map.zoomToExtent(new OpenLayers.Bounds(-180, -90, 180, 90));
        this.Map.map.setCenter(new OpenLayers.LonLat(0, 0));
        this.Map.bboxControl.activate();
        this.Map.navControl.deactivate();
    }
};

/**
 * Returns the ID for this picker, which is the ID of the HTML element 
 * containing this picker
 *
 * @this {giovanni.widget.BoundingBoxPicker}
 * @author Chocka
 */
giovanni.widget.BoundingBoxPicker.prototype.getId = function () {
    return this.containerId;
};
