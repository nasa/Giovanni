/**
 * @this This file contains a single Jasmine test specification for:
 * UI-BboxPicker-001
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */



describe("UI-BboxPicker-001",
	function() {

		var QUERY_STRING = "service=TmAvMp&starttime=&endtime=&bbox=-180,-90,180,90";

		beforeAll(async function(){
			// Load the bookmarked URL into the GUI.
			await querySetupNoVar(QUERY_STRING);
		});

		// afterAll(async function() {
	 //    await querySetup("service=", CRITERIA_UPDATE_WAIT_PERIOD);
	 //  });

		it("should find the default bounding box values.",
			async function() {
				// Verify the bounding box picker contains the
				// default values.
			
				var field =
						document.getElementById("sessionDataSelBbPkbbox");
				expect(field).toBeTruthy();
				expect(field.value).toBe("-180,-90,180,90");
		}); // end it()

		it("map appears when you click on the globe.",
			function() {
				var element = document.getElementById('sessionDataSelBbPkmapLink');
				element.click();
				var map;
				map = session.dataSelector.boundingBoxPicker.Map.map;
				expect(map).not.toBe(null);
				var closeButton = $("div#mapPanel").find("a");
				closeButton[0].click();
		}); // end it()

		it("show Australia and Madagascar",
			function() {
				field = document.getElementById('sessionDataSelBbPkbbox');
				field.value = '110, -45, 155, -9 ';
				mychange(field);
				var element = document.getElementById('sessionDataSelBbPkmapLink');
				myfire(element);

				// get BoundingBoxPicker.MapDisplay so we can grab the
				// the extent drawn on the map
				mapDisplay = session.dataSelector.boundingBoxPicker.Map;
				expect(mapDisplay).not.toBe(null);
				// grab the drawn bounds
				mapBbox = mapDisplay.markerLayer.getDataExtent();
				expect(mapBbox).toBeTruthy();
				// turn the field value into a bounds for comparison
				expect(field).toBeTruthy();
				var fvA = field.value.split(",");
				var fvBounds = new OpenLayers.Bounds(fvA[0],fvA[1],fvA[2],fvA[3]);
				// compare field value bounds to the drawn bounds; they should be the same
				expect(fvBounds.toBBOX(4)).toEqual(mapBbox.toBBOX(4));
				
				field = document.getElementById('sessionDataSelBbPkbbox');
				field.value = '42, -29, 50, -12';
				mychange(field);
				var element = document.getElementById('sessionDataSelBbPkmapLink');
				myfire(element);

				// get BoundingBoxPicker.MapDisplay so we can grab the
				// the extent drawn on the map
				expect(mapDisplay).not.toBe(null);
				// grab the drawn bounds
				mapBbox = mapDisplay.markerLayer.getDataExtent();
				expect(mapBbox).toBeTruthy();
				// turn the field value into a bounds for comparison
				var fvA = field.value.split(",");
				var fvBounds = new OpenLayers.Bounds(fvA[0],fvA[1],fvA[2],fvA[3]);
				// compare field value bounds to the drawn bounds; they should be the same
				expect(fvBounds.toBBOX(4)).toEqual(mapBbox.toBBOX(4));
			
				var closeButton = $("div#mapPanel").find("a");
				closeButton[0].click();
			}); // end it()

		it("should make a map selection with the mouse to get a non-default bounding box.",
			function() {			
				var showMapButton =
						document.getElementById("sessionDataSelBbPkmapLink");
				expect(showMapButton).toBeTruthy();
				showMapButton.click();

				// Select a region on the map with the mouse.
				var mapBbox;
				
				// Grab the the actual MapDisplay object (bboxMap) 
				// from BoundingBoxPicker class (bboxPicker)
				var bboxPicker = session.dataSelector.boundingBoxPicker;
				expect(bboxPicker).toBeTruthy();
				var bboxMap = bboxPicker.Map;
				expect(bboxMap).toBeTruthy();

				// Get the current scroll positions.
				var pageXOffset = window.pageXOffset;
				var pageYOffset = window.pageYOffset;

				// Get the location of the upper-left corner
				// of the map widget in the browser content
				// area (NOT the visible area).
				var mapPanel_c =
						document.getElementById("mapPanel_c");
				expect(mapPanel_c).toBeTruthy();
				var mapWidgetLeft = mapPanel_c.offsetLeft;
				var mapWidgetTop = mapPanel_c.offsetTop;

				// Drill down to the map itself.
				var bboxBboxMappMap =
						document.getElementById("bboxBboxMappMap");
				expect(bboxBboxMappMap).toBeTruthy();
				var OLviewPort = bboxBboxMappMap.childNodes[0];
				expect(OLviewPort).toBeTruthy();
				var OLcontainer = OLviewPort.childNodes[0];
				expect(OLcontainer).toBeTruthy();
				var OLmap = OLcontainer.childNodes[3];

				expect(OLmap).toBeTruthy();

				// Compute the positions of the mouse down and
				// mouse up events relative to the upper-left
				// corner of the current visible area in the
				// browser.
				var leftOffset = 100;
				var topOffset = 100;
				var width = 100;
				var height = 100;
				var left = (mapWidgetLeft - pageXOffset) + leftOffset;
				var top = (mapWidgetTop - pageYOffset) + topOffset;
				var right = left + width;
				var bottom = top + height;

				// NOTE: The current code REQUIRES that the
				// entire map widget be visible for the test
				// to execute properly.

				// Create a mouse event (left mouse button
				// down) to send to the map.
				var mousedownEvent = document.createEvent("MouseEvent");
				mousedownEvent.initMouseEvent("mousedown", true, true,
																			window, 0, 0, 0,
																			left, top,
																			false, false, false,
																			false, 1, null);
				OLmap.dispatchEvent(mousedownEvent);

				// Create a mouse event (left mouse button up)
				// to send to the map.
				var mouseupEvent = document.createEvent("MouseEvent");
				mouseupEvent.initMouseEvent("mouseup", true, true,
																		window, 0, 0, 0,
																		right, bottom,
																		false, false, false,
																		false, 1, null);
				OLmap.dispatchEvent(mouseupEvent);

				// Get OpenLayers map vector layer object
				// so we can grab the feature object that
				// is the bounding box and get it's bounds
				var boxLayer = bboxMap.markerLayer;
				expect(boxLayer).toBeTruthy();
				mapBbox = boxLayer.getDataExtent();
				expect(mapBbox).toBeTruthy();

				// A new bounding box should now be selected.
				// Get te bounding box coordinates from the text field
				var boundingBoxField =
						document.getElementById("sessionDataSelBbPkbbox");
				expect(boundingBoxField).toBeTruthy();
				var fv = boundingBoxField.value;
				// turn the string value into a bounds to remove the spaces
				expect(fv).toBeTruthy();
				var fvA = fv.split(",");
				expect(fvA).toBeTruthy();
				var fieldBounds = new OpenLayers.Bounds(fvA[0],fvA[1],fvA[2],fvA[3]);
				// compare the text field bounds with the feature object bounds;
				// they should be the same
				expect(fieldBounds.toBBOX(4)).toBe(mapBbox.toBBOX(4));

				var closeButton = $("div#mapPanel").find("a")[0];
				expect(closeButton).toBeTruthy();
				closeButton.click();
		}); // end it()

		it("should use a mouse drag to move the map viewpoint.",
			function() {
					
				var mapControlsContainer =
						document.getElementById("bboxBboxMappControl");
				expect(mapControlsContainer).toBeTruthy();
				var handButton = mapControlsContainer.childNodes[1];
				expect(handButton).toBeTruthy();
				clickADiv(handButton); // click() does not work?

				// Fetch the initial map view position.
				var mapViewport;
				var startLoc;
				var stopLoc;

				// fetch the map container and check that it's ok
				var mapContainer = document.getElementById("mapPanel_c");
				expect(mapContainer).toBeTruthy();

				// fetch the actual map object and it's viewport so
				// we can work with the viewport (can't get the actual SVG object)
				var bboxPicker = session.dataSelector.boundingBoxPicker;
				expect(bboxPicker).toBeTruthy();
				var mapDisplay = bboxPicker.Map;
				expect(mapDisplay).toBeTruthy();
				var olmap = mapDisplay.map;
				mapViewport = olmap.getViewport();
				// make sure the viewport is there
				expect(mapViewport).toBeTruthy();

				// fetch the container location
				startLoc = mapViewport.getBoundingClientRect();

				// grab style location from map container as it is available
				var mcStyleTop = parseInt(mapContainer.style.top.replace('px'));
				var mcStyleLeft = parseInt(mapContainer.style.left.replace('px'));
				// add modify the style location
				mapContainer.style.top = mcStyleTop + 10 + 'px';
				mapContainer.style.left = mcStyleLeft + 10 + 'px';

				// Make sure the map has moved.
				// grab the new location of the viewport....it should have changed
				// with the moving of the map container panel since it is contained
				// within
				stopLoc = mapViewport.getBoundingClientRect();
				// top and left attributes of div should change.
				expect(stopLoc.top).toBe((startLoc.top + 10));
				expect(stopLoc.left).toBe((startLoc.left + 10));

				var closeButton = $("div#mapPanel").find("a")[0];
				expect(closeButton).toBeTruthy();
				closeButton.click();

			}); // end it()

}); // end describe()
