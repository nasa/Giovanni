//$Id: Map.js,v 1.181 2015/08/12 21:35:43 kbryant Exp $
//-@@@ AG, Version $Name:  $
/**
 * Used by ResultView to display interactive overaly maps.  Map class has pan, zoom and
 * layer-switching functionality.  OpenLayers3 is the current OTS used to
 * render the map.  The plot itself is added as a layer.
 */

giovanni.namespace('giovanni.widget.OverlayMap');

/*
 * constructor
 * args:
 * containerId - the ID of the element used as the container for the component
 * serviceId - identifies the service, overlay map vs. regular time-averaged map; 
 * used to configure the behavior of this class (render variables as layers on one map or separate maps)
 * resultURLArray - set of results URLs used to fetch JSON response for generating maps/overlays
 * construction:
 * Map builds HTML elements that make up the map frame, including the map container
 * uses the result URL(s) (one per variable) to assemble the JSON response object 
 * (this is a set of asynchronous requests to getGiovanniMapInfo.pl as JSON responses
 * are returned, layers are added to the map, first layer of each type is added to the map); 
 * uses the JSON response object to create OL layers and finish rendering the map; 
 * map object builds and keeps OL layers in an array and responds to layer change events; 
 * Map also builds an Options object and the giovanni.widget.OverlayMap.LayerSwitcher (initially collapsed/hidden);
 * giovanni.widget.OverlayMap.LayerSwitcher adds LayerControls as layers are loaded onto the map.
 *
 * @author K. Bryant
 */


giovanni.widget.OverlayMap = function (containerId, config) {
    // hold arguments
    config.enableReplot.subscribe(this.handleEnableReplotEvent, self);
    var projConf = giovanni.app.projectionConf;

    this.containerId = containerId;
    this.resultBbox = null;
    this.userBbox = config.userBbox;
    this.plotCount = 0;
    this.maxPlots = config.maxPlots;
    this.contourCount = 0;
    this.baseLayer = projConf.baseLayer;
    this.overlayLayers = projConf.overlayLayers;
    this.plotData = config.plotData;
    this.multiLayer = config.multiLayer;
    this.addedVariables = [];
    this.decorationsRendered = false;
    this.supportingLayersRendered = false;
    this.rendered = false;
    this.workspaceRef = config.workspaceRef;

    // if no projections yet, create an array
    if (!giovanni.widget.OverlayMap.projections) {
        giovanni.widget.OverlayMap.projections = [];
        projConf.projections.forEach(function (proj, i) {
            try {
                proj4.defs(proj.code, proj.proj4);
                ol.proj.get(proj.code).setExtent(proj.extent);
                giovanni.widget.OverlayMap.projections.push(proj);
            } catch (err) {
                console.log('incorrect projection config ', proj.name);
            }
        })
    }

    // subscribe to Workspace hide event so we can cleanup dialogs
    // when necesary
    var self = this;
    this.workspaceRef.hideEvent.subscribe(self.cleanupDialogs, self);

    this.render();
};

giovanni.widget.OverlayMap.prototype.handleEnableReplotEvent = function (type, args, o) {
    $(".layersButton").prop("disabled", false);
    /* $(".giovanni-layer-switcher").css("background-color", "rgba(64, 64, 64, 0.9)"); */
    this.config.enableReplotEvent.unsubscribe();
};
/*
 * The vertical order in which we'd like the layers to appear
 */
giovanni.widget.OverlayMap.zIndexMap = {
    map: 0,
    contour: 1,
    vector: 2
};

/*
 * The order the layer types are actually presented in the json response object
 */
giovanni.widget.OverlayMap.layerIndex = {
    map: this.multiLayer ? 1 : 0,
    contour: this.multiLayer ? 0 : 1,
    vector: 2
};

/*
 * bounding box corners
 */
giovanni.widget.OverlayMap.bboxCorners = {
    WEST: 0,
    SOUTH: 1,
    EAST: 2,
    NORTH: 3
};

/*
 * for supporting overlays
 */
giovanni.widget.OverlayMap.sOverlayConfig = [
  'coastlines',
  'countries',
  'grid'
];

/**
 * Used by giovanni.ui.ResultView when the map has already
 * been created and just needs to be recalled from persistent storage
 **/
giovanni.widget.OverlayMap.prototype.refresh = function (id, groupContainer) {
    this.containerId = id;
    // if there is no overlayImageFrame, reconstitute it
    if (!this.multiLayer && !$('#' + this.containerId + 'Frame').length && groupContainer) {
        $(groupContainer).append(
            '<div id="' + this.containerId + 'Frame" class="overlayImageFrame">\
          <div id="' + this.containerId + '"></div>\
         </div>'
        );
    }
    // add the map frame back in
    $('#' + this.containerId).append(this.mapFrame);
    // make sure the target is NOT display:none
    $('#' + this.map.getTarget() + ' > div > canvas').css('display', 'block');
    // resize the map so display attribues are set correctly
    this.map.updateSize();
    if (!$('#decorations-header-button').length) {
        // build decorations
        this.buildDecorations();
        // if we're done loading, set the current layers in each group
        this.buildSupportingLayers();
        // zoom to the result extent
        if (this.map.getView().getProjection().getCode() === 'EPSG:4326') {
            this._zoomToExtent();
        }
    }
};

giovanni.widget.OverlayMap.prototype.buildDecorations = function () {
    if (!this.decorationsRendered) {
        // add decorations control
        var decorations = new giovanni.widget.OverlayMap.Decorations({
            selfParent: this,
            containerId: this.containerId,
            frame: this.mapFrame
        });
        this.layerSwitcher.el.find('ul.layer-groups').append($('<li></li>').append(decorations.el));
        this.decorationsRendered = true;
    }
}

giovanni.widget.OverlayMap.prototype.buildSupportingLayers = function () {
    if (!this.supportingLayersRendered) {
        var overlays = this._renderOverlays(this.overlayLayers);
        this.downloadOptions.setOverlays(overlays);
        // add supporting layers UI
        this.supportingLayers =
            new giovanni.widget.OverlayMap.SupportingLayers({
                containerId: this.containerId,
                frame: this.mapFrame,
                overlays: overlays,
                sOverlayConfig: giovanni.widget.OverlayMap.sOverlayConfig
            });
        this.layerSwitcher.el.find('ul.layer-groups').append($('<li></li>').append(this.supportingLayers.el));
        this.supportingLayersRendered = true;
    }
}

/*
 * builds map elements, creates OpenLayer map with base layer; adds data layers and
 * supporting layers asynchronously
 */
giovanni.widget.OverlayMap.prototype.render = function (result) {
    // generate HTML elements
    this._assembleHTMLElements();
    // make sure status is invisible
    this.mapFrame.find('.layerStatusContainer').hide();
    $('#' + this.containerId).append(this.mapFrame);
    var center = new ol.extent.getCenter([0, 0]);
    // build map
    this.map = new ol.Map({
        target: this.containerId + 'Map',
        layers: [],
        interactions: ol.interaction.defaults({
            doubleClickZoom: true
        }),
        //controls: ol.control.defaults({}).extend([mousePosControl]),
        view: new ol.View({
            center: center,
            zoom: 2,
            projection: 'EPSG:4326',
            extent: [-360, -90, 360, 90]
        })
    });
    // remove attributions control -
    // doing it this way since OL3 doesn't seem to
    // handle the overriding of it's default controls
    // at construction time
    var map = this.map;
    map.getControls().forEach(function (control) {
        if (control instanceof ol.control.Attribution) {
            map.removeControl(control);
        }
    });

    // build layer switcher
    this.layerSwitcher = new giovanni.widget.OverlayMap.LayerSwitcher({
        containerId: this.containerId,
        frame: this.mapFrame,
        map: this.map,
        multiLayer: this.multiLayer,
        rendered: false
    });

    // build the download menu
    this.downloadOptions = new giovanni.widget.OverlayMap.DownloadOptions({
        containerId: this.containerId,
        frame: this.mapFrame,
        map: this.map,
        overlays: [],
        sOverlayConfig: giovanni.widget.OverlayMap.sOverlayConfig,
        bboxA: [],
        plotData: this.plotData,
        layerGroups: this.layerSwitcher.layerGroups,
        rendered: false
    });

    // add legend
    $('.ol-viewport').append(this.legendElement);

    // add the cursor coordinate readout element
    var mousePosContainer = $('<div id="' + this.containerId + 'mouse-position" class="giovanni-map-mouse-position"></div>');
    var mousePosControl = new ol.control.MousePosition({
        coordinateFormat: ol.coordinate.createStringXY(4),
        projection: 'EPSG:4326',
        className: 'giovanni-map-mouse-position',
        undefinedHTML: '&nbsp;'
    });
    this.map.addControl(mousePosControl);
};

/*
 * Public method that supports download functionality from downloads panel.
 * When and if the downloads panel in ResultView.js goes away, this method can go away.
 */
giovanni.widget.OverlayMap.prototype.download = function (e, options) {
    this.downloadOptions.download(e, options);
}

/*
 * returns a single DOM node containing all of the necessary HTML elements
 */
giovanni.widget.OverlayMap.prototype._assembleHTMLElements = function () {

    // create the map frame div; this will get added to the parent container
    this.mapFrame = $('<div class="mapFrame">\
      <div class="iconContainer"></div>\
      <div class="layerStatusContainer">Fetching map data...<img src="./img/progress.gif"/></div>\
      <div class="plotOverlayMapTitle" title="Layer Titles">\
        <div class="plotMapTitle_vector"></div>\
        <div class="plotMapSubTitle_vector"></div>\
        <div class="plotMapTitle_contour"></div>\
        <div class="plotMapSubTitle_contour"></div>\
        <div class="plotMapTitle_map"></div>\
        <div class="plotMapSubTitle_map"></div>\
      </div>\
    </div>');

    /* HACK:  This should be removed when IE11 fixes it's SVG rendering bug */
    if (navigator.userAgent.indexOf('.NET') > -1) {
        this.mapFrame.append('<div id="' + this.containerId + 'Map" class="olPlotMap olPlotMap_IE11"><div class="control-panel"></div></div>');
    } else {
        this.mapFrame.append('<div id="' + this.containerId + 'Map" class="olPlotMap"><div class="control-panel"></div></div>');
    }

    // build legend elements
    var legendEl;
    if (this.multiLayer) {
        legendEl = $('<div class="legend">\
      <div class="vectorLegend">\
        <img class="vectorLegendImg"/>\
      </div>\
      <div class="contourLegend">\
        <img class="contourLegendImg"/>\
      </div>\
      <div class="shadedLegend">\
        <img class="shadedLegendImg"/>\
      </div>');
    } else {
        legendEl = $('<div class="legend">\
      <div class="vectorLegend">\
        <img class="vectorLegendImg"/>\
      </div>\
      <div class="shadedLegend">\
        <img class="shadedLegendImg"/>\
      </div>');
    }
    this.legendElement = legendEl;

    // build caption element
    var captionEl =
        $('<div class="plotOverlayMapCaption">\
        <div style="display:none;" class="caption_vector"></div>\
        <div style="display:none;" class="caption_contour"></div>\
        <div style="display:none;" class="caption_map"></div>\
      </div>');
    this.mapFrame.append(captionEl);

};

giovanni.widget.OverlayMap.prototype._renderOverlays = function (overlayLayers) {
    var overlays = [];
    var self = this;
    overlayLayers.forEach(function (layer, index) {
        if (layer.name !== 'grid') {
            var newLayer =
                new ol.layer.Tile({
                    source: new ol.source.TileWMS({
                        urls: layer.url, // an array of shards from map_config.json
                        params: layer.params,
                        projection: layer.projection
                    }),
                    zIndex: 50,
                    extent: [-360, -90, 360, 90]
                });
            overlays[layer.name] = newLayer;
            self.map.addLayer(newLayer);
        }
    });
    // Need to use image tile to get correct behavior on map
    var grid = new ol.layer.Image({
        source: new ol.source.ImageWMS({
            url: "https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc",
            params: {
                'LAYERS': 'grid45'
            },
            ratio: 1
        }),
        zIndex: 51,
        extent: [-360, -90, 360, 90]
    });

    this.map.addLayer(grid);
    overlays['grid'] = grid;

    return overlays;
}

