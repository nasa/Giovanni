//$Id: ScatterPlot.js,v 1.68 2015/08/05 20:11:36 kbryant Exp $
//-@@@ Giovanni, Version $Name:  $
/**
 * create namespace for InteractiveScatterPlot
 */
giovanni.namespace("giovanni.widget.InteractiveScatterPlot");

/**
 * Create the Giovanni.widget.InteractiveScatterPlot object - interactive
 * scatter plot allows plot zooming and interaction with a supporting geographic
 * map; drawing a bounding box on the map results in the appropriate points
 * being displayed on the scatter plot and vice versa.
 *
 * @constructor 
 * @param {String, url}
 * @returns {giovanni.widget.InteractiveScatterPlot}
 * @author L. Davitt
 */

giovanni.widget.InteractiveScatterPlot = function (containerId, scatterInfoUrl, query) {

    // whether the plot is time-averaged
    this.isTimeAveraged = false;
    // time duration
    this.duration = 1;
    // hold the json array of scatter plot data
    this.jsonArray = new Array();
    // hold the hightchart object
    this.chart;
    // series identifiers
    this.SCATTER = 0;
    this.SELECTED = 1;
    this.REGRESSION = 2;
    // geographic bounding box; selected by dragging a bounding box
    // on the map
    this.lonMax = -200.000;
    this.lonMin = 200.000;
    this.latMax = -100.000;
    this.latMin = 100.000;
    // hold the 'bounding box' of the plot - actually the min and max
    // of the scatter plot axes
    this.boxXmin = null;
    this.boxXmax = null;
    this.boxYmin = null;
    this.boxYmax = null;
    // spatial resolution of the data
    this.resolution = 1;
    // x-axis name (used by updateMaskLayer)
    this.xAxisName;
    // x-axis label (HTML)
    this.xAxisLabel;
    // y-axis name (used by updateMaskLayer)
    this.yAxisName;
    // y-axis label (HTML) 
    this.yAxisLabel;
    // x, y variable names
    this.xVarName = "";
    this.yVarName = "";
    // chart name
    this.chartName;
    // sub-title content (HTML)
    this.subTitleName;
    // regression x min
    this.regressionXmin;
    // regression x man
    this.regressionXmax;
    // regression y min
    this.regressionYmin;
    // regression y max
    this.regressionYmax;
    // regression y array
    this.regressionYpoints;
    // regression x array
    this.regressionXpoints;
    // regression slope
    this.slope;
    // regression y intercept
    this.yIntercept;
    // graph box
    this.xMin = 0;
    this.xMax = 0;
    this.yMin = 0;
    this.yMax = 0;

    // grab spatial criteria
    var bbox = (giovanni.util.extractQueryValue(query, 'bbox')).split(",");
    this.userWest = parseFloat(bbox[0]);
    this.userSouth = parseFloat(bbox[1]);
    this.userEast = parseFloat(bbox[2]);
    this.userNorth = parseFloat(bbox[3]);

    // container (DIV) id
    this.containerId = containerId;
    // map data layer
    this.dataLayer = null;
    // map mask layer
    this.maskLayer = null;
    // base mask url
    this.dataLayerUrl = "";
    this.maskInfoBaseUrl = "";
    this.maskInfoQuery = "";
    this.maskLayerBaseUrl = "";
    this.maskLayerQuery = "";
    // create the map that interacts with the scatter plot
    this.map = new OpenLayers.Map({
        div: containerId + "map",
        tileSize: new OpenLayers.Size(180, 180)
    });
    this.map.addControl(new OpenLayers.Control.LayerSwitcher());
    // map base layer
    var baseLayer = new OpenLayers.Layer.WMS("Base",
        "https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc?", {
            layers: 'coastline',
            format: 'image/gif',
            bgcolor: '0xdfdff5',
        }, {
            wrapDateLine: true,
            buffer: '2',
            displayInLayerSwitcher: false,
            isBaseLayer: true
        }
    );
    // create a vector layer on which to draw a bounding box
    this.boxLayer = new OpenLayers.Layer.Vector("Box layer", {
        displayInLayerSwitcher: false
    });
    // add the base layer to the map
    this.map.addLayer(baseLayer);

    // add the bounding box layer to the map
    this.map.addLayer(this.boxLayer);

    this.getScatterPlotInfo(scatterInfoUrl);

    // use the default lat/lon min/max to set the map center - factor in dateline
    var cWest = this.userWest;
    var cEast = this.userEast;
    var userExtent = new OpenLayers.Bounds(cWest - 10, this.userSouth - 10, cEast + 10, this.userNorth + 10);
    var paddedExtent = new OpenLayers.Bounds(cWest - 45, this.userSouth - 30, cEast + 45, this.userNorth + 30);
    this.map.zoomToExtent(userExtent);

    // assign 'self' to the scatter plot class - we'll be using that reference a lot later
    var self = this;

    // add coastline layer
    var countries = new OpenLayers.Layer.WMS("Countries",
        "https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc", {
            layers: "countries",
            format: "image/png"
        }, {
            wrapDateLine: true,
            isBaseLayer: false,
            transparent: true,
            opacity: 0.45
        }
    );
    this.map.addLayer(countries);

    // create a marker layer for the map ('Cities' should be replaced by a more appropriate name)
    this.markers = new OpenLayers.Layer.Markers("Pair Geo Markers", {
        displayInLayerSwitcher: false
    });

    // create the navigation toolbar for the map
    this.customNavToolbar();
    // add the marker layer to the map
    this.map.addLayer(this.markers);

    // add hover control to the map
    this.createHoverControl();
    // add coordinate readout to the map frame
    document.getElementById(this.containerId + 'cursor').innerHTML = this.getCoordinateReadoutHTML();
    var self = this;
    this.map.events.register("mousemove", this.map, function (e) {
        var lonlat = self.map.getLonLatFromPixel(e.xy);
        self.updateCoordinateReadout('Cursor', lonlat);
    });
    /*
            //Formatter for the cursor location (significant digits...) before displaying
            var formatLonLat=function(lonLat){
                    var lat=lonLat.lat;
                    var lon=lonLat.lon;
                    if (Math.abs(lat)<=90 && Math.abs(lon)<=180){
                            var ns=OpenLayers.Util.getFormattedLonLat(lat,'lat','dm');
                            var ew=OpenLayers.Util.getFormattedLonLat(lon,'lon','dm');
                            return '<strong>Lat: </strong>'+ns+', <strong>Lon: <strong>'+ew;
                    }
                    return '&nbsp;';
            };
    	// add the mouse position control (reports location of the cursor as the user mouses over the map)
    	this.map.addControl(new OpenLayers.Control.MousePosition({div:'markerPanel',numDigits:1, formatOutput:formatLonLat,emptyString:""}));
    */
    // track selected graph points
    this.selected = [];

    // create a marker panel to display marker info
    this.pointsPanel = document.createElement('div');
    this.pointsPanel.setAttribute('id', 'pointsPanel');
    this.pointsPanel.setAttribute('visibility', 'hidden');
    this.pointsPanel.setAttribute('class', 'markerPanel');
    document.getElementById(this.containerId + 'map').parentNode.appendChild(this.pointsPanel);

    this.showPointsEvent = new YAHOO.util.CustomEvent("ShowPointsEvent");
    this.showPointsEvent.subscribe(this.handleShowPoints, this);

    // graph the data in the json array on the scatter plot
    this.graphIt(this.jsonArray, containerId);

};

