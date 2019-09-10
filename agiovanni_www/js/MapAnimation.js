//$Id: MapAnimation.js,v 1.67 2015/02/03 19:02:55 kbryant Exp $
//-@@@ AG, Version $Name:  $
/**
 * Used by ResultView to display interactive, animated maps.  Map class has pan, zoom and
 * layer-switching functionality.  OpenLayers is the current OTS used to
 * render the map.  The plot itself is added as a layer.  Animation class has 'start', 
 * 'stop' and 'pause' controls
 */

giovanni.namespace('giovanni.widget.MapAnimation');

/*
 * Constructor
 * 
 * Builds MapAnimation class.  Uses the OverlayMap class (OverlayMap.js) to handle
 * plot options
 * 
 * @constructor
 * @this {giovanni.widget.MapAnimation}
 * @params {String, Object}
 * @returns {giovanni.widget.MapAnimation}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation = function (containerId, config) {
    // container id
    this.containerId = containerId;
    // container element
    this.container = $('.animationImageFrame');
    // time indices
    this.times = [];
    // hold the layer parameters
    this.layerData = null;
    // rate at which the animation runs (milliseconds per frame - the delay between attempted frame refreshes)
    this.animRate = 125;
    // animation frame count
    this.frameIndex = 0;
    // have all of the frames been loaded?
    //this.framesLoaded = [];
    // track initial state of class so we can re-enable disabled animation icons and map controls
    //this.loaded = false;
    // track layer loading
    this.layerLoaded = true;
    //this.bufLayerLoaded = true;
    this.animationTimeout = null;
    // loading panel - contains progress text and bar
    this.loadingPanel = null;
    // last animation command
    this.lastCommand = '';
    // pause/play state
    this.paused = undefined;
    // Subscribe to animation refresh events.  These occur when the min/max range is
    // set or the palette is updated.
    //this.animatedMap.refreshAnimationEvent.subscribe(this.handleRefreshEvent, this);
    // frame title
    this.title = "";
    // frame subtitle
    this.subtitle = "";
    // frame caption
    this.caption = undefined;
    // default frame width
    this.animationWidth = session ? session.getAnimationDims.width : 1024;
    // default frame height
    this.animationHeight = session ? session.getAnimationDims.height : 512; 
    // placeholder for map options object 
    this.mapOptions = null;
    this.imageCache = [];
    // handle login events
    // (uncomment next 3 lines to require login in order to enable download of animation)
    //if (login) {
    //    login.loginEvent.subscribe(this.handleLoginEvent,this);
    //}
    // call render to build the animation controls and start the animation
    this.render();
}

giovanni.widget.MapAnimation.prototype.refresh = function(groupContainer) {
    $(groupContainer).append(this.container);
    //if (this.firsttime || Object.keys(this.imageCache).length < this.times.length) 
      this.start(true);
}

giovanni.widget.MapAnimation.prototype.addLayerData = function (plotData) {
    var self = this;
    if(plotData.getSource().indexOf("getGiovanniMapInfo")>-1){
      // bad - this is an old server side response
      $('.animationImageFrame').html("<div>Sorry, but there has been an error.  Check the console or try again.</div>");
      return;
    }
    $.ajax({
        url: plotData.getSource(),
        method: "GET",
        async: true,
        success: function (data) {
            self.addDataLayerToMap(data, plotData);
        }
    });
}

giovanni.widget.MapAnimation.prototype.addDataLayerToMap = function (data, plotData) {
    // resulting data object
    var requestData = data.layers;
    // set a global holder for the layer data
    var layerData = data.layers.layer[0];
    // set the times array
    var times = data.layers.time;
    // check times - if there are none, don't do anything
    // as we don't have anything to animate
    if (times == null || times.length == 0) {
        // loading message element
        $('.animationImageFrame').html(
          "Our apologies, but there was a problem loading this animation.  Please try again or <span class=\"inlineFeedbackLink\" onclick=\"session.sendFeedback(event,'workspace');\">send us feedback</span> and we'll investigate.  Thanks!");
        return;
    }

    // precache the images
    //this.precacheImages(requestData, this);

    this.title = layerData.title;
    this.subtitle = layerData.subtitle;
    this.caption = layerData.caption;

    // use CSS to make animation image conform to result view space constraints
    var bbox =  layerData.bbox;
    var dist = giovanni.util.getCartesianDistance(bbox.split(','));
    var dx = dist[1];
    var dy = dist[2];
    var width = $('.resultView').width()  - 220;
    var height = Math.floor( (width * dy) / dx );
    if( dy > (dx/2) ) {
        height = $('.resultView').height() - 220;
        width = Math.floor( height *  (dx / dy) );        
    }
    $('.animationImage').width(width);
    $('.animationImage').height(height);
    height = height <= 400 ? height : 400;
    $('.animationLegendImage').height(height);
    this.animationWidth = width;
    this.animationHeight = height;
    // set legend
    $('.animationLegendImage').prop('src', 'daac-bin/agmap.pl' +
        '?version=1.1.1&service=WMS&request=GetLegendGraphic' +
        '&LAYER=' + encodeURIComponent(layerData.name) +
        '&FORMAT=image%2Fpng' +
        '&session=' + encodeURIComponent(requestData.session) +
        '&resultset=' + encodeURIComponent(requestData.resultset) +
        '&result=' + encodeURIComponent(requestData.result) +
        '&mapfile=' + encodeURIComponent(requestData.mapfile) +
        '&sld=' + encodeURIComponent(layerData.variable_sld[0].url) +
        '&rand=' + Math.random() * 10000000
    );
    // set class level variables
    this.plotData = plotData;
    this.requestData = requestData;
    this.layerData = layerData;
    this.times = times;
    // build the map options
    if(!this.mapOptions) this.buildOptions();
    // start the animation with load panel visible
    this.start(true);
}

giovanni.widget.MapAnimation.prototype.buildOptions = function () {
    this.mapOptions = new giovanni.widget.OverlayMap.LayerOptions({
        containerId: this.containerId,
        frame: $('.animationImageFrame'),
        group: null,
        layer: $.extend(true, this.layerData, {
            session: this.requestData.session,
            resultset: this.requestData.resultset,
            result: this.requestData.result,
            datafile: this.plotData.dataFileUrl
        }), 
        map: null,
        multiLayer: false,
        olLayer: null,
        plotSource: this.plotData.source,
        animation: true,
        frameIndex: this.frameIndex,
        updateFunc: this.handleRefreshEvent,
        updateObj: this
    }); 
    this.mapOptions.el.find('.options-button').addClass('iconButton');
    this.mapOptions.el.prop('disabled',true).css('opacity', 0.5);
    $(this.container).prepend(this.mapOptions.el);
    $(this.container).prepend(this.downloadBtn);
}

giovanni.widget.MapAnimation.prototype.precacheImages = function (requestData, self) {

    self.wmsUrls = self.getAnimationUrls(requestData);
    if (!self.preloadImages) {
        self.preloadImages = {};
        self.preloadImages.list = [];
    }
    var list = self.preloadImages.list;
    
    for (var i = 0; i < self.wmsUrls.length; i++) {
        var img = new Image();
        img.onload = function() {
            var index = list.indexOf(this);
            if (index !== -1) {
                // remove image from the array once it's loaded
                // for memory consumption reasons
                list.splice(index, 1);
            }
        }
        list.push(img);
        img.src = self.wmsUrls[i];
    }
}

giovanni.widget.MapAnimation.prototype.getAnimationUrls = function (requestData) {
    var times = requestData.time;
    var urls = [];
    var urlbase = this.getAnimationUrlBase(requestData);
    for(var i=0;i<times.length;i++){
        url = urlbase + "&TIME=" + times[i].value;
        urls.push(url);
    }
    return urls;
}

giovanni.widget.MapAnimation.prototype.getAnimationUrl = function (requestData,index) {
    return this.getAnimationUrlBase(requestData) + '&TIME=' + this.times[index].value;
}

giovanni.widget.MapAnimation.prototype.getAnimationUrlBase = function (requestData) {
    var layer = requestData.layer[0];
    var paletteName = (this.userSelections && this.userSelections['paletteName']) ? 
        this.userSelections['paletteName'] : 
            (this.defaults && this.defaults['paletteName']) ? this.defaults['paletteName'] : layer.variable_sld[0].label;
    var sldUrl = this.getSldUrl(paletteName, requestData);
    var url = "./daac-bin/getAnimationFrame.pl?";
        url += "LAYERS=" + encodeURIComponent(layer.name) + ",coastline,countries,us_states,grid" + giovanni.util.getGridIncrement(null,null,layer.bbox);
        url += "&SESSION=" + encodeURIComponent(requestData.session);
        url += "&RESULTSET=" + encodeURIComponent(requestData.resultset);
        url += "&RESULT=" + encodeURIComponent(requestData.result);
        url += "&SLD=" + encodeURIComponent(sldUrl);
        url += "&BBOX=" + encodeURIComponent(layer.bbox);
        url += "&WIDTH=" + this.animationWidth;
        url += "&HEIGHT=" + this.animationHeight;
        url += "&CAPTION=" + encodeURIComponent(layer.caption);
        url += "&TITLE=" + encodeURIComponent(layer.title);
    return url;
};

giovanni.widget.MapAnimation.prototype.render = function () {
    // assemble HTML elements
    // - loading panel
    // - animation map frame
    //   - controls container
    this._assembleHTMLElements();
}

giovanni.widget.MapAnimation.prototype._assembleHTMLElements = function () {
    var self = this;
    // build loading panel
    this.container.append('<div id="animationLoadingPanel'+this.containerId+'" \
        class="loadingPanel">\
        <span id="loadingText"></span>\
        <div id="animationProgressBar"/>\
        </div>');
    // build downlaod button
    this.downloadBtn = $('<button id="'+this.containerId+'animationDownloadButton" class="iconButton animationIconButton" \
        title="Download as zip file of PNGs">\
        <i class="fa fa-download mapIcon"></i>\
        <span class="iconText" id="downloadIconText">Download</span>\
        </button>');

    // set up map bits including map display area, title, legend, etc.
    this.container.append('<div class="animationMap">\
        <div class="iconContainer"></div>\
        <div class="animationTitle"></div>\
        <div class="plotMapSubTitle"></div>\
        <div class="animControls"></div>\
        <div class="plotMapFrame">\
            <img class="animationImage"></img>\
        </div>\
        <div class="animationLegend">\
            <img class="animationLegendImage"/>\
        </div>\
        <div class="animationPlotCaption"></div>\
    </div>');

    // build controls
    $('.animControls').append(
        '<button id="animStart" class="icon animStart"></button>\
        <button id="animRewind" class="icon animRewind"></button>\
        <button id="animForwind" class="icon animForwind"></button>\
        <button id="animStepBack" class="icon animStepBack"></button>\
        <button id="animStepFor" class="icon animStepFor"></button>\
        <div class="frameRateContainer">\
            <label title="Animation speed in seconds between frames (e.g., 1.25 = 1 frame every 1.25 seconds">Frame Delay</label>\
            <select id="frameRateControl" class="animRate">\
                <option value="2000">2.00s</option>\
                <option value="1500">1.50s</option>\
                <option value="1000">1.00s</option>\
                <option value="500">0.50s</option>\
                <option value="250">0.25s</option>\
                <option value="125">0.125s</option>\
                <option value="63">0.063s</option>\
                <option value="32">0.032s</option>\
            </select>\
        </div>\
        <div id="jumpContainer" class="jumpContainer">\
            <span id="jumpInputLabel" title="Go to a specific frame">Go To:</span>\
            <input type="text" id="jumpInput" size="3" title="Enter a specific frame for display">\
        </div>\
        of <div id="numberOfFrames" style="display:inline-block;"></div>\
        <div id="animControlsShim" style="clear:both;"></div>'
    );

    $(document).ready( function () {
        $('#frameRateControl').val('125');        
        $('.animControls').css('display','none');
        $('.animationLegend').css('display','none');
        $('.animationLegend').css('opacity',0.1);
        $( "#animationProgressBar" ).progressbar({
            value: 0
        });
        $('#frameRateControl').change( self, self.changeFrameRate );
        $('#jumpInput').keyup( self, self.handleJumpInput );
        $('#animStart').on( 'click', self, self.playPause );
        $('#animStepBack').on( 'click', self, self.stepBack );
        $('#animForwind').on( 'click', self, self.forwind );
        $('#animRewind').on( 'click', self, self.rewind );
        $('#animStepFor').on( 'click', self, self.stepForward );
        $(self.downloadBtn).on( 'click', self, self.downloadAnimation );
        $(self.downloadBtn).prop('disabled',true).css('opacity', 0.5);
        $('#animationOptionsButton').on( 'click', self, self.showOptions );
    });
}

giovanni.widget.MapAnimation.prototype.getOptionValue = function (str, layerData) {
    var optValue = this.userSelections && this.userSelections[str] ? this.userSelections[str] : 
        (this.defaults && this.defaults[str]) ? this.defaults[str] : null;
    return optValue ? optValue : "";
}

giovanni.widget.MapAnimation.prototype.getSldUrl = function (paletteName, responseData) {
    var url = "";
    var layerData = responseData ? responseData.layer[0] : this.layerData;
    // define the ovrall palette list if it isn't
    if(!this.paletteList){
        this.paletteList = layerData.sld ? layerData.sld : layerData.sld_list;
    }
    // define the local sld list, including those specific to the variable 
    // in question, and the overall list
    var slds = layerData.variable_sld;
    slds = this.paletteList ? slds.concat(this.paletteList) : slds;
    // find the matching palette and fetch it's url
    for (var i = 0; slds && i < slds.length; i++) {
        if (slds[i].label == paletteName) {
            url = slds[i].url;
            break;
        }
    }
    return url;
};

/*
 * Start the animation
 *
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.start = function (firsttime) {
    this.firsttime = firsttime ? firsttime : false;
/*
    if (refresh) {
      // the animation still loading?
      if(this.imageCache.length < this.times.length) {
        this.firsttime = true;
      }
    }
*/
    try{
    if(firsttime){
        $('.animationImage').css('opacity',0.3);
        $('.loadingPanel').css('display','block');
        $('#numberOfFrames').html(this.times.length);
        if (this.caption) $('.animationPlotCaption').html(this.caption);
    }
    }catch(err){/*don't care*/}

    // store the initial frame as loaded
    //if (!this.loaded) {
    //    this.framesLoaded[this.times[0].value] = true;
    //}
    this.layerLoaded = true;
    // ensure the animation is NOT paused
    this.paused = false;
    // set the play/pause toggle to show 'pause' as the control
    this.togglePauseControl(true);
    // if the frame index is greater than the length of the animation
    // re-start the animation
    var replay = false;
    if (this.frameIndex >= this.times.length-1) {
        this.frameIndex = 0;
        replay = true;
    }
    // keep track of the currently selected control
    this.currentControl = 'Start';
    // run the animation
    this.doAnimation(replay);
}

