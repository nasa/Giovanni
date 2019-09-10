//$Id: MapDisplay.js,v 1.14 2015/04/24 17:58:26 kbryant Exp $
//-@@@ SSW, Version $Name:  $
/**
 * 
 *
 */

giovanni.namespace("widget");

giovanni.widget.MapDisplay=function(containerId,config)
{
	//Get the ID of the container element
	this.container=document.getElementById(containerId);
	if (this.container==null){
		alert("Error [giovanni.widget.MapDisplay]: element '"+containerId+"' not found!");
		return;
	}
	//Store the container's ID
	this.containerId=containerId;	
	//Define an object for holding configuration 
	if (config===undefined){
		config={};
	}
	//Set the default zoom to 1
	if (config.zoom===undefined){
		config.zoom={max:10, min:1, defaultVal:1};
	}
        if (config.maxExtent===undefined){
                config.maxExtent=new OpenLayers.Bounds(-180,-90,180,90);
        }
	if (config.maxSelected === undefined){
		config.maxSelected=0; // unlimited selections
	}
	this.maxSelected = config.maxSelected;
	//Create a DIV for the Map status 
	var statusDiv=document.createElement('div');
	statusDiv.setAttribute('id',this.containerId+'Status');
	statusDiv.setAttribute('class','status mapStatus');
	//this.container.appendChild(statusDiv);
	//Create a DIV for cursor location
	var cursorDiv=document.createElement('div');
	cursorDiv.setAttribute('id',this.containerId+'Cursor');
	cursorDiv.setAttribute('class','bboxMapCursor');
	//cursorDiv.setAttribute('class','olControlMousePosition');
	cursorDiv.innerHTML='&nbsp;';
	this.container.appendChild(cursorDiv);
	
	//Create a DIV for Map Controls
	var panZoomDiv=document.createElement('div');
        this.container.appendChild(panZoomDiv);
	var controlDiv=document.createElement('div');
	controlDiv.setAttribute('id',this.containerId+'Control');
	controlDiv.setAttribute('class','bboxMapControl');
	this.container.appendChild(controlDiv);
	
	//Create a DIV for Map itself
	var mapDiv=document.createElement('div');
	mapDiv.setAttribute('id',this.containerId+'Map');
	this.container.appendChild(mapDiv);	

	// add status div
	this.container.appendChild(statusDiv);

	//By default selection type is bounding box
	this.selectionType="BBOX";	
	//Create the OpenLayers map
	var defaultControls=[new OpenLayers.Control.PanZoom()];
	this.hasPointLayer = 0;
	this.noPopups = false;
        this.geojsonFormat = new OpenLayers.Format.GeoJSON();
	this.map=new OpenLayers.Map(this.containerId+'Map',{controls:defaultControls});
	this.map.setOptions({restrictedExtent:config.maxExtent,minResolution:"auto",units:'degrees'});
        //this.map.setOptions({maxExtent:config.maxExtent,minResolution:"auto",units:'degrees'});

        /* for now, remove the blue marble layer in favor a plain map */
        /*
	//Add the blue marble layer
	this.addLayer({name:"Blue Marble", type:"WMS", 
 		//url:"http://maps.opengeo.org/geowebcache/service/wms",
 		url:"https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc",
		parameters:{layers:"bluemarble",format:"image/png"},
		options:{ isBaseLayer: true, wrapDateLine:true, buffer: '2', opacity: 0.35} 
        });
        */

        // for now, again, use coastlines as a base layer
        this.addLayer({name:"Coastlines", type:"WMS",
            url:"https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc",
            parameters: {layers: 'coastline', format: 'image/gif', bgcolor: '0xefeff5'},
            options: {isBaseLayer: true, wrapDateLine:true}	
        });

        // Add country layer
        this.addLayer({name:"Countries", type: "WMS",
                url:"https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc",
                parameters: {layers: 'countries', format: 'image/png'},
                options: {isBaseLayer: false, 'buffer': 1, transparent: true, opacity: 0.35}
        });
        // Add US states layer
        this.addLayer({name:"US States", type: "WMS",
                url:"https://disc1.gesdisc.eosdis.nasa.gov/daac-bin/wms_ogc",
                parameters: {layers: 'us_states', format: 'image/png'},
                options: {isBaseLayer: false, 'buffer': 1, transparent: true, opacity: 0.35}
        });

        // Add graticule control
        var grat = new OpenLayers.Control.Graticule({
            numPoints: 2,
            labelled: true,
            displayInLayerSwitcher: true
        });
        this.map.addControl(grat);
        this.shapeLayer = this.addLayer({
          name: 'shape',
          type: 'Vector',
          options: {
            renderers: ["Canvas", "SVG", "VML"],
            style: {
              strokeColor: '#90EE90',
              strokeWidth: 1,
              fillColor: '#90EE90',
              fillOpacity: 0.4
            }
          }
        });
	//Add a vector layer for drawing 
        this.markerLayer=this.addLayer({name:"Marker", type:"Vector", wrapDateLine:true});
	this.cloneLayer=this.addLayer({name:"Clone",type:"Vector",wrapDateLine:true});
        this.dlLayer=this.addLayer({name:"Dateline",type:"Vector",wrapDateLine:true});
        this.drawDateLine();
	//Formatter for the cursor location (significant digits...) before displaying
	var formatLonLat=function(lonLat){
		var lat=lonLat.lat;
		var lon=lonLat.lon;
		if (Math.abs(lat)<=90 && Math.abs(lon)<=180){
			var ns=OpenLayers.Util.getFormattedLonLat(lat,'lat','dm');
			var ew=OpenLayers.Util.getFormattedLonLat(lon,'lon','dm');
			return ns+', '+ew;
		}
		return '&nbsp;';
	};
	//Enable cursor location display
    this.map.addControl(new OpenLayers.Control.MousePosition({div:cursorDiv,numDigits:1, formatOutput:formatLonLat}));
    //var graticuleCtl=new OpenLayers.Control.Graticule({numPoints:2,labelled:true});
    //this.map.addControl(graticuleCtl);
    
    //Create Pan control
    var navControl = new OpenLayers.Control.Navigation({title: 'Click and Drag to pan the map'});
    //Create the bounding box selection control
    var bboxControl=this.getBoundingBoxControl({type:OpenLayers.Control.TYPE_TOOL,
    	title: 'Click and Drag to draw region of interest', 
    	displayClass:'olControlBbox'});
    //Create a control panel with default control as the bounding box selection control
    var controlPanel=new OpenLayers.Control.Panel({defaultControl:bboxControl, div:document.getElementById(this.containerId+'Control')});
    //Add created controls to the control panel
    controlPanel.addControls([bboxControl,navControl]);
    this.navControl=navControl;
    this.bboxControl=bboxControl;
    //Add the control panel
    this.map.addControl(controlPanel);
    //Set the map center to (0,0)
    this.map.setCenter(new OpenLayers.LonLat(0, 0), config.zoom.defaultVal);

    //Create a custom event for completion of selection
    this.onSelectionEvent=new YAHOO.util.CustomEvent("SelectionEvent",this);
    this.onSelectionEventOG=new YAHOO.util.CustomEvent("SelectionEvent",this);

this.map.isValidZoomLevel = function(zoomLevel) {
   if (zoomLevel<1){
     this.zoomTo(1);
   }
   return (zoomLevel >=1 ? true : false);
}


};