/*
 * Set up the navigation toolbar for the map 
 * 
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {}
 * @return {}
 * @author L. Davitt
 */
giovanni.widget.InteractiveScatterPlot.prototype.customNavToolbar = function () {

    var self = this;
    var zoombox = new OpenLayers.Control.ZoomBox({
        alwaysZoom: true,
        displayClass: 'olControlNavToolbarScatterZoom'
    });
    OpenLayers.Util.extend(zoombox, {
        draw: function () {
            // this Handler.Box will intercept the shift-mousedown
            // before Control.MouseDefault gets to see it
            this.box = new OpenLayers.Handler.Box(zoombox, {
                    "done": this.notice
                },
                {});
            this.box.activate();
        },

        notice: function (bounds) {
            self.selectBBox(bounds, self);
        }
    });

    // Creation of a custom panel with a ZoomBox control with the alwaysZoom
    // option sets to true
    OpenLayers.Control.CustomNavToolbar = OpenLayers.Class(
        OpenLayers.Control.Panel, {

            /**
             * Constructor: OpenLayers.Control.NavToolbar Add our two
             * mousedefaults controls.
             * 
             * Parameters: options - {Object} An optional object whose
             * properties will be used to extend the control.
             */

            initialize: function (options) {
                OpenLayers.Control.Panel.prototype.initialize.apply(this, [options]);
                this.addControls([new OpenLayers.Control.Navigation(),
                    zoombox
                ]);
                // To make the custom navtoolbar use the regular navtoolbar
                // style
                this.displayClass = 'olControlNavToolbarScatter';
            },
            defaultControl: zoombox
                /**
                 * Method: draw calls the default draw, and then activates mouse
                 * defaults.
                 */
                /*
                 * ,draw: function() { var div =
                 * OpenLayers.Control.Panel.prototype.draw.apply(this, arguments);
                 * this.defaultControl = this.controls[0]; return div; }
                 */

        });

    var navpanel = new OpenLayers.Control.CustomNavToolbar();
    this.map.addControl(navpanel);

};

giovanni.widget.InteractiveScatterPlot.prototype.createHoverControl = function () {
    var self = this;
    OpenLayers.Control.Hover = OpenLayers.Class(OpenLayers.Control, {
        defaultHandlerOptions: {
            'delay': 350,
            'pixelTolerance': null,
            'stopMove': false
        },

        initialize: function (options) {
            this.handlerOptions = OpenLayers.Util.extend({}, this.defaultHandlerOptions);
            OpenLayers.Control.prototype.initialize.apply(
                this, arguments
            );
            this.handler = new OpenLayers.Handler.Hover(
                this, {
                    'pause': this.onPause,
                    'move': this.onMove
                },
                this.handlerOptions
            );
        },

        onPause: function (evt) {

            self.selected = [];

            var adjustedMinLon = self.correctForIDL(self.lonMin);
            var adjustedMaxLon = self.correctForIDL(self.lonMax);
            var lonCoords = self.correctForMinMaxSwap(adjustedMinLon, adjustedMaxLon);
            adjustedMinLon = lonCoords[0];
            adjustedMaxLon = lonCoords[1];
            var lonlat = self.map.getLonLatFromPixel(evt.xy);
            var lat = lonlat.lat;
            var lon = self.correctForMinMaxSwap(lonlat.lon, adjustedMaxLon)[0];

            if (lon > adjustedMinLon && lon < adjustedMaxLon &&
                lat > self.latMin && lat < self.latMax) {
                var len = self.jsonArray.length;
                var selectedPairs = [];
                var radius = self.resolution / 2;
                var center, west, south, east, north = 0;
                var pointList = [];
                var linearRing = [];
                for (var i = 0; i < len; i++) {
                    west = self.jsonArray[i].longitude - radius;
                    east = self.jsonArray[i].longitude + radius;
                    south = self.jsonArray[i].latitude - radius;
                    north = self.jsonArray[i].latitude + radius;
                    pointList = [];
                    pointList.push(new OpenLayers.Geometry.Point(west, north));
                    pointList.push(new OpenLayers.Geometry.Point(west, south));
                    pointList.push(new OpenLayers.Geometry.Point(east, south));
                    pointList.push(new OpenLayers.Geometry.Point(east, north));
                    linearRing = new OpenLayers.Geometry.LinearRing(pointList);
                    if (linearRing.intersects(new OpenLayers.Geometry.Point(lonlat.lon, lonlat.lat))) {
                        self.selected.push(self.jsonArray[i]);
                        selectedPairs.push([self.jsonArray[i].x, self.jsonArray[i].y, self.jsonArray[i].time]);
                    }
                    if (selectedPairs.length == self.duration) {
                        break;
                    }
                }
                if (selectedPairs.length > 0) {
                    self.showPointsEvent.fire(selectedPairs, lonlat, radius);
                } else {
                    self.hidePointsInfo();
                }
            } else {
                self.chart.series[self.SELECTED].setData([]);
                self.hidePointsInfo();
            }
        },

        onMove: function (evt) {
            // if this control sent an Ajax request (e.g. GetFeatureInfo) when
            // the mouse pauses the onMove callback could be used to abort that
            // request.
            //console.log( 'move '+evt.xy );
            /*
            		    var lonlat = self.map.getLonLatFromPixel(evt.xy);
            		    var len = self.jsonArray.length;
            		    for( var i=0; i<len; i++){
            		        if(lonlat.lon == self.jsonArray[i].longitude &&
            		           lonlat.lat == self.jsonArray[i].latitude){
            			    self.chart.series[0].data[i].select();
            			}
            		    }
            */
            //for(var i=0;i<self.selected.length;i++){
            //		self.chart.series[0].data[self.selected[i]].select(false);
            //}
            //self.selected = [];
            //self.chart.series[2].hide();
            //var lonlat = self.map.getLonLatFromPixel(evt.xy);
            //if( lonlat.lon > self.lonMin && lonlat.lon < self.lonMax &&
            //    lonlat.lat > self.latMin && lonlat.lat < self.latMax ) {
            //}else{
            //if(self.pointsPanel.style.visibility == "visible"){
            //    self.chart.series[self.SELECTED].setData( [] );
            self.hidePointsInfo();
            //}
            //}
        }
    });
    var hoverCtrl = new OpenLayers.Control.Hover({
        handlerOptions: {
            'delay': 400,
            'pixelTolerance': 4
        }
    });
    self.map.addControl(hoverCtrl);
    hoverCtrl.activate();
}