giovanni.widget.OverlayMap.prototype._getMapContainer = function () {
    return this.mapFrame.getElementById(this.containerId + 'Map');
};

/*
 * Adds data layers; the first data layer of a given type returned during the rendering
 * process is the layer that is visible on the map
 */
giovanni.widget.OverlayMap.prototype.addLayerData = function (plotData) {
    // if we've already added this one, don't send another ajax request
    if (this.addedVariables[plotData.getSource()]) {
        return;
    }
    // record the fact that the variable was added
    this.addedVariables[plotData.getSource()] = true;
    // if we haven't seen this variable, go get the JSON and add the layer
    var self = this;
    $.ajax({
        url: plotData.getSource(),
        method: "GET",
        async: true,
        success: function (data) {
            self.addDataLayerToMap(data, plotData);
        }
    });
};

/*
 * Add a data layer to the map using the JSON response that results
 * from a successful service_manager.pl visualization query
 */
giovanni.widget.OverlayMap.prototype.addDataLayerToMap = function (data, plotData) {
    // set map type
    var mapType = data.layers.layer[giovanni.widget.OverlayMap.layerIndex.map].type;
    // build shaded layer - index 1
    var layer = $.extend(true, {
        mapfile: data.layers.mapfile,
        result: data.layers.result,
        resultset: data.layers.resultset,
        session: data.layers.session,
        plotId: plotData.id,
        getMapInfoUrl: plotData.getSource(),
        datafile: plotData.dataFieldLabel,
        zIndex: giovanni.widget.OverlayMap.zIndexMap[data.layers.layer[giovanni.widget.OverlayMap.layerIndex.map].type]
    }, data.layers.layer[giovanni.widget.OverlayMap.layerIndex.map]);
    // set result bbox and bbox array since this is where we can get the bbox
    // from the server side 
    if (!this.resultBbox) {
        this.resultBbox = data.layers.layer[0].bbox && data.layers.layer[0].bbox !== "" ?
            data.layers.layer[0].bbox : this.userBbox && this.userBbox !== "" ?
            this.userBbox : "-360,-90,360,90";
        // set the layer bbox in case it was empty to begin with 
        layer.bbox = this.resultBbox;
        // create the bbox array
        this.bboxArray = this.resultBbox.split(",").map(function (x) {
            return parseFloat(x);
        });
        // set the bbox array used by DownloadOptions 
        this.downloadOptions.bboxA = this.bboxArray.slice();
        //set the default centee
        var center = new ol.extent.getCenter(this.bboxArray);
        giovanni.widget.OverlayMap.EQCenter = center;
    }
    // add shaded layer to layer switcher (and map via switcher)
    this.layerSwitcher.addLayer(mapType, layer);

    // build contour layer if there is one
    if (this.multiLayer) {
        var contourLayer;
        if (data.layers.layer[giovanni.widget.OverlayMap.layerIndex.contour]) {
            contourLayer = $.extend(true, {
                mapfile: data.layers.mapfile,
                result: data.layers.result,
                resultset: data.layers.resultset,
                session: data.layers.session,
                plotId: plotData.id,
                getMapInfoUrl: plotData.getSource(),
                datafile: plotData.dataFieldLabel,
                zIndex: giovanni.widget.OverlayMap.zIndexMap[data.layers.layer[giovanni.widget.OverlayMap.layerIndex.contour].type]
            }, data.layers.layer[giovanni.widget.OverlayMap.layerIndex.contour]);
            // add contour layer to switcher (and map via switcher)
            this.layerSwitcher.addLayer(data.layers.layer[giovanni.widget.OverlayMap.layerIndex.contour].type, contourLayer);
            // increment the contour count; we'll use this to set the contour variable
            // after everything is rendered.
            this.contourCount++;
        }
    }
    // make sure that layers that are populated show up
    for (var layerGroup in this.layerSwitcher.layerGroups) {
        this.layerSwitcher.layerGroups[layerGroup].currentLayer.setVisible(true);
    }

    this.plotCount++;
    if (this.plotCount == this.maxPlots && !this.decorationsRendered) {
        // add decorations control
        this.buildDecorations();
        // if we're done loading, set the current layers in each group
        this.buildSupportingLayers();
        // add listener to handle zooming into WMS grid layer
        // - ADD IT HERE becuase otherwise the map doesn't have
        // a properly rendered extent to draw from
        this.map.getView().on('change:resolution',
            giovanni.util.handleMapResolutionChange, {
                'map': this.map,
                'proj': 'EPSG:4326',
                'bbox': this.bboxArray
            });
        // zoom to the result-supplied extent or USERS extent
        this._zoomToExtent();
    }
};

giovanni.widget.OverlayMap.prototype._zoomToExtent = function () {
    // determine the projection
    var proj = this.map.getLayers()[0] ? this.map.getLayers()[0].getSource().getProjection().getCode() : 'EPSG:4326';
    var bbox = giovanni.util.scrubBbox(this.bboxArray, proj, true);
    this.map.getView().fit(bbox, this.map.getSize());
}

/**
 *  Handles hideEvent fired from Workspace - the idea of which
 *  is to clean up (close) dialogs that have not been closed
 *  when the user switches back to data selection or switches
 *  to a different result or node in the history tree
 *
 *  @author K. Bryant
 **/
giovanni.widget.OverlayMap.prototype.cleanupDialogs = function (e, args, self) {
    self.layerSwitcher.layerGroups.forEach(function (layerGroup) {
        var layers = layerGroup.layers;
        layers.forEach(function (layer) {
            layer.layerOptions.optionsPanel.hide();
        });
    });
};

/** 
 * How to use:
 * var ls = new giovanni.widget.OverlayMap.LayerSwitcher({ 
 * layerGroups: [ 
 *     { name: 'a', layers: [ new OpnerLayers.Layer.WMS() ] } 
 *     { name: 'button', layers: [ new OpnerLayers.Layer.WMS(),  new OpnerLayers.Layer.WMS() ] } 
 *   ] 
 * })
 * new ol.Map().addControl(ls)
 **/

giovanni.widget.OverlayMap.LayerSwitcher = function (options, Control) {
    var self = this;

    self.origOptions = options || {};
    self.layerGroups = [];
    //self.decorationsRendered = false;
    self.rendered = self.origOptions.rendered;

    self.el = $('<div class="giovanni-layer-switcher">\
    <h3>\
      <button class="layersButton" disabled>\
        <i class="fa fa-bars"></i>\
        Options\
        <i class="fa fa-caret-down"></i>\
      </button>\
    </h3>\
    <ul class="layer-groups">\
     <li class="group_vector"></li>\
     <li class="group_contour"></li>\
     <li class="group_map"></li>\
    </ul>\
  </div>');

    self.el.find('button').click(function () {
        self.el.toggleClass('giovanni-layer-switcher-active');
    });

    if (!self.rendered) {
        self.origOptions.frame.find('.control-panel').prepend(self.el[0]);
        self._render();
    }

};

giovanni.widget.OverlayMap.LayerSwitcher.prototype.addLayer = function (groupName, layer) {
    var groupObject;

    this.layerGroups.forEach(function (layerGroup) {
        if (layerGroup.name === groupName) {
            groupObject = layerGroup;
            return;
        }
    });

    if (!groupObject) {
        this.addLayerGroup({
            name: groupName,
            containerId: this.origOptions.containerId,
            frame: this.origOptions.frame,
            multiLayer: this.origOptions.multiLayer,
            layers: [layer]
        });
    } else {
        groupObject.addLayer(layer);
    }

};

giovanni.widget.OverlayMap.LayerSwitcher.prototype.addLayerGroup = function (layerGroup) {
    layerGroup.map = this.origOptions.map;
    var layerGroup = new giovanni.widget.OverlayMap.LayerGroup(layerGroup);
    this.layerGroups.push(layerGroup);
    this.el.find('li.group_' + layerGroup.name).append(layerGroup.el);
};

giovanni.widget.OverlayMap.LayerSwitcher.prototype._render = function () {
    if (!this.rendered && this.origOptions.layerGroups) {
        this.rendered = true;
        this.origOptions.layerGroups.forEach(function (layerGroup) {
            this.addLayerGroup(layerGroups[i]);
        }, this);
    }
};

giovanni.widget.OverlayMap.LayerGroup = function (options) {
    var self = this;
    var layers = options.layers;
    this.id = Date.now();
    this.name = options.name;
    this.containerId = options.containerId;
    this.frame = options.frame;
    this.options = options;
    this.layers = [];
    this.currentLayer = null;
    this.visible = true;
    this.multiLayer = options.multiLayer;
    this.onClick = this._handleGroupClick.bind(this);

    this.render();
};

giovanni.widget.OverlayMap.LayerGroup.prototype.render = function () {
    var self = this;

    var groupName = self.name === 'map' ? 'shaded' : self.name;

    self.el = $('<div>\
    <h4 class="button-header"><i class="layerGroupIcon' + this.name + ' fa fa-check"/>\
    <button class="layerGroup' + this.name + '">' + groupName + '</button></h4>\
    <ul class="layer-group"></ul>\
  </div>');

    self.options.layers.forEach(function (layer) {
        self.addLayer(layer);
    }, self);

    self.el.find('.layerGroup' + self.name).click(function (e) {
        self._handleGroupClick(e);
    });

    self.currentLayer = self.layers[0];
    if (!self.multiLayer) {
        var groupLabel = self.layers[0].options.layer.fullName ?
            self.layers[0].options.layer.fullName : self.layers[0].options.layer.name.replace(/_/g, " ");
        self.el.find('.layerGroup' + self.name).text(groupLabel);
    }

    return self.el;
};

giovanni.widget.OverlayMap.LayerGroup.prototype._handleGroupClick = function (e) {
    // determine if the group check is 'visible'
    var isGroupVisible =
        this.el.find('.layerGroupIcon' + this.name).css('visibility') === 'visible' ? true : false;
    // set the first layer in the group
    this.layers[0].olLayer.setVisible(!isGroupVisible);
    // set the group layer object
    this.currentLayer.setVisible(!isGroupVisible);
    this.currentLayer.setDecorations(!isGroupVisible);
    // set the group icon (checkmark)
    this.el.find('.layerGroupIcon' + this.name).css('visibility', isGroupVisible ? 'hidden' : 'visible');
    // set the group radio controls (for each layer in the group)
    this.el.find('input').prop('disabled', isGroupVisible);
    // set the group visibility 
    this.setVisible(!isGroupVisible);
}

giovanni.widget.OverlayMap.LayerGroup.prototype.addLayer = function (layer) {
    var layerObj = new giovanni.widget.OverlayMap.Layer({
        layer: layer,
        map: this.options.map,
        containerId: this.options.containerId,
        frame: this.frame,
        multiLayer: this.options.multiLayer,
        group: this,
        onClick: this._handleLayerClick.bind(this)
    });

    layerObj.setVisible(false);

    this.layers.push(layerObj);

    this.el.find('ul.layer-group').append(layerObj.el);

    // order the variables alphabetically
    var lbls = this.el.find('div.layer-label');
    lbls.sort(function (a, b) {
        a = a.getAttribute('id');
        b = b.getAttribute('id');
        if (a > b) return 1;
        if (a < b) return -1;
        return 0;
    });
    lbls.detach().appendTo(this.el.find('ul.layer-group'));
};