/////////// Edited by: tjoshi, 04/26/11 /////////////////////////////////
/////////// START POINT DATA CODE ///////////////////////////////////////


giovanni.widget.MapDisplay.prototype.addPoints=function(points){
	// Set up marker layer
	if(!this.hasPointLayer){
	    this.selectedPoints = new Array(); // keeps track of selected points
	    this.markers = new Array(); // to validate uniqueness on marker name
	    this.pointLayer = new OpenLayers.Layer.Markers("PointLayer");
	    this.map.addLayer(this.pointLayer);
	    // create custom point selection event
	    this.onPointSelectionEvent=new YAHOO.util.CustomEvent("PointSelectionEvent",this);
	    this.onBoxSelectionEvent=new YAHOO.util.CustomEvent("BoxSelectionEvent",this);
            this.icons = ['../giovanni/images/offMarker.png','../giovanni/images/hoverMarker.png','../giovanni/images/onMarker.png'];
	    // subscribe to bounding box selection event
	    this.onSelectionEvent.subscribe( this.updateSelectedPoints, this );
	    this.hasPointLayer = 1;
	    
	}
	for(var i=0; i<points.length; ++i){
	    // Validate point data and set defaults
	    if(points[i].name === undefined){
		alert("Point data must have a name!");
	        continue;
	    }
	    if(points[i].name in this.markers){
		alert("Point data must have a UNIQUE name: " + points[i].name);
		continue;
	    }
	    if(points[i].latitude === undefined || points[i].longitude === undefined){
		alert("Point data must have a lat and lon coordinate!");
		continue;
	    }
	    if(points[i].latitude > 90 || points[i].latitude < -90 || points[i].longitude > 180 || points[i].longitude < -180){
		alert("Point data must have valid coordinates: (-90 <= lat <= 90) and (-180 <= lon <= 180)");
		continue;
	    }
	    if(points[i].title === undefined){
		points[i].title = points[i].name;
	    }
	    if(points[i].description === undefined){
		points[i].description = "";
	    }
	    // Create Marker on marker layer
	    var size = new OpenLayers.Size(10,10);
            var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
	    var markerIcon = new OpenLayers.Icon(this.icons[0],size,offset);
	    var marker = new OpenLayers.Marker(new OpenLayers.LonLat(points[i].longitude,points[i].latitude),markerIcon);
	    marker.name = points[i].name;
	    marker.popup = null; 
	    marker.self = this;
	    marker.title = "<b>"+points[i].title+"</b>";
	    marker.description = points[i].description+"";
	    marker.attributes = new Array();
	    for(var key in points[i]){
		if( key != "title" && key != "description" && key !="latitude" && key !="longitude" && key !="name"){
		    marker.attributes[key] = points[i][key];	
		}
            }
	    marker.statusMsg = "<span style='color:green'>Click to selct</span>";
	    // register events for the marker
            marker.events.register('mousedown', marker, this.pointMousedown); 
	    marker.events.register('mouseover', marker, this.pointMouseover);
	    marker.events.register('mouseout', marker, this.pointMouseout);
	    this.markers[marker.name] = marker;
	    //add the marker
	    this.pointLayer.addMarker(marker);
	}

};