/*
 * Toggles action based on this.pause state
 */
giovanni.widget.MapAnimation.prototype.playPause = function (e) {
    var self = e.data;
    // get the play/pause button
    var playPauseBtn = $('#animStart');
    // if it's disabled, don't do anything; otherwise,
    // call the appropriate method
    if (playPauseBtn.attr('class').indexOf('Disabled') < 0) {
        if (self.paused || self.paused == undefined) {
            self.disableCompoundControl('jumpInput');
            self.start();
        } else {
            self.enableCompoundControl('jumpInput');
            self.pause();
        }
    }
    self.currentControl = 'Start';
}

/*
 * Toggles playPause icon state
 */
giovanni.widget.MapAnimation.prototype.togglePauseControl = function (bool) {
    var playPauseBtn = $('#animStart');
    var disabled = false;
    if (bool) {
        playPauseBtn.removeClass();
        playPauseBtn.addClass( disabled ? 'icon animPauseDisabled' : 'icon animPause' );
    } else {
        playPauseBtn.removeClass();
        playPauseBtn.addClass( disabled ? 'icon animStartDisabled' : 'icon animStart' );
    }
}


/*
 * Pause the animation; clears the animation timeout
 *
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.pause = function () {
    // set the 'paused' flag to true
    this.paused = true;
    // set the play/pause control to show 'play'
    this.togglePauseControl(false);
    // since we could be cutting the animation cycle short and
    // pause in the middle of a frame update, make sure we've
    // got the current progress correctly displayed
    this.currentControl = 'Start';
}

/*
 * Handles the layer 'loadend' event
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.handleLoadend = function (aniObj) {
    //var self = e.data;
    var self = aniObj;
    // layer is loaded; allow other functions to know
    self.layerLoaded = true;
    // show update in jump box
    $('#jumpInput').val( self.frameIndex + 1 );
    // update title with new time stamp
    $('.animationTitle').text(self.title + ", " + self.getFormattedTimeStamp(self.times[self.frameIndex].value));
    //this.layerLoaded = true;
    if (self.firsttime) {
      $( "#animationProgressBar" ).progressbar({
        value: Math.floor( (((self.frameIndex+1) * 100) / self.times.length) )
      });
      $('#loadingText').text( "Loading " + (self.frameIndex + 1) + " of " + self.times.length + " frames"); 
    }
   
    
    
    // set the ui state based on the frame index once the frame is loaded
    self.updateUIState();
}

/*
 * Run the animation loop - if the loop is not paused, the most recent layer has already been
 * loaded and the frameIndex is less than the total number of frames, update the animation frame
 * and issue the next loop request
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.doAnimation = function (startingReplay) {
    if (this.paused) {
        this.animationTimeout = clearTimeout(this.animationTimeout);
    } else {
        // if the frame index equals the end time index, stop the animation 
        if (this.frameIndex > this.times.length - 1) {
            this.animationTimeout = clearTimeout(this.animationTimeout);
            // handle last frame
            this.setAnimationFrame();
            // set UI
            $('.animationImage').css('opacity',1);
            $('.loadingPanel').css('display','none');
            $('.animationLegend').css('display','block');
            $('.animationLegend').animate({
                opacity: 0.75
            });
            this.enableMapControls();
            if(this.firsttime){
                this.firsttime = false;
                this.frameIndex = 0;
                $(this.downloadBtn).prop('disabled',false).css('opacity', 1.0);
                $(this.mapOptions.el).prop('disabled',false).css('opacity', 1.0);
                this.setAnimationFrame();
            }
            this.pause();
        } else {

            // make sure pause state is false (animation is running)
            this.paused = false;

            // if the last layer was loaded, increment the counter and do another frame
            if (this.layerLoaded) {
                if(startingReplay) {
                  this.frameIndex = 0;
                } else {
                  this.frameIndex++;
                }
                this.layerLoaded = false;
                // try to load the new frame
                this.setAnimationFrame();
            }
            // keep it going until we're done or until there is a pause
            this.animationTimeout = window.setTimeout(
                function (x) {
                    return function () {
                        x.doAnimation();
                    };
                }(this),
                this.animRate);
        }
    }
}

/*
 * Handle the update of a layer; called when the layer has finished loading
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.updateUIState = function () {
    // if the frame has been loaded....
    //if (this.frameIndex < this.times.length) {
    //    this.framesLoaded[this.times[this.frameIndex].value] = true;
    //}
    //this.updateProgress();
    this.updateControlStates();
    if (!this.paused || (this.lastCommand == 'Rewind' && this.frameIndex == 0)) {
        this.lastCommand = '';
    }
}

giovanni.widget.MapAnimation.prototype.updateControlStates = function () {
    var idx = this.frameIndex;
    if (idx >= this.times.length - 1) {
        this.togglePauseControl(false);
        this.enableIcons(['animStart','animStepBack', 'animRewind']);
    } else if (idx > 0 && idx < this.times.length - 1) {
        this.enableIcons(['animStart','animStepBack', 'animRewind', 'animStepFor','animForwind']);
        if (this.paused) {
            this.togglePauseControl(false);
        } else {
            this.togglePauseControl(true);
        }
    } else if (idx <= 0) {
        this.enableIcons(['animStart','animStepFor','animForwind']);
        this.togglePauseControl(false);
    }
}

/*
 * 'Rewind' the animation to it's starting point (pauses the loop and
 * sets the frameIndex to the beginning); handles the appropriate enabling/disabling
 * of icon controls
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.rewind = function (e) {
    var self = e.data;
    // if the element displays as disabled, don't allow interaction
    if( $('#animRewind').attr('class').indexOf('Disabled')<0 ) {
        // pause the animation loop
        self.pause();
        //self.flashControl('animRewind', true);
        // set the frame index to zero
        self.frameIndex = 0;
        self.layerLoaded = false;
        // track the last command
        self.lastCommand = 'Rewind';
        // set the frame
        self.setAnimationFrame();
        // update the UI (HTML controls) state
        self.updateUIState();
    }
}

/*
 * Forward the animation to it's stopping point (pauses the loop and
 * sets the frameIndex to it's max); handles the appropriate enabling/disabling
 * of icon controls
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.forwind = function (e) {
    var self = e.data;
    if( $('#animForwind').attr('class').indexOf('Disabled')<0 ) {
        self.pause();
        //self.flashControl('animForwind', true);
        self.frameIndex = self.times.length - 1;
        self.layerLoaded = false;
        self.currentControl = 'Forwind';
        // set the frame
        self.setAnimationFrame();
        // update the UI state
        self.updateUIState();
    }
}

/*
 * Step forward by one frame (pauses the loop and
 * increments the frameIndex by one); handles the appropriate enabling/disabling
 * of icon controls
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.stepForward = function (e) {
    var self = e.data;
    if( $('#animStepFor').attr('class').indexOf('Disabled')<0 ) {
        self.pause();
        self.frameIndex++;
        if (self.frameIndex >= self.times.length - 1) {
            //this.disableIcon('Forwind');
            //this.disableIcons('animForwind')
            self.frameIndex = self.times.length - 1;
            //self.flashControl('animStepFor', true);
        } else {
            //self.flashControl('animStepFor');
        }
        self.layerLoaded = false;
        self.currentControl = 'StepFor';
        self.setAnimationFrame();
        self.updateUIState();
    }
}

/*
 * Step backward by one frame (pauses the loop and
 * decrements the frameIndex by one); handles the appropriate enabling/disabling
 * of icon controls
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.stepBack = function (e, o) {
    var self = e.data;
    if( $('#animStepBack').attr('class').indexOf('Disabled')<0 ) {
        self.pause();
        self.frameIndex--;
        if (self.frameIndex <= 0) {
            //self.flashControl('animStepBack', true);
            self.disableIcon('Rewind');
            self.frameIndex = 0;
        } else if (self.frameIndex >= self.times.length - 1) {
            self.frameIndex = self.times.length - 2;
            //self.flashControl('animStepBack');
        } else {
            //selfflashControl('animStepBack');
        }
        self.layerLoaded = false;
        self.currentControl = 'StepBack';
        self.setAnimationFrame();
        self.updateUIState();
    }
}

/*
 * Updates the animation frame assuming the frameIndex has not reached it's max
 * (this.times.length - 1)
 * 
 * @this {giovanni.widget.MapAnimation}
 * @params {}
 * @author K. Bryant
 */