/*
 * Handle map bounding box selects
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {OpenLayers.Bounds,InteractiveScatterPlot}
 * @return {}
 * @L. Davitt
 * @modified K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.selectBBox = function (bounds,
    self) {

    var ll = self.map
        .getLonLatFromPixel(new OpenLayers.Pixel(bounds.left, bounds.bottom));
    var ur = self.map
        .getLonLatFromPixel(new OpenLayers.Pixel(bounds.right, bounds.top));
    self.latMin = parseFloat(ll.lat.toFixed(4));
    self.latMax = parseFloat(ur.lat.toFixed(4));
    self.lonMin = parseFloat(ll.lon.toFixed(4));
    self.lonMax = parseFloat(ur.lon.toFixed(4));

    var markerStyle = OpenLayers.Util.extend({},
        OpenLayers.Feature.Vector.style['default']);
    markerStyle.fillOpacity = 0.2;
    markerStyle.graphicOpacity = 1;

    var pointList = [];
    var tl = self.map
        .getLonLatFromPixel(new OpenLayers.Pixel(bounds.left, bounds.top));
    var br = self.map
        .getLonLatFromPixel(new OpenLayers.Pixel(bounds.right,
            bounds.bottom));

    // set class references to current bbox
    self.latMin = br.lat;
    self.latMax = tl.lat;
    self.lonMin = tl.lon;
    self.lonMax = br.lon;

    // correct for lon values > +/-180 degrees
    tl.lon = self.correctForIDL(tl.lon);
    br.lon = self.correctForIDL(br.lon);

    // handle the min>max swap issue
    var lonCoords = self.correctForMinMaxSwap(tl.lon, br.lon);
    tl.lon = lonCoords[0];
    br.lon = lonCoords[1];

    // create a OpenLayers linear ring so we can calculate the bounded area
    pointList.push(new OpenLayers.Geometry.Point(tl.lon, tl.lat));
    pointList.push(new OpenLayers.Geometry.Point(tl.lon, br.lat));
    pointList.push(new OpenLayers.Geometry.Point(br.lon, br.lat));
    pointList.push(new OpenLayers.Geometry.Point(br.lon, tl.lat));
    var linearRing = new OpenLayers.Geometry.LinearRing(pointList);

    /* don't allow bounding boxes of zero size */
    if (Math.abs(linearRing.getGeodesicArea()) > 0) {
        var region = new OpenLayers.Feature.Vector(
            new OpenLayers.Geometry.Polygon([linearRing]), null,
            markerStyle);
        self.markers.clearMarkers();
        self.boxLayer.removeAllFeatures();
        self.boxLayer.addFeatures(region);

        self.map.addLayer(self.boxLayer);

        var updatedPoints = new Array();

        var jsonArray = self.jsonArray;
        for (var i = 0; i < jsonArray.length; i++) {

            var lat = parseFloat(jsonArray[i].latitude);
            var lon = parseFloat(jsonArray[i].longitude);

            var x = parseFloat(jsonArray[i].x);
            var y = parseFloat(jsonArray[i].y);

            if ((lat >= br.lat && lat <= tl.lat &&
                self.correctForMinMaxSwap(lon, br.lon)[0] >= tl.lon &&
                self.correctForMinMaxSwap(lon, br.lon)[0] <= br.lon) &&
                ((self.boxXmin == null) ||
                    (x >= self.boxXmin && x <= self.boxXmax && y >= self.boxYmin && y <= self.boxYmax))) {

                var dataPoint = {
                    "time": [],
                    "latitude": [],
                    "longitude": [],
                    "x": [],
                    "y": []
                };
                dataPoint.time = jsonArray[i].time;
                dataPoint.latitude = lat;
                dataPoint.longitude = lon;

                dataPoint.x = parseFloat(jsonArray[i].x);
                dataPoint.y = parseFloat(jsonArray[i].y);

                updatedPoints.push(dataPoint);
            }
        }

        /*
         * commenting out self jsonArray update since it will prevent the
         * bounding box reset from behaving
         */

        // make sure there are points to update
        if (updatedPoints.length > 1) {

            // update markers
            self.markers.clearMarkers();

            self.setSubTitle(updatedPoints, null, null, self.lonMin, self.lonMax);

            var update_x = [];
            var update_y = [];
            var newPoints = [];
            $.each(updatedPoints, function (itemNo, item) {
                newPoints.push([updatedPoints[itemNo].x, updatedPoints[itemNo].y]);
                update_x.push(updatedPoints[itemNo].x);
                update_y.push(updatedPoints[itemNo].y);
            });

            // update the chart data
            self.chart.series[self.SCATTER].setData(newPoints, false);

            /*
             * update the least squares output since we're actually using a
             * different number of points
             */
            self.findLineByLeastSquares(update_x, update_y);

            // update regression line
            update_x = update_x.sort(self.numericComp);
            update_y = update_y.sort(self.numericComp);
            var xmin = update_x[0];
            var xmax = update_x[update_x.length - 1];
            self.updateRegressionLine(updatedPoints.length, xmin, xmax, true);

            self.chart.redraw();
            // update the map mask
            self.getMaskInfo(null, false);

        } else {
            alert("selectBBox: Not enough points to plot.  Please select at least 2 points!");
        }

    }

};