giovanni.widget.MapDisplay.prototype.hideAllPoints = function(){
    for(var i=0; i<this.pointLayer.markers.length; ++i){	
	var marker = this.pointLayer.markers[i];
        if( !(marker.popup === null) ){
	    this.map.removePopup(marker.popup);
    	    marker.popup.destroy();
    	    marker.popup = null;
        }
    }
    this.setSelectedPoints([]);
    this.pointLayer.clearMarkers();
};

giovanni.widget.MapDisplay.prototype.showSelectedPoints = function(pointNames){
    for(var i=0; i<pointNames.length; i++){
	if(this.markers[pointNames[i]] === undefined){
	    alert("Please add point before attempting to display it!");
        }
	this.pointLayer.addMarker(this.markers[pointNames[i]]);
    }
};

giovanni.widget.MapDisplay.prototype.setSelectedPoints = function(pointNames){
    for(var j=0; j<this.pointLayer.markers.length; j++){
	if(this.pointLayer.markers[j].name in pointNames){
	    this.toggleSelected(this.pointLayer.markers[j],false,true,false);
	}
	else{
	    this.toggleSelected(this.pointLayer.markers[j],true,false,false);
	}
    }
    this.firePointSelectionEvent(); // fire a selection event
};

giovanni.widget.MapDisplay.prototype.updateSelectedPoints = function(evt,args,self){
    var maxLat = args[0][2];
    var minLat = args[0][0];
    var maxLon = args[0][3];
    var minLon = args[0][1];
    var returnArray = new Array();
    for(var i=0; i<self.pointLayer.markers.length; i++){
        var markerLatLon = self.pointLayer.markers[i].lonlat;
	if( markerLatLon.lat > minLat && markerLatLon.lat < maxLat && markerLatLon.lon > minLon && markerLatLon.lon < maxLon ){
	    returnArray.push(self.pointLayer.markers[i].name);
	    //self.toggleSelected(self.pointLayer.markers[i],false,true,false); // toggle only to SELECTED if applicable, and don't show popups
        }else{
	    //self.toggleSelected(self.pointLayer.markers[i],true,false,false); // toggle only to DESELECTED if applicable, and don't show popups
	}
    }    
    // fire a selection event
    if(returnArray.length > 0){
        self.hideAllPoints();
        self.showSelectedPoints(returnArray);
        self.onBoxSelectionEvent.fire({pointNames:returnArray});
    }

};