giovanni.widget.MapAnimation.prototype.setAnimationFrame = function () {
    // if the frameIndex has not max'd out, update the frame
    if (this.frameIndex < this.times.length) {
        this.updateCount = 0;
        // update map
        this.updateImageSource(this.times[this.frameIndex].value);
    }
}

/*
 * Retrieve the formatted time stamp
 */
giovanni.widget.MapAnimation.prototype.getFormattedTimeStamp = function (timestamp) {
    var dateStr = timestamp.split("T")[0];
    var timeStr = timestamp.split("T")[1];
    var times = timeStr.split(":");
    timeStr = " " + times[0] + ":" + times[1];
    return dateStr + timeStr;
}

giovanni.widget.MapAnimation.prototype.getAnimationDownloadUrl = function () {
    return "./daac-bin/downloadAnimation.pl?" +
    'session=' + encodeURIComponent(this.requestData.session) +
    '&resultset=' + encodeURIComponent(this.requestData.resultset) +
    '&result=' + encodeURIComponent(this.requestData.result);

}

giovanni.widget.MapAnimation.prototype.downloadAnimation = function (e) {
    var self = e && e.data ? e.data : this;
    var downloadUrl = self.getAnimationDownloadUrl();
    var form = document.createElement("form");
    form.setAttribute("action", downloadUrl);
    form.setAttribute("method", "POST");
    form.setAttribute("enctype", "application/x-download");
    form.style.display = "none";
    document.body.appendChild(form);
    form.submit();
    document.body.removeChild(form);
}