/*
 * Called by 'Reset Map and Chart' button; resets both the chart and the map
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.resetAll = function () {
    // reset the saved scatter plot axes min/max
    this.boxXmin = null;
    this.boxXmax = null;
    this.boxYmin = null;
    this.boxYmax = null;
    // reset the saved bounding box values
    this.lonMax = 180.000;
    this.lonMin = -180.000;
    this.latMax = 90.000;
    this.latMin = -90.000;
    // used the saved original points array
    var points = this.jsonArray.slice(0);

    try {
        // handle map updates
        // make sure there is no bounding box displayed on the map box layer
        this.boxLayer.removeAllFeatures();
        // update markers
        this.markers.clearMarkers();
        this.maskLayer.setVisibility(false);
        this.dataLayer.setVisibility(true);
        // set map extent and zoom
        var cWest = this.userWest;
        var cEast = this.userEast;
        var userExtent = new OpenLayers.Bounds(cWest - 10, this.userSouth - 10, cEast + 10, this.userNorth + 10);
        this.map.zoomToExtent(userExtent);
    } catch (e) {}

    // generate regression values
    var regressionXpoints = [];
    var regressionYpoints = [];
    $.each(points, function (itemNo) {
        regressionXpoints.push(points[itemNo].x);
        regressionYpoints.push(points[itemNo].y);
    });
    this.findLineByLeastSquares(regressionXpoints, regressionYpoints);

    // build chart data and set regression min/max values
    var scatterPoints = [];
    $.each(points, function (itemNo) {

        if (itemNo == 0) {
            this.regressionXmin = points[itemNo].x;
            this.regressionXmax = points[itemNo].x;
        }
        scatterPoints.push([points[itemNo].x, points[itemNo].y]);
        if (points[itemNo].x > this.regressionXmax) {
            this.regressionXmax = points[itemNo].x;
            this.regressionYmax = (this.slope * this.regressionXmax) + this.yIntercept;
        }
        if (points[itemNo].x < this.regressionXmin) {
            this.regressionXmin = points[itemNo].x;
            this.regressionYmin = (this.slope * this.regressionXmin) + this.yIntercept;
        }

    });

    this.setSubTitle(points);
    // reset axes (zoom out)
    this.chart.xAxis[0].zoom();
    this.chart.yAxis[0].zoom();
    // update regression line
    this.updateRegressionLine(points.length, this.regressionXmin, this.regressionXmax, true);
    // update chart data
    this.chart.series[this.SCATTER].setData(scatterPoints, false);
    this.chart.redraw();

}

/*
 * Graph the scatter plot pairs for the first time (used only during the initial creation of the scatter plot)
 * 
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {Array, HTML Element}
 * @return {}
 * @author L. Davitt
 * @modified K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.graphIt = function (
    points, container) {

    var self = this;
    var reset = false;

    this.setSubTitle(points, null, null, self.userWest, self.userEast);

    var cid = container + 'graph';
    var options = {
        title: {
            text: this.chartName,
            margin: 50
        },
        subtitle: {
            text: this.subTitleName
        },
        xAxis: {
            title: {
                text: this.xAxisLabel,
                margin: 20
            },
        },
        yAxis: {
            title: {
                text: this.yAxisLabel,
                margin: 40
            }
        },
        legend: {
            layout: 'vertical',
            align: 'center',
            verticalAlign: 'top',
            x: 20,
            y: 60,
            floating: true,
            backgroundColor: '#ffffff'
        },
        plotOptions: {
            series: {
                allowPointSelect: true,
                point: {
                    events: {
                        select: function () {
                            var chartLoc = document.getElementById(self.containerId + 'graph').getBoundingClientRect();
                            var pointLoc = this.graphic.element.getBoundingClientRect();
                            var x = chartLoc.left + pointLoc.left - 10;
                            var y = chartLoc.top + pointLoc.top - 160;

                            self.pointsPanel.style.left = x + 'px';
                            self.pointsPanel.style.top = y + 'px';
                            self.hidePointsInfo();
                        }
                    }
                }

            },
            scatter: {
                stickyTracking: false,
                allowPointSelect: true,
                marker: {
                    radius: 3,
                    states: {
                        hover: {
                            enabled: true,
                            lineColor: 'rgb(100,100,100)'
                        },
                        select: {
                            fillColor: 'red',
                            lineWidth: 1
                        }
                    }
                },
                point: {
                    events: {
                        click: function () {
                            self.handleGraphLocationEvent(this.x, this.y, self);
                        },
                        mouseOver: function () {
                            self.handleGraphLocationEvent(this.x, this.y, self);
                        },
                        mouseOut: function () {
                            self.hideMarkers();
                        }
                    }
                }
            }
        },
        series: [],
        tooltip: {
            useHTML: true,
            headerFormat: '<small>Pair Data:</small><br/>',
            pointFormat: '<strong>x:</strong>{point.x}<br/><strong>y:</strong>{point.y}<br/><strong>lat:</strong>{point.index}<br/><strong>lon:</strong>{point.longitude}<br/>',
            valueDecimals: 4
        },

        chart: {
            resetZoomButton: {
                position: {
                    x: 0,
                    y: -1000
                }
            },
            renderTo: cid,
            defaultSeriesType: 'scatter',
            type: 'scatter',
            zoomType: 'xy',
            events: {

                selection: function (event) {

                    var regressionXpoints = new Array();
                    var regressionYpoints = new Array();
                    try { // if it's a reset of the graph zoom box, there will be no axis values defined
                        self.boxXmin = event.xAxis[0].min;
                        self.boxXmax = event.xAxis[0].max;
                        self.boxYmin = event.yAxis[0].min;
                        self.boxYmax = event.yAxis[0].max;
                    } catch (e) {}
                    var selectionSlope;
                    var selectionYintercept;
                    var updatedPoints = new Array(); // one array for calculation
                    var newPoints = new Array(); // one array for updating the graph - the two should become one...

                    var minLon = self.correctForIDL(self.lonMin);
                    var maxLon = self.correctForIDL(self.lonMax);

                    // handle the min>max swap issue
                    var lonCoords = self.correctForMinMaxSwap(minLon, maxLon);
                    minLon = lonCoords[0];
                    maxLon = lonCoords[1];

                    // loop through the array to figure what stays and what goes
                    for (var i = 0; i < self.jsonArray.length; i++) {

                        var x = parseFloat(self.jsonArray[i].x);
                        if (isNaN(x)) {
                            x = 0;
                        }
                        if (isNaN(y)) {
                            y = 0;
                        }
                        var y = parseFloat(self.jsonArray[i].y);
                        var lat = parseFloat(self.jsonArray[i].latitude);
                        var lon = parseFloat(self.jsonArray[i].longitude);
                        lon = self.correctForMinMaxSwap(lon, maxLon)[0];

                        if ( (x >= self.boxXmin && x <= self.boxXmax && y >= self.boxYmin && y < self.boxYmax) && 
                             (lat >= self.latMin && lat <= self.latMax && lon >= minLon && lon <= maxLon)) {

                            var dataPoint = {
                                "time": [],
                                "latitude": [],
                                "longitude": [],
                                "x": [],
                                "y": []
                            };
                            dataPoint.time = self.jsonArray[i].time;
                            dataPoint.latitude = parseFloat(self.jsonArray[i].latitude);
                            dataPoint.longitude = parseFloat(self.jsonArray[i].longitude);

                            dataPoint.x = x;
                            dataPoint.y = y;
                            regressionXpoints.push(dataPoint.x);
                            regressionYpoints.push(dataPoint.y);

                            updatedPoints.push(dataPoint);
                            newPoints.push([dataPoint.x, dataPoint.y]);
                        }
                    }

                    // if there are sufficient points to update, do so
                    if (updatedPoints.length > 1) {
                        // set the class member to have the updated points
                        // update the graph
                        self.chart.series[self.SCATTER].setData(newPoints, false);
                        // calc least squares
                        self.findLineByLeastSquares(regressionXpoints,
                            regressionYpoints);
                        // update regression line and replace in chart
                        self.updateRegressionLine(updatedPoints.length,
                            self.boxXmin, self.boxXmax, true);

                        self.chart.redraw();
                        // update markers
                        self.getMaskInfo();
                    } else {
                        alert("graphIt:  Not enough points to plot.  Please select at least 2 points!");
                        event.preventDefault();
                    }

                },

            }

        }
    };

    // set the highcharts scatter 'series' object and some options
    var scatterSeries = {
        name: "Pairs",
        type: 'scatter',
        color: 'rgba(119, 152, 191, .5)',
        showInLegend: false,
        //allowPointSelect: true,
        //data : points,
        data: [],
        turboThreshold: 100000, // required to plot values where N is > 5000???
        tooltip: {
            useHTML: true,
            headerFormat: '<small>Pair Data:</small><br/>',
            pointFormat: '<strong>x:</strong>{point.x}<br/><strong>y:</strong>{point.y}',
            valueDecimals: 4
        }
    };

    // loop through the points to establish the regression min/max values and the actual points 
    // that get loaded into highcharts
    $.each(points, function (itemNo) {
        var x = points[itemNo].x;
        var y = points[itemNo].y;
        //if( !isNaN(x) && !isNaN(y) ){

        if (itemNo == 0) {
            self.regressionXmin = x;
            self.regressionXmax = x;
        }
        // add the points to the highcharts scatter series data
        scatterSeries.data.push([x, y]);
        if (x > self.regressionXmax) {
            self.regressionXmax = x;
            self.regressionYmax = (self.slope * self.regressionXmax) + self.yIntercept;
        }
        if (x < self.regressionXmin) {
            self.regressionXmin = x;
            self.regressionYmin = (self.slope * self.regressionXmin) + self.yIntercept;
        }
        //}

    });

    // add the scatter 'series' object to the chart options
    options.series.push(scatterSeries);

    // set the regression line series object for highcharts
    var lineSeries = self.createRegressionLine(points, self.regressionXmin,
        self.regressionXmax);


    // set up for popping selected scatter pairs
    var selectedPairs = {
        name: "Selected",
        color: 'rgba(255, 60, 60, .8)',
        type: 'scatter',
        showInLegend: false,
        allowPointSelect: true,
        data: [],
        tooltip: {
            useHTML: true,
            headerFormat: '<small>Pair Data:</small><br/>',
            pointFormat: '<strong>x:</strong>{point.x}<br/><strong>y:</strong>{point.y}',
            valueDecimals: 4
        }
    };
    options.series.push(selectedPairs);
    // add the regression line 'series' object to the chart options
    options.series.push(lineSeries);

    this.chart = new Highcharts.Chart(options);

};

/*
 * From the resulting JSON file, set up some basic graph elements like axes names
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {JSON Object}
 * @return {}
 * @author L. Davitt
 */