giovanni.widget.MapDisplay.prototype.pointMouseout = function(evt){
	// change icon back to its old status
	if( ! (this.name in this.self.selectedPoints) ){
	    this.icon.setUrl(this.self.icons[0]);
        }else{
	    this.icon.setUrl(this.self.icons[2]);
	}
	// kill popups
	if(!(this.popup === null)){
            this.self.map.removePopup(this.popup);
            this.popup.destroy();
            this.popup = null;
	}
	OpenLayers.Event.stop(evt);    
};

giovanni.widget.MapDisplay.prototype.pointMouseover = function(evt){
	this.self.clearPopups();
	// set icon to yellow
	this.icon.setUrl(this.self.icons[1]);
	// create and add popup for the marker
	if(!(this.self.noPopups === true)){
            this.popup = this.self.createPopup(this);          
	    this.self.map.addPopup(this.popup);
	}
        OpenLayers.Event.stop(evt);
};

giovanni.widget.MapDisplay.prototype.pointMousedown = function(evt){
    this.self.toggleSelected(this,true,true,true); // toggle SELECTED or DESELECTED and show popups
    this.self.firePointSelectionEvent(); // fire a selection event
    OpenLayers.Event.stop(evt);
};

giovanni.widget.MapDisplay.prototype.firePointSelectionEvent = function(){
    this.onPointSelectionEvent.fire({pointNames:this.selectedPoints});

};

giovanni.widget.MapDisplay.prototype.getSelectedPoints = function(){
    // put selected marker names from associative array to standard array to return to the user
    return this.selectedPoints;

};

giovanni.widget.MapDisplay.prototype.getSelectedSize = function(){
    var myArray = new Array();
    for(var name in this.selectedPoints){
	myArray.push(name);
    }
    return myArray.length;
};

giovanni.widget.MapDisplay.prototype.toggleSelected = function(marker,deselectFlag,selectFlag,refreshFlag){
    // if the marker is already selected, and deselecting is allowed
    if( marker.name in this.selectedPoints  && deselectFlag ){
	// deselect the point
        delete this.selectedPoints[marker.name];
        marker.icon.setUrl(this.icons[0]);
        marker.statusMsg = "<span style='color:green'>Not Selected: click to SELECT</span>";
    } // if the marker is not already selected and selecting is allowed
    else if(selectFlag){
	// select the point
	if( (this.maxSelected != 0) && (this.getSelectedSize() >= this.maxSelected) ){
	    this.setSelectedPoints([]);
        }
	this.selectedPoints[marker.name] = 1;
	marker.icon.setUrl(this.icons[2]);
	marker.statusMsg = "<span style='color:red'>Click to remove</span>";

    }
    // if popups should be shown, refresh popups
    if(refreshFlag){
    	this.refreshPopup(marker);
    }
    return;

};

giovanni.widget.MapDisplay.prototype.createPopup = function(marker){
    // create a popup at the marker's lonlat called my popup with a div with meta info and status
    var mylat = marker.lonlat.lat;
    var mylon = marker.lonlat.lon;
//    if(marker.lonlat.lat < 0){ mylat = marker.lonlat.lat + 20;}
//    if(marker.lonlat.lon < 0){ mylat = marker.lonlat.lon + 20;}
    var attrString = "";
    /*attrString += "<table style='border:1px solid; width:100%; font-size:8px; height:20px;'>"; 
    for(var key in marker.attributes){
	attrString += "<tr><td>"+key+"</td><td>" + marker.attributes[key]+"</td></tr>";
    }
    attrString += "</table>";*/
    var html = "<div style='font-size:12px;'><h1 style='display:block; font-size:12px;'>"+ marker.title +" (lat: "+ marker.lonlat.lat + ", lon: " + marker.lonlat.lon +")</h1>";
    html += "" + marker.description + attrString + marker.statusMsg + "</div>";
    var mylonlat = new OpenLayers.LonLat(mylon,mylat);
    return new OpenLayers.Popup.FramedCloud("myPopup",
                                     mylonlat,
                                     null,
                                     html,
                                     marker.icon, false);

};