giovanni.widget.MapAnimation.prototype.changeFrameRate = function (e) {
    var self = e.data;
    self.animRate = $('#frameRateControl option:selected').val();
}

giovanni.widget.MapAnimation.prototype.enableIcons = function (ids) {
    if(!this.controlButtonIds){
        var btns = $(".animControls").find( "button" );
        var btnIds = [];
        for(var i=0;i<btns.length;i++){
            btnIds.push( $(btns[i]).prop("id") );
        }
        this.controlButtonIds = btnIds.slice();
    }
    var cbids = this.controlButtonIds.slice();
    var disable = true;
    for(var i=0;i<cbids.length;i++){
        disable = true;
        for(var j=0;j<ids.length;j++){
            if( cbids[i] === ids[j] ){
                disable = false;
                break;
            }
        }
        if(disable){
            $('#'+cbids[i]).prop("disabled",true);
            $('#'+cbids[i]).addClass(cbids[i]+'Disabled');
        }else{
            $('#'+cbids[i]).prop("disabled",false);
            $('#'+cbids[i]).removeClass(cbids[i]+'Disabled');
        }
    }
}
giovanni.widget.MapAnimation.prototype.disableIcons = function (ids) {
    if(!this.controlButtonIds){
        var btns = $(".animControls").find( "button" );
        var btnIds = [];
        for(var i=0;i<btns.length;i++){
            btnIds.push( $(btns[i]).prop("id") );
        }
        this.controlButtonIds = btnIds.slice();
    }
    for(var i=0;i<ids.length;i++){
        if( this.controlButtonIds.join().indexOf( ids[i] ) > -1){
            $('#'+ids[i]).prop("disabled",true);
        }else{
            $('#'+ids[i]).prop("disabled",false);
        }
    }
}