giovanni.widget.InteractiveScatterPlot.prototype.createScatterPlot = function (
    dataUrl) {

    var dataElements = this.setScatterData(dataUrl);
    var xLongName = dataElements[0];
    var xFirstLine = '';
    var xSecondLine = '';
    var yFirstLine = '';
    var ySecondLine = '';
    var yThirdLine = '';
    var yLongName = dataElements[1];
    var beginTime = dataElements[2];
    var endTime = dataElements[3];
    var beginLat = dataElements[4];
    var endLat = dataElements[5];
    var beginLon = dataElements[6];
    var endLon = dataElements[7];
    this.xVarName = dataElements[8];
    this.yVarName = dataElements[9];

    xLongName = xLongName.split(" ");
    yLongName = yLongName.split(" ");
    // set up the long name breaks (kludge)
    for (var i = 0; i < xLongName.length; i++) {
        if (i < 7)
            xFirstLine += ' ' + xLongName[i];
        else
            xSecondLine += ' ' + xLongName[i];
    }

    for (var j = 0; j < yLongName.length; j++) {
        if (j < 6)
            yFirstLine += ' ' + yLongName[j];
        else if (j >= 6 && j < 14)
            ySecondLine += ' ' + yLongName[j];
        else
            yThirdLine += ' ' + yLongName[j];
    }

    // set the x-axis name
    this.xAxisName = dataElements[0];
    // set the x-axis label
    this.xAxisLabel = '<span style="margin-top: 2px;">' + xFirstLine + ' </span><br/><span style="margin-bottom: 2px";>' + xSecondLine + '</span><br/>';
    // set the y-axis name
    this.yAxisName = dataElements[1];
    // set the y-axis label
    this.yAxisLabel = '<span style="margin-top: 20px;">' + yFirstLine + ' </span><br/><span style="margin-middle: 2px";>' + ySecondLine + '</span><br/><span style="margin-bottom: 2px";>' + yThirdLine + '</span><br/>';
    // set the graph label
    this.chartName = '<span style="margin-bottom: 2px;">' + beginTime;
    if (beginTime != endTime) {
        this.chartName += ' through ' + endTime;
    }
    this.chartName = this.chartName + '</span><br/>';
    // set the sub title
    this.setSubTitle(null, beginLat, endLat, beginLon, endLon);

};

/*
 * Get keys from JSON object
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {JSON Object}
 * @return {Array}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.getKeys = function (obj) {
    var keys = [];

    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            keys.push(key);
        }
    }

    return keys;
};

/*
 * Uses the scatter plot info url to fetch the data url, the data layer url and the mask url
 */
giovanni.widget.InteractiveScatterPlot.prototype.getScatterPlotInfo = function (infoUrl) {
    var self = this;

    $.ajax({
        type: "GET",
        url: infoUrl,
        async: false,
        beforeSend: function (x) {
            if (x && x.overrideMimeType) {
                x.overrideMimeType("application/j-son;charset=UTF-8");
            }
        },
        dataType: "json",
        success: function (json) {
            try {
                self.createScatterPlot(json.scatterplot.data);
            } catch (e) {
                alert(e);
            }
            try {
                self.setDataLayer(json.scatterplot.layers[0].url);
            } catch (e) {
                alert(e);
            }
            try {
                self.getMaskInfo(json.scatterplot.filter.replace("+", "%2B"));
            } catch (e) {
                alert(e);
            }
        }
    });

}

/*
 * Fetch the scatter plot data 
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {String}
 * @return {}
 * @author L. Davitt
 */
giovanni.widget.InteractiveScatterPlot.prototype.setScatterData = function (dataUrl) {

    var xAxi;
    var yAxi;
    var xName;
    var yName;
    var timeNames = new Array();
    var latNames = new Array();
    var lonNames = new Array();
    var regressionXpoints = new Array();
    var regressionYpoints = new Array();
    var self = this;

    $.ajax({
        type: "GET",
        url: dataUrl,
        async: false,
        beforeSend: function (x) {
            if (x && x.overrideMimeType) {
                x.overrideMimeType("application/j-son;charset=UTF-8");
            }

        },
        dataType: "json",
        success: function (file) {
            // do your stuff with the JSON data

            var time = new Array();
            var lat = new Array();
            var lon = new Array();
            var x = null;
            var y = null;

            // call keys function to get hash terms.
            var hashes = self.getKeys(file);
            xAxi = hashes[3];
            yAxi = hashes[4];
            var xData = file["" + xAxi];
            var yData = file["" + yAxi];
            var xNoFill = xData._FillValue;
            var yNoFill = yData._FillValue;
            xName = xData.plot_hint_axis_title;
            yName = yData.plot_hint_axis_title;

            // grab the time array information from the file
            $.each(file.time.data, function (itemNo) {
                time[itemNo] = file.time.data[itemNo];
                timeNames[itemNo] = file.time.data[itemNo];
            });

            // if the time array has only one value, the time dim is averaged
            self.duration = time.length;
            if (time.length == 1) {
                self.isTimeAveraged = true;
            }

            // grab the lat array information from the file
            $.each(file.lat.data, function (itemNo) {
                lat[itemNo] = file.lat.data[itemNo];
                latNames[itemNo] = file.lat.data[itemNo];
            });

            // grab the lon array information from the file
            $.each(file.lon.data, function (itemNo) {
                lon[itemNo] = file.lon.data[itemNo];
                lonNames[itemNo] = file.lon.data[itemNo];
            });

            // spatial resolution - choose an arbitrary point in 
            // the lon array to calculate the res; assume 
            // data cells are square
            self.resolution = lon[3] - lon[2];

            // using the 3 built arrays, cycle through them and set up
            // the point objects for the map and graph
            $.each(
                time,
                function (timeItem) {
                    $.each(
                        lat,
                        function (latItem) {
                            $.each(
                                lon,
                                function (lonItem) {
                                    x = file["" + xAxi].data[timeItem][latItem][lonItem];
                                    y = file["" + yAxi].data[timeItem][latItem][lonItem];
                                    if( !isNaN(x) && x != null && x != xNoFill && !isNaN(y) && y != null && y != yNoFill ){ 
                                        var dataPoint = {
                                            "time": [],
                                            "latitude": [],
                                            "longitude": [],
                                            "x": [],
                                            "y": []
                                        };
                                        dataPoint.time = time[timeItem];
                                        dataPoint.latitude = parseFloat(lat[latItem]);

                                        dataPoint.longitude = parseFloat(lon[lonItem]);
                                        dataPoint.x = parseFloat(x);
                                        regressionXpoints
                                            .push(dataPoint.x);
                                        dataPoint.y = parseFloat(y);
                                        regressionYpoints
                                            .push(dataPoint.y);
                                        self.jsonArray
                                            .push(dataPoint);

                                        if (lat[latItem] < self.latMin)
                                            self.latMin = lat[latItem];
                                        if (lat[latItem] > self.latMax)
                                            self.latMax = lat[latItem];
                                        if (lon[lonItem] < self.lonMin)
                                            self.lonMin = lon[lonItem];
                                        if (lon[lonItem] > self.lonMax)
                                            self.lonMax = lon[lonItem];
                                    }

                                });
                        });
                });

        }
    });
    timeNames = timeNames.sort(this.numericComp);
    latNames = latNames.sort(this.numericComp);
    lonNames = lonNames.sort(this.numericComp);

    self.setSubTitle(null, latNames[0], latNames[latNames.length - 1],
        lonNames[0], lonNames[lonNames.length - 1]);

    self.regressionXpoints = regressionXpoints;
    self.regressionYpoints = regressionYpoints;

    self.findLineByLeastSquares(regressionXpoints, regressionYpoints);

    return [xName, yName, timeNames[0], timeNames.pop(), latNames[0],
        latNames.pop(), lonNames[0], lonNames.pop(), xAxi, yAxi
    ];
};

