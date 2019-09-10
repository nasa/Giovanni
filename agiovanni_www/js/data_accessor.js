giovanni.namespace("portal");

giovanni.portal.getCatalog = function(config, asyncCallback) {
  
  var baseQuery = 'q=dataFieldActive:true&version=2.2&indent=on&facet=true&facet.sort=index&wt=json';
  
  var facetFieldQuery = '';
  for (var i=0; i<config.searchFacets.length; i++)
  {
    facetFieldQuery += '&facet.field='+config.searchFacets[i].name;
  }
  var queryStr = baseQuery+facetFieldQuery;
  
  // make an async query to get the list of facets and total dataset count
  asyncCallback.query = queryStr;
  asyncCallback.countonly = true;
  giovanni.util.getCatalogData(asyncCallback);
};

giovanni.portal.serviceDataAccessor = function() {
  if (giovanni.portal.serviceDataAccessor.services == undefined) {
    giovanni.portal.serviceAccessSettings.async = false;
    $.ajax(giovanni.portal.serviceAccessSettings);
  }
  return giovanni.portal.serviceDataAccessor.services;
};

giovanni.portal.handleServiceDataResponse = function(obj) {
  // store the DOM response
  giovanni.portal.serviceDataAccessor.services = obj;
  // get the default service for use in FacetedSelector.js for the initial query, 
  // before any user action, to get the variable constraints for the default service
  var defaultSvc = $(giovanni.portal.serviceDataAccessor.services).find('service[default="true"]')[0];
  giovanni.portal.serviceDataAccessor.DEFAULT_SERVICE = defaultSvc.getAttribute('name');
};

giovanni.portal.serviceAccessSettings = {
    dataType : "xml",
    url : './giovanni_services.xml',
    success : giovanni.portal.handleServiceDataResponse
};
$.ajax(giovanni.portal.serviceAccessSettings);

giovanni.portal.locationDataAccessor = function(bbPicker, queryString) {
  var respJsonStr = '{"width":360, "height":180}';
  var returnObject = { 'argument':{self:bbPicker,format:"json"}, 'responseText':respJsonStr};
  giovanni.widget.BoundingBoxPicker.fetchDataSuccessHandler(returnObject);
  
};

giovanni.portal.variablesDataAccessor = function(asyncCallback, facetedSelector) {
  var fs = facetedSelector;
  giovanni.portal.getCatalog(fs.config, asyncCallback);
};

giovanni.portal.dateRangeDataAccessor = function(datePicker, queryString) {

  // convert queryString object to string before use
  if (typeof queryString == 'object') queryString = queryString.join();
  queryString = decodeURIComponent(queryString);
  var params = queryString.split("&");
  if (params.length == 0) return;
  
  var varParam = null;
  var service = null;
  for (var i=0; i<params.length; i++) {
    if (params[i].indexOf(giovanni.widget.VariablePicker.dataQueryPartName+'=')==0) {
      varParam = params[i].substring(giovanni.widget.VariablePicker.dataQueryPartName.length+1);
    } else if (params[i].indexOf('service=')==0) {
      service = params[i].substring(8);
    }
  }
  
  // for empty varParam - set start and end date time to empty
  if (varParam == null || varParam=='') 
  {
    var dateJsonStr = '{"startDate":null, "endDate":null}';
    var returnObject = { 'argument':{self:datePicker,format:"json"}, 'responseText':dateJsonStr};
    datePicker.fetchDataSuccessHandler(returnObject);
  } else { // or go and fetch and start/end date for the selected variable
    var selectedVariables = varParam.split(",");
    var baseQuery = 'q=dataFieldActive:true&version=2.2&indent=on&wt=json';
    var facetFilterQuery = '&fq=dataFieldId:(';
    
    for (var i=0; i<selectedVariables.length; i++) {
      // split by '(' to remove the bracket options - if present
      facetFilterQuery +='%22'+selectedVariables[i].split('(')[0]+'%22';
      if (i<selectedVariables.length-1) {
        facetFilterQuery +='%20OR%20';
      }
    }
    facetFilterQuery += ')';
    var queryStr = baseQuery+facetFilterQuery;
    
    giovanni.util.getCatalogData({
      query: queryStr,
      scope: this,
      success: giovanni.portal.dateRangeSuccessCallback,
      failure: giovanni.portal.dateRangeFailureCallback,
      argument: datePicker
    });
  }
  
  // process date range constraints for the selected service
  if (service!=null && service!='') {
    // compute min range
    var minRange = 0;
    if (service=='CoMp' || service=='HvLt' || service=='HvLn') {
      minRange = 3;
    } else if (service=='MpAn' || service=='ArAvTs' || service=='DiArAvTs') {
      minRange = 2;
    }
    minRange = giovanni.portal.getTimeFromTemporalSlices(minRange);
    datePicker.setMinRange(minRange);
    
    // compute max range using time step limit set in service configuration
    var serviceConfig = $(giovanni.portal.serviceDataAccessor.services).find('service[name="'+service+'"]')[0];
    var maxRange = parseInt(serviceConfig.getAttribute('max_frames'));
    if (isNaN(maxRange)) {
      maxRange = 0;
    }
    maxRange = giovanni.portal.getTimeFromTemporalSlices(maxRange);
    datePicker.setMaxRange(maxRange);
  }

};