giovanni.widget.OverlayMap.LayerGroup.prototype._handleLayerClick = function (layer) {
    this.currentLayer.setVisible(false);
    this.currentLayer = layer;
    this.currentLayer.setVisible(true);
};

giovanni.widget.OverlayMap.LayerGroup.prototype.setVisible = function (bool) {
    this.visible = bool;
}
giovanni.widget.OverlayMap.LayerGroup.prototype.isVisible = function () {
    return this.visible;
}

giovanni.widget.OverlayMap.Layer = function (options) {
    this.options = options;

    var projection = ol.proj.get('EPSG:4326');
    var tileGrid = ol.tilegrid.createXYZ({
        extent: projection.getExtent(),
        tileSize: 512
    });
    this.options = options;
    var bbox = giovanni.util.scrubBbox(options.layer.bbox, projection.getCode());
    this.olLayer = new ol.layer.Tile({
        source: new ol.source.TileWMS({
            url: "./daac-bin/agmap.pl",
            visible: false,
            params: {
                LAYERS: options.layer.name,
                FORMAT: 'image/png',
                TRANSPARENT: true,
                sld: options.layer.variable_sld && options.layer.variable_sld[0].url,
                MAPFILE: options.layer.mapfile,
                SESSION: options.layer.session,
                RESULTSET: options.layer.resultset,
                RESULT: options.layer.result,
                RAND: giovanni.util.getRandom()
            },
            tileGrid: tileGrid
        }),
        zIndex: options.layer.zIndex,
        extent: bbox
    });

    this.options.map.addLayer(this.olLayer);

    this.render();
};

giovanni.widget.OverlayMap.Layer.prototype.render = function () {
    var self = this;
    var options = self.options;

    if (options.multiLayer) {
        self.el = $('<div class="layer-label" id="' + options.layer.fullName + '_label">' +
            '<input name="' + options.group.id + '" type="radio"/><span class="radio-label">' +
            options.layer.fullName + '</span></div>');

        self.el.find('input').click(function () {
            options.onClick(self);
        });
        self.el.find('.radioLabel').click(function () {
            options.onClick(self);
        });
    } else { // if there is one layer only, don't show radio
        self.el = $('<div></div>');
    }

    // set options for layers except vector layers
    var params = $.extend(true, {
        olLayer: self.olLayer
    }, options);
    if (params.layer.type !== 'vector') {
        self.layerOptions = new giovanni.widget.OverlayMap.LayerOptions(params);
        self.el.append(self.layerOptions.el);
    }

    return self.el;
};

giovanni.widget.OverlayMap.Layer.prototype.setVisible = function (visible) {
    var self = this;
    // check group visibility - if false, do some housekeeping
    // and then return
    if (!self.options.group.isVisible()) {
        self.el.find('input').prop('checked', visible);
        self.olLayer.setVisible(visible);
        return;
    }

    self.olLayer.setVisible(visible);

    self.el.find('input').prop('checked', visible);
    // set title, subtitle, caption
    self.setDecorations(visible);
    self.options.group.el.find('.toggle-options').prop('disabled', true);
    self.options.group.multiLayer ?
        self.options.group.el.find('.toggle-options').prop('class', 'toggle-options options-button-disabled') :
        self.options.group.el.find('.toggle-options').prop('class', 'toggle-options options-button-single-layer-disabled');

    self.el.find('.toggle-options').prop('disabled', false);
    self.options.group.multiLayer ?
        self.el.find('.toggle-options').prop('class', 'toggle-options options-button') :
        self.el.find('.toggle-options').prop('class', 'toggle-options options-button-singler-layer');
}

giovanni.widget.OverlayMap.Layer.prototype.setDecorations = function (isLayerVisible) {
    var self = this;
    var isVisible = isLayerVisible;
    var type = self.options.layer.type;
    var label = type === "map" ? "SHADED" : self.options.layer.type.toUpperCase();

    // get title element
    var titleEl = self.options.frame.find('.plotMapTitle_' + type);
    // set title visibility and content
    if (isLayerVisible) {
        self.options.frame.find('.plotMapTitle_' + type).show();
    } else {
        self.options.frame.find('.plotMapTitle_' + type).hide();
    }

    if (self.options.multiLayer) {
        var content = label + ": " + self.options.layer.fullName +
            ((self.options.layer.fullName.indexOf(self.options.layer.unit) > -1 ?
                " " + self.options.layer.units : ""));
        titleEl.text(content);
    } else {
        titleEl
            .text(self.options.layer.title);
    }
    // get subtitle element
    var subTitleEl = self.options.frame.find('.plotMapSubTitle_' + type);
    // set subtitle element visibility and content
    subTitleEl.css('display', (isVisible ? 'block' : 'none'));
    subTitleEl
        .html(this.options.layer.subTitle.replace('2nd Variable', '<br/>2nd Variable').replace('Var. 2', '<br/>Var. 2').replace('minus', 'minus<br/>'));
    // set caption visibility and content
    self.options.frame.find('.caption_' + type).css('display', (self.options.layer.caption && isVisible ? 'block' : 'none'));
    if (self.options.layer.caption) {
        self.options.frame.find('.caption_' + type).html(
            self.options.multiLayer ? self.options.layer.caption.replace('-', label + " CAPTION: ") : self.options.layer.caption.replace('-', ''));
    } else {
        self.options.frame.find('.caption_' + type).empty();
    }

    if (self.options.frame.find('.caption_vector').html() ||
        self.options.frame.find('.caption_contour').html() ||
        self.options.frame.find('.caption_map').html()) {
        self.options.frame.find('.plotOverlayMapCaption').css('display', 'block');
        self.options.frame.find('.caption_' + type).attr('title', self.options.layer.caption);
    } else {
        self.options.frame.find('.plotOverlayMapCaption').css('display', 'none');
    }
    self.setLegend(isVisible);
};

giovanni.widget.OverlayMap.Layer.prototype.setLegend = function (isVisible) {
    var self = this;
    var layer = self.options.layer;
    self.legendUrl = './daac-bin/agmap.pl' +
        '?version=1.1.1&service=WMS&request=GetLegendGraphic' +
        '&LAYER=' + encodeURIComponent(layer.name) +
        '&FORMAT=image%2Fpng' +
        '&session=' + encodeURIComponent(layer.session) +
        '&resultset=' + encodeURIComponent(layer.resultset) +
        '&result=' + encodeURIComponent(layer.result) +
        '&mapfile=' + encodeURIComponent(layer.mapfile) +
        (self.options.layer.type === 'map' ?
            '&SLD=' + encodeURIComponent(self.layerOptions.optionsBody.getSldUrl(self.layerOptions.optionsBody.userSelections.paletteName)) : "")
        //+ '&date=' + new Date().getTime()
        +
        '&rand=' + Math.random() * 10000000;
    var type = self.options.layer.type;
    if (type === 'map') type = 'shaded';
    self.options.frame.find('.' + type + 'LegendImg').attr('src', self.legendUrl);
    if (type === 'vector' || type === 'shaded') {
        self.options.frame.find('.' + type + 'Legend').css('display', (isVisible ? 'block' : 'none'));
    }
}

giovanni.widget.OverlayMap.LayerOptions = function (options) {
    var self = this;
    this.options = options;
    var params = $.extend({
        onSelectionChange: function (selections, errorText) {
            self.el.find('.statusError').text(errorText);
        },
    }, options);
    if (options.layer.type === 'map') {
        this.optionsBody = new giovanni.widget.OverlayMap.MapLayerOptions(params);
    } else {
        this.optionsBody = new giovanni.widget.OverlayMap.ContourLayerOptions(params);
    }
    this.render();
};

giovanni.widget.OverlayMap.LayerOptions.prototype.render = function () {
    var self = this;
    this.el = $('<div>\
    <button class="' + (this.options.animation ? 'iconButton animationIconButton' : 'toggle-options options-button') + '">\
      <i class="fa fa-cog ' + (this.options.animation ? 'mapIcon' : '') + '"></i>\
      Options\
    </button>\
    //<div id="' + this.id + '"></div>\
  </div>')
        .find('button')
        .click(this.toggleOptions.bind(this));

    this.optionsPanel = new YAHOO.widget.Panel($('<div>')[0], {
        resize: true,
        constraintoviewport: true,
        close: true,
        visible: false,
        draggable: true,
        autofillheight: "body",
        zIndex: 10000,
        width: "400px",
        fixedcenter: true,
        effect: {
            effect: YAHOO.widget.ContainerEffect.FADE,
            duration: 0.5
        }
        //context: [this.el[0], 'tl', 'bl', [], [0, 0]]
    });

    var label = self.options.layer.fullName != "" ? self.options.layer.fullName : self.options.layer.title;
    var body = $('<div>\
    <div class="mapOptionsTitle">' + label + '</div>\
    <div class="dialogContainer paletteContainer"></div>\
    <div class="statusError"></div>\
    <div class="clear paletteRefreshContainer">\
      <span class="yui-button yui-button-button">\
        <span class="first-child">\
          <button title="Click to restore the original min/max and palette values" class="reset">Restore Defaults</button>\
        </span>\
      </span>\
      <span class="yui-button yui-button-button">\
        <span class="first-child">\
          <button title="Click to refresh the map with the selected palette" class="replot">Re-Plot</button>\
        </span>\
      </span>\
    </div>\
  </div>');

    body.find('.dialogContainer').append(this.optionsBody.el);

    body.find('button.reset').click(function () {
        self.optionsBody.reset();
        self.optionsPanel.hide();
        $('#' + self.options.containerId + ' > .giovanni-layer-switcher').toggleClass('giovanni-layer-switcher-active');
    });

    body.find('button.replot').click(function () {
        self.optionsBody.replot();
    });

    this.optionsPanel.setHeader('<span style="text-align: left;">Map Options</span>');
    this.optionsPanel.setBody(body[0]);
    this.optionsPanel.render(document.body); // not happy about it rendering to body, but whatever

    self.optionsBody.setDialog(self.optionsPanel);

    return this.el;
};

giovanni.widget.OverlayMap.LayerOptions.prototype.toggleOptions = function () {
    if (this.optionsPanel.cfg.getProperty('visible')) {
        this.optionsPanel.hide();
    } else {
        this.optionsPanel.show();
    }
};

giovanni.widget.OverlayMap.MapLayerOptions = function (options) {
    var self = this;
    var slds = options.layer.variable_sld;

    self.id = Date.now();
    self.options = options;
    self.userSelections = {};
    self.addedPalettes = [];
    self.currentProj = 'EPSG:4326';
    self.mapHasBeenReProjected = false;

    // set default map options
    if (slds) {
        self.defaults = {
            smooth: 'off',
            scale: options.layer.scale || 'linear',
            paletteName: slds[0].label
        };

        if (slds[0].min === null || slds[0].max === null) {
            self.sldPromise = $.get(slds[0].url)
                .then(function (resp) {
                    var colorMapEntries = resp.getElementsByTagName('ColorMapEntry');
                    self.defaults.min = slds[0].min || colorMapEntries[1].getAttribute('label');
                    self.defaults.max = slds[0].max || colorMapEntries[colorMapEntries.length - 2].getAttribute('label');
                }, function () {
                    alert('could not fetch SLD for to grab default values');
                });
        } else {
            self.defaults.min = slds[0].min;
            self.defaults.max = slds[0].max;
            self.sldPromise = $.Deferred()
                .resolve()
                .promise();
        }
    }

    if (self.sldPromise) {
        self.sldPromise.then(function () {
            $.extend(true, self.userSelections, self.defaults);
        });
    }

    if (self.sldPromise) {
        self.sldPromise.then(function () {
            $.extend(true, self.userSelections, self.defaults);
        });
    }
    self.palettePromise = $.get(self.options.layer.getMapInfoUrl ? self.options.layer.getMapInfoUrl : self.options.plotSource, {
            palette: 1
        })
        .then(function (resp) {
            // currently, the map (or 'shaded') layer sits at index 1
            self.paletteList = self.options.layer.sld;
            // || resp.layers.layer[0].sld 
            // || resp.layers.layer[0].sld_list 
            // || resp.layers.layer[1].sld 
            // || resp.layers.layer[1].sld_list;
        });

    self._render();
};

