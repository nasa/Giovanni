/* global giovanni,YAHOO,$ */
/* eslint new-cap: 0 */
// -*- tab-width: 2 -*-

/**
 * Dialog allowing selection from full list of palettes to apply to any plot.
 *
 * State:
 * - container, jQuery object referencing container DOM node
 * - containerId, ID of widget's root DOM element
 * - paletteList, the full list of palettes
 * - selectedPalette, internal object of palette in row with checked radio
 *
 * Communication:
 * - AddPaletteEvent (see: getAddPaletteEvent())
 *     Triggered when the user clicks the "Add Palette" button. Contains data.
 *     Data is an object with a single key, selectedPalette (object rep of palette
 *     currently selected).
 * - CloseEvent (see: getCloseEvent())
 *     Triggered when the user clicks the "Close" button. Contains no data.
 *
 * Author:
 * - Daniel da Silva <Daniel.daSilva@nasa.gov>
 */

giovanni.namespace('giovanni.widget');


giovanni.widget.PaletteSelection = function(container, paletteList) {
  // State variables
  if (typeof container === 'string') {
    this.containerId = container.id;
    this.container = $('#' + container);
  } else {
    this.containerId = Date.now();
    this.container = $(container);
  }
  this.paletteList = paletteList;
  this.selectedPalette = null;

  // Objects representing subwidgets
  this.table = null;
  this.closeBtn = null;
  this.addPaletteBtn = null;

  // Events this widget emits (see Communication in header)
  this.addPaletteEvent = new YAHOO.util.CustomEvent('AddPaletteEvent', this);
  this.closeEvent = new YAHOO.util.CustomEvent('CloseEvent', this);
};


/**
 * Add Palettes table to DOM element.
 *
 * Sets this.table to the YUI widget.
 */
giovanni.widget.PaletteSelection.prototype.addTableToDOM = function(container) {
  var columnDefs;
  var orderedPaletteList;
  var dataSourceInput;
  var palettesDataSource;

  columnDefs = [
    {key: 'radio',
     label: '',
     resizable: false,
     width: 20},
    {key: 'preview',
     label: 'Preview',
     sortable: false,
     width: 50},
    {key: 'label',
     label: 'Name',
     sortable: true}
  ];

  orderedPaletteList = this.paletteList.slice();

  orderedPaletteList.sort(function(palette1, palette2) {
    return palette1.label.localeCompare(palette2.label);
  });

  dataSourceInput = giovanni.util.map(orderedPaletteList, function(palette) {
    var dataSourceElement = $.extend({}, palette);
    dataSourceElement.radio = '<input name="paletteRadio" type="radio"/>';
    dataSourceElement.preview = '<img src="' + palette.thumbnail + '">';
    return dataSourceElement;
  });

  palettesDataSource = new YAHOO.util.DataSource(dataSourceInput);
  palettesDataSource.responseType = YAHOO.util.XHRDataSource.TYPE_JSARRAY;
  palettesDataSource.responseScheme = {fields: ['radio', 'preview', 'name']};

  this.table = new YAHOO.widget.ScrollingDataTable(container[0], columnDefs, palettesDataSource, {
    width: '480px',
    height: '290px'
  });
};


/**
 * Add all elements to the DOM.
 */
giovanni.widget.PaletteSelection.prototype.addToDOM = function() {
  var buttonContainer = $('<div>', {
    id: this.containerId + 'Buttons',
    style: 'float: right;'
  });
  var tableContainer = $('<div>');
  // Create data table for the long palette list.
  this.container.append(tableContainer);

  this.addTableToDOM(tableContainer);

  // Add spacer between table and buttons
  this.container.append($('<div>', {height: '5px'}));

  // Add buttons at the bottom of the dialog to DOM
  this.container.append(buttonContainer);

  this.closeBtn = giovanni.util.createButton(this.containerId + 'CloseButton',
                                             buttonContainer[0],
                                             'Close');

  this.addPaletteBtn = giovanni.util.createButton(this.containerId + 'AddPaletteButton',
                                                  buttonContainer[0],
                                                  'Add Palette');
};

/**
 * Bind to events in the DOM.
 */
giovanni.widget.PaletteSelection.prototype.bindToDOM = function() {
  var self = this;

  // Palette table
  this.table.subscribe('rowClickEvent', function(oArgs) {
    //$("input[type='radio']", self.container).attr('checked', false);
    //$("input[type='radio']", oArgs.target).attr('checked', true);
    self.selectedPalette = this.getRecord(oArgs.target).getData();
  });

  // Buttons
  this.closeBtn.subscribe('click', function() {
    self.closeEvent.fire();
  });

  this.addPaletteBtn.subscribe('click', function() {    
    if (self.selectedPalette) {
      $("input[type='radio']", self.container).attr('checked', false);
      self.addPaletteEvent.fire({selectedPalette: self.selectedPalette});
    }
  });
};


giovanni.widget.PaletteSelection.prototype.getAddPaletteEvent = function() {
  return this.addPaletteEvent;
};


giovanni.widget.PaletteSelection.prototype.getCloseEvent = function() {
  return this.closeEvent;
};