giovanni.widget.MapDisplay.prototype.refreshPopup = function(marker){
    // if popup doesnt exist, don't destroy it
    if( !(marker.popup === null) ){
	this.map.removePopup(marker.popup);
    	marker.popup.destroy();
    	marker.popup = null;
    }
    // create and add the popup to the map
    if(!(this.noPopups === true)){
        marker.popup = this.createPopup(marker);
        this.map.addPopup(marker.popup);
    }
    return;
};

giovanni.widget.MapDisplay.prototype.clearPopups = function(){
    for(var i=0; i<this.pointLayer.markers.length; ++i){
	var marker = this.pointLayer.markers[i];
	if(!(marker.popup===null)){
	    this.map.removePopup(marker.popup);
	    marker.popup.destroy();
	    marker.popup= null;
        }

    }

};


/////// END POINT DATA CODE ///////////////////////////////////////////////////

giovanni.widget.MapDisplay.prototype.addLayer=function(config)
{
	var layer;
	if (config.type==='WMS'){
		//Adding a WMS layer
		layer=new OpenLayers.Layer.WMS(config.name,config.url,config.parameters,config.options);
		this.map.addLayer(layer);
	}else if (config.type==='Vector'){
		//Adding a vector layer
		layer=new OpenLayers.Layer.Vector(config.name, config.options);
		this.map.addLayer(layer);
	}
	//Return the layer
	return layer;
};

giovanni.widget.MapDisplay.prototype.drawBoundingBox=function()
{
	if (this.nwCorner===undefined || this.seCorner===undefined){
	  return;
	}
	var markerStyle = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default']);
	markerStyle.fillOpacity = 0.2;
	markerStyle.graphicOpacity = 1;
	var tl=this.nwCorner;
	var br=this.seCorner;

	// correct for dateline crossing
	if(tl.lon > 0 && br.lon > 0){
	    if(tl.lon > br.lon && br.lon < 0){
                tl.lon = ((180 - tl.lon) + 180) * -1;
                br.lon = ((180 - br.lon) + 180) * -1;
	    }else if(tl.lon > br.lon && br.lon > 0){
                tl.lon = ((180 - tl.lon) + 180) * -1;
	    }
	}else if(tl.lon > br.lon && br.lon < 0 ){
            tl.lon = ((180 - tl.lon) + 180) * -1;
        }

	var pointList=[];
	pointList.push(new OpenLayers.Geometry.Point(tl.lon,tl.lat));
	pointList.push(new OpenLayers.Geometry.Point(tl.lon,br.lat));
	pointList.push(new OpenLayers.Geometry.Point(br.lon,br.lat));
	pointList.push(new OpenLayers.Geometry.Point(br.lon,tl.lat));
	var linearRing = new OpenLayers.Geometry.LinearRing(pointList);
	var region=new OpenLayers.Feature.Vector(
	  new OpenLayers.Geometry.Polygon([linearRing]),null,markerStyle);
	this.markerLayer.addFeatures(region);

	this.drawBBClone();

};

// Draws region clones to fool OL into displaying the user-selected region
// in multiple globes (overcomes an OL limitation dealing with maps greater
// than 360 degrees - happens when wrapping the map)
giovanni.widget.MapDisplay.prototype.drawBBClone = function () {
	var tl=this.nwCorner;
	var br=this.seCorner;
        this.drawCloneRegion(1);
	this.drawCloneRegion(-1);
}

// Draw a region on the clone layer
giovanni.widget.MapDisplay.prototype.drawCloneRegion = function (factor) {
	if(factor===undefined){ factor = 1; }
        // establish layer style for new feature (region)
	var cloneStyle = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default']);
	cloneStyle.fillOpacity = 0.2;
	cloneStyle.graphicOpacity = 1;
	// grab corners from class
	var tl=this.nwCorner;
	var br=this.seCorner;
	// lon/lat times n number of 'globes' to repeat the marker layer selection
  	tl.lon = tl.lon + 360*factor;
  	br.lon = br.lon + 360*factor;
	// push region points into an array
  	var pointList=[];
  	pointList.push(new OpenLayers.Geometry.Point(tl.lon,tl.lat));
  	pointList.push(new OpenLayers.Geometry.Point(tl.lon,br.lat));
  	pointList.push(new OpenLayers.Geometry.Point(br.lon,br.lat));
  	pointList.push(new OpenLayers.Geometry.Point(br.lon,tl.lat));
	// create a new OpenLayers linear ring of points to establish the region
  	var linearRing = new OpenLayers.Geometry.LinearRing(pointList);
  	var region=new OpenLayers.Feature.Vector(
  	  new OpenLayers.Geometry.Polygon([linearRing]),null,cloneStyle);
	// add the linear ring as a feature to the layer
  	this.cloneLayer.addFeatures(region);
}