giovanni.widget.OverlayMap.MapLayerOptions.prototype.setDialog = function (dialog) {
    this.dialog = dialog;
}

giovanni.widget.OverlayMap.MapLayerOptions.prototype._render = function () {
    var self = this;
    self.el = $('<div></div>');

    $.when([self.sldPromise, self.palettePromise])
        .then(function () {
            self.el.append(self._renderOptionsBody(self.options));
        });
};

giovanni.widget.OverlayMap.MapLayerOptions.prototype.insertPalette = function (palette) {
    // Add to instance state
    this.addedPalettes.push(palette);
    $(this.el).find('.paletteListContainer')
        .append($(this._getPaletteElementString(palette, true)));
};

/*
 * Create the HTML for the options panel
 *
 * @this {giovanni.widget.OverlayMap}
 * @params {JSON Object}
 * @return {}
 * @author K. Bryant
 * @modified D. Da Silva, C. Smit
 */
giovanni.widget.OverlayMap.MapLayerOptions.prototype._renderOptionsBody = function (config) {
    var self = this;
    var projections = '';
    try {
        giovanni.widget.OverlayMap.projections.forEach(function (proj, i) {
            projections += '<option ' + (proj.code === 'EPSG:4326' ? 'selected' : '') + ' value="' + proj.code + '">' + proj.name + '</option>'
        });
    } catch (err) {
        console.log("No projection list required; MapLayerOptions is being used by MapAnimation.js");
    }
    var palettes = config.layer.variable_sld ? config.layer.variable_sld.concat(this.addedPalettes) : undefined;
    if (!palettes) {
        // If there are no palettes return undefined, indicating no options should be shown.
        // This will change when we do min/max for wind vector data -- K. Bryant.
        return;
    }

    var hideProjectionSelector = (this.options.multiLayer || self.options.animation) ? 'hidden="true"' : '';

    var rangeMin = palettes[0].min == null ? this.defaults.min : palettes[0].min;
    var rangeMax = palettes[0].max == null ? this.defaults.max : palettes[0].max;

    /*                   dialogRoot
     *                    /      \
     *           dialogTitle       +------dialogContainer-------+----------------------+
     *                             /          |                  \                      \
     *                      rangeRoot      palettesRoot      smoothingRoot          scalingRoot
     *                       /    |           |      \             |      \              |   \
     *          MapOptionsHeader  |           |     MapOptionsBody |     MapOptionsBody  |   MapOptionsBody
     *                  MapOptionsBody     MapOptionsHeader      MapOptionsHeader    MapOptionsHeader
     *                             
     */

    var body = $('<div>\
    <div class="mapOptionsHeader">Data Range</div>\
    <div class="mapOptionsBody">\
      <div class="mapOptionsField">\
        <input type="text" name="' + self.id + 'RangeMin" value="' + rangeMin + '" size="12"></input>\
        &nbsp;Minimum\
      </div>\
      <div class="mapOptionsField">\
        <input type="text" name="' + self.id + 'RangeMax" value="' + rangeMax + '" size="12"></input>\
        &nbsp;Maximum\
      </div>\
    </div>\
    <div>\
      <div class="mapOptionsHeader">Palette</div>\
      <div class="paletteListContainer mapOptionsBody">' +
        palettes.map(function (palette, i) {
            return self._getPaletteElementString(palette, i === 0)
        }).join('') +
        '</div>\
      <button style="margin-left: 20px; margin-bottom: 10px;" class="view-all-palettes">View All Palettes</button>\
    </div>\
    <div>\
      <div class="mapOptionsHeader"><a href="./doc/UsersManualworkingdocument.docx.html#h.ki0vxeqdkf0j" target="help">Smoothing</a></div>\
      <div class="mapOptionsBody">\
        <input type="radio" name="' + self.id + 'SmoothChoice" value="on"/>\
        <span>On</span>\
        <span>&nbsp;&nbsp;&nbsp</span>\
        <input type="radio" name="' + self.id + 'SmoothChoice" value="off" checked="true"/>\
        <span>Off</span>\
      </div>\
    </div>\
    <div class="mapOptionsHeader"' + hideProjectionSelector + '">Projection</div>\
    <div class="mapOptionsBody"' + hideProjectionSelector + '">\
        <select name="' + self.options.containerId + 'ProjectionChoice" id="' + self.options.containerId + 'ProjectionChoice">' +
        projections +
        '</select>\
    </div>\
    <div>\
      <div class="mapOptionsHeader">Scaling</div>\
      <div class="mapOptionsBody">\
        <input type="radio" name="' + self.id + 'ScaleChoice" value="linear"' + (this.options.layer.scale === 'linear' ? 'checked' : '') + '/>\
        <span>Linear</span>\
        <span>&nbsp;&nbsp;&nbsp</span>\
        <input type="radio" name="' + self.id + 'ScaleChoice" value="log"' + (this.options.layer.scale === 'log' ? 'checked' : '') + '/>\
        <span>Log</span>\
      </div>\
    </div>');

    body.change(function (e) {
        var $target = $(e.target);
        var name = $target.attr('name');
        var val = $target.val();
        var errStr = '';

        if (name.indexOf('ScaleChoice') !== -1) {
            self.userSelections.scale = val;
        } else if (name.indexOf('SmoothChoice') !== -1) {
            self.userSelections.smooth = val;
        } else if (name.indexOf('RangeMin') !== -1) {
            self.userSelections.min = val;
        } else if (name.indexOf('RangeMax') !== -1) {
            self.userSelections.max = val;
        } else if (name.indexOf('PaletteChoice') !== -1) {
            self.userSelections.paletteName = val;
        } else if (name.indexOf('ProjectionChoice') !== -1) {
            self.userSelections.projection = val;
        }

        self.options.onSelectionChange(self.userSelections, self.validateOptionSelections(self.userSelections));
    });

    // Attach click handler to 'View all Palettes' button, already in DOM
    body.find('.view-all-palettes').click(function () {
        // The palette window exists after the following code executes and until this Map instance
        // is removed from memory. If the user clicks 'close' or the X in the top-right, the
        // window is hidden. When the window is hidden, subsequent clicks will show it.
        if (self.palettePanel) {
            self.palettePanel.show();
        } else {
            // The model of computation here aims to open the palette window now if
            // the palette list is loaded, otherwise do so as soon it is.
            // 
            // This is done by creating a new event loadPaletteWindowEvent, which has behaviour
            // attached to it to open the window. If the palettes are loaded, the
            // event is triggered now. If it's not, we attach a function to the *loading* event
            // which fires the aforementioned event.

            var container = $("<div id='PaletteSelection'></div>");
            self.palettePanel = new YAHOO.widget.Panel("PalettePanel", {
                width: "500px",
                height: "400px",
                fixedcenter: true,
                zindex: 20000,
                visible: false,
                draggable: true,
                constraintoviewport: true,
                effect: {
                    effect: YAHOO.widget.ContainerEffect.FADE,
                    duration: 0.5
                }
            });
            self.palettePanel.setHeader("<span style='text-align: left;'>Palette Options</span>");
            self.palettePanel.setBody(container[0]);

            self.paletteSelection = new giovanni.widget.PaletteSelection(
                container[0], self.paletteList);
            self.paletteSelection.addToDOM();
            self.paletteSelection.bindToDOM();

            self.paletteSelection.getCloseEvent().subscribe(function () {
                self.palettePanel.hide();
            });

            self.paletteSelection.getAddPaletteEvent().subscribe(function (unused, args) {
                self.insertPalette(args[0].selectedPalette);
                self.userSelections.paletteName = args[0].selectedPalette.label;
                self.palettePanel.hide();
            });

            self.palettePanel.render(document.body);
            self.palettePanel.show();
        }
    });

    return body;
};

giovanni.widget.OverlayMap.MapLayerOptions.prototype._getPaletteElementString = function (palette, checked) {
    return '<input type="radio" name="' + this.id + 'PaletteChoice" value="' + palette.label + '"' + (checked ? 'checked' : '') + '></input>\
    <img class="paletteIcon" src="' + palette.thumbnail + '" alt="' + palette.label + '" title="' + palette.label + '"></img>\
    <span class="paletteLabel">' + palette.label + '</span>\
    <input type="hidden" value="' + palette.name + '"></input>\
    <br/>';
};

/**
 * Replot shaded map layer
 *
 * @this {giovanni.widget.OverlayMap.MapLayerOptions}
 * @author M. Nauage
 * @params {Object}
 * @returns nothing
 * @modified K. Bryant
 **/
giovanni.widget.OverlayMap.MapLayerOptions.prototype.replot = function (selections) {
    var self = this;
    // set selections using the argument, this.userSelections or the default
    selections = selections || this.userSelections;
    selections = selections || this.defaults;
    var errorStr = this.validateOptionSelections(selections || this.userSelections);
    // check for validation errors; if none, kickoff map update
    if (errorStr) {
        return $.Deferred()
            .reject(errorStr)
            .fail(function () {
                $('.statusError').text(errorStr);
            })
            .promise();
    } else {
        $('.statusError').text("");
        // local ref for the layer in question
        var layer = self.options.layer;
        // gather the map options for this layer
        var mapOptions = {
            name: layer.name,
            min: selections.min,
            max: selections.max,
            smooth: selections.smooth,
            scale: selections.scale,
            projection: selections.projection ? selections.projection : 'EPSG:4326',
            sld: this.getSldUrl(selections.paletteName)
        };
        // store the palette selection for future reference
        this.userSelections.paletteName = selections.paletteName;
        this.userSelections.projection = selections.projection;
        // build the base request URL
        var url = "./daac-bin/service_manager.pl?";

        url += "session=" + encodeURIComponent(layer.session);
        url += "&resultset=" + encodeURIComponent(layer.resultset);
        url += "&result=" + encodeURIComponent(layer.result);

        //if(self.options.animation){
        //    url += "&service=MpAn";
        //}

        // create some status on the UI
        $("body").css("cursor", "progress");
        var statusContainer = $('.clear, .paletteRefreshContainer');
        statusContainer.prepend($('<img class="replotSpinner" style="float:left;" src="img/progress.gif"/>'));
        var replotButton = statusContainer.find('.replot');
        var resetButton = statusContainer.find('.reset');
        var dialogContainer = $('.dialogContainer');
        var closeButton = $('.container-close');
        replotButton.prop('disabled', true);
        replotButton.text('Plotting...');
        replotButton.addClass('disabledElement');
        resetButton.addClass('disabledElement');
        dialogContainer.addClass('disabledElement');
        closeButton.addClass('disabledElement');
        replotButton.css('cursor', 'progress');
        // set the map options as a class member so we can retrieve them
        // when it finally comes time to update the layer parameters....
        // after service manager has finished returning.
        self.mapOptions = mapOptions;

        // initiate the request (and start to poll the server)
        self.doUpdatePoll(url, mapOptions);
    }
};

/**
 * Handling polling and for asynchronous map updates
 *
 * @author K. Bryant
 **/
