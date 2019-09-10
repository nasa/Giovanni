//$Id: VerticalProfile.js,v 1.8 2014/01/06 16:15:45 cchidamb Exp $
//-@@@ AG, Version $Name:  $

/**
 * Used by ResultView to display vertical profiles.
 */

giovanni.namespace('giovanni.widget.VerticalProfile');

/*
 * Construct Vertical Profile class.  Includes calling render()
 */
giovanni.widget.VerticalProfile = function (containerId, dataUrl, chartWidth, chartHeight) {

  // store the container's ID
  this.containerId = containerId;
	// get the container element
	this.container = document.getElementById(containerId);
	if (this.container==null){
	    console.log("Error [giovanni.widget.VerticalProfile]: element '"+containerId+"' not found!");
	    return;
	}

	this.dataUrl = dataUrl;
	if (this.dataUrl == null) {
    console.log("Error [giovanni.widget.VerticalProfile]: data URL for the plot is null");
    return;
	}
	
	this.chartWidth = chartWidth ? chartWidth : '800';
	this.chartHeight = chartHeight ? chartHeight : '600';

	// derive other IDs from container ID
	this.plotId = this.containerId + 'Plot';
  this.captionId = this.containerId + 'Caption';
	
	// clear container
	this.container.innerHTML = "";

	// title div
	this.titleDiv = document.createElement('div');
	this.titleDiv.setAttribute('class', 'plotVerticalProfileTitle');
	this.container.appendChild(this.titleDiv);

	// sub-title div
	this.subTitleDiv = document.createElement('div');
	this.subTitleDiv.setAttribute('class', 'plotVerticalProfileSubTitle');
	this.container.appendChild(this.subTitleDiv);

	// div for the vertical profile plot
	this.plotDiv = document.createElement('div');
	this.plotDiv.setAttribute('id', this.plotId);
	this.plotDiv.setAttribute('class', 'olPlotVerticalProfile');
	this.container.appendChild(this.plotDiv);

	// legend div
	this.legendDiv = document.createElement('div');
	this.legendDiv.setAttribute('class','legendDiv');
	this.container.appendChild(this.legendDiv);
	
	// caption div
	this.captionDiv = document.createElement('div');
	this.captionDiv.setAttribute('id', this.captionId);
	this.captionDiv.setAttribute('class', 'plotVerticalProfileCaption');
	this.container.appendChild(this.captionDiv);
	
	this.render();
};

/*
 * Start the render process 
 *
 * @this {giovanni.widget.VerticalProfile}
 * @author cchidamb
 */
giovanni.widget.VerticalProfile.prototype.render = function (obj) {
  // initiate AJAX call to retrieve data for rendering
  $.ajax({
    dataType : "json",
    url : this.dataUrl,
    success : this.dataCB,
    context : this
  });
};

/*
 * Callback for AJAX call to get data
 *
 * @this {giovanni.widget.VerticalProfile}
 * @author cchidamb
 */
giovanni.widget.VerticalProfile.prototype.dataCB = function (respObj) {

  var vars = respObj.variables;
  var attrs = respObj.attributes;
  
  //var index = 0;
  var xAxis=null, yAxis=null;
  
  for (itemKey in vars) {
    var item = vars[itemKey];
    if (item.dimensions.length > 0 && item.dimensions[0]!='bnds') {
      if (item.attributes.quantity_type) {
        yAxis = item;
      } else {
        xAxis = item;
      }
    }
  }
  
  var data = [];
  var fillValue = yAxis.attributes._FillValue;
  if (xAxis.attributes.positive == 'down') {
    for (var i=xAxis.values.length-1; i>=0; i--) {
      if (yAxis.values[i] != fillValue) {
        data.push([xAxis.values[i], yAxis.values[i]]);
      }
    }
  } else if (xAxis.attributes.positive == 'up') {
    for (var i=0; i<xAxis.values.length; i++) {
      if (yAxis.values[i] != fillValue) {      
        data.push([xAxis.values[i], yAxis.values[i]]);
      }
    }
  }
  
  var options = {
      title : {
        text: attrs['plot_hint_title']
      },
      subtitle : {
        text: attrs['plot_hint_subtitle']
      },
      chart: {
        width: this.chartWidth,
        height: this.chartHeight,
        zoomType: 'xy',
        inverted: true
      },
      xAxis: {
        reversed: true,
        type: 'logarithmic',
        //min: 1,
        //max: 1000,
        //endOnTick: true,
        //tickInterval: 1,
        //minorTickInterval: 0.1,
        labels : {
          format: "{value}"
        },
        gridLineWidth: 1, 
        title: {
          // the chart and hence the axes are reversed - swap labels too
          text: attrs['plot_hint_y_axis_label']
        }
      },

      yAxis: {
        //reversed: true,
        //type: 'logarithmic',
        //min: 1,
        //max: 1000,
        //tickInterval: 1,
        //minorTickInterval: 0.1,
        labels : {
          format: "{value}"
        },
        gridLineWidth: 0,
        title: {
          // the chart and hence the axes are reversed - swap labels too
          text: attrs['plot_hint_x_axis_label']
        }
      },

      legend: {
        enabled: false
      },
      
      series : [ {
        data : data,
        type : 'line'
      } ],
      
      tooltip: {
        formatter: function() {
          return yAxis.attributes.standard_name + ' = ' + this.y + ' ' + yAxis.attributes.units + '<br>' 
            + xAxis.attributes.standard_name + ' = ' + this.x + ' ' + xAxis.attributes.units;
        }
      }
  };
  
  $('#'+this.plotId).empty();
  this.chart = $('#'+this.plotId).highcharts(options);
};