//Adds an OpenLayers control for selecting bounding boxes
giovanni.widget.MapDisplay.prototype.getBoundingBoxControl=function(config)
{
	if (config===undefined){
		config={};
	}
	config.self=this;
	this.bboxControl=new OpenLayers.Control(config);
	this.bboxControl.oldActivate=this.bboxControl.activate;
	this.bboxControl.oldDeActivate=this.bboxControl.deactivate;
	OpenLayers.Util.extend(this.bboxControl,
			{				
				draw: function(){
					this.self.noPopups = true;
					this.box=new OpenLayers.Handler.Box(this.self.bboxControl, 
							{"done": this.notice});
					var oldStartBox=this.box.startBox;
					OpenLayers.Util.extend(this.box,{
						startBox: function(xy){
							this.self.markerLayer.destroyFeatures();
							this.self.cloneLayer.destroyFeatures();
							//oldStartBox(xy);
						}
					});
				},
				notice: function(bounds){
					this.self.noPopups = false;
					this.self.markerLayer.destroyFeatures();
					this.self.cloneLayer.destroyFeatures();
					var tl=this.self.map.getLonLatFromPixel(new OpenLayers.Pixel(bounds.left,bounds.top));
					var br=this.self.map.getLonLatFromPixel(new OpenLayers.Pixel(bounds.right,bounds.bottom));
					this.self.nwCorner=tl;
					this.self.seCorner=br;
                                        this.self.drawBoundingBox();

				        // correct for lon values > +/-180 degrees
          				if( tl.lon < -180 ){
	  				  tl.lon = tl.lon + 360;
          				}else if( tl.lon > 180 ){
					  tl.lon = tl.lon -360;
					}
					if( br.lon < -180 ){
					  br.lon = br.lon + 360;
					}else if( br.lon > 180 ){
	    				  br.lon = br.lon - 360;
          				} 

					this.self.onSelectionEvent.fire([br.lat,tl.lon,tl.lat,br.lon]);
					this.self.onSelectionEventOG.fire([tl.lon,br.lat,br.lon,tl.lat]);
				},
				toggleActivate: function(){alert('toggle');},
				activate: function(){
					this.box.activate();
					this.self.bboxControl.oldActivate();
				},
				deactivate: function(){
					this.box.deactivate();
					this.self.bboxControl.oldDeActivate();
				},
				redraw: function(){
					alert('redraw');
				},
				trigger: function(){
					alert('trigger');
				},
				click: function(){
					alert('test');
				}
			}
			);
	return this.bboxControl;
};

//Hides a layer given its name
giovanni.widget.MapDisplay.prototype.hideLayer=function(name)
{
	//Loop through all layers in the map to look for layer with specified name
	for (var i=0; i<this.map.layers.length; i++){
		if (this.map.layers[i].name===name){
			//Set visibility of the given layer to false
			this.map.layers[i].setVisibility(false);
		}
	}
		
};

//Shows a layer given its name
giovanni.widget.MapDisplay.prototype.showLayer=function(name)
{
	//Loop through all layers in the map to look for layer with specified name
	for (var i=0; i<this.map.layers.length; i++){
		if (this.map.layers[i].name===name){
			//Set visibility of the given layer to true
			this.map.layers[i].setVisibility(true);
		}
	}		
};

giovanni.widget.MapDisplay.prototype.redraw=function()
{
	alert('test');
  this.showLayer('Marker');
  this.drawBoundingBox();
};

//Sets the value of the Map component
giovanni.widget.MapDisplay.prototype.setValue=function(nw,se)
{
this.markerLayer.destroyFeatures();
this.cloneLayer.destroyFeatures();
if (nw!==undefined && se!==undefined){
this.nwCorner=new OpenLayers.LonLat(nw.lon,nw.lat);
this.seCorner=new OpenLayers.LonLat(se.lon,se.lat);
}else{
delete(this.nwCorner);
delete(this.seCorner);
}
this.drawBoundingBox();
this.hideLayer('Marker');
};