giovanni.widget.OverlayMap.MapLayerOptions.prototype.doUpdatePoll = function (url, initOptions) {
    // request code
    var code;
    // request status
    var complete;
    var self = this;
    // layer reference - need this when polling is done
    var layer = self.options.layer;
    // timeout reference
    var updateTimeout;
    // save the baseUrl (we'll use it for polling)
    var baseUrl = url;
    // create the initial URL for updating the map
    var updateUrl = initOptions ? baseUrl + "&options=" + encodeURIComponent(JSON.stringify([{
        options: initOptions,
        id: layer.plotId
    }])) : baseUrl;

    //  make the request and do the work when the request completes
    $.get(updateUrl)
        .then(function (data) {
            // each time through, grab code and percent complete to see if the server is done 
            code = $(data).find("session > resultset > result > status > code").text();
            complete = $(data).find("session > resultset > result > status > percentComplete").text();
            // check for request completion
            if (code == 0 && complete == 100) {
                // clear the timeout so we don't poll again
                clearTimeout(updateTimeout);

                var images = $(data).find("session > resultset > result > data > fileGroup > dataFile > image");
                var image = $.grep(images, function (e) {
                    return $(e).find("id").text() == self.options.layer.plotId
                });

                if ($(image[0]).find("status").text() || self.options.animation) {
                    // get the SLD (again - since options are not passed a second time, we need this)
                    var sld = self.getSldUrl(self.userSelections.paletteName);
                    // get current projection
                    var currentProj = $('#' + self.options.containerId + 'ProjectionChoice').val();
                    var layer = self.options.layer;
                    // update the layer
                    if (!self.options.animation) {
                        self.options.olLayer.getSource().updateParams($.extend(true, {}, {
                          LAYERS: layer.name,
                          FORMAT: 'image/png',
                          TRANSPARENT: true,
                          sld: sld,
                          MAPFILE: layer.mapfile,
                          SESSION: layer.session,
                          RESULTSET: layer.resultset,
                          RESULT: layer.result,
                          RAND: giovanni.util.getRandom()
                        }));
                    } else {
                        // for now, just hide the dialog...
                        self.dialog.hide();
                        // ... and then update animation frame
                        self.options.updateFunc(null, self.userSelections, self.options.updateObj);
                        // may need to relocate this call since it gives control back to
                        // MapAnimation.js...
                    }
                    // reset the legend source url
                    self.legendUrl = './daac-bin/agmap.pl' +
                        '?version=1.1.1&service=WMS&request=GetLegendGraphic' +
                        '&LAYER=' + encodeURIComponent(layer.name) +
                        '&FORMAT=image%2Fpng' +
                        '&session=' + encodeURIComponent(layer.session) +
                        '&resultset=' + encodeURIComponent(layer.resultset) +
                        '&result=' + encodeURIComponent(layer.result) +
                        '&mapfile=' + encodeURIComponent(layer.mapfile) +
                        '&SLD=' + encodeURIComponent(sld) +
                        '&rand=' + new Date().getTime() ;

                    // update the legend on the page
                    if (!self.options.animation) {
                        self.options.frame.find('.shadedLegendImg').attr("src", self.legendUrl);
                    } else {
                        try {
                            $('.animationLegendImage').prop("src", self.legendUrl);
                        } catch (err) {
                            // legend return a 404 or something similar = should not happen
                        }
                    }
                    // if currentProjection does not equal the projection in mapOptions, we need
                    // to change the projection and so need to call setProjection; 
                    // ALSO, if currenProjection is NOT EPSG:4326, need to call setProjection -
                    // this should not be required BUT an issue with getting OpenLayers to refresh
                    // properly after a reproject requires some research
                    if (!self.options.multiLayer && !self.options.animation && (self.mapOptions.projection !== self.currentProjection ||
                            self.mapHasBeenReProjected)) {
                        self.setProjection(self.mapOptions.projection);
                    }
                } else {
                    //error handle here
                    var overlayFrame = $("#" + self.options.containerId + 'Map').closest(".overlayImageFrame")
                    $('<div class="errorMessagePlot" id=error-' + self.options.containerId +
                        '>Sorry. We could not produce a plot. Please <a href="javascript:void(0)" id="sendFeedback-' +
                        self.options.containerId + '" onclick="session.sendFeedback(event, \'pageSelection\')">report the error</a>. ' +
                        '<span class="closeErrorButton" id="closeError-' + self.options.containerId + '"></span>' +
                        '</div>').insertBefore(overlayFrame);
                    $(".closeErrorButton").click(function (e) {
                        $("#error-" + e.target.id.substring(11)).remove();
                    });
                }

                // reset status and hide the dialog
                var statusContainer = $('.clear, .paletteRefreshContainer');
                var replotButton = statusContainer.find('.replot');
                var resetButton = statusContainer.find('.reset');
                var dialogContainer = $('.dialogContainer');
                var closeButton = $('.container-close');
                replotButton.css('color', 'inherit');
                replotButton.text('Re-Plot');
                replotButton.prop('disabled', false);
                replotButton.removeClass('disabledElement');
                resetButton.removeClass('disabledElement');
                dialogContainer.removeClass('disabledElement');
                closeButton.removeClass('disabledElement');
                replotButton.css('cursor', 'pointer');
                $('img.replotSpinner').remove();
                $("body").css("cursor", "default");
                self.dialog.hide();

            } else {
                // server is not done, so go around again passing only the base URL - passing
                // the options again will create a new request
                updateTimeout = setTimeout((self.doUpdatePoll).bind(self, baseUrl), 500);
            }
        }, function () {
            // fail only once - there are no retries here
            console.log("Map update request failed");
        });

};

giovanni.widget.OverlayMap.MapLayerOptions.prototype.setProjection = function (proj) {
    var newProjection = ol.proj.get(proj);
    var newProjExtent;
    var center;
    if (proj === 'EPSG:4326') {
        newProjExtent = [-360, -90, 360, 90];
        center = giovanni.widget.OverlayMap.EQCenter;
    } else {
        newProjExtent = newProjection.getExtent();
        center = [0, 0];
    }
    // save old center
    var currentViewCenter = this.options.map.getView().getCenter();
    //var currentProj = this.currentProjection;
    // create new view with updated projection extents, etc.
    var newView = new ol.View({
        projection: newProjection,
        center: this.currentProjection === proj ? currentViewCenter : center,
        zoom: 1,
        extent: newProjExtent
    });

    var layersToAdd = [];
    var layersToRemove = [];
    // grab and scrub the layer bounding box
    var bbox = this.options.layer.bbox && this.options.layer.bbox != "" ? this.options.layer.bbox : newProjExtent;
    bbox = giovanni.util.scrubBbox(bbox);

    var map = this.options.map;
    // set the new view on the map 
    map.setView(newView);
    // update the map layers as necessary 
    map.getLayers().forEach(function (layer) {
        // to ensure that supporting layers (grid, coastlines, etc) would be 
        // redrawn when changing from same type of projection (eg. North to South pole)
        var source = layer.getSource();
        var params = source.getParams();
        params.t = new Date().getMilliseconds();
        source.updateParams(params);

        // use a +/-360 extent for the layer (not the tile)
        // when the proj is cylindrical; otherwise, use what
        // the projection specifies
        var lyrExtent = proj === 'EPSG:4326' ? [-360, -90, 360, 90] : newProjExtent;

        if (params.FORMAT) {
            var zIndex = layer.getZIndex();
            // use a +/-180 extent or whatever the projection
            // specifies for the tile
            var tileGrid = ol.tilegrid.createXYZ({
                extent: proj === 'EPSG:4326' ? [-180, -90, 180, 90] : newProjExtent,
                tileSize: 512
            });
            var olLayer = new ol.layer.Tile({
                source: new ol.source.TileWMS({
                    url: "./daac-bin/agmap.pl",
                    visible: false,
                    params: {
                        LAYERS: params.LAYERS,
                        FORMAT: params.FORMAT,
                        MAPFILE: params.MAPFILE,
                        RAND: giovanni.util.getRandom(),
                        RESULT: params.RESULT,
                        RESULTSET: params.RESULTSET,
                        SESSION: params.SESSION,
                        TRANSPARENT: params.TRANSPARENT,
                        sld: params.sld
                    },
                    tileGrid: tileGrid
                }),
                zIndex: zIndex,
                extent: lyrExtent
            });
            layersToRemove.push(layer);
            layersToAdd.push(olLayer);
        } else {
            params.t = new Date().getMilliseconds();
            source.updateParams(params);
            layer.setZIndex(1);
            layer.setExtent(lyrExtent);
        }
    });

    layersToRemove.forEach(function (layer) {
        map.removeLayer(layer);
    });

    layersToAdd.forEach(function (layer) {
        map.addLayer(layer);
    });

    // since we created a new view and blew the old one away, add the resolution
    // change listener back in
    map.getView().on('change:resolution', giovanni.util.handleMapResolutionChange, {
        'map': map,
        'proj': proj
    });

    // center map and set zoom level as necessary
    if (proj === 'EPSG:4326') {
        if (giovanni.util.isDoubleGlobe(bbox)) {
            bbox[0] = -180;
            bbox[2] = 180;
        }
        map.getView().fit(bbox, map.getSize());
    } else {
        if (giovanni.util.isGlobal(bbox)) {
            map.getView().dispatchEvent('change:resolution');
        } else {
            if (this.currentProjection !== proj) {
                map.getView().setCenter(ol.proj.transform(currentViewCenter, 'EPSG:4326', newProjection));
            }
            var dist = giovanni.util.getCartesianDistance(bbox)[0];
            if (dist <= 2) {
                map.getView().setZoom(7);
            } else if (dist > 2 && dist <= 5) {
                map.getView().setZoom(6);
            } else if (dist > 5 && dist <= 10) {
                map.getView().setZoom(5);
            } else if (dist > 10 && dist <= 40) {
                map.getView().setZoom(4);
            } else if (dist > 40 && dist <= 80) {
                map.getView().setZoom(3);
            } else if (dist > 80 && dist <= 150) {
                map.getView().setZoom(2);
            } else if (dist > 150 && dist < 200) {
                map.getView().setZoom(1);
            }
        }
    }
    this.currentProjection = proj;
    this.mapHasBeenReProjected = true;
};

giovanni.widget.OverlayMap.MapLayerOptions.prototype.reset = function () {
    this.el.find('input[name="' + this.id + 'RangeMin"]').val(this.defaults.min);
    this.el.find('input[name="' + this.id + 'RangeMax"]').val(this.defaults.max);
    this.el.find('input[name="' + this.id + 'PaletteChoice"][value="' + this.defaults.paletteName + '"]').prop('checked', true);
    this.el.find('input[name="' + this.id + 'SmoothChoice"][value="' + this.defaults.smooth + '"]').prop('checked', true);
    this.el.find('input[name="' + this.id + 'ScaleChoice"][value="' + this.defaults.scale + '"]').prop('checked', true);
    this.el.find('input[name="' + this.id + 'ProjectionChoice"][value="' + this.defaults.projection + '"]').prop('checked', true);

    $.extend(true, this.userSelections, this.defaults);

    this.replot(this.userSelections);
};

giovanni.widget.OverlayMap.MapLayerOptions.prototype.validateOptionSelections = function (selections) {
    var err = '';

    var min = parseFloat(selections.min);
    var max = parseFloat(selections.max);

    if (selections.min === '' || selections.max === '') {
        err = 'Please fill in all fields';
    } else if (isNaN(min) || isNaN(max)) {
        err = 'Min/max values must be numbers';
    } else if (min > max) {
        err = 'The maximum value must be greater than the minimum value';
    } else if (selections.scale === 'log' && (min <= 0 || max <= 0)) {
        err = "Log scale values must be greater than 0";
    }

    // set error message on UI
    $('.statusError').text(err);
    if (err === '') {
        $('.replot').prop("disabled", false);
        $('.replot').css("color", "black");
    } else {
        $('.replot').prop("disabled", true);
        $('.replot').css("color", "#888");
    }

    return err;
};

giovanni.widget.OverlayMap.MapLayerOptions.prototype.getSldUrl = function (paletteName) {
    var url = "";
    var slds = this.options.layer.variable_sld;

    if (this.paletteList) {
        slds = slds.concat(this.paletteList);
    }

    for (var i = 0; slds && i < slds.length; i++) {
        if (slds[i].label == paletteName) {
            url = slds[i].url;
            break;
        }
    }

    return url;
};