/*
 * Set the data layer value and add it to the map; assumes getScatterPlotInfo.pl returns JSON
 * object with all items necessary to make a data map WMS request.
 */
giovanni.widget.InteractiveScatterPlot.prototype.setDataLayer = function (url) {
    //if(config instanceof String){
    //    this.dataBaseUrl = config.split("?")[0];
    //    var pairs = giovanni.util.map(config.split("&"), function(p) {return p.split("=");});
    //    pairs = giovanni.util.filter(pairs, function(p) {return p[0] != "session";});
    //}
    if (this.dataLayer == null) {
        this.dataLayerUrl = url;
        this.dataLayer = new OpenLayers.Layer.WMS(
            "Full Scatter Data",
            url, {
                rand: Math.random() * 10000000,
            }, {
                buffer: '2', // helps reduce animation flashing
                isBaseLayer: false,
            }
        );
        this.map.addLayer(this.dataLayer);
    }
}

/*
 * Set the mask layer value and add it to the map; assumes the getScatterPlotInfo.pl request
 * returns a JSON object containing, among other things, the map mask WMS url
 * @param url - {String} optional
 * @param blocking - {Boolean} optional, whether or not this function should block on the
 * request made. By default, true.
 */
giovanni.widget.InteractiveScatterPlot.prototype.getMaskInfo = function (url, blocking) {
    if (blocking == null) {
        blocking = true;
    }

    var maskInfoUrl = url;
    if (this.maskLayer == null && url != null) {
        // set url components for later use
        this.maskInfoBaseUrl = url.split("?")[0];
        var pairs = giovanni.util.map(url.split("?")[1].split("&"), function (p) {
            return p.split("=");
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "xybox";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "bbox";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "x";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "y";
        });
        this.maskInfoQuery = giovanni.util.map(pairs, function (p) {
            return p.join("=");
        }).join("&");
        maskInfoUrl = this.maskInfoBaseUrl + "?" + this.maskInfoQuery + "&x=" + encodeURIComponent(this.xVarName) + "&y=" + encodeURIComponent(this.yVarName);
        console.log("getMaskInfo: url: " + maskInfoUrl);
    } else {
        maskInfoUrl = this.maskInfoBaseUrl + "?" + this.maskInfoQuery;
        var bbox = this.lonMin != 200.000 ? this.lonMin + "," + this.latMin + "," + this.lonMax + "," + this.latMax : "";
        var xybox = this.boxXmin ? this.boxXmin + "," + this.boxXmax + "," + this.boxYmin + "," + this.boxYmax : "";
        maskInfoUrl += (bbox != "" ? "&bbox=" + bbox : "");
        maskInfoUrl += (xybox != "" ? "&xybox=" + xybox : "");
        maskInfoUrl += "&x=" + this.xVarName;
        maskInfoUrl += "&y=" + this.yVarName;
    }
    var self = this;
    $.ajax({
        type: "GET",
        url: maskInfoUrl,
        async: !blocking,
        beforeSend: function (x) {
            if (x && x.overrideMimeType) {
                x.overrideMimeType("application/j-son;charset=UTF-8");
            }
        },
        dataType: "json",
        success: function (json) {
            self.updateMaskLayer(json);
        }
    });
}

/*
 * Assumes a map mask cgi will return the information necessary to make an updated map mask WMS request
 */
giovanni.widget.InteractiveScatterPlot.prototype.updateMaskLayer = function (json) {
    if (this.maskLayer == null) {
        this.maskLayerBaseUrl = this.dataLayerUrl.split("?")[0];
        var pairs = giovanni.util.map(this.dataLayerUrl.split("?")[1].split("&"), function (p) {
            return p.split("=");
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "xybox";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "bbox";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "x";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "y";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "layers";
        });
        pairs = giovanni.util.filter(pairs, function (p) {
            return p[0] != "mapfile";
        });
        this.maskLayerQuery = giovanni.util.map(pairs, function (p) {
            return p.join("=");
        }).join("&");
        // create mask layer
        this.maskLayer = new OpenLayers.Layer.WMS(
            "Scatter Data Mask",
            this.maskLayerBaseUrl + "?" + this.maskLayerQuery, {
                layers: json.maskMap.name,
                mapfile: json.maskMap.mapfile,
                rand: Math.random() * 10000000,
            }, {
                buffer: '2', // helps reduce animation flashing
                isBaseLayer: false,
            }
        );
        this.maskLayer.setVisibility(false);
        this.map.addLayer(this.maskLayer);
    } else {
        this.maskLayer.mergeNewParams({
            mapfile: json.maskMap.mapfile,
            layers: json.maskMap.name,
            rand: Math.random() * 1000000
        });
        this.maskLayer.setVisibility(true);
        this.dataLayer.setVisibility(false);
    }
}

// Compare these two objects numerically
giovanni.widget.InteractiveScatterPlot.prototype.numericComp = function (a, b) {
    if (a === b) {
        return 0;
    } else if (a > b) {
        return 1;
    } else {
        return -1;
    }
};

