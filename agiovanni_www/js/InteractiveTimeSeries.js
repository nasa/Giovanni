/**
 * Used by ResultView to display interactive time series.
 */

giovanni.namespace('giovanni.widget.InteractiveTimeSeries');

/*
 * Construct the Time Series class
 */
giovanni.widget.InteractiveTimeSeries = function (containerId, chartWidth, chartHeight) {

    // store the container's ID
    this.containerId = containerId;
    // get the container element
    this.container = document.getElementById(containerId);
    if (this.container == null) {
        console.log("Error [giovanni.widget.InteractiveTimeSeries]: element '" + containerId + "' not found!");
        return;
    }

    this.dataUrlList = [];
    this.responsesSoFar = {};

    this.chart = null;
    this.chartWidth = chartWidth ? chartWidth : '800';
    this.chartHeight = chartHeight ? chartHeight : '600';

    // derive other IDs from container ID
    this.plotId = this.containerId + 'Plot';
    this.captionId = this.containerId + 'Caption';

    // clear container
    this.container.innerHTML = "";

    // title div
    this.titleDiv = document.createElement('div');
    this.titleDiv.setAttribute('class', 'plotTimeSeriesTitle');
    this.container.appendChild(this.titleDiv);

    // sub-title div
    this.subTitleDiv = document.createElement('div');
    this.subTitleDiv.setAttribute('class', 'plotTimeSeriesSubTitle');
    this.container.appendChild(this.subTitleDiv);

    // div for the vertical profile plot
    this.plotDiv = document.createElement('div');
    this.plotDiv.setAttribute('id', this.plotId);
    this.plotDiv.setAttribute('class', 'plotTimeSeries');
    this.container.appendChild(this.plotDiv);

    // legend div
    this.legendDiv = document.createElement('div');
    this.legendDiv.setAttribute('class', 'legendDiv');
    this.container.appendChild(this.legendDiv);

    // caption div
    this.captionDiv = document.createElement('div');
    this.captionDiv.setAttribute('id', this.captionId);
    this.captionDiv.setAttribute('class', 'plotTimeSeriesCaption');
    this.container.appendChild(this.captionDiv);
};

giovanni.widget.InteractiveTimeSeries.prototype.addSeries = function (dataUrl) {

    if (dataUrl == null) {
        console.log("Error [giovanni.widget.InteractiveTimeSeries]: data URL for the series is null");
        return;
    }

    this.dataUrlList.push(dataUrl);

    $.ajax({
        dataType: "json",
        url: dataUrl,
        success: function (respObj) {
            this.dataCB(respObj, dataUrl)
        },
        context: this
    });
};

/*
 * Callback for AJAX call to get data
 * 
 * @this {giovanni.widget.InteractiveTimeSeries} @author cchidamb
 */
giovanni.widget.InteractiveTimeSeries.prototype.dataCB = function (respObj, dataUrl) {

    // keep track of what we've already seen
    this.responsesSoFar[dataUrl] = respObj;

    // see if we've got all the responses we need
    var keys = Object.keys(this.responsesSoFar);
    if (keys.length != this.dataUrlList.length) {
        // no need to do anything yet
        return;
    }

    // go through all the responses we've had
    for (var i in this.dataUrlList) {
        var response = this.responsesSoFar[this.dataUrlList[i]];

        var dims = response.header.dimensions;
        var vars = response.header.variables;
        var global_attrs = response.header.global_attributes;

        var xName = null,
            xAxis = null,
            yName = null,
            yAxis = null;
        for (itemKey in vars) {
            var item = vars[itemKey];
            if (item.dimensions.length == 1 && item.dimensions[0] == 'time' && !item.attributes.quantity_type && itemKey == 'datayear') {
                xName = itemKey;
                xAxis = item;
            } else if (item.dimensions.length > 0 && item.attributes.quantity_type) {
                yAxis = item;
                yName = itemKey;
            }
        }

        var categories = [];
        var data = [];
        for (var j = 0; j < response.data[xName].length; j++) {
            data.push([response.data[xName][j], response.data[yName][j]]);
        }

        var yTitleSplit = yAxis.attributes.long_name.match(/.{1,50}(?=\s|$)/g);
        var yAxisTitle = yTitleSplit.join("<br>");


        if (i == 0) {
            // first time through, we need to create the chart
            var options = {
                title: {
                    text: "Interannual Time Series" // moved from PostProcess::get_seasonal_title
                },
                subtitle: {
                    text: global_attrs['plot_hint_title'] +
                    global_attrs['plot_hint_subtitle'] 
                },
                chart: {

                    width: this.chartWidth,
                    height: this.chartHeight,
                    zoomType: 'xy',
                    // inverted: true
                },
                xAxis: {
                    //type : 'datetime',
                    //minTickInterval : 365 * 24 * 60 * 60 * 1000, // 365 days
                    // maxZoom: 30 * 24 * 3600000, // 30 days
                    // reversed: true,
                    // type: 'logarithmic',
                    // min: 1,
                    // max: 1000,
                    endOnTick: false,
                    tickInterval: 1,
                    // minorTickInterval: 0.1,
                    labels: {
                        format: "{value}"
                    },
                    // gridLineWidth: 0,
                    // categories: categories,
                    title: {
                        text: xAxis.attributes.long_name
                    }
                },

                yAxis: {
                    // reversed: true,
                    // type: 'logarithmic',
                    // min: 1,
                    // max: 1000,
                    // tickInterval: 1,
                    // minorTickInterval: 0.1,
                    labels: {
                        format: "{value}"
                    },
                    // gridLineWidth: 0,
                    title: {
                        text: yAxisTitle,
                        margin: 40 /* + 10*(yAxisTitleLines-1) */
                    }
                },

                legend: {
                    enabled: true
                },

                series: [{
                    name: yAxis.attributes.plot_hint_legend_label,
                    data: data,
          }],

                tooltip: {
                    formatter: function () {
                        return '<b>' + this.series.name + '</b><br/>' + this.x + ' : ' + this.y + ' ' + yAxis.attributes.units;
                    }
                }
            };

            $('#' + this.plotId).empty();
            this.chart = $('#' + this.plotId).highcharts(options);
            $('#' + this.captionId).append(global_attrs['plot_hint_caption']);
        } else {

            var options = {
                name: yAxis.attributes.plot_hint_legend_label,
                data: data,
            };
            if (this.chart) {
                this.chart.highcharts().addSeries(options, false);
                this.chart.highcharts().redraw();
            }
        }

    }

};