giovanni.widget.OverlayMap.ContourLayerOptions = function (options) {
    var self = this;
    this.id = new Date();
    this.options = options;
    this.selectOptions = {
        thickness: [1, 2, 3, 4, 5],
        style: ['solid', 'dotted', 'dashed']
    };
    this.defaults = {
        rgb: [0, 0, 255],
        thickness: 1,
        style: 'solid',
        min: this.options.layer.min,
        max: this.options.layer.max,
        interval: this.options.layer.intervalcount
    };
    this.plottedSelections = $.extend(true, {}, this.defaults);
    this.userSelections = $.extend(true, {}, this.defaults);
    this.serverColor = [0, 0, 255];

    ol.source.TileImage.defaultTileLoadFunction = this.options.olLayer.getSource().getTileLoadFunction();

    this._render();
};

giovanni.widget.OverlayMap.ContourLayerOptions.prototype.setDialog = function (dialog) {
    this.dialog = dialog;
}

giovanni.widget.OverlayMap.ContourLayerOptions.prototype._render = function () {
    var self = this;
    self.el = $('<div>\
    <div>\
      <div class="mapOptionsHeader">Data Range</div>\
      <div class="mapOptionsBody">\
        <div class="mapOptionsField"><input class="minthumb" name="' + self.id + 'Min" value="' + this.userSelections.min + '"></input>&nbsp;Minimum</div>\
        <div class="mapOptionsField"><input class="maxthumb" name="' + self.id + 'Max" value="' + this.userSelections.max + '"></input>&nbsp;Maximum</div>\
      </div>\
    </div>\
    <div>\
      <div class="mapOptionsHeader">Interval</div>\
      <div class="mapOptionsBody"><input name="' + self.id + 'IntervalCount" value="' + this.userSelections.interval + '"></input></div>\
    </div>\
    <div>\
      <div class="mapOptionsHeader">Color</div>\
      <div class="mapOptionsBody"><input class="jscolor" name="' + self.id + 'rgb"></input></div>\
    </div>\
    <div>\
      <div class="mapOptionsHeader">Thickness</div>\
      <div class="mapOptionsBody">\
        <select name="' + self.id + 'Thickness">' +
        self.selectOptions.thickness.map(function (option) {
            return '<option ' + (self.userSelections.thickness === option ? 'selected' : '') + ' value="' + option + '">' + option + 'x</option>';
        }).join('') +
        '</select>\
      </div>\
    </div>\
    <div>\
      <div class="mapOptionsHeader">Line Style</divl>\
      <div class="mapOptionsBody">\
        <select name="' + self.id + 'Style">' +
        self.selectOptions.style.map(function (option) {
            return '<option ' + (self.userSelections.style === option ? 'selected' : '') + ' value="' + option + '">' + option + '</option>';
        }).join('') +
        '</select>\
      </div>\
    </div>\
  </div>');

    new jscolor(self.el.find('.jscolor')[0], {
        zIndex: 10001,
        rgb: self.userSelections.rgb
    });

    self.el.find('input, select').change(function (e) {
        var $target = $(e.target);
        var name = $target.attr('name').replace(self.id.toString(), '');
        name = name[0].toLowerCase() + name.slice(1);

        self.userSelections[name] = $target.val();

        if (name === 'rgb') {
            self.userSelections[name] = e.target._jscLinkedInstance.rgb;
        }

        self.options.onSelectionChange(self.userSelections, self.validateOptionSelections(self.selections));
    });
};

giovanni.widget.OverlayMap.ContourLayerOptions.prototype.validateOptionSelections = function (selections) {

};

giovanni.widget.OverlayMap.ContourLayerOptions.prototype._updateContourColorer = function () {
    var self = this;

    self.options.olLayer.getSource().setTileLoadFunction(function (imageTile, src) {
        var image = new Image();
        image.crossOrigin = "anonymous";

        image.onload = function () {
            var canvas = document.createElement('canvas');
            canvas.width = image.width;
            canvas.height = image.height

            var gl = canvas.getContext("webgl");
            var vertexShader = '\
        attribute vec2 a_position;\
        attribute vec2 a_texCoord;\
        uniform vec2 u_resolution;\
        varying vec2 v_texCoord;\
        void main() {\
          vec2 zeroToOne = a_position / u_resolution;\
          vec2 zeroToTwo = zeroToOne * 2.0;\
          vec2 clipSpace = zeroToTwo - 1.0;\
          gl_Position = vec4(clipSpace * vec2(1, -1), 0, 1);\
          v_texCoord = a_texCoord;\
        }';
            var fragmentShader = '\
        precision mediump float;\
        uniform sampler2D u_image;\
        uniform vec4 u_color;\
        uniform vec4 u_possibleColor;\
        varying vec2 v_texCoord;\
        void main() {\
          vec4 texColor = texture2D(u_image, v_texCoord);\
          gl_FragColor = texColor;\
          if ((u_possibleColor == texColor) || (texColor.a > 0.0 && texColor.b > texColor.r && texColor.b > texColor.g)) {\
            gl_FragColor = u_color;\
          }\
        }';
            vertexShader = self.createShader(gl, gl.VERTEX_SHADER, vertexShader);
            fragmentShader = self.createShader(gl, gl.FRAGMENT_SHADER, fragmentShader);

            var program = gl.createProgram();

            gl.attachShader(program, vertexShader);
            gl.attachShader(program, fragmentShader);

            gl.linkProgram(program);
            var success = gl.getProgramParameter(program, gl.LINK_STATUS);
            if (!success) {
                // something went wrong with the link
                throw ("program filed to link:" + gl.getProgramInfoLog(program));
            }

            gl.useProgram(program);

            var positionLocation = gl.getAttribLocation(program, "a_position");
            var texCoordLocation = gl.getAttribLocation(program, "a_texCoord");

            // provide texture coordinates for the rectangle.
            var texCoordBuffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, texCoordBuffer);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
                0.0, 0.0,
                1.0, 0.0,
                0.0, 1.0,
                0.0, 1.0,
                1.0, 0.0,
                1.0, 1.0]), gl.STATIC_DRAW);
            gl.enableVertexAttribArray(texCoordLocation);
            gl.vertexAttribPointer(texCoordLocation, 2, gl.FLOAT, false, 0, 0);

            // Create a texture.
            var texture = gl.createTexture();
            gl.bindTexture(gl.TEXTURE_2D, texture);

            // Set the parameters so we can render any size image.
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

            // Upload the image into the texture.
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);

            var resolutionLocation = gl.getUniformLocation(program, 'u_resolution');
            gl.uniform2f(resolutionLocation, image.width, image.height);

            var possibleColorLocation = gl.getUniformLocation(program, 'u_possibleColor');
            gl.uniform4f(possibleColorLocation, self.serverColor[0], self.serverColor[1], self.serverColor[2], 1);

            buffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
            gl.enableVertexAttribArray(positionLocation);
            gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);


            var x1 = 0;
            var x2 = image.width;
            var y1 = 0;
            var y2 = image.height;
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([x1, y1, x2, y1, x1, y2, x1, y2, x2, y1, x2, y2]), gl.STATIC_DRAW);


            var uColor = gl.getUniformLocation(program, 'u_color');
            gl.uniform4f(uColor,
                self.userSelections.rgb[0] / 255,
                self.userSelections.rgb[1] / 255,
                self.userSelections.rgb[2] / 255,
                1.0);

            gl.drawArrays(gl.TRIANGLES, 0, 6);

            ol.source.TileImage.defaultTileLoadFunction.apply(null, [imageTile, canvas.toDataURL()]);
        };

        image.src = src;
    });
};

giovanni.widget.OverlayMap.ContourLayerOptions.prototype.replot = function (selections, force) {
    selections = selections || this.userSelections;
    selections = this.userSelections || this.defaults;

    var self = this;
    var layer = self.options.layer;
    var errorStr = this.validateOptionSelections(selections || this.userSelections);

    if (errorStr) {
        return $.Deferred()
            .reject(errorStr)
            .promise();
    } else {
        $('.statusError').text("");
        // build request url
        var url = "./daac-bin/service_manager.pl?";
        url = url + "session=" + encodeURIComponent(layer.session);
        url = url + "&resultset=" + encodeURIComponent(layer.resultset);
        url = url + "&result=" + encodeURIComponent(layer.result);
        url = url + "&random=" + Math.floor(Math.random() * 100000000);
        // build contour map options
        var int_rgb = selections.rgb.map(function (c) {
            return Math.round(c);
        });
        var params = {
            name: layer.name,
            datafile: layer.datafile,
            min: selections.min ? selections.min : 0,
            max: selections.max ? selections.max : 100,
            contourinterval: selections.intervalCount,
            contoursize: selections.thickness,
            contourlinestyle: selections.style,
            contourcolor: int_rgb.join('+')
        };

        var shouldUpdate = Object.keys(selections).some(function (key) {
            return selections[key] !== self.plottedSelections[key];
        });

        self.plottedSelections = $.extend(true, {}, selections);

        if (shouldUpdate) {
            // create some status
            $("body").css("cursor", "progress");
            var statusContainer = $('.clear, .paletteRefreshContainer');
            statusContainer.prepend($('<img class="replotSpinner" style="float:left;" src="img/progress.gif"/>'));
            var replotButton = statusContainer.find('.replot');
            var resetButton = statusContainer.find('.reset');
            var dialogContainer = $('.dialogContainer');
            var closeButton = $('.container-close');
            replotButton.prop('disabled', true);
            replotButton.addClass('disabledElement');
            resetButton.addClass('disabledElement');
            dialogContainer.addClass('disabledElement');
            closeButton.addClass('disabledElement');
            replotButton.text('Plotting...');
            replotButton.css('cursor', 'progress');
            // initiate request
            self.doUpdatePoll(url, params, true);
        } else {
            return $.Deferred()
                .resolve()
                .promise();
        }
    }
};

/**
 *  Handling polling and for asynchronous contour updates
 *  
 *  @author K. Bryant
 *  @params {URL, Object}
 *  @returns {}
 **/
giovanni.widget.OverlayMap.ContourLayerOptions.prototype.doUpdatePoll = function (url, params, initial) {
    // request code
    var code;
    // request status
    var complete;
    var self = this;
    // layer reference - need this when polling is done
    var layer = self.options.layer;
    // timeout reference
    var updateTimeout;
    // save the baseUrl (we'll use it for polling)
    var baseUrl = url;
    // create the initial URL for updating the map
    var updateUrl = initial ? baseUrl + "&options=" + encodeURIComponent(JSON.stringify([{
        options: params,
        id: layer.plotId
    }])) : baseUrl;
    //  make the request and do the work when the request completes
    $.get(updateUrl)
        .then(function (data) {
            // each time through, grab code and percent complete to see if the server is done 
            code = $(data).find("session > resultset > result > status > code").text();
            complete = $(data).find("session > resultset > result > status > percentComplete").text();
            // check for request completion
            if (code == 0 && complete == 100) {
                // clear the timeout so we don't poll again
                clearTimeout(updateTimeout);
                // update the contour layer
                self.options.olLayer.getSource().updateParams($.extend(true, {}, {
                    LAYERS: params.LAYERS,
                    FORMAT: params.FORMAT,
                    TRANSPARENT: params.TRANSPARENT,
                    sld: params.sld,
                    MAPFILE: params.MAPFILE,
                    SESSION: params.SESSION,
                    RESULTSET: params.RESULTSET,
                    RESULT: params.RESULT,
                    RAND: giovanni.util.getRandom()
                }));
                // reset status and hide container
                var statusContainer = $('.clear, .paletteRefreshContainer');
                var replotButton = statusContainer.find('.replot');
                var resetButton = statusContainer.find('.reset');
                var dialogContainer = $('.dialogContainer');
                var closeButton = $('.container-close');
                replotButton.css('color', 'inherit');
                replotButton.text('Re-Plot');
                replotButton.prop('disabled', false);
                replotButton.removeClass('disabledElement');
                resetButton.removeClass('disabledElement');
                dialogContainer.removeClass('disabledElement');
                closeButton.removeClass('disabledElement');
                replotButton.css('cursor', 'pointer');
                $('img.replotSpinner').remove();
                $("body").css("cursor", "default");
                self.dialog.hide();
            } else {
                // server is not done, so go around again passing only the base URL - passing
                // the options again will create a new request
                updateTimeout = setTimeout((self.doUpdatePoll).bind(self, baseUrl, params), 500);
            }
        }, function () {
            //fail only once - there are no retries here
            console.log("Contour map update request failed");
        });
};