/* 
 * Find the least squares fit/R
 * 
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {Array,Array}
 * @return {}
 * @author L. Davitt
 * @modified K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.findLineByLeastSquares = function (
    values_x, values_y) {

    var sum_x = 0;
    var sum_y = 0;
    var sum_xy = 0;
    var sum_xx = 0;
    var sum_yy = 0;
    var count = 0;
    var x = 0;
    var y = 0;
    /* compare point arrays to make sure they are even */
    var values_length = values_x.length;
    if (values_length != values_y.length) {
        throw new Error(
            'The parameters values_x and values_y need to have same size!');
    }
    /* if there are no points, there is nothing to do.... */
    if (values_length === 0) {
        return [
            [],
            []
        ];
    }

    /* Calculate the sum for each of the parts necessary. */
    for (var v = 0; v < values_length; v++) {
        y = values_y[v];
        x = values_x[v];
        sum_x += x;
        sum_y += y;
        sum_xx += x * x;
        sum_xy += x * y;
        sum_yy += y * y;
        count++;
    }

    /* Calculate m and b for the formula: y = x * m + b */
    var m = (count * sum_xy - sum_x * sum_y) / (count * sum_xx - sum_x * sum_x);
    if (isNaN(m)) m = 0;
    var b = (sum_y / count) - (m * sum_x) / count;
    if (isNaN(b)) b = 0;

    /* set slope and y intercept */
    this.slope = m;
    this.yIntercept = b;

    /* calculate y avg for R calc */
    var y_avg = sum_y / count;

    /**
     * Calculate R using the formula below > y: data point array > y_avg:
     * average of y > y_est: estimated y array based on linear regression > >
     * TSS = sum[(y-y_avg)^2] > RSS = sum[(y-y_est)^2] > R2 = (TSS-RSS)/TSS
     */
    var tss = 0;
    var rss = 0;
    for (var v = 0; v < values_length; v++) {
        y = values_y[v];
        x = values_x[v];
        tss += (y - y_avg) * (y - y_avg);
        rss += (y - ((x * m) + b)) * (y - ((x * m) + b));
    }
    var r2 = (tss - rss) / tss;
    var sign = m < 0 ? -1 : 1;
    this.fit = Math.sqrt(Math.abs(r2)) * sign;
    if (isNaN(this.fit)) this.fit = 0;

    /* calcuation reporting precision */
    this.statsPrecision = Math
        .floor(3 - (Math.log(1 - (this.fit * this.fit)) / Math.log(10)));
    if (isNaN(this.statsPrecision)) {
        this.statsPrecision = 2;
    }
    if (this.statsPrecision > 6) {
        this.statsPrecision = 6;
    }
    if (this.statsPrecision < 2) {
        this.statsPrecision = 2;
    }

};

/*
 * Set the graph subtitle
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {Array,String,String,String,String}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.setSubTitle = function (points,
    minLat, maxLat, minLon, maxLon) {
    var lats = [];
    var lons = [];
    if (points != null) {
        for (var i = 0; i < points.length; i++) {
            lats.push(points[i].latitude);
            lons.push(points[i].longitude);
        }
        lats.sort(this.numericComp);
        minLat = lats[0];
        maxLat = lats[lats.length - 1];
        var dist = 0;
        var minDist = 720;
        var distIdx = 0;
        if (minLon == null) {
            minLon = this.userWest;
        }
        if (maxLon == null) {
            maxLon = this.userEast;
        }
        for (var i = 0; i < lons.length; i++) {
            dist = this.getCartesianDistance([minLon, minLat, lons[i], maxLat])[0];
            if (dist < minDist) {
                minDist = dist;
                distIdx = i;
            }
        }
        minLon = lons[distIdx];
        dist = 0;
        minDist = 720;
        distIdx = 0;
        for (var i = 0; i < lons.length; i++) {
            dist = this.getCartesianDistance([lons[i], minLat, maxLon, maxLat])[0];
            if (dist < minDist) {
                minDist = dist;
                distIdx = i;
            }
        }
        maxLon = lons[distIdx];
    }
    this.subTitleName = '<span>Latitude: ' + minLat + ' to </span><span>' + maxLat + '</span><span><br/>Longitude: ' + minLon + ' to </span><span>' + maxLon + '</span>';
    if (this.chart) {
        this.chart.setTitle(null, {
            text: this.subTitleName
        });
    }
}

/*
 * Updates the regression line based on user graph zoom or map bbox selection
 *
 * @this {giovanni.widget.InteractiveScatter}
 * @params {Array,Number,Number,Boolean}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.updateRegressionLine = function (pointsLen, xMin, xMax, redraw) {
    this.xMin = xMin;
    this.xMax = xMax;
    /*
     * ASSUMES slope and yIntercept have been calculated PRIOR to calling this
     * function
     */
    var yMin = (this.slope * xMin) + this.yIntercept;
    var yMax = (this.slope * xMax) + this.yIntercept;
    this.yMin = yMin;
    this.yMax = yMax;
    var r = new Number(this.fit).toPrecision(this.statsPrecision);
    if (pointsLen.length < 3) {
        r = 'n/a';
    }
    // set title
    var title = 'Regression: y = ' + new Number(this.slope).toPrecision(this.statsPrecision) + 'x + ' + new Number(this.yIntercept).toPrecision(this.statsPrecision) + ', R: ' + r + ', N: ' + pointsLen;
    // update series name with title
    this.chart.series[this.REGRESSION].update({
        name: title
    }, redraw);
    // update series data with new min/max points from regression calc
    this.chart.series[this.REGRESSION].setData([
        [xMin, yMin],
        [xMax, yMax]
    ], redraw);

}

/*
 * Creates initial regression line 'series' for highcharts
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {Array,Number,Number}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.createRegressionLine = function (points, xMin, xMax) {
    /*
     * ASSUMES slope and yIntercept have been calculated PRIOR to calling this
     * function
     */
    var yMin = (this.slope * xMin) + this.yIntercept;
    var yMax = (this.slope * xMax) + this.yIntercept;
    var r = new Number(this.fit).toPrecision(this.statsPrecision);
    if (points.length < 3) {
        r = 'n/a';
    }
    // create new line object for the chart
    var line = {
        type: 'line',
        name: 'Regression: y = ' + new Number(this.slope).toPrecision(this.statsPrecision) + 'x + ' + new Number(this.yIntercept).toPrecision(this.statsPrecision) + ', R: ' + r + ', N: ' + points.length,
        data: [
            [xMin, yMin],
            [xMax, yMax]
        ],
        marker: {
            enabled: false
        },
        states: {
            hover: {
                lineWidth: 0
            }
        },
        enableMouseTracking: false
    };
    return line;
};

/*
 * Update the map markers based on the points array
 * 
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {Array}
 * @returh {}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.updateMarkers = function (points) {
    var parse = undefined;
    var location = undefined;
    var coordinates = undefined;
    this.markers.clearMarkers();

    var size = new OpenLayers.Size(5, 7);
    var offset = new OpenLayers.Pixel(-(size.w / 2), -size.h);
    var icon = new OpenLayers.Icon('./img/green_map_marker.png', size, offset);

    // update the map markers
    for (var j = 0; j < points.length; j++) {
        coordinates = points[j].longitude + ' , ' + points[j].latitude;
        parse = coordinates.split(',');
        location = new OpenLayers.LonLat(parse[0], parse[1]);
        markers.addMarker(new OpenLayers.Marker(location, icon.clone()));
    }
}

giovanni.widget.InteractiveScatterPlot.prototype.showMarkers = function (coords) {
    var parse = undefined;
    var loc = undefined;
    this.markers.clearMarkers();

    var size = new OpenLayers.Size(20, 20);
    var offset = new OpenLayers.Pixel(-(size.w / 2), -size.h);
    var icon = new OpenLayers.Icon('./img/green_map_marker.png', size, offset);

    // update the map markers
    var marker = null;
    var self = this;
    for (var i = 0; i < coords.length; i++) {
        parse = coords[i].split(',');
        loc = new OpenLayers.LonLat(parse[0], parse[1]);
        locPlus360 = new OpenLayers.LonLat(parse[0] + 360, parse[1]);
        locMinus360 = new OpenLayers.LonLat(parse[0] - 360, parse[1]);
        marker = new OpenLayers.Marker(loc, icon.clone());
        markerPlus = new OpenLayers.Marker(locPlus360, icon.clone());
        markerMinus = new OpenLayers.Marker(locMinus360, icon.clone());
        /*
                            marker.events.register('mouseover', 
        			marker, 
        			function (evt) { 
        				self.showMarkerInfo(this.lonlat,evt.x,evt.y,parse[2],parse[3]); 
        				OpenLayers.Event.stop(evt);
        		    	}
        		    );
        		    marker.events.register('mouseout',
        			marker,
        			function (evt) { 
        				self.hideMarkerInfo(); 
        				OpenLayers.Event.stop(evt);
        		    	}
        		    );
        */
        //this.markers.addMarker(new OpenLayers.Marker(location, icon.clone()));
        this.markers.addMarker(markerMinus);
        this.markers.addMarker(marker);
        this.markers.addMarker(markerPlus);
        this.showMarkerInfo(loc, null, null, null, null, (i == 0 ? 'Pair Data' : '----'));
    }
}

