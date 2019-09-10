//$Id: StaticPlot.js,v 1.12 2015/07/31 20:11:49 kbryant Exp $
//-@@@ AG, Version $Name:  $

/**
 * Used by ResultView to display the default ('static') plot object
 */

giovanni.namespace('giovanni.widget.StaticPlot');

/*
 * Construct the StaticPlot class
 * 
 * @this {giovanni.widget.StaticPlot}
 * @params {String,Object,Number,Number}
 * @return {giovanni.widget.StaticPlot}
 * @author K. Bryant
 */


giovanni.widget.StaticPlot = function (containerId, config) {

    // store the container's ID
    this.containerId = containerId;
    // get the container element
    this.container = document.getElementById(containerId);
    if (this.container === null) {
        console.log("Error [giovanni.widget.StaticPlot]: element '" + containerId + "' not found!");
        return;
    }

    // get the plotObject
    this.plotUrl = config.plotObject.source;
    this.plotOptions = config.plotObject.plotOptions;
    this.plotId = config.plotObject.id;
    this.plotCaption = config.plotObject.caption;
    this.plotTitle = config.plotObject.title;
    this.plotLabel = config.plotObject.dataFieldLabel;
    this.showTitle = config.plotObject.showTitle;
    this.showCaption = config.plotObject.showCaption;
    this.res = config.res;
    this.res.enableReplot.subscribe(this.handleEnableReplotEvent, self);

    if (this.plotId === null) {
        console.log("Error [giovanni.widget.StaticPlot]: plotting object not found");
        this.renderError(this.plotOptions);
    } else if (this.plotOptions === null || typeof (this.plotOptions) !== 'object') {
        if (config.plotObject.resId) {
            this.plotUrl = plot.plotUrl;
            this.plotOptions = plot.plotOptions;
            this.plotId = plot.plotId;
            this.plotTitle = plot.plotTitle;
            this.plotCaption = plot.plotCaption;
            this.res = config.res;
            this.render();
        } else {
            console.log("Error [giovanni.widget.StaticPlot]: Plot options not found");
        }
    } else {
        // render the plot
        this.render();
    }
};

giovanni.widget.StaticPlot.palettesSelection = new Array();

giovanni.widget.StaticPlot.palettesGroups = new Array();




giovanni.widget.StaticPlot.prototype.handlePlotUpdateEvent = function (type, args, o) {
    self = o;    
    var newPlotData = args[0].data;
    if (self.currentId === newPlotData.id && newPlotData.source) {
        self.plotUrl = newPlotData.source;
        self.plotOptions = newPlotData.plotOptions;
        self.plotId = self.currentId;

        $("#dialog-form-" + self.containerId).dialog('destroy').remove();
        $(".re-plot-btn").html('Re-Plot');
        $(".re-plot-btn").prop('disabled', false);
        $(".reset-btn").prop('disabled', false);  
        $(".ui-dialog-titlebar-close").prop('disabled', false);
        $(".ui-dialog-content").removeClass('disabledElement');
        self.render();        
        self.res.plotUpdateEvent.unsubscribe(self.handleResultUpdateEvent, self);
    } else if (self.currentId === newPlotData.id && !newPlotData.source) {
        $("#dialog-form-" + self.containerId).dialog('close');
        $(".re-plot-btn").html('Re-Plot');
        $(".re-plot-btn").prop('disabled', false);
        $(".reset-btn").prop('disabled', false);
        $(".ui-dialog-titlebar-close").prop('disabled', false);
        $(".ui-dialog-content").removeClass('disabledElement');
        $('<div class="errorMessagePlot" id=error-' + self.containerId +
            '>Sorry. We could not produce a plot. Please <a href="javascript:void(0)" id="sendFeedback-' +
            self.containerId + '" onclick="session.sendFeedback(event, \'pageSelection\')">report the error</a>. ' +
            '<span class="closeErrorButton" id="closeError-' + self.containerId + '"></span>' +
            '</div>').insertBefore($("#" + self.containerId).closest(".imageFrame"));
        $(".closeErrorButton").click(function (e) {
            $("#error-" + e.target.id.substring(11)).remove();
        });        
        self.res.plotUpdateEvent.unsubscribe(self.handleResultUpdateEvent, self);
    }
    // handle login events
    // (uncomment next 3 lines to require login in order to enable download of static plots)
    //if (login) {
    //    login.loginEvent.subscribe(this.handleLoginEvent,this);
    //}
    self.res.resultUpdateEvent.unsubscribe(self.handleResultUpdateEvent, self);
};