giovanni.widget.OverlayMap.ContourLayerOptions.prototype.setProjection = function (proj) {
    var newProjection = ol.proj.get(proj);
    var newProjExtent;
    var center;
    if (proj === 'EPSG:4326') {
        newProjExtent = [-360, -90, 360, 90];
        center = giovanni.widget.OverlayMap.EQCenter;
    } else {
        newProjExtent = newProjection.getExtent();
        center = [0, 0];
    }
    var newView = new ol.View({
        projection: newProjection,
        center: center,
        zoom: 2,
        extent: newProjExtent
    });

    var map = this.options.map;
    var layersToAdd = [];
    var layersToRemove = [];

    map.getLayers().forEach(function (layer) {
        // to ensure that supporting layers (grid, coastlines, etc) would be 
        // redrawn when changing from same type of projection (eg. North to South pole)
        var source = layer.getSource();
        var params = source.getParams();
        if (params.LAYERS.indexOf('contour') > -1) {
            var zIndex = layer.getZIndex();
            var tileGrid = ol.tilegrid.createXYZ({
                extent: newProjExtent,
                tileSize: 512
            });
            var olLayer = new ol.layer.Tile({
                source: new ol.source.TileWMS({
                    url: "./daac-bin/agmap.pl",
                    visible: false,
                    params: {
                        LAYERS: params.LAYERS,
                        FORMAT: params.FORMAT,
                        TRANSPARENT: params.TRANSPARENT,
                        sld: params.sld,
                        MAPFILE: params.MAPFILE,
                        SESSION: params.SESSION,
                        RESULTSET: params.RESULTSET,
                        RESULT: params.RESULT,
                        RAND: giovanni.util.getRandom()
                    },
                    tileGrid: tileGrid
                }),
                zIndex: zIndex
            });
            layersToRemove.push(layer);
            layersToAdd.push(olLayer);
        }
    });
    layersToRemove.forEach(function (layer) {
        map.removeLayer(layer);
    })
    layersToAdd.forEach(function (layer) {
        map.addLayer(layer);
    })
    this.options.map.setView(newView);
}

giovanni.widget.OverlayMap.ContourLayerOptions.prototype.reset = function (selections) {
    this.el.find('input[name="' + this.id + 'Min"]').val(this.defaults.min);
    this.el.find('input[name="' + this.id + 'Max"]').val(this.defaults.max);
    this.el.find('input[name="' + this.id + 'IntervalCount"]').val(this.defaults.intervalCount);
    this.el.find('select[name="' + this.id + 'Thickness"]').val(this.defaults.thickness);
    this.el.find('select[name="' + this.id + 'Style"]').val(this.defaults.style);
    this.el.find('input[name="' + this.id + 'rgb"]')[0]._jscLinkedInstance.fromRGB(this.defaults.rgb[0], this.defaults.rgb[1], this.defaults.rgb[2]);

    $.extend(true, this.userSelections, this.defaults);

    this.replot(this.userSelections);
};

giovanni.widget.OverlayMap.ContourLayerOptions.prototype.createShader = function (gl, type, source) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    var success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (!success) {
        // Something went wrong during compilation; get the error
        throw "could not compile shader:" + gl.getShaderInfoLog(shader);
    }

    return shader;
};

giovanni.widget.OverlayMap.DownloadOptions = function (options) {
    var self = this;

    self.options = options || {};

    self.bboxA = self.options.bboxA;
    self.plotData = self.options.plotData;
    self.layerGroups = self.options.layerGroups;
    self.target = self.options.target;
    self.rendered = self.options.rendered;
    self.containerId = self.options.containerId;
    self.overlays = self.options.overlays;
    self.sOverlayConfig = self.options.sOverlayConfig;

    // handle login events
    // (uncomment next 3 lines to require login in order to enable download of overlay maps)
    //if (login) {
    //    login.loginEvent.subscribe(this.handleLoginEvent, this);
    //}

    self.menuItems = [
        {
            'name': 'GEOTIFF',
            'label': 'GeoTIFF'
        },
        {
            'name': 'KMZ',
            'label': 'KMZ'
        },
        {
            'name': 'PNG',
            'label': 'PNG'
        }
    ];
    self.menuItemObjects = [];

    self.el = $('<div class="map-download">\
    <h3>\
      <button class="downloadButton">\
        <i class="fa fa-download"></i>\
        Download\
        <i class="fa fa-caret-down"></i>\
      </button>\
    </h3>\
    <ul class="download-menu"></ul>\
  </div>');

    self.el.find('h3').click(function () {
        self.el.toggleClass('map-download-active');
    });

    if (!self.rendered) {
        self.options.frame.find('.control-panel').prepend(self.el[0]);
        self._render();
    }

};

giovanni.widget.OverlayMap.DownloadOptions.prototype.setOverlays = function (overlays) {
    this.overlays = overlays;
}

giovanni.widget.OverlayMap.DownloadOptions.prototype._render = function () {
    if (!this.rendered) {
        this.rendered = true;
        for (var i = 0; i < this.menuItems.length; i++) {
            this.addMenu(this.menuItems[i]);
        }
        // Login button is another download menu item, but special
        // (uncomment next line to require login in order to enable download of overlay maps)
        //if (login) {
        //    this.addLogin({'name': 'login', 'label': 'Login to enable download options'});
        //}
    }
};

giovanni.widget.OverlayMap.DownloadOptions.prototype.addMenu = function (config) {
    var menuItem = new giovanni.widget.OverlayMap.DownloadMenuItem({
        containerId: this.containerId,
        frame: this.options.frame,
        name: config.name,
        label: config.label,
        target: this.el,
        mapConfig: {
            bboxA: this.bboxA,
            plotData: this.plotData,
            layerGroups: this.layerGroups
        },
        onClick: this._handleMenuClick.bind(this)
    });
    this.menuItemObjects[config.name] = menuItem;
}

giovanni.widget.OverlayMap.DownloadOptions.prototype.addLogin = function (config) {
    // Login button is another download menu item, but with checkLogin instead of a map 
    var menuItem = new giovanni.widget.OverlayMap.DownloadMenuLoginItem({
        containerId: this.containerId,
        frame: this.options.frame,
        name: config.name,
        label: config.label,
        target: this.el,
        onClick: login.checkLogin.bind(login)
    });
}

giovanni.widget.OverlayMap.DownloadOptions.prototype.getMenuItem = function (name) {
    return this.menuItemObjects[name];
}

giovanni.widget.OverlayMap.DownloadOptions.prototype._handleMenuClick = function (options) {
    this.download(null, options);
};

/*
 * If logged in, enable download capability, otherwise disable it and provide button to log in
 */
giovanni.widget.OverlayMap.DownloadOptions.prototype.handleLoginEvent = function (type, args, obj) {
    if (login && login.isLoggedIn) {
        // Once logged in, enable all menu buttons
        obj.el.find('.download-menu-item').removeClass("disabledElement");
        // But hide login button
        obj.el.find('button[name="login"]').css("display", "none");
    } else {
        // When logged out, disable all menu buttons
        obj.el.find('.download-menu-item').addClass("disabledElement");
        // But show and enable login button
        obj.el.find('.download-menu-login').removeClass("disabledElement");
        obj.el.find('button[name="login"]').css("display", "");
    }
};

giovanni.widget.OverlayMap.DownloadMenuItem = function (config) {
    this.config = config;
    this._render();
};

giovanni.widget.OverlayMap.DownloadMenuItem.prototype._render = function () {
    var self = this;
    var config = this.config;

    self.el = $('<li class="download-menu-item">\
     <button name="' + config.name + '">' + config.label +
        '</button></li>');

    self.el.find('button').click(function () {
        config.onClick(self);
    });

    $(self.config.frame).find('.download-menu').append(self.el[0]);
};

giovanni.widget.OverlayMap.DownloadMenuItem.prototype.getConfig = function () {
    return this.config;
}

giovanni.widget.OverlayMap.DownloadMenuLoginItem = function (config) {
    this.config = config;
    this._render();
};

giovanni.widget.OverlayMap.DownloadMenuLoginItem.prototype._render = function () {
    var self = this;
    var config = this.config;

    self.el = $('<li class="download-menu-item download-menu-login">\
     <button name="' + config.name + '"' + '>' + config.label +
        '</button></li>');

    self.el.find('button').click(function () {
        config.onClick(self);
    });
    if (login && login.isLoggedIn) {
        // If logged in, do not display login button
        self.el.find('button').css("display", "none");
    };

    $(self.config.frame).find('.download-menu').append(self.el[0]);
};

giovanni.widget.OverlayMap.DownloadOptions.prototype.download = function (evt, options) {
    // gather the export/download data that will be posted 
    // (we do the POST because there are a lot of these data)
    var postData = this._getExportData(options);
    // create the form attributes
    var url = './daac-bin/downloadMap.pl?';
    var form = document.createElement("form");
    form.setAttribute("action", url);
    form.setAttribute("method", "POST");
    //form.setAttribute("target","_blank");
    form.style.display = "none";
    for (var property in postData) {
        if (postData.hasOwnProperty(property)) {
            var value = postData[property];
            if (value instanceof Array) {
                for (var i = 0; i < value.length; i++) {
                    var elem = document.createElement("input");
                    elem.setAttribute("type", "hidden");
                    elem.setAttribute("name", property);
                    elem.setAttribute("value", value[i]);
                    form.appendChild(elem);
                }
            } else {
                var elem = document.createElement("input");
                elem.setAttribute("type", "hidden");
                elem.setAttribute("name", property);
                elem.setAttribute("value", value);
                form.appendChild(elem);
            }
        }
    }
    // append the form
    document.body.appendChild(form);
    // submit the form
    form.submit();
    // remove the form since we don't use it after the POST
    document.body.removeChild(form);
}