giovanni.portal.getTimeFromTemporalSlices = function (val) {
  var selVars = session.dataSelector.variablePicker.fs.selectedVariables;
  if (selVars.length == 0) {
    val = 0; // if no variables have been selected, the required interval time cannot be determined 
  } else {
    var maxInterval = 0;
    for (var i=0; i<selVars.length; i++) {
      var curInterval = selVars[i].data.dataProductTimeInterval;
      var order = giovanni.widget.FacetedSelector.getTempResOrder(curInterval);
      maxInterval = order > maxInterval ? order : maxInterval;
    }
    switch (maxInterval) {
    case 1: val = val * 1800; break; // val * 30 * 60; seconds equivalent for 'val' half-hours
    case 2: val = val * 3600; break; // val * 60 * 60; seconds equivalent for 'val' hours
    case 3: val = val * 10800; break; // val * 3 * 60 * 60; seconds equivalent for 'val' 3-hours
    case 4: val = val * 86400; break; // val * 24 * 60 * 60; seconds equivalent for 'val' days
    case 5: val = val * 86400 * 8; break; // val 8 * 24 * 60 * 60; seconds equivalent for 'val' 8 days
    case 6: val = val * 2628028; break; // val * 30.417 * 24 * 60 * 60; seconds equivalent for 'val' months (30.417 avg days per month in a year)
    }
/*
    if (selVars[i].data.dataProductTimeInterval == 'daily') {
      // even if one selected variable is daily, the range has to be in days
      val = val * 24; // convert to minutes equivalent to 'val' days 
      break;
    } else if (selVars[i].data.dataProductTimeInterval == 'hourly') {
      continue;
    }
*/
  }
  return val;
};

giovanni.portal.dateRangeSuccessCallback = function (resp) {

  var respObj = resp.responseObject;
  var docs = respObj.response.docs;
  
  var startDateTime=[], endDateTime=[];
  var hourRequired = false;
  var minutesRequired = false;
  var monthlyDataCount = 0;
  var monthOnlyRequired = false;
  for (var i=0; i<docs.length; i++) {
    //if (startDateTime == null || docs[i].dataProductBeginDateTime < startDateTime) {
      startDateTime.push(docs[i].dataProductBeginDateTime);
    //}
    //if (endDateTime == null || docs[i].dataProductEndDateTime > endDateTime) {
      if (docs[i].dataProductEndDateTime == undefined || 
          docs[i].dataProductEndDateTime == null ||
          docs[i].dataProductEndDateTime == '' ||
          docs[i].dataProductEndDateTime == '2038-01-19T03:14:07Z') {
        docs[i].dataProductEndDateTime = new Date().toISO8601DateTimeString();
      }
      endDateTime.push(docs[i].dataProductEndDateTime);
    //}
      //check for temporal resolution
      if (docs[i].dataProductTimeInterval == 'half-hourly') {
        hourRequired = true;
        minutesRequired = true;
      }else if (docs[i].dataProductTimeInterval == 'hourly') {
        hourRequired = true;
      }else if (docs[i].dataProductTimeInterval == '3-hourly') {
        hourRequired = true;
      }else if (docs[i].dataProductTimeInterval == 'monthly') {
	monthlyDataCount++;
      }
      if(monthlyDataCount == docs.length){
        monthOnlyRequired = true;
      }
  }
  
  var datePicker = resp.argument;
  var dateJsonStr = '{"startDate":["'+startDateTime.join('","')+'"], "endDate":["'+endDateTime.join('","')+'"], "minutesRequired":' + minutesRequired + ', "hourRequired":'+hourRequired+', "monthOnlyRequired":'+monthOnlyRequired+'}';
  var returnObject = { 'argument':{self:datePicker,format:"json"}, 'responseText':dateJsonStr};
  datePicker.fetchDataSuccessHandler(returnObject);
};

giovanni.portal.dateRangeFailureCallback = function (resp) {
};