giovanni.widget.StaticPlot.prototype.rePlot = function (options, res, dialog, plotId, containerId) {
    self = this;
    var palettesGroup = giovanni.widget.StaticPlot.palettesGroups.find(function (group) {
        return group.plotId === plotId;
    });
    if (palettesGroup && palettesGroup.palettes) {
        var selectedPalette = $("#palette-select-" + containerId + " option:selected").text();
        palettesGroup.palettes.forEach(function (item) {
            if (item.label === selectedPalette) {
                options.Palette = item;
            }
        });
    };
    self.currentId = plotId;
    self.containerId = containerId;
    $("#error-" + self.containerId).remove();
    giovanni.widget.StaticPlot.palettesSelection.forEach(function (item) {
        if (item.plotId === plotId) {
            item.selectedPalette = selectedPalette;
        }
    });
    self.container = document.getElementById(containerId);
    res.plotUpdateEvent.subscribe(this.handlePlotUpdateEvent, self);
    res.initiateRePlot('&options=' + encodeURIComponent('[' + JSON.stringify({
        "options": options,
        "id": plotId
    }) + ']'));
    return;
}

giovanni.widget.StaticPlot.prototype.renderError = function (error) {
    this.container.innerHTML = "";
    var errorContainer = document.createElement('div');
    errorContainer.setAttribute('id', 'error-' + this.containerId);
    errorContainer.setAttribute('class', 'errorMessagePlot');
    errorContainer.innerHTML = 'Sorry. We could not produce a plot. Please <a href="javascript:void(0)" id="sendFeedback-' +
        this.containerId + '" onclick="session.sendFeedback(event, \'pageSelection\')">report the error</a>.';
    this.container.appendChild(errorContainer);
}

giovanni.widget.StaticPlot.prototype.handleEnableReplotEvent = function (type, args, o) {
    $(".plotOptionsContainer").removeClass("disabledLink");
    o.res.enapleReplotEvent.unsubscribe();
}
/*
 * Render the plot image using the parent container
 *
 * @this {giovanni.widget.StaticPlot}
 * @params {}
 * @return {}
 * @author K. Bryant
 */