giovanni.widget.OverlayMap.DownloadOptions.prototype._getExportData = function (options) {
    // config is different depending on where the request comes from (this class or ResultView)  
    var config = {
        bboxA: this.bboxA,
        plotData: this.plotData,
        layerGroups: this.layerGroups
    };
    // constrain the download bbox
    if (config.bboxA[0] === -360) config.bboxA[0] = -180;
    if (config.bboxA[2] === 360) config.bboxA[2] = 180;
    // if the request comes from ResultView, the 'view' is 'downloads'
    var view = options.view ? options.view : "";
    // array to hold the post data
    var postData = new Array();
    // set geo image width/height using the bbox array
    var d = giovanni.util.getCartesianDistance(config.bboxA);
    var bboxDownload = encodeURIComponent(config.bboxA.toString());
    var geoHeight = d[2];
    var geoWidth = d[1];
    var width = 0;
    var height = 0;
    if (geoWidth > geoHeight) {
        width = 1024;
        height = Math.floor((geoHeight * 1024) / geoWidth);
    } else if (geoHeight >= geoWidth) {
        height = 512;
        width = Math.floor((geoWidth * 512) / geoHeight);
    }
    var wmsUrl;
    var groupName;
    // format config is in a different spot depending on the request origin
    var format = options.name ? options.name : options.config.name;
    var selectedLayer;
    var userSelections;
    var dataUrls = [];
    // layerGroups is in a different spot depending on the request origin
    var layerGroups = config.mapConfig ? config.mapConfig.layerGroups : config.layerGroups;
    var name;
    var type;
    var title = "";
    var caption = "";
    var self = this;
    if (format === 'PNG') {
        projCode = self.options.map.getView().getProjection().getCode();
        thisProj = giovanni.widget.OverlayMap.projections.find(function (x) {
            return x.code === projCode
        });
        projBbox = self.options.map.getView().calculateExtent(self.options.map.getSize());
        // constrain overly large projection bounding boxes
        if (projBbox[0] < thisProj.extent[0]) {
            projBbox[0] = thisProj.extent[0]
        }
        if (projBbox[1] < thisProj.extent[1]) {
            projBbox[1] = thisProj.extent[1]
        }
        if (projBbox[2] > thisProj.extent[2]) {
            projBbox[2] = thisProj.extent[2]
        }
        if (projBbox[3] > thisProj.extent[3]) {
            projBbox[3] = thisProj.extent[3]
        }
        // calculate relative width and height
        relWidth = Math.abs(projBbox[2] - projBbox[0]);
        relHeight = Math.abs(projBbox[3] - projBbox[1]);
        // TODO: We can move projection height and width setting to config file for projections and reduce this code. 

        if (projCode !== 'EPSG:4326') {
            if (relWidth > relHeight) {
                projWidth = 768;
                projHeight = Math.floor((relHeight * 768) / relWidth);
            } else {
                projHeight = 768;
                projWidth = Math.floor((relWidth * 768) / relHeight);
            }
        } else {
            projWidth = width;
            projHeight = height;
            projBbox = config.bboxA;
        }
    } else {
        projWidth = width;
        projCode = 'EPSG:4326';
        projHeight = height;
        projBbox = bboxDownload;
    };
    // sort the layerGroups so we get a consistent
    // order between titles on the UI and titles on the download
    var layerOrder = ['vector', 'contour', 'map'];
    layerGroups = layerGroups.sort(function (a, b) {
        return layerOrder.indexOf(a.name) - layerOrder.indexOf(b.name);
    });
    // loop through the layer groups
    for (var lg in layerGroups) {
        name = layerGroups[lg].name;
        selectedLayer = layerGroups[lg].currentLayer.options.layer;
        if (layerGroups[lg].visible && layerGroups[lg].currentLayer.olLayer.getVisible()) {
            // add data urls
            userSelections = layerGroups[lg].currentLayer.layerOptions ?
                layerGroups[lg].currentLayer.layerOptions.optionsBody.userSelections : undefined;
            wmsUrl = './daac-bin/agmap.pl' + "?" +
                'LAYERS=' + encodeURIComponent(selectedLayer.name) +
                ((userSelections && userSelections.paletteName) ?
                    '&SLD=' + encodeURIComponent(layerGroups[lg].currentLayer.layerOptions.optionsBody.getSldUrl(userSelections.paletteName)) : "") +
                '&MAPFILE=' + encodeURIComponent(selectedLayer.mapfile) +
                '&DATAFILE=' + encodeURIComponent(selectedLayer.datafile) +
                '&SESSION=' + encodeURIComponent(selectedLayer.session) +
                '&RESULTSET=' + encodeURIComponent(selectedLayer.resultset) +
                '&RESULT=' + encodeURIComponent(selectedLayer.result) +
                (name === 'map' ? '&BGCOLOR=0x7b7b91' : '') +
                '&FORMAT=image%2Fpng&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap' +
                '&TRANSPARENT=TRUE' +
                '&SRS=' + projCode +
                '&WIDTH=' + projWidth + '&HEIGHT=' + projHeight +
                '&BBOX=' + projBbox;
            dataUrls.push(wmsUrl);
            // set title, subtitle, caption
            if (this.options.frame.find('.plotMapTitle_' + name).is(':visible') ||
                view === 'downloads') {
                if (layerGroups.length > 1) {
                    title += (name === 'vector' ? '+VECTOR:' : "");
                    title += (name === 'map' ? '+SHADED:' : "");
                    title += (name === 'contour' ? '+CONTOUR:' : "");
                    title += selectedLayer.title + " " + selectedLayer.subTitle;
                } else {
                    title += selectedLayer.title;
                    postData['subtitle'] = selectedLayer.subTitle;
                }
            }
            if (this.options.frame.find('.plotOverlayMapCaption').is(':visible')||
                view === 'downloads') {
                if (selectedLayer.caption) {
                   if (layerGroups.length > 1) {
                      caption += (name === 'vector'  ? '+VECTOR CAPTION:' : "");
                      caption += (name === 'map'     ? '+SHADED CAPTION:' : "");
                      caption += (name === 'contour' ? '+CONTOUR CAPTION:' : "");
                   }
                  caption += selectedLayer.caption ;
                }
            }
        }
    }
    // stuff the array into the 'data' element
    postData['data'] = dataUrls;

    // if the request is NOT 'GEOTIFF', set up overlay data
    if (format !== 'GEOTIFF' && format !== 'KMZ') {
        var overlays = [];
        self.options.map.getLayers().forEach(function (layer) {
            var source = layer.getSource();
            var layerName = source.getParams().LAYERS;
            var test = layerName;
            // test for grid layer; remove grid numbers and 
            // replace with those appropriate to the user bbox (projBbox)
            if (test.indexOf('grid') > -1) {
                test = test.replace(/\d-?\d?/g, "");
                // set the download grid value since we don't honor the zoom level
                // seen on the map
                layerName = test + giovanni.util.getGridIncrement(undefined, projCode, projBbox);
            }
            // take first string only (for countries,us_states)
            if (test.indexOf(",") > -1) {
                test = test.substring(0, test.indexOf(","));
            }
            if (layer.getVisible() && self.sOverlayConfig.join().indexOf(test) > -1) {
                overlays.push(layerName);
            }
        });
        if (overlays.length > 0) {
            var overlayUrl = 'https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc?' +
                'LAYERS=' + overlays.join() + '&FORMAT=image%2Fpng&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=' +
                '&SRS=' + projCode + '&WIDTH=' + projWidth + '&HEIGHT=' + projHeight +
                '&BBOX=' + projBbox;
            postData['overlay'] = overlayUrl;
        }
    }
    postData['title'] = title;
    postData['caption'] = caption;
    postData['format'] = format ? format : 'TIFF';
    postData['legend'] = $('.legend').is(":visible") ? 'on' : 'off';
    return postData;
}

giovanni.widget.OverlayMap.Decorations = function (options) {
    var self = this;
    self.options = options;

    self.el = $('<div id="decorations">\
      <h4>\
        <i class="fa fa-check"/>\
        <button class="button-header">\
          Decorations\
        </button>\
      </h4>\
      <ul class="layer-group">\
        <li><label class="checkboxLabel"><input class="titleToggle" name="title" type="checkbox" checked="checked">Title, Sub-title</input></label><li>\
        <li><label class="checkboxLabel"><input class="captionToggle" name="caption" type="checkbox" checked="checked">Caption</input></label><li>\
        <li><label class="checkboxLabel"><input class="legendToggle" name="legend" type="checkbox" checked="checked">Legend</input></label><li>\
      </ul>\
    </div>');

    self.el.find('.button-header').click(function () {
        self._handleHeaderClick(self);
    });

    self.el.find('input').click(function () {
        self.show(self);
    });
};

giovanni.widget.OverlayMap.Decorations.prototype._handleHeaderClick = function (self) {
    // Checks for display:[none|block], ignores visible:[true|false]
    var toggle = self.el.find('.fa').css("visibility");
    toggle = toggle === 'visible' ? false : true;
    // map parent element
    var mapFrame = self.options.selfParent.mapFrame;
    mapFrame.find('.plotOverlayMapTitle').css('display', (toggle ?
        (self.el.find('input[name="title"]').is(':checked') ? 'block' : 'none') : 'none'));
    mapFrame.find('.plotOverlayMapCaption').css('display', (toggle ? (self.el.find('input[name="caption"]').is(':checked') ? 'block' : 'none') : 'none'));
    mapFrame.find('.legend').css('display', (toggle ?
        (self.el.find('input[name="legend"]').is(':checked') ? 'block' : 'none') : 'none'));

    if (toggle) {
        self.el.find('.fa').css("visibility", "visible");
    } else {
        self.el.find('.fa').css("visibility", "hidden");
    }
}

giovanni.widget.OverlayMap.Decorations.prototype.show = function (self) {
    // map parent element
    var mapFrame = self.options.selfParent.mapFrame;
    var decorationToggle = $('#decorations').find('.fa-check').css('visibility') === 'visible' ? true : false;
    var toggle = self.el.find('input[name="title"]').is(':checked');
    if (toggle && decorationToggle) {
        mapFrame.find('.plotOverlayMapTitle').show();
    } else {
        mapFrame.find('.plotOverlayMapTitle').hide();
    }
    toggle = self.el.find('input[name="caption"]').is(':checked');
    if (toggle && decorationToggle) {
        var caption = mapFrame.find('.plotOverlayMapCaption');
        if (!caption.is(':empty')) {
            caption.show();
        }
    } else {
        mapFrame.find('.plotOverlayMapCaption').hide();
    }
    toggle = self.el.find('input[name="legend"]').is(':checked');
    if (toggle && decorationToggle) {
        mapFrame.find('.legend').show();
    } else {
        mapFrame.find('.legend').hide();
    }
}

giovanni.widget.OverlayMap.SupportingLayers = function (options) {
    var self = this;

    self.containerId = options.containerId;
    self.overlays = options.overlays;
    self.sOverlayConfig = options.sOverlayConfig;

    self.el = $('<div>\
    <h4>\
      <i class="fa fa-check"/>\
      <button class="button-header">\
        Supporting Overlays\
      </button>\
    </h4>\
    <ul class="layer-group">\
    </ul>\
  </div>');

    for (var name in self.sOverlayConfig) {
        self.el.find('.layer-group').append(
            '<li><label class="checkboxLabel"><input class="' + self.sOverlayConfig[name] + 'Toggle" ' +
            'name="' + self.sOverlayConfig[name] + '" type="checkbox" ' +
            'checked="checked"' +
            '><span style="text-transform:capitalize">' + self.sOverlayConfig[name] + '</span></input><label><li>'
        );
    };

    self.el.find('.button-header').click(function () {
        self._handleHeaderClick(self);
    });

    self.el.find('input').click(function () {
        self.show();
    });
};

giovanni.widget.OverlayMap.SupportingLayers.prototype._handleHeaderClick = function (self) {
    // Checks for display:[none|block], ignores visible:[true|false]
    var toggle = self.el.find('.fa').css("visibility");
    toggle = toggle === 'visible' ? false : true;
    self.show(toggle);
    if (toggle) {
        self.el.find('.fa').css("visibility", "visible");
    } else {
        self.el.find('.fa').css("visibility", "hidden");
    }
}

giovanni.widget.OverlayMap.SupportingLayers.prototype.show = function (toggle) {
    var self = this;
    var headerToggle = toggle !== undefined ? toggle : self.el.find('.fa').css('visibility') === 'visible' ? true : false;
    var toogle = undefined;
    for (var idx in self.sOverlayConfig) {
        toggle = self.el.find('input[name="' + self.sOverlayConfig[idx] + '"]').is(':checked');
        if (toggle && headerToggle) {
            self.overlays[self.sOverlayConfig[idx]].setVisible(true);
        } else {
            self.overlays[self.sOverlayConfig[idx]].setVisible(false);
        }
    }
}