giovanni.widget.MapAnimation.prototype.enableMapControls = function () {
    var self = this;
    $('.animControls').css('display','block');    
    $('#' + self.containerId + 'animationDownloadButton').prop('disabled', false);
    self.enableCompoundControl('jumpInput');
}

giovanni.widget.MapAnimation.prototype.disableIcon = function (id) {
    $('#'+id).addClass(id+'Disabled');
    $('#'+id).css('cursor','default');
}
giovanni.widget.MapAnimation.prototype.enableIcon = function (id) {
    $('#'+id).removeClass(id+'Disabled');
    $('#'+id).css('cursor','pointer');
}

giovanni.widget.MapAnimation.prototype.disableCompoundControl = function (id) {
    $('#'+id).prop('disabled',true);
    $('#'+id).removeClass('enabledLabel');
    $('#'+id).addClass('disabledLabel');
}
giovanni.widget.MapAnimation.prototype.enableCompoundControl = function (id) {
    $('#'+id).prop('disabled',false);
    $('#'+id).removeClass('disabledLabel');
    $('#'+id).addClass('enabledLabel');
}

/*
 * Replicates giovanni.widget.Map.updateImageSource but handles sending
 * resultant images to the buffer element 
 */
giovanni.widget.MapAnimation.prototype.updateImageSource = function (time, imgTag) {
    var self = this;
    var aniUrl = self.getAnimationUrlBase(self.requestData);
    aniUrl += "&TIME=" + encodeURIComponent(time);
    // set image source and when the image is loaded, do housekeeping;
    // need to use an ajax request to grab the image so we can ensure it's
    // cached upon load (otherwise, the default no-cache policy is in effect when
    // simply assigning the image URL to image.src)
    var winUrl = window.URL || window.webkitURL;

    var cacheKey = aniUrl;
    for (var key in self.userSelections) {
        cacheKey += self.userSelections[key]; 
    }

    if (navigator.msSaveOrOpenBlob) { // no ajax request for IE
        // check the cache before doing async request
        if ( self.imageCache[cacheKey] ) {
            $('.animationImage').one('load', function() { self.handleLoadend(self); }).attr('src', "data:image/png;base64,"+self.imageCache[cacheKey]);
        } else {  // need to do an async request manually (IE does not have full implementation of $.ajax)
            var xhr = new XMLHttpRequest();
            xhr.open('GET', aniUrl, true);
            xhr.responseType = 'arraybuffer';
            xhr.onload = function(e) {
                // credit for blob to image conversion: https://stackoverflow.com/questions/8022425/getting-blob-data-from-xhr-request
                if (this.status == 200) {
                    var uInt8Array = new Uint8Array(this.response);
                    var i = uInt8Array.length;
                    var binaryString = new Array(i);
                    while (i--) {
                        binaryString[i] = String.fromCharCode(uInt8Array[i]);
                    }
                    var data = binaryString.join('');
                    var base64 = window.btoa(data);
                    // make sure we cache the base64 image
                    self.imageCache[cacheKey] = base64;
                    // load base64 image
                    $('.animationImage').one('load', function() { self.handleLoadend(self); }).attr('src', "data:image/png;base64,"+base64); 
                }
            };
            xhr.send();
        }
    } else { // send async request using $.ajax
        // check cache first - since this is a different object than what is stored for IE and requires different handling,
        // the check is done in this else clause
        if ( self.imageCache[cacheKey] ) {
            $('.animationImage').one('load', function() { self.handleLoadend(self); }).attr('src', winUrl.createObjectURL(self.imageCache[cacheKey]));
        } else {
            $.ajax({
                url: aniUrl,
                method: "GET",
                cache: false,
                async: true,
                xhr: function() {
                  // credit:  https://stackoverflow.com/questions/176571184/using-jquery-ajax-method-to-retrieve-images-as-a-blob
                  var xhr = new XMLHttpRequest();
                  xhr.responseType = 'blob';
                  return xhr;
                },
                success: function (data) {
                    self.imageCache[cacheKey] = data;
                    $('.animationImage').one('load', function() { self.handleLoadend(self); }).attr('src', winUrl.createObjectURL(data));
                },
                error: function (data) {
                    // could not update image, try again...untl max count reached
                    console.log("failed to get ( " + self.updateCount + "): " + aniUrl);
                    if(self.updateCount < 4) { 
                        self.updateCount++;
                        self.updateImageSource(self.times[self.frameIndex].value);
                    } else { // move on
                        $('.animationImage').one('load', function() { self.handleLoadend(self); }).attr('src', './image/delete.png');
                    }
                }
            });
        }
    }
}