giovanni.widget.InteractiveScatterPlot.prototype.hideMarkers = function () {
    this.markers.clearMarkers();
    this.hideMarkerInfo();
}

giovanni.widget.InteractiveScatterPlot.prototype.showMarkerInfo = function (geoloc, x, y, dataX, dataY, marker) {
    this.updateCoordinateReadout(marker, geoloc);
}

giovanni.widget.InteractiveScatterPlot.prototype.hideMarkerInfo = function () {
    this.updateCoordinateReadout("", null);
}

giovanni.widget.InteractiveScatterPlot.prototype.showPointsInfo = function (lonlat, radius) {
    //var str = "<small><strong>Corresponding Pair Data for Lon: " + lonlat.lon + ", Lat: " + lonlat.lat + ", Radius: " + radius + " degrees";
    var str = "<small><strong>Corresponding Pair Data for Lon: " + lonlat.lon + ", Lat: " + lonlat.lat;
    str += ": </strong></small><br/>";
    for (var i = 0; i < this.selected.length; i++) {
        str += "<strong>x: </strong>" + this.selected[i].x.toFixed(3) + ", <strong>y: </strong>" + this.selected[i].y.toFixed(3);
        if (!this.isTimeAveraged) {
            str += " <strong>Time: </strong>" + this.selected[i].time;
        }
        str += "<br/>";
    }
    this.pointsPanel.innerHTML = str;
    this.pointsPanel.style.visibility = "visible";
}

giovanni.widget.InteractiveScatterPlot.prototype.hidePointsInfo = function () {
    this.pointsPanel.innerHTML = "";
    this.pointsPanel.style.visibility = "hidden";
}

/* Adjust longitude to a 0 - 360 domain to help handle IDL crossing
 * 
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {String}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.correctForDateLine = function (lon) {
    var adj = parseFloat(lon);
    if (this.userWest > this.userEast && adj <= this.userEast) {
        adj = adj + 360;
    }
    return adj;
}

/*
 * Restore 0 - 360 domain to -180 - 180 to help handling IDL crossing 
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {String}
 * @return {Number}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.inverseDateLine = function (lon) {
    var adj = parseFloat(lon);
    if (adj > 180) {
        adj = adj - 360;
    }
    return adj;
}

/*
 * Used by map to catch window move/scroll events and refresh it's origin to compensate
 *
 * @this {giovanni.widget.InteractiveScatterPlot}
 * @params {YAHOO.util.Event,Object}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.InteractiveScatterPlot.prototype.refreshMap = function (e, o) {
    YAHOO.util.Event.stopPropagation(e);
    window.scrollBy(1, 1);
    this.map.updateSize();
};

giovanni.widget.InteractiveScatterPlot.prototype.getCoordinateReadoutHTML = function () {
    return "<div id='coordsReadout'>" + "<div id='readoutTitle'>----</div>" + "<div id='readoutLat'>Lat: <span id='readoutLatValue'> ---- </span></div>" + "<div id='readoutLon'>Lon: <span id='readoutLonValue'> ---- </span></div>" + "</div>";
};

giovanni.widget.InteractiveScatterPlot.prototype.updateCoordinateReadout = function (title, lonlat) {
    document.getElementById('readoutTitle').innerHTML = title;
    if (lonlat) {
        document.getElementById('readoutLatValue').innerHTML = lonlat.lat.toFixed(4);
        document.getElementById('readoutLonValue').innerHTML = lonlat.lon.toFixed(4);
    } else {
        document.getElementById('readoutLatValue').innerHTML = "----";
        document.getElementById('readoutLonValue').innerHTML = "----";
    }
}

giovanni.widget.InteractiveScatterPlot.prototype.handleGraphLocationEvent = function (x, y, self) {
    var coordinates = [];
    $.each(
        self.jsonArray,
        function (itemNo) {
            if (x === self.jsonArray[itemNo].x && y === self.jsonArray[itemNo].y) {
                coordinates.push(self.jsonArray[itemNo].longitude + "," + self.jsonArray[itemNo].latitude);
            }
        }
    );
    if (coordinates.length > 0)
        self.showMarkers(coordinates);
}

giovanni.widget.InteractiveScatterPlot.prototype.handleShowPoints = function (e, args, self) {
    //YAHOO.util.Event.stopPropagation(e);
    self.chart.series[self.SELECTED].setData(args[0]);
    self.chart.series[self.SELECTED].data[args[0].length - 1].select();
    // second arg is OpenLayers.LonLat
    // third arg is the radius used around the LonLat point
    self.showPointsInfo(args[1], args[2]);
}

giovanni.widget.InteractiveScatterPlot.prototype.correctForIDL = function (lon) {
    if (lon < -180) {
        lon = lon + 360;
    } else if (lon > 180) {
        lon = lon - 360;
    }
    return lon;
}
giovanni.widget.InteractiveScatterPlot.prototype.correctForMinMaxSwap = function (min, max) {
    if (min > 0 && max > 0) {
        if (min > max && max < 0) {
            min = ((180 - min) + 180) * -1;
            max = ((180 - max) + 180) * -1;
        } else if (min > max && max > 0) {
            min = ((180 - min) + 180) * -1;
        }
    } else if (min > max && max < 0) {
        min = ((180 - min) + 180) * -1;
    } else if (min < 0 && max > 180) {
        min = min + 360;
    } else if (min > 0 && max < -180) {
        min = min - 360;
    }
    return [min, max];
}
giovanni.widget.InteractiveScatterPlot.prototype.getCartesianDistance = function (boundsArr) {
    var x1 = parseFloat(boundsArr[0]);
    var y1 = parseFloat(boundsArr[1]);
    var x2 = parseFloat(boundsArr[2]);
    var y2 = parseFloat(boundsArr[3]);

    // handle IDL crossing
    if (x1 > x2 && x2 < 0) {
        x2 = (180 - Math.abs(x2)) + 180;
    }

    var xSQ = (x2 - x1) * (x2 - x1);
    var ySQ = (y2 - y1) * (y2 - y1);
    var xsqrt = Math.sqrt(xSQ);
    var ysqrt = Math.sqrt(ySQ);
    var d = Math.sqrt(xSQ + ySQ);
    return [d, xsqrt, ysqrt];
}