giovanni.widget.StaticPlot.prototype.render = function () {


    self = this;
    // remove diolog for image id, if exists, to prevent duplicating dialogs.
    $('[plotid=' + this.plotId + ']').dialog('destroy').remove();;

    // clear container before render
    this.container.innerHTML = "";

    var dialog;

    var schema = JSON.parse(this.plotOptions.schema[0].value);
    var defaultOptions = JSON.parse(this.plotOptions.defaults[0].value);

    if (schema.properties.Palette) {
        self = this;
        this.palettes = schema.properties.Palette['enum'].slice();
        var group = giovanni.widget.StaticPlot.palettesGroups.find(function (item) {
            return self.plotId == item.plotId;
        });
        if (!group) {
            giovanni.widget.StaticPlot.palettesGroups.push({
                'plotId': this.plotId,
                'palettes': this.palettes
            });
        }
        delete schema.properties.Palette;
    }

    if (schema.title) {
      schema.title = this.plotTitle;
    }

    if (defaultOptions.Palette) {
        // this.defaultPalette = defaultOptions.Palette;
        var result = $.grep(giovanni.widget.StaticPlot.palettesSelection, function (e) {
            return e.plotId === self.plotId;
        });
        if (result.length === 0) {
            giovanni.widget.StaticPlot.palettesSelection.push({
                'plotId': this.plotId,
                'selectedPalette': '',
                'defaultPalette': defaultOptions.Palette
            });
        }
    }

    var btnLink = document.createElement('div');
    var btnOptions = document.createElement('div');
    var plotOptionsModal = document.createElement('div');
    
    var paletteHeader = document.createElement('div');
    var paletteSelect = document.createElement('select');
    var editorHolder = document.createElement('div');
    var editorOptions = {
        schema: schema,
        disable_collapse: true,
        disable_edit_json: true,
        disable_properties: true
    }

    JSONEditor.defaults.options.theme = 'html';

    var editor = new JSONEditor(editorHolder, editorOptions);

    // use image plot source for now; later, test if the download url is available;
    // if there, use it; otherwise, use the plot image source
    var downloadUrl = 'http://' +
        location.host +
        location.pathname +
        "./daac-bin/downloadPlot.pl?" +
        "image=" + encodeURIComponent(this.plotUrl) + "&";
    // remove debug html ref if it's there
    downloadUrl = downloadUrl.replace("index-debug.html", "");
    downloadUrl += "format=PNG&";
    // add caption if necessary
    if(this.showCaption && this.plotCaption !=null){
      downloadUrl += "caption=" + encodeURIComponent(this.plotCaption) + "&";
    }
    if(this.showTitle) { downloadUrl += "title=" + encodeURIComponent(this.plotTitle) + "&" };
    this.downloadUrl = downloadUrl;
    btnLink.setAttribute('class', 'imageDownloadButton');
    btnLink.setAttribute('title', 'Download image as PNG');
    btnLink.innerHTML = '<h3><a href="' + downloadUrl + '"> <i class="fa fa-download"></i> Image </a></h3></div>';
    this.container.appendChild(btnLink);

    

        btnOptions.setAttribute('class', 'plotOptionsContainer disabledLink');
        btnOptions.setAttribute('title', 'Plot options');
        var btnOptionsHtml = 
            '<h3><button class="plotOptionsButton" id="plot-options_' + this.containerId  + '">' +
            '<i class="fa fa-bars"></i>       Options      <i class="fa fa-caret-down"></i></button></h3>' +
            '<ul class="static-options">'
        if (!jQuery.isEmptyObject(defaultOptions)) { 
          btnOptionsHtml += '<li class="options"><div><button class="options-modal-button" id="options-modal_' + this.containerId + '_' + this.plotId + '"><i class="fa fa-cog "></i> Re-Plot Options </button></div></li>' }
        btnOptionsHtml += '<li class="checkbox"><input type="checkbox" id="titleCheckbox' + this.containerId + '" checked="checked"><label>Show title</label></li>';
        if (this.plotCaption) { 
          btnOptionsHtml += '<li class="checkbox"><input type="checkbox" id="captionCheckbox' + this.containerId + '" checked="checked"><label>Show caption</label></li></ul></div>';
        } else {
          btnOptionsHtml += '</ul></div>';
        }

        btnOptions.innerHTML = btnOptionsHtml;
        plotOptionsModal.setAttribute('id', 'dialog-form-' + this.containerId);
        plotOptionsModal.setAttribute('plotId', this.plotId);
        plotOptionsModal.setAttribute('title', 'Plot options');

        editorHolder.setAttribute('id', 'editor-' + this.containerId);

        plotOptionsModal.appendChild(editorHolder);

        if (this.palettes) {
            paletteHeader.innerHTML = '<h3>Palette:</h3>';

            paletteSelect.setAttribute('id', 'palette-select-' + this.containerId);
            paletteSelect.setAttribute('style', 'width: 95%;');

            plotOptionsModal.appendChild(paletteHeader);
            plotOptionsModal.appendChild(paletteSelect);
        }

        this.container.appendChild(btnOptions);
        this.container.appendChild(plotOptionsModal);
        
        var self = this;

        $("#titleCheckbox" + this.containerId).on("click", function () {
          self.showTitle = !self.showTitle;
          if (!self.showTitle) {
            $('#' + self.containerId).find(".plotTitle").hide();
            self.downloadUrl = self.downloadUrl.replace('title=' + encodeURIComponent(self.plotTitle) + '&', '');
          } else {
            $('#' + self.containerId).find(".plotTitle").show();
            self.downloadUrl += "title=" + encodeURIComponent(self.plotTitle) + "&";
          }
          self.updatePlotTitleState(self.plotId, self.showTitle);
          self.updateDownloadLink(self.containerId, self.downloadUrl);
        });

        $("#captionCheckbox" + this.containerId).on("click", function () {
          self.showCaption = !self.showCaption;
          if (!self.showCaption) {
            $('#' + self.containerId).find(".plotCaption").hide();
            self.downloadUrl = self.downloadUrl.replace('caption=' + encodeURIComponent(self.plotCaption) + '&', '');
          } else {
            $('#' + self.containerId).find(".plotCaption").show();
            self.downloadUrl += "caption=" + encodeURIComponent(self.plotCaption) + "&";
          }
          self.updatePlotCaptionState(self.plotId, self.showCaption);
          self.updateDownloadLink(self.containerId, self.downloadUrl);
        });
        

        dialog = $("#dialog-form-" + this.containerId).dialog({
            autoOpen: false,
            height: 600,
            width: 400,
            modal: true,
            closeOnEscape: false,
            buttons: [
                {
                    'text': 'Re-Plot',
                    'click': function () {
                        var errors = editor.validate();
                        var value = editor.getValue();
                        if (errors.length == 0)
                          {
                            $(".re-plot-btn").html('<span>Re-plotting<img src="./img/progress.gif" id=/"progressSpinner/"></span>');
                            $(".re-plot-btn").prop('disabled', true);
                            $(".reset-btn").prop('disabled', true);
                            $(".ui-dialog-titlebar-close").prop('disabled', true);
                            $(".ui-dialog-content").addClass('disabledElement');
                            self.rePlot(value, self.res, dialog, $(this).data('plotId'), $(this).data('containerId'));
                        }
                    },
                    'class': 're-plot-btn'
        },
                {
                    'text': 'Reset to defaults',
                    'click': function (e) {
                        editor.setValue(defaultOptions);
                        var plotId = $(this).data('plotId');
                        var containerId = $(this).data('containerId');
                        giovanni.widget.StaticPlot.palettesSelection.forEach(function (item) {
                            if (item.plotId === plotId) {
                                $("#palette-select-" + containerId).val(item.defaultPalette.legend).trigger('change');
                            }
                        });
                    },
                    'class': 'reset-btn'
        }
      ],
            close: function () {
            }
        });

        $("#plot-options_" + this.containerId).click(function () {
          $(this).closest(".plotOptionsContainer").toggleClass('plot-options-active');
        });

        $("#options-modal_" + this.containerId + '_' + this.plotId).on("click", function (event) {
            var params = event.target.id.split('_');
            $("#dialog-form-" + params[1])
                .data('plotId', params[2])
                .data('containerId', params[1])
                .dialog("open");
        });
    
    // add the link to the container
    this.container.appendChild(document.createElement('br'));
    var title = document.createElement('div');
    title.setAttribute('class', 'plotTitle');
    title.innerHTML = this.plotTitle;
    // create the plot image 
    var img = document.createElement('img');
    // set img 'src' with plot source (the plot image url)
    img.setAttribute('src', this.plotUrl);
    img.setAttribute('alt', this.plotTitle);
    img.setAttribute('title', this.plotTitle);
    img.setAttribute('class', 'plotImage');
    // add title and image to the container
    this.container.appendChild(title);
    this.container.appendChild(img);
    // create plot caption if necessary
    if (this.plotCaption) {
        // create caption element
        var caption = document.createElement('div');
        // set caption style
        caption.setAttribute('class', 'plotCaption');
        // replace caption string newlines with HTML breaks as necessary
        caption.innerHTML = this.plotCaption.replace('\n', '<br/>');
        this.container.appendChild(caption);
    }

    if (!this.showTitle) { 
      $('#titleCheckbox' + this.containerId).prop('checked', false);
      $('#' + this.containerId).find(".plotTitle").hide();
    }
    if (this.plotCaption && !this.showCaption) { 
      $('#captionCheckbox' + this.containerId).prop('checked', false);
      $('#' + this.containerId).find(".plotCaption").hide(); 
    }

    if (this.palettes) {
        var data = [];
        this.palettes.forEach(function (item) {
            data.push({
                'id': item.legend,
                'text': item.label
            })
        });

        $("#palette-select-" + this.containerId).select2({
            data: data,
            templateResult: this._formatPalette,
            templateSelection: this._formatPalette,
            minimumResultsForSearch: Infinity
        })

        giovanni.widget.StaticPlot.palettesSelection.forEach(function (item) {
            if (item.plotId == self.plotId) {
                if (item.selectedPalette) {
                    var selectedPaletteVal;
                    var selectedPaletteLabel = item.selectedPalette;
                    self.palettes.forEach(function (item) {
                        if (item.label === selectedPaletteLabel) {
                            selectedPaletteVal = item.legend;
                        }
                    });
                    $("#palette-select-" + self.containerId).val(selectedPaletteVal).trigger('change');
                } else {
                    $("#palette-select-" + self.containerId).val(item.defaultPalette.legend).trigger('change');
                }
            }
        });
    };

};