/*
 * Handles animation refresh event generated by requesting min/max or palette
 * changes from the 'options' panel
 */
giovanni.widget.MapAnimation.prototype.handleRefreshEvent = function (e, args, self) {
    // pause the animation
    self.pause();
    // ensure that the animation loop thinks the last frame was loaded
    self.frameIndex = 0;
    self.layerLoaded = false;
    self.userSelections = args;
    //self.setAnimationFrame();
    self.start(true);
    // load the buffer
}

/*
 * Handle frame index entries into the jump field
 */
giovanni.widget.MapAnimation.prototype.handleJumpInput = function (e) {
    var target = giovanni.util.getTarget(e);
    var self = e.data;
    if (target) {
        var idx = parseInt(target.value) - 1;
        if (!isNaN(idx)) {
            var min = 0;
            var max = self.times.length - 1;
            if (idx >= min && idx <= max) {
                // make sure the text is a non-error color
                $('#animJumpInput').css('color','black');
                // set the frame index
                self.frameIndex = idx;
                // disable icons
                //this.disableIcons(false);
                self.layerLoaded = false;
                // display the frame
                self.setAnimationFrame();
                // enable icons
                //this.enableIcons();
                self.updateUIState();
            } else {
                // show an error color on the input
                $('#animJumpInput').css('color','red');
            }
        }
        target.focus();
    }
}

/*
 * If logged in, enable download capability, otherwise disable it and provide button to log in
 */
giovanni.widget.MapAnimation.prototype.handleLoginEvent = function (type,args,o){
    var btnid = "#downloadIconText";
    if( login && login.isLoggedIn ){
        $( btnid ).html('Download');
        $( btnid ).unbind(login.checkLogin.bind(login));
        YAHOO.util.Event.addListener(o.downloadBtn, 'click', o.downloadAnimation, {}, o);
    }else{
        $( btnid ).html('Login to download');
        $( btnid ).click(login.checkLogin.bind(login));
        YAHOO.util.Event.removeListener(o.downloadBtn, 'click', o.downloadAnimation, {}, o);
    }
}