giovanni.widget.MapDisplay.prototype.setValueOG=function(w,s,e,n){
    this.markerLayer.destroyFeatures();
    this.cloneLayer.destroyFeatures();
    if(w !== undefined && s!== undefined && e!==undefined && n!==undefined){
	this.nwCorner = new OpenLayers.LonLat(w,n);
	this.seCorner = new OpenLayers.LonLat(e,s);
    }else{
	delete(this.nwCorner);
	delete(this.seCorner);
    }
    this.drawBoundingBox();
    this.hideLayer('Marker');
};

giovanni.widget.MapDisplay.prototype.show=function()
{
  this.showLayer('Marker');
  this.showLayer('Clone');
  this.showLayer('Dateline');
  this.showLayer('Graticule');
};

//Hide the map
giovanni.widget.MapDisplay.prototype.hide=function()
{
  this.hideLayer('Marker');
  this.hideLayer('Clone');
  this.hideLayer('Dateline');
  this.hideLayer('Graticule');
};

giovanni.widget.MapDisplay.prototype.drawDateLine = function () {
        var dlStyle = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default']);
        dlStyle.strokeColor = "red";
        dlStyle.strokeWidth = 1;
        dlStyle.strokeOpacity = 1;
        var linePoints=[];
        linePoints.push(new OpenLayers.Geometry.Point(180,90));
        linePoints.push(new OpenLayers.Geometry.Point(180,-90));
        var line0 = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.LineString(linePoints),null,dlStyle);
        linePoints = [];
        linePoints.push(new OpenLayers.Geometry.Point(-180,90));
        linePoints.push(new OpenLayers.Geometry.Point(-180,-90));
        var line1 = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.LineString(linePoints),null,dlStyle);
        this.dlLayer.addFeatures([line0,line1]);
}

/**
 * Handle status change events from the using picker (e.g., BoundingBoxPicker.js)
 * 
 * @this (Giovanni.widget.MapDisplay)
 *
 * @param (YAHOO.util.CustomEvent,Array,Object)
 * @author K. Bryant
 **/
giovanni.widget.MapDisplay.prototype.handleStatusChange = function(evt,args,self){
	self.setStatus(args[0],args[1]);
}

/**
 * set the maps status (generally an echo of the picker user the map - e.g., BoundingBoxPicker.js)
 *
 * @this (Giovanni.widget.MapDisplay)
 *
 * @param (String,boolean)
 * @author K. Bryant
 */
giovanni.widget.MapDisplay.prototype.setStatus = function (s,isError) {
  this.statusStr = s;
  var statusDiv = document.getElementById(this.containerId+'Status');
  statusDiv.style.color = (isError === true)? "red":"green";
  statusDiv.innerHTML = "" + s + "";
}

giovanni.widget.MapDisplay.shapeCache = {};

giovanni.widget.MapDisplay.prototype.setShape = function(shapeFileId, shapeId) {
	var self = this;
	
	if (!shapeFileId || !shapeId) {
		self.shapeLayer.removeAllFeatures();
		return $.when({});
	}

	var queryValue = shapeFileId + '/' + shapeId;
	var possibleShape = giovanni.widget.MapDisplay.shapeCache[queryValue];
	var shapeInCache = !!possibleShape;
  var deferred = shapeInCache ?
		$.when(possibleShape) :
		$.get('daac-bin/getGeoJSON.py?shape=' + queryValue);
	
	var body = $(document.body).addClass('progress-cursor');
  deferred.always(function() {
			self.shapeLayer.removeAllFeatures();
			window.setTimeout(function() {
				body.removeClass('progress-cursor');		
			}, 10);
		})
  	.then(function(json) {
			if (!possibleShape) {
    		giovanni.widget.MapDisplay.shapeCache[queryValue] = json;
			}

		if (json.type === "FeatureCollection") {
			self.shapeLayer.addFeatures(self.geojsonFormat.read(json));
		} else {
			console.log('geojson has not been generated');
			return $.when('geojson has not been generated');
		}
    }, function(err) {
      console.log(err);
    });

	return deferred;
};