giovanni.widget.StaticPlot.prototype.updateDownloadLink = function (containerId, newurl) {
  $('#' + containerId).find('a').attr('href' , newurl);
}

giovanni.widget.StaticPlot.prototype.updatePlotTitleState = function(plotId) {
  this.res.plots.map(function (plot) {
    if(plot.id === plotId) { plot.toggleTitleView();}
  });
}

giovanni.widget.StaticPlot.prototype.updatePlotCaptionState = function(plotId) {
  this.res.plots.map(function (plot) {
    if(plot.id === plotId) { plot.toggleCaptionView();}
  });
}



giovanni.widget.StaticPlot.prototype._formatPalette = function (palette) {
    if (!palette.id) {
        return palette.text;
    }
    var $palette = $(
        '<span><img src="' + palette.id + '" class="img-palette" /> ' + palette.text + '</span>'
    );
    return $palette;
};

// Check if logged in and enable/disable download button accordingly
// (uncomment next 3 lines to require login in order to enable download of static plots)
//if (login) {
//    this.handleLoginEvent();
//}

/*
 * If logged in, enable download capability, otherwise disable it and provide button to log in
 */
giovanni.widget.StaticPlot.prototype.handleLoginEvent = function (type, args, o) {
    if (login && login.isLoggedIn) {
        $("#imageDownloadButton").attr('title', 'Download image as PNG');
        $("#imageDownloadButton").attr('href', o.downloadUrl);
        var linkParts = o.plotObj.getSource().split("/");
        $("#imageDownloadButton").attr('download', linkParts[linkParts.length - 1]);
        $("#imageDownloadButton").addClass('plotImagePdfButton');
        $("#imageDownloadButton").html("");
        $("#imageDownloadButton").unbind(login.checkLogin.bind(login));
    } else {
        $("#imageDownloadButton").attr('title', 'Please login to download the plot as a PNG');
        $("#imageDownloadButton").attr('href', '#');
        $("#imageDownloadButton").removeAttr('download');
        $("#imageDownloadButton").removeClass('plotImagePdfButton');
        $("#imageDownloadButton").html("Login to download");
        $("#imageDownloadButton").css('float', 'right');
        $("#imageDownloadButton").click(login.checkLogin.bind(login));
    }
}