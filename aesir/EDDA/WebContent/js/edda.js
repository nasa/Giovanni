// $Id: edda.js,v 1.121 2016/02/12 19:04:33 eseiler Exp $
//-@@@ EDDA, Version $Name:  $

/** EDDA JavaScript Library v1.0 */
//TODO show waiting status for calls that take too long to complete
edda = function() {
  edda.SCRIPT_BASE = "/edda/daac-bin/";

  this.dataProductTable = null;
  this.dataProductRefreshFlag = false;
  this.dataProductRequest = null;
  this.navLocations = [ [ "Home", "home" ] ];
  this.difIdSrc = null;
  this.difIdRequest = null;
  this.autoCompMinLen = 3;
  this.pendingAjaxCalls = 0;
  this.showGESDISCProdOnly = false;

  $('#brLnk').click(this, function(e) {
    e.data.getDataProducts();
    return false;
  });
  $('#addLnk').click(this, function(e) {
    e.data.addDataProduct();
    return false;
  });
  $('#statLnk').click(this, function(e) {
    e.data.getVariableStatus();
    return false;
  });
  $('#feedback').click(this, function(e) {
    e.data.sendFeedback(e, e.data);
    return false;
  });
  $('a[href=\'#\']').click(function() {
    alert('This feature is not available yet.');
    return false;
  });
  //TODO move gesDiscOnly and difIdSubmit click function defs to addDataProduct method
  $("#gesDiscOnly").click(this, function(e) {
    e.data.showGESDISCProdOnly = this.checked ? true : false;
  });
  $("#difIdSubmit").click(this, function(e) {
    if( $('input[name=prodCreateChoice]:checked').val()=='inCMR' ){
      var sName = $("#newProdShortName").val();
      var verId = $("#newProdVerId").val();
      var provId = $("#newProdProvId").val();
      e.data.getNewDataProductInfoFromCMR(sName, verId, provId);
    } else if( $('input[name=prodCreateChoice]:checked').val()=='inGCMD' ){
      var difId = $("#newProdDifId").val();
      //TODO check for visibility before getting value ?
      var sName;
      var verId;
      e.data.getNewDataProductInfo(difId, sName, verId);
    } else if( $('input[name=prodCreateChoice]:checked').val()=='inXMLFile' ){
      var url = $("#newProdXMLURL").val();
      var path = url.substring(0,url.lastIndexOf("/")+1);
      var file = url.substring(url.lastIndexOf("/")+1,url.length);
      file = file.replace(".xml","");
      console.log("trying to get file using url:" + url);
      e.data.getNewDataProductInfoFromXMLFile(path,file);
    }
  });

  $('#newProdShortName').focusin(function () {
    $('#inCMR').prop('checked',true);
  });
  $('#newProdVerId').focusin(function () {
    $('#inCMR').prop('checked',true);
  });
  $('#newProdProvId').focusin(function () {
    $('#inCMR').prop('checked',true);
  });
  $('#newProdDifId').focusin(function () {
    $('#inGCMD').prop('checked',true);
  });
  $('#newProdXMLURL').focusin(function () {
    $('#inXMLFile').prop('checked',true);
  });

  this.updateNavBar();
  this.initCollapsible('.viewerHeader');

  // perform any advance initialization, as required
  edda.sldMetaDataURLPrefix = "/giovanni/sld/"; 
  $.getJSON( edda.sldMetaDataURLPrefix + "sld_list.json", function( data ) {
    edda.sldMetaData = data.sldList.sld;
  });

  $(window).bind('beforeunload', this, function(event) {
    return event.data.handleUnload(event);
  });
};

edda.prototype.home = function() {
  $("#intro").css("display", "block");
  $("#prodBrowse").css("display", "none");
  $("#prodCreate").css("display", "none");
  $("#prodView").css("display", "none");
  this.navLocations.splice(1, this.navLocations.length - 1);
  this.updateNavBar();
};

edda.prototype.updateNavBar = function() {
  var navLocLinks = [];
  // display hyperlink on all but last location
  for ( var i = 0; i < this.navLocations.length - 1; i++) {
    navLocLinks[i] = "<a id=\"hist" + i + "\" href=\"js.html\">" + this.navLocations[i][0] + "</a>";
  }
  // display just the label for the last location
  navLocLinks[i] = this.navLocations[i][0];
  $("#navBar").html(navLocLinks.join(' &#8594; '));

  for ( var i = 0; i < this.navLocations.length - 1; i++) {
    var func = this[this.navLocations[i][1]];
    var args = this.navLocations[i].slice(2);
    $("#hist" + i).click({
      func : func,
      args : args,
      self : this
    }, function(e) {
      e.data.func.apply(e.data.self, e.data.args);
      return false;
    });
  }
};

edda.prototype.initCollapsible = function(selector, openFn, closeFn) {
  try {
    var self = this;
    $(selector).collapsible({
      // config initializing the collapsible panel
      // disable cookies
      cookieName : '',
      // 300 ms to complete the slide up/down animation
      speed : 300,
      animateClose : function(elem, opts) {
        // do the close animation and display collapsed state info for the facet
        if (closeFn && self[closeFn.name]) {
          (self[closeFn.name]).apply(self, closeFn.args);
        }
        elem.next().slideUp(opts.speed);
      },
      animateOpen : function(elem, opts) {
        if (openFn && self[openFn.name]) {
          (self[openFn.name]).apply(self, openFn.args);
        }
        elem.next().slideDown(opts.speed);
      }
    });
  } catch (err) {
    console.log("Error while initiating collapsible : " + err.message);
  }
};

edda.prototype.getDifEntryIdList = function() {
  $("#difIdInfo").html('<img src="images/loader_small.gif" alt="... loading ..."></img> <span style="color:#cc6644;">Loading DIF ID suggestions...</span>');
  this.difIdRequest = $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "DIFEntryIdList",
    success : this.buildDifEntryIdList,
    complete : this.hideDifIdFetchProgress,
    timeout : 30000,
    context : this
  });
};

edda.prototype.buildDifEntryIdList = function(resp) {
  this.difIdSrc = resp.Entry_IDs;
  console.log("Total Dif Entry IDs : " + this.difIdSrc.length);
  var self = this;
  $("#newProdDifId").autocomplete({
    source : function(request, response) {
      var results = $.ui.autocomplete.filter(self.difIdSrc, request.term);
      if (self.showGESDISCProdOnly) {
        results = $.ui.autocomplete.filter(results, "GES_DISC");
      }
      response(results);
    },
    appendTo : "#difIdAutoComp",
    minLength : this.autoCompMinLen
  });
};

edda.prototype.hideDifIdFetchProgress = function(jqXHR, status) {
  if (status == 'success') {
    $("#difIdInfo").text("Type 3 or more characters for DIF ID suggestions");
  } else {
    $("#difIdInfo").text("Could not retrieve DIF ID suggestions");
  }
};

edda.prototype.handleUnload = function(event) {
  console.log(this);
  // TODO save any open edit sessions here
};

edda.prototype.getDataProducts = function(navBack) {
  $("#intro").css("display", "none");
  $("#prodBrowse").css("display", "block");
  $("#prodCreate").css("display", "none");
  $("#prodView").css("display", "none");

  if (!navBack) {
    this.navLocations.push([ "Browse and Edit", "getDataProducts", true ]);
  } else {
    while (this.navLocations[this.navLocations.length - 1][0] != "Browse and Edit") {
      this.navLocations.pop();
    }
  }
  this.updateNavBar();

  // make a data products request
  // if data product table doesn't exist or the refresh flag has been set
  // - AND -
  // either a data product request doesn't exist or didn't succeed
  if ((this.dataProductTable == null || this.dataProductRefreshFlag)
      && (this.dataProductRequest == null || (this.dataProductRequest.status && this.dataProductRequest.status != 200))) {
    // clear and hide the old data table - this is for the refresh case
    if (this.dataProductTable) {
      $('#dataProductTable').empty();
      this.dataProductTable.fnDestroy();
      $('#dataProductTable').hide();
    }
    // show the loading icon
    $('#tableLoadIcon').show();
    // make ajax request
    this.dataProductRequest = $.ajax({
      dataType : "json",
      url : edda.SCRIPT_BASE + "getDataProducts",
      success : this.dataProductsCB,
      context : this
    });
  } else {
    // position the cursor in the search box
    // works only if the table has been created - otherwise doesn't do anything
    $("div.dataTables_filter input").focus();
  }
};

edda.prototype.dataProductsCB = function(data, textStatus, jqXHR) {
  var list = [];
  if (data.dataProducts.dataProduct) {
    list = data.dataProducts.dataProduct;
  }
  var tableData = [];
  for ( var i = 0; i < list.length; i++) {
    var dataObj = {
      "id" : list[i].dataProductId[0].value[0].value,
      "difId" : list[i].dataProductGcmdEntryId[0].value[0].value,
      "sName" : list[i].dataProductShortName[0].value[0].value,
      "ver" : list[i].dataProductVersion[0].value[0].value
    };
    tableData.push(dataObj);
  }
  // clear the refresh flag
  this.dataProductRefreshFlag = false;
  // clear the request - to enable making new requests when refresh flag is set
  this.dataProductRequest = null;

  var tableOptions = { // refer http://datatables.net/ref
    "bPaginate" : true,
    "bFilter" : true,
    "bProcessing" : true,
    "bSort" : true,
    "bInfo" : true,
    "bAutoWidth" : false,
    "iDisplayLength" : 25,
    "oLanguage" : { // refer http://www.datatables.net/usage/i18n
      "sSearch" : "Search for data sets: ",
      "sInfo" : "Showing _START_ to _END_ of _TOTAL_ data sets",
      "sLengthMenu" : "Show _MENU_ data sets",
      "sZeroRecords" : "No matching data sets found",
      "sInfoEmpty" : "Showing _TOTAL_ data sets",
      "sInfoFiltered" : " - filtered from _MAX_ total data sets"
    },
    "aaData" : tableData,
    "aoColumns" : [ {
      "mData" : "id",
      "sWidth" : "10%",
      "sType" : "html",
      "sClass" : "centered",
      "bSortable" : false, 
      "mRender" : function(data, type, full) {
        // since mData is set to the 'id' attribute
        // the first parm to this function 'data' (mData) = 'full'.'id'
        if (type === 'display') {
          // show the select button
          return '<button id="select_' + data + '" title="Click to view/edit this data set\'s attributes and data variables">Edit</a>';
        }
        // for type == 'filter' || 'sort' || 'type' || undefined - just use the raw value
        return data;
      }
    }, {
      //TODO clicking on the anchors in <th> also triggers the sorting feature of the column - can't find a way to stop that
      "sTitle" : "<a target='GCMD' href='http://gcmd.nasa.gov/'>GCMD</a> " + 
                 "<a target='DIF' href='http://gcmd.gsfc.nasa.gov/add/difguide/entry_id.html'>DIF ID</a>",
      "mData" : "difId",
      "sWidth" : "60%",
      "sType" : "html",
      "mRender" : function(data, type, full) {
        // since mData is set to the 'difId' attribute
        // the first parm to this function 'data' (mData) = 'full'.'difId'
        if (type === 'display') {
          // the displayed gcmd dif id will be hyperlinked to the description url
          return data + '<span  class="spacedCtrl">[' 
            + '<a target="' + data + '" href="http://gcmd.gsfc.nasa.gov/getdif.htm?' + data 
            + '" title="Click to view documentation">Read More</a>]';
        }
        // for type == 'filter' || 'sort' || 'type' || undefined - just use the raw value
        return data;
      }
    }, {
      "sTitle" : "Short Name",
      "mData" : "sName",
      "sWidth" : "20%",
      "sType" : "string"
    }, {
      "sTitle" : "Version",
      "mData" : "ver",
      "sWidth" : "10%",
      "sType" : "string",
      "sClass" : "centered"
//    }, {
//      "mData" : "difId",
//      "sWidth" : "10%",
//      "sType" : "html",
//      "sClass" : "centered",
//      "bSearchable" : false, 
//      "bSortable" : false, 
//      "mRender" : function(data, type, full) {
//        // since mData is set to the 'difId' attribute
//        // the first parm to this function 'data' (mData) = 'full'.'difId'
//        if (type === 'display') {
//          // the displayed gcmd dif id will be hyperlinked to the description url
//          return '<a target="' + data + '" href="http://gcmd.gsfc.nasa.gov/getdif.htm?' + data + '" title="Click to view documentation">Read More</a>';
//        }
//        // for type == 'filter' || 'sort' || 'type' || undefined - just use the raw value
//        return data;
//      }
    } ],
    "aaSorting" : [ [ 1, "asc" ] ],
    // refer http://datatables.net/usage/options#sDom
    "sDom" : '<"top"lf>rt<"bottom"pi><"clear">',
    "sPaginationType" : "full_numbers"
  };

  // create data table & hide loading icon
  this.dataProductTable = $('#dataProductTable').dataTable(tableOptions);
  $('#dataProductTable').show();
  $('#tableLoadIcon').hide();

  // clicking on the select button in the first column should flow forward
  // to the product info page for the corresponding product
  this.dataProductTable.$('td:first button').click(this, function(e) {
    var pos = e.data.dataProductTable.fnGetPosition(this.parentElement);
    var data = e.data.dataProductTable.fnGetData(pos[0]);
    e.data.getDataProductInfo(data.id);
  });

  // position the cursor in the search box
  $("div.dataTables_filter input").focus();
};

edda.prototype.getDataProductInfo = function(dataProdId, navBack) {
  $("#intro").css("display", "none");
  $("#prodBrowse").css("display", "none");
  $("#prodCreate").css("display", "none");
  $("#prodView").css("display", "block");

  if (!navBack) {
    this.navLocations.push([ dataProdId, "getDataProductInfo", dataProdId, true ]);
  } else {
    while (this.navLocations[this.navLocations.length - 1][0] != dataProdId) {
      this.navLocations.pop();
    }
  }
  this.updateNavBar();

  this.showWaitCursor();
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getDataProductInfo?dataProductId=" + dataProdId,
    success : this.dataProductInfoCB,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.dataProductInfoCB = function(data, textStatus, jqXHR) {
  var dataProductInfo = data.dataProducts.dataProduct[0];
  var productId = extractValues(dataProductInfo.dataProductId[0])[0];

  var ln = extractValues(dataProductInfo.dataProductIdentifiers[0].value[0].dataProductLongName[0])[0];
  var sn = extractValues(dataProductInfo.dataProductIdentifiers[0].value[0].dataProductShortName[0])[0];
  $("#viewerTitle").text(ln + " (" + sn + ")");

  var attrPrefix = productId.replace(/\./g, '_');

//  var values = extractLabelTypeValues(dataProductInfo);

  $('.viewerHeader').collapsible('close');
  $("#attributesEdit").empty(); // in case anything was left behind
  $("#attributes").empty();

  var htmlStr = '<table width="100%"><thead><tr><th width="30%"/><th width="70%"/></tr></thead><tbody>';
  for (key in dataProductInfo) {
    var attrValue = (dataProductInfo[key])[0];
    // attributes without label are not displayed
    if (attrValue.label && attrValue.label[0].value) {
      htmlStr += createEditHtml(attrPrefix, key, attrValue);
    }
  }
  htmlStr += '</tbody></table>'

//  for ( var i = 0; i < values.length; i++) {
//    htmlStr = createViewHtml(values[i]);
//    $("#attributes").append(htmlStr);
//  }

  var buttonId = attrPrefix + "_update";  
  var buttonId2 = attrPrefix + "_delete";  
  htmlStr += '<p class="actionPanel"><button id="' + buttonId + '">Save</button> <button class="spacedCtrl" id="' + buttonId2 + '">Delete</button></p>';
  $("#attributes").append(htmlStr);

  $("#" + buttonId).click(this, function(e) {
    e.data.updateDataProductInfo(dataProductInfo);
  });

  $("#" + buttonId2).click(this, function(e) {
    $("#deleteDatasetConfDlg").dialog({
      title : 'Confirm Data Set Deletion',
      modal : true,
      width: 500,
      height: 300,
      buttons : [ {
        text : "Delete Data Set",
        click : function() {
          var comment = $("#deleteDatasetComment").val();
          e.data.deleteDataProduct(dataProductInfo, comment);
          $(this).dialog("close");
        }
      }, {
        text : "Cancel",
        click : function() {
          $(this).dialog("close");
        }
      } ]
    });
  });

//  $("#" + attrPrefix + "_republish").click(this, function(e) {
//    $("#republishConfDlg").dialog({
//      title : 'Confirm Republish',
//      modal : true,
//      width: 500,
//      height: 300,
//      buttons : [ {
//        text : "Republish all published variables",
//        click : function() {
//          var comment = $("#republishComment").val();
//          e.data.updateDataProductInfo(dataProductInfo, 1, comment);
//          $(this).dialog("close");
//        }
//      }, {
//        text : "Cancel",
//        click : function() {
//          $(this).dialog("close");
//        }
//      } ]
//    });
//  });

//  $("#productActionPanel").hide();

  var canAddNewFields = extractValues(dataProductInfo.dataProductCanAddNewFields[0])[0] == 'true';
  // for new products, i.e., canAddNewFields is true, get the new fields list right away
  // instead of showing the 'Add Data Variable' button
  if (canAddNewFields) {
    this.getDataFieldsByProbe(productId);
    // $("#productActionPanel").html("<button id=\"addNewDataField\">Add Data
    // Field</button>");
    // $("#productActionPanel").show();
  } else {
    $("#fieldsList").empty();
    $("#fieldsList").hide();
    // $("#productActionPanel").empty();
    // $("#productActionPanel").hide();
  }
  // $("#addNewDataField").click(this, function(e) {
  // var id = extractValues(dataProductInfo.dataProductId[0])[0];
  // e.data.getNewDataFieldInfo(id);
  // });

  $("#productActionPanel").hide();
  $("#newField").empty();
  $("#newField").hide();

  // var dataFieldAttr = dataProductInfo['dataProductDataFieldIds'][0];
  // var fieldIds = extractValues(dataFieldAttr);
  // htmlStr = createViewHtml({
  // "label" : "Data Field IDs",
  // "value" : fieldIds
  // });
  // $("#publicFields").append(htmlStr);

  // get and populate the data fields dropdowns
  this.getDataFields(productId);
};

edda.prototype.getDataFields = function(dataProdId) {
  // empty the data fields list
  $("#dataFields").empty();
  $("#dataFieldsFooter").empty();
  $("#dataFieldsCount").empty();

  // call getDataFields to display a line item per data field, in the editor area
  this.showWaitCursor();
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getDataFields?dataProductId=" + dataProdId,
    success : this.dataFieldsCB,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.dataFieldsCB = function(data, textStatus, jqXHR) {
  var fields = data.dataFields.dataField;
  if (!fields)
    fields = []; // for new products, there are no fields yet

  var pub = 0, prv = 0;
  var setFooterNotes = false;

  for ( var i = 0; i < fields.length; i++) {
    var field = fields[i];
    var ln = extractValues(field.dataFieldLongName[0])[0];
    var id = extractValues(field.dataFieldId[0])[0];
    var state = extractValues(field.dataFieldState[0])[0];
//    var lastPubDate = extractValues(field.dataFieldLastPublished[0])[0];
//    if (lastPubDate) {
//      lastPubDate = lastPubDate.substring(0, 10) + ' ' + lastPubDate.substring(11, 19);
//    }
    var baselines = field.dataFieldPublishedBaselineInfo;
    // baseline list is sorted by hierarchy; get the last item (the highest baseline)
    var highBase = '';
    var highBasePubDate = '';
    var highBasePubActive = '';
    if (baselines) {
      // pick the baseline with the latest published date
      for (var j=0; j<baselines.length; j++) {
        var baseDate = baselines[j] ? baselines[j].value[0].dataFieldPublishedDate[0].value[0].value : '';
        if (!isNaN(Date.parse(baseDate)) 
            && (Date.parse(baseDate) > Date.parse(highBasePubDate) || isNaN(Date.parse(highBasePubDate)))) {
          highBasePubDate = baseDate;
          highBase = baselines[j].value[0].dataFieldPublishedBaseline[0].value[0].value;
          highBasePubActive = baselines[j].value[0].dataFieldActive[0].value[0].value;
          if (highBasePubActive == 'false') {
            highBase += '*';
          }
        }
      }
      // if the last pub dates are not available, pick the last one in the list - which is the highest published baseline in the hierarchy
      if (!highBase) {
        highBase = baselines[baselines.length-1].value[0].dataFieldPublishedBaseline[0].value[0].value;
        highBasePubActive = baselines[baselines.length-1].value[0].dataFieldActive[0].value[0].value;
        if (highBasePubActive == 'false') {
          highbase += '*';
        }
      }
    }
    var fieldElementExists = $("#dataFields div#"+id).length;
    if ( ('Published' == state) || ('Unpublished' == state) ) {
      if (fieldElementExists) {
        var coFldHd = $("#dataFields div#"+id).prev();
        coFldHd.children("span.stateLabel").empty();
        coFldHd.children("span.baselineLabel").text(highBase);
        if (highBasePubDate) {
          coFldHd.children("span.fltRt").text("Last published date: " + highBasePubDate);
        }
        $("#dataFields div#"+id).empty();
      } else {
        $("#dataFields").append(
            "<div class='editorHeader' id='coFldHd" + i + "'>" 
            + "<span class='collapse-icon'></span>" 
            + "<span class='stateLabel'></span>" 
            + "<span class='baselineLabel'>" + highBase + "</span>" 
            + ln + " [" + id + "] " 
            + (highBasePubDate ? "<span class='fltRt'>Last published date: " + highBasePubDate + "</span>" : "") 
            + "</div>"
        );
        $("#dataFields").append("<div class='editorLineItem' id='" + id + "'></div>");
        pub++;
      }
    } else if ('Private' == state || 'Updated' == state || 'SubmittedPrivate' == state || 'SubmittedUpdated' == state) {
      var stTxt = '';
      switch (state) {
      case 'Private': stTxt = 'Draft'; break;
      case 'Updated': stTxt = '*'; setFooterNotes = true; break;
      case 'SubmittedPrivate': 
      case 'SubmittedUpdated': stTxt = 'Pending Publish'; break;
      }
      if (fieldElementExists) {
        var coFldHd = $("#dataFields div#"+id).prev();
        coFldHd.children("span.stateLabel").text(stTxt);
        coFldHd.children("span.baselineLabel").text(highBase);
        if (highBasePubDate) {
          coFldHd.children("span.fltRt").text("Last published date : " + highBasePubDate);
        }
        $("#dataFields div#"+id).empty();
      } else {
        $("#dataFields").append(
            "<div class='editorHeader' id='coFldHd" + i + "'>" 
            + "<span class='collapse-icon'></span>" 
            + "<span class='stateLabel'>" + stTxt + "</span>" 
            + "<span class='baselineLabel'>" + highBase + "</span>" 
            + ln + " [" + id + "] "
            + (highBasePubDate ? "<span class='fltRt'>Last published date : " + highBasePubDate + "</span>" : "") 
            + "</div>"
        );
        $("#dataFields").append("<div class='editorLineItem' id='" + id + "'></div>");
        prv++;
      }
    } else {
      console.log("System Error: Invalid value '" + state + "' for attribute 'dataFieldState' of field ID '" + id + "'");
      //alert("System Error: Invalid value '" + state + "' for attribute 'dataFieldState' of field ID '" + id + "'");
      continue;
    }
    // TODO check why the data field entries create an additional scroll bar
    if (! fieldElementExists) {
      this.initCollapsible('#coFldHd' + i, {
        name : "getDataFieldInfo",
        args : [ id, state ]
      }, {
        name : "dataFieldClose",
        args : [ id ]
      });
    }
  }

  $("#dataFieldsCount").text('(' + (prv || pub ? prv+pub : 'empty') + ')');
  if (setFooterNotes) {
    $("#dataFieldsFooter").text(" * Data variable has unpublished updates");
  }        
};

edda.prototype.getDataFieldsByProbe = function(dataProdId) {
  // empty the data fields select list
  $("#fieldsList").empty();

  // call getDataFields with dataProbe flag to get the list of fields from the OPeNDAP granule
  this.showWaitCursor();
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getDataFields?dataProductId=" + dataProdId + "&dataProbe",
    success : function(data) {
      this.dataFieldsProbeCB(data, dataProdId);
    },
    error: function (data) {
      this.dataFieldsProbeErrorCB(data, dataProdId);
    },
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.dataFieldsProbeErrorCB = function (data, dataProdId) {
  var select = document.createElement("button");
  select.setAttribute('id','emptyFieldButton');
  select.innerHTML = "Add an empty variable";
  $("#fieldsList").append(select);
  $("#fieldsList").show();
  $('#emptyFieldButton').click(this, function(e) {
    var select = document.getElementById("fieldsListMenu");
    // call getNewDataFieldInfo with product id
    e.data.getNewDataFieldInfo(dataProdId);
  });
}

edda.prototype.dataFieldsProbeCB = function(data, dataProdId) {
  $("#fieldsList").empty();
  var fields = data.dataFields.dataField;
  if (!fields) {
    // no fields obtained from probe - have to create blank variable
    // but cannot create variable yet - have to provide the user that choice
    // this.getNewDataFieldInfo(<product id>);
    // return;
    fields = [];
  }

  // display the list of fields - along with option for a blank variable
  // based on user response, call getNewDataFieldInfo with optional prod and
  // field id

  // $("#addNewDataField").attr('disabled', 'disabled'); // hide();
  $("#fieldsList").empty();

  $("#fieldsList")
      .append(
          "<p>The following data variables are available from the sample granule file for this data set. Please choose one to retrieve its information, or choose to add an empty variable.</p>");

  // create list of data fields available to be added for this product
  var select = document.createElement("select");
  select.id = 'fieldsListMenu';
  for ( var i = 0; i < fields.length; i++) {
    var field = fields[i];
    var ln = extractValues(field.dataFieldLongName[0])[0];
    var id = extractValues(field.dataFieldId[0])[0];
    $(select).append('<option value="' + id + '">' + ln + ' [' + id + ']</option>');
  }
  $(select).append('<option value="none">Add an empty variable</option>');
  $("#fieldsList").append(select);

  $("#fieldsList").append('<button class="spacedCtrl" id="fieldsListNext">Retrieve Data Variable</button>');
  $("#fieldsList").show();

  $("#fieldsListNext").click(this, function(e) {
    var select = document.getElementById("fieldsListMenu");
    // call getNewDataFieldInfo with product id and field id
    if (select.value != "none") {
      e.data.getNewDataFieldInfo(dataProdId, select.value);
    } else {
      e.data.getNewDataFieldInfo(dataProdId);
    }
  });

  // $("#fieldsListCancel").click(this, function(e) {
  // $("#fieldsList").empty();
  // $("#fieldsList").hide();
  // // $("#addNewDataField").removeAttr('disabled'); // show();
  // });
};

edda.prototype.getDataFieldInfo = function(fieldId, state) {
  // proceed to get data field info only if the editor line item div is empty
  // don't refresh the field info with the collapse-open action
  if ($("#dataFields div#"+fieldId).children().length > 0) {
    return;
  }
  this.showWaitCursor();
  var successFn = null;
  switch(state) {
  case 'Private': 
  case 'Updated':
  case 'Unpublished': 
  case 'Published': successFn = this.unsubmittedDataFieldInfoCB; break;
  case 'SubmittedPrivate': 
  case 'SubmittedUpdated': successFn = this.submittedDataFieldInfoCB; break;
  }
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getDataFieldInfo?dataFieldId=" + fieldId,
    success : successFn,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.unsubmittedDataFieldInfoCB = function(data, textStatus, jqXHR) {
  var dataFieldInfo = data.dataFields.dataField[0];
  var fieldId = extractValues(dataFieldInfo.dataFieldId[0])[0];
  this.showDataFieldInfo(fieldId, dataFieldInfo);

  var state = extractValues(dataFieldInfo.dataFieldState[0])[0];

  var htmlStr = '<p class="actionPanel"><button id="' + fieldId + '_save">Save</button>'
    + '<button class="spacedCtrl" id="' + fieldId + '_pub">Publish</button>';
  if ('Published' == state) {
    htmlStr += '<button class="spacedCtrl" id="' + fieldId + '_unpub">Unpublish</button>';
  }
  htmlStr += '<button class="spacedCtrl" id="' + fieldId + '_delete">Delete</button></p>';
  htmlStr +='</p>';
  $("#" + fieldId).append(htmlStr);

  $("#" + fieldId + "_save").click(this, function(e) {
    e.data.saveField(dataFieldInfo);
  });
  $("#" + fieldId + "_pub").click(this, function(e) {
    $("#publishConfDlg").dialog({
      title : 'Confirm Publish',
      modal : true,
      width: 500,
      height: 300,
      buttons : [ {
        text : "Publish",
        click : function() {
          var comment = $("#publishComment").val();
          e.data.publishField(dataFieldInfo, comment);
          $(this).dialog("close");
        }
      }, {
        text : "Cancel",
        click : function() {
          $(this).dialog("close");
        }
      } ]
    });
//    var confPub = confirm("Do you want to submit a request for publishing this variable ?");
//    if (confPub) {
//      e.data.publishField(dataFieldInfo);
//    }
  });

  $("#" + fieldId + "_unpub").click(this, function(e) {
    $("#unpublishVariableConfDlg").dialog({
      title : 'Confirm Variable Unpublishing',
      modal : true,
      width: 500,
      height: 300,
      buttons : [ {
        text : "Unpublish Variable",
        click : function() {
          var comment = $("#unpublishVariableComment").val();
          e.data.unpublishField(dataFieldInfo, comment);
          $(this).dialog("close");
        }
      }, {
        text : "Cancel",
        click : function() {
          $(this).dialog("close");
        }
      } ]
    });
  });

  $("#" + fieldId + "_delete").click(this, function(e) {
    $("#deleteVariableConfDlg").dialog({
      title : 'Confirm Variable Deletion',
      modal : true,
      width: 500,
      height: 300,
      buttons : [ {
        text : "Delete Variable",
        click : function() {
          var comment = $("#deleteVariableComment").val();
          e.data.deleteField(dataFieldInfo, comment);
          $(this).dialog("close");
        }
      }, {
        text : "Cancel",
        click : function() {
          $(this).dialog("close");
        }
      } ]
    });
  });
};

edda.prototype.submittedDataFieldInfoCB = function(data, textStatus, jqXHR) {
  var dataFieldInfo = data.dataFields.dataField[0];
  var fieldId = extractValues(dataFieldInfo.dataFieldId[0])[0];
  this.showDataFieldInfo(fieldId, dataFieldInfo, true);

  var htmlStr = '<p class="actionPanel"><button disabled="disabled">Save</button>'
    + '<button class="spacedCtrl" disabled="disabled">Publish</button>'
    + '<button class="spacedCtrl" id="' + fieldId + '_cancel">Cancel Publish Request</button></p>';
  $("#" + fieldId).append(htmlStr);

  $("#" + fieldId + "_cancel").click(this, function(e) {
    var cancPub = confirm("Do you want to cancel the publish request for this data variable?");
    if (cancPub) {
      e.data.cancelPublishField(dataFieldInfo);
    }
  });
};

////TODO could merge intDataFieldInfoCB and extDataFieldInfoCB since the add/save button distinction is now gone
//// both have commmon actions now - save and publish
//edda.prototype.intDataFieldInfoCB = function(data, textStatus, jqXHR) {
//  var dataFieldInfo = data.dataFields.dataField[0];
//  var fieldId = extractValues(dataFieldInfo.dataFieldId[0])[0];
//  this.showDataFieldInfo(fieldId, dataFieldInfo);
//
//  $("#" + fieldId).append('<p class="actionPanel"><button id="' + fieldId + '_save">Save</button><button class="spacedCtrl" id="' + fieldId + '_pub">Publish</button></p>');
//
//  var self = this;
//  $("#" + fieldId + "_save").click(function() {
//    // self.lastSavedField = dataFieldInfo; // TODO this is a race condition
//    // while saving two fields in succession
//    self.saveField(dataFieldInfo);
//  });
//};
//
//edda.prototype.extDataFieldInfoCB = function(data, textStatus, jqXHR) {
//  var dataFieldInfo = data.dataFields.dataField[0];
//  var fieldId = extractValues(dataFieldInfo.dataFieldId[0])[0];
//  this.showDataFieldInfo(fieldId, dataFieldInfo);
//
//  $("#" + fieldId).append('<p class="actionPanel"><button id="' + fieldId + '_save">Save</button><button class="spacedCtrl" id="' + fieldId + '_pub">Publish</button></p>');
//
//  $("#" + fieldId + "_save").click(this, function(e) {
//    e.data.addField(dataFieldInfo);
//  });
//};

edda.prototype.showDataFieldInfo = function(fieldId, dataFieldInfo, readonly) {
  // clear and reconstruct the field info editor area contents every time the
  // field is closed and opened
  $("#" + fieldId).empty();
  var htmlStr;

  // attributes of type 'dataFieldPublishedBaselineInfo' are for UI usage only
  // remove them before sending back the field for save/publish
  var baselines = '';
  for (key in dataFieldInfo) {
    var attrValue = (dataFieldInfo[key])[0];
    if (attrValue.type && attrValue.type[0] && attrValue.type[0].value=='dataFieldPublishedBaselineInfo') {
      console.log("deleting attribute " + key + " from Data Field ID : " + fieldId + " since the attribute type is 'dataFieldPublishedBaselineInfo'");
      baselines = dataFieldInfo[key];
      delete dataFieldInfo[key];
    }
  }

  //if readonly - create view only html
  if (readonly) {
    var values = extractLabelTypeValues(dataFieldInfo);
    for ( var i = 0; i < values.length; i++) {
      htmlStr = createViewHtml(values[i]);
      $("#" + fieldId).append(htmlStr);
    }
  } else {
    htmlStr = '<table width="100%"><thead><tr><th width="30%"/><th width="70%"/></tr></thead><tbody>';
    for (key in dataFieldInfo) {
      var attrValue = (dataFieldInfo[key])[0];
      // attributes without label are not displayed
      if (attrValue.label && attrValue.label[0].value) {
        htmlStr += createEditHtml(fieldId, key, attrValue);
      }
    }
    htmlStr += '</tbody></table>';
    $("#" + fieldId).append(htmlStr);

    var attrKey = null;
    var attrValue = null;
    for (key in dataFieldInfo) {
      var tmpValue = (dataFieldInfo[key])[0];
      //if (tmpValue.type[0].value == 'colorPalette') {
      if (key == 'dataFieldSld') {
        attrKey = key;
        attrValue = tmpValue;
        break;
      }
    }
    $('#'+fieldId+'AddPal').click(function() {
      showPaletteDialog(fieldId, attrKey, attrValue.valids[0].valid);
    });
    for (var i=0; i<attrValue.value.length; i++) {
      if (attrValue.value[i].value) {
        $('#'+fieldId+'DelPal'+i).click( getDeleteFn(fieldId, attrKey, attrValue.value[i].value) );
      }
    }
  }
};

function getEditFn(fieldId, attrKey, value) {
  return function() {
    showPaletteDialog(fieldId, attrKey, value);
  };
};

function getDeleteFn(fieldId, attrKey, value) {
  return function() {
    var input = $("#"+fieldId+" input[name="+fieldId+attrKey+"][value="+value+"]");
    var cell = input.parent();
    var row = cell.parent();
    if (cell.prev().html() == '') { // 2nd or higher row - remove entire row
      row.empty();
    } else { // first row - empty cell only
      cell.empty();
    }
  };
};

edda.prototype.saveField = function(dataFieldInfo) {
  var attrPrefix = extractValues(dataFieldInfo.dataFieldId[0])[0];
  var saveDataFieldInfo = this.createSaveObject(attrPrefix, dataFieldInfo);
  if (saveDataFieldInfo) {
    var saveObject = {
      "dataField" : saveDataFieldInfo
    };
    this.showWaitCursor();
    $.ajax({
      type : "POST",
      data : JSON.stringify(saveObject),
      dataType : "json",
      contentType : "application/json; charset=UTF-8",
      url : edda.SCRIPT_BASE + "updateDataFieldInfo?action=save",
      success : this.handleSaveResponse,
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

edda.prototype.publishField = function(dataFieldInfo, comment) {
  var attrPrefix = extractValues(dataFieldInfo.dataFieldId[0])[0];
  var saveDataFieldInfo = this.createSaveObject(attrPrefix, dataFieldInfo);
  if (saveDataFieldInfo) {
    var saveObject = {
      "dataField" : saveDataFieldInfo
    };
    var commentStr = comment ? "&comment="+encodeURIComponent(comment) : '';
    this.showWaitCursor();
    $.ajax({
      type : "POST",
      data : JSON.stringify(saveObject),
      dataType : "json",
      contentType : "application/json; charset=UTF-8",
      url : edda.SCRIPT_BASE + "updateDataFieldInfo?action=publish" + commentStr,
      success : this.handlePublishResponse,
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

edda.prototype.unpublishField = function(dataFieldInfo, comment) {
  var attrPrefix = extractValues(dataFieldInfo.dataFieldId[0])[0];
  var saveDataFieldInfo = this.createSaveObject(attrPrefix, dataFieldInfo);
  if (saveDataFieldInfo) {
    var saveObject = {
      "dataField" : saveDataFieldInfo
    };
    var commentStr = comment ? "&comment="+encodeURIComponent(comment) : '';
    this.showWaitCursor();
    $.ajax({
      type : "POST",
      data : JSON.stringify(saveObject),
      dataType : "json",
      contentType : "application/json; charset=UTF-8",
      url : edda.SCRIPT_BASE + "updateDataFieldInfo?action=unpublish" + commentStr,
      success : this.handleUnpublishResponse,
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

edda.prototype.cancelPublishField = function(dataFieldInfo) {
  var saveObject = {
    "dataField" : dataFieldInfo
  };
  this.showWaitCursor();
  $.ajax({
    type : "POST",
    data : JSON.stringify(saveObject),
    dataType : "json",
    contentType : "application/json; charset=UTF-8",
    url : edda.SCRIPT_BASE + "updateDataFieldInfo?action=cancel",
    success : this.handleCancelResponse,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.deleteField = function(dataFieldInfo, comment) {
  var dataFieldId = extractValues(dataFieldInfo.dataFieldId[0])[0];
  var dataProdId = extractValues(dataFieldInfo.dataFieldProductId[0])[0];
  var qStr = "?";
  if (dataFieldId) {
      qStr += "dataFieldId=" + dataFieldId;
    if (comment) {
      qStr += "&comment="+encodeURIComponent(comment);
    }
    this.showWaitCursor();
    $.ajax({
      type : "GET",
      url : edda.SCRIPT_BASE + "deleteDataField" + qStr,
      success : function(dataObj) {
        this.deleteFieldCB(dataObj, dataProdId, dataFieldId);
      },
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

//edda.prototype.addField = function(dataFieldInfo) {
//  var attrPrefix = extractValues(dataFieldInfo.dataFieldId[0])[0];
//  var saveDataFieldInfo = this.createSaveObject(attrPrefix, dataFieldInfo);
//  if (saveDataFieldInfo) {
//    var saveObject = {
//      "dataField" : saveDataFieldInfo
//    };
//    this.showWaitCursor();
//    $.ajax({
//      type : "POST",
//      data : JSON.stringify(saveObject),
//      dataType : "json",
//      contentType : "application/json; charset=UTF-8",
//      url : edda.SCRIPT_BASE + "updateDataFieldInfo",
//      success : this.handleAddResponse,
//      complete: this.showDefaultCursor,
//      context : this
//    });
//  }
//};

edda.prototype.createSaveObject = function(attrPrefix, dataObject) {
  for (attr in dataObject) {
    var attrValue = (dataObject[attr])[0];
    //    var label = attrValue.label[0].value;
    var label;
    if (attrValue.label) {
      label = attrValue.label[0].value;
    }
    //    var type = attrValue.type[0].value;
    var type;
    if (attrValue.type) {
      type = attrValue.type[0].value;
    }
    var constraints = attrValue.constraints;
    var editable = false;
    var regex = null;
    var regexTxt = null;
    if (constraints) {
      editable = (constraints[0].editable[0].value == 'true');
      if (constraints[0].regex) {
        regex = constraints[0].regex[0].value;
        regexTxt = constraints[0].validationText[0].value;
      }
    }
    if (type == 'container') {
      // TODO call saveObject recursively for container
      var recVal = this.createSaveObject(attrPrefix + attr, attrValue.value[0]);
      if (recVal) {
        attrValue.value = [ recVal ];
      } else {
        return null;
      }
    } else if (label && editable) {
      var userVal;
      if (attrValue.multiplicity[0].value == "one") {
        // TODO make sure a single select list gives the value directly
        // rather than an array of size 1
        if ($("#" + attrPrefix + attr).length) {
          userVal = $("#" + attrPrefix + attr).val();
        } else if (attrValue.type[0].value == "boolean") {
          userVal = $("input[name=" + attrPrefix + attr + "]:checked").val();
        }
      } else if (attr == 'dataFieldSld') {
        userVal = [];
        $("input[name=" + attrPrefix + attr + "]").each(function() {
          var val = $(this).val();
          if (val && typeof(val) !== 'undefined') {
            userVal.push(val);
          }
        });
      } else if (attrValue.type[0].value == "list") {
        userVal = $("#" + attrPrefix + attr).val() || [];
      } else {
        userVal = [];
        $("input[name=" + attrPrefix + attr + "]").each(function() {
          var val = $(this).val();
          if (val && typeof(val) !== 'undefined') {
            userVal.push(val);
          }
        });
      }
      attrValue.value = [];
      if (attrValue.multiplicity[0].value == "one" && userVal && typeof(userVal) !== 'undefined') {
        if (regex && !userVal.match(regex)) {
          alert("Invalid value '" + userVal + "' for '" + attrValue.label[0].value + "'.\n" + regexTxt);
          return null;
        }
        attrValue.value.push({
          'value' : userVal
        });
      } else if (attrValue.multiplicity[0].value == "many" && userVal.length > 0) {
        for ( var i = 0; i < userVal.length; i++) {
          // TODO this 'if' statement may not be necessary because
          // the value is checked before being pushed into userVal
          if (userVal[i] && regex && !userVal[i].match(regex)) {
            alert("Invalid value '" + userVal[i] + "' for '" + attrValue.label[0].value + "'.\n" + regexTxt);
            return null;
          }
          if (userVal[i] && typeof(userVal[i]) !== 'undefined') {
            attrValue.value.push({
              'value' : userVal[i]
            });
          }
        }
      } else {
        attrValue.value.push({});
        if (attrValue.constraints[0].required[0].value == 'true') {
          alert("Please enter a value for attribute '" + attrValue.label[0].value + "'");
          return null;
        }
      }
    } else {
      // TODO for attributes without a label or not editable - still have to
      // check if value
      // exists, when 'required = true'
      var required = false;
      if (constraints) {
        required = (constraints[0].required[0].value == 'true');
      }
      if (attr == 'dataProductDataFieldIds') {
        // this attribute's value should be an empty value object
        // instead of missing value element
      }
      if (attr == 'dataProductId') {
        // this should already come from getNewDataProductInfo
        // var sn = $("#" + attrPrefix + 'dataProductShortName').val();
        // var ver = $("#" + attrPrefix + 'dataProductVersion').val();
        // attrValue.value[0].value = sn + '.' + ver;
      }
      if (attr == 'dataFieldProductId') {
        // this is already set in newDataFieldInfoCB
      }
      if (attr == 'dataFieldId') {
        // dataFieldId is required=false
        // the service will fill in this value (to keep ID rules in one place)
        // var prodId = (dataObject['dataFieldProductId'])[0].value[0].value;
        // var sdsName = $("#" + attrPrefix + 'dataFieldSdsName').val();
        // attrValue.value[0].value = prodId + '_' + sdsName;
      }
      // if (attr == 'dataProductStartTimeOffset' || attr ==
      // 'dataProductEndTimeOffset') {
      // attrValue.value[0].value = ' ';
      // }
      //      var value = attrValue.value[0].value;
      var value;
      if (attrValue.value) {
        value = attrValue.value[0].value;
      }
      if (required && !value) {
        alert("Missing value for attribute " + attr);
      }
      if (value && regex && !value.match(regex)) {
        alert("Invalid value '" + value + "' for '" + attr + "'.\n" + regexTxt);
      }
    }
  }
  return dataObject;
};

edda.prototype.handleSaveResponse = function(data, textStatus, jqXHR) {
  var response = data.updateResponse;

  var status = response.status[0].value;

  if (status == '1') {
    alert("The data variable was successfully saved.");
    // var respDataField = response.result[0].dataField[0];
    // this.lastSavedField.dataFieldLastModified[0].value[0].value =
    // respDataField.dataFieldLastModified[0].value[0].value;
    // TODO is copying timestamp enough or all the attributes need to be copied
    // ?
    // or rebuild field info ?
    var cbData = {
      dataFields : {
        dataField : response.result[0].dataField
      }
    };
    this.dataFieldsCB(cbData, textStatus, jqXHR);
    this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);
  } else if (status == '2') {
    // alert("Error: Saving was unsuccessful. The data field might have been edited
    // concurrently. Please refresh the page and try again.");
    // TODO should the save be done again with the new timestamp info?

    // or rebuild field info as in status=='1' and change error message from
    // 'refresh the page and try again' to just 'review the data field info and
    // save again'
    var cbData = {
      dataFields : {
        dataField : response.result[0].dataField
      }
    };
    this.dataFieldsCB(cbData, textStatus, jqXHR);
    this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);
    alert("Error: Saving was unsuccessful. The data variable might have been edited concurrently. Please review the data variable information and save again.");
  } else {
    alert("Error: Saving was unsuccessful. Please try again later.");
  }
};

edda.prototype.handlePublishResponse = function(data, textStatus, jqXHR) {
  var response = data.updateResponse;
  var status = Number(response.status[0].value);

  if (!isNaN(status)) {
    var cbData = {
      dataFields : {
        dataField : response.result[0].dataField
      }
    };
    this.dataFieldsCB(cbData, textStatus, jqXHR);

    if (status == 1) {
      var dataFieldState =  extractValues(response.result[0].dataField[0].dataFieldState[0])[0];
      if ('SubmittedPrivate' == dataFieldState || 'SubmittedUpdated' == dataFieldState) {
        this.submittedDataFieldInfoCB(cbData, textStatus, jqXHR);
        alert("A request to publish has been submitted for this variable");
      } else {
        this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);
        if ('Published' == dataFieldState) {
          alert("The data variable was successfully published.");
        } else {
          console.log('handlePublishResponse: Invalid state ' + dataFieldState + ' returned after a successful publish');
        }
      }
    } else if (status > 1) {
      this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);

      var errCode = response.errorCode[0].value;
      if (errCode == 'OUT_OF_SEQUENCE') {
        alert("Error: The request to publish failed. The data variable might have been edited concurrently. Please review the data variable information and try again.");
      } else if (errCode == 'RESCRUB_ERROR' ) {
        alert("Error: The request to publish failed attempting to rescrub cached variables.");
      } else if (errCode == 'PUBLICATION_BASELINE_UNKNOWN' || errCode == 'PUBLISH_ERROR' || errCode == 'SOLR_PUBLISH_ERROR' ) {
        alert("Error: The request to publish failed attempting to update the database. Changed values were saved. Please try again after the database issues have been resolved.");
      } else if (errCode == 'UNITS_VALIDATION_ERROR' || errCode == 'UNITS_VALIDATION_PARSE_ERROR') {
        alert("Error: The request to publish failed attempting to validate the values. Please review the data variable info and try again.");
      } else if (errCode == 'INVALID_DESTINATION_UNITS_ERROR') {
        alert(response.errorMessage[0].value);
      } else {
         alert("Error: The request to publish failed. Please try again later.");
      }
    }
  } else {
    alert("Error: The request to publish failed. Please try again later.");
  }
};

edda.prototype.handleUnpublishResponse = function(data, textStatus, jqXHR) {
  var response = data.updateResponse;
  var status = Number(response.status[0].value);

  if (!isNaN(status)) {
    var cbData = {
      dataFields : {
        dataField : response.result[0].dataField
      }
    };
    this.dataFieldsCB(cbData, textStatus, jqXHR);

    if (status == 1) {
      var dataFieldState =  extractValues(response.result[0].dataField[0].dataFieldState[0])[0];
      if ('SubmittedPrivate' == dataFieldState || 'SubmittedUpdated' == dataFieldState) {
        this.submittedDataFieldInfoCB(cbData, textStatus, jqXHR);
        alert("A request to unpublish has been submitted for this variable");
      } else {
        this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);
        if ('Unpublished' == dataFieldState) {
          alert("The data variable was successfully unpublished.");
        } else {
          console.log('handleUnpublishResponse: Invalid state ' + dataFieldState + ' returned after a successful unpublish');
        }
      }
    } else if (status > 1) {
      this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);

      var errCode = response.errorCode[0].value;
      if (errCode == 'OUT_OF_SEQUENCE') {
        alert("Error: The request to unpublish failed. The data variable might have been edited concurrently. Please review the data variable information and try again.");
      } else if (errCode == 'RESCRUB_ERROR' ) {
        alert("Error: The request to unpublish failed attempting to rescrub cached variables.");
      } else if (errCode == 'PUBLICATION_BASELINE_UNKNOWN' || errCode == 'PUBLISH_ERROR' || errCode == 'SOLR_PUBLISH_ERROR' ) {
        alert("Error: The request to unpublish failed attempting to update the database. Changed values were saved. Please try again after the database issues have been resolved.");
      } else if (errCode == 'UNITS_VALIDATION_ERROR' || errCode == 'UNITS_VALIDATION_PARSE_ERROR') {
        alert("Error: The request to unpublish failed attempting to validate the values. Please review the data variable info and try again.");
      } else if (errCode == 'INVALID_DESTINATION_UNITS_ERROR') {
        alert(response.errorMessage[0].value);
      } else {
         alert("Error: The request to unpublish failed. Please try again later.");
      }
    }
  } else {
    alert("Error: The request to unpublish failed. Please try again later.");
  }
};

edda.prototype.deleteFieldCB = function(obj, dataProdId, dataFieldId) {
  var response = obj.deleteDataFieldResponse;
  var status = Number(response.status[0].value);

  if (!isNaN(status)) {

    if (status == 1) {
      alert("The data variable was successfully deleted.");
      var select = document.getElementById("fieldsListMenu");
      if (select) {
          this.getDataFieldsByProbe(dataProdId);
      }
      this.getDataFields(dataProdId);
    } else if (status > 1) {
      //      this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);

      var errCode = response.errorCode[0].value;
      if (errCode == 'DATA_FIELD_FILE_NOT_FOUND') {
        alert("Error: Unable to find the EDDA variable data file.");
      } else if (errCode == 'DATA_PRODUCT_ID_NOT_FOUND') {
        alert("Error: Unable to find the EDDA data set data file.");
      } else if (errCode == 'DELETE_FROM_ADD_DOC_ERROR') {
        alert("Error: Failed to delete the variable from the AESIR catalog.");
      } else if (errCode == 'SOLR_PUBLISH_ERROR' ) {
        alert("Error: The variable was deleted from the AESIR catalog but the catalog could not be updated.");
      } else if (errCode == 'DATA_PRODUCT_UPDATE_ERROR' ) {
        alert("Error: The variable was deleted from the AESIR catalog but not from the product.");
      } else if (errCode == 'DATA_FIELD_NOT_MOVED' ) {
        alert("Error: The variable was deleted from the AESIR catalog and the product but the variable data file could not be deleted.");
      } else {
         alert("Error: The request to delete failed. Please try again later.");
      }
    }
  } else {
    alert("Error: The request to delete failed. Please try again later.");
  }
};

edda.prototype.deleteDataProductCB = function(obj, dataProdId) {
  var response = obj.deleteDataProductResponse;
  var status = Number(response.status[0].value);

  if (!isNaN(status)) {

    if (status == 1) {
      alert("The data set was successfully deleted.");
      this.dataProductRefreshFlag = true;
      this.getDataProducts();
    } else if (status > 1) {
      var errCode = response.errorCode[0].value;
      if (errCode == 'DATA_PRODUCT_FILE_NOT_FOUND') {
        alert("Error: Unable to find the EDDA data set data file.");
        //      } else if (errCode == 'DELETE_FROM_ADD_DOC_ERROR') {
        //        alert("Error: Failed to delete variables from the AESIR catalog.");
        //      } else if (errCode == 'DATA_FIELDS_NOT_MOVED' ) {
        //        alert("Error: Variables were deleted from the AESIR catalog and the data set but the variable data file(s) could not be deleted.");
      } else if (errCode == 'SOLR_PUBLISH_ERROR' ) {
        alert("Error: Variables were deleted from the AESIR catalog but the catalog could not be updated.");
      } else if (errCode == 'DATA_PRODUCT_NOT_MOVED' ) {
        alert("Error: Variables were deleted from the AESIR catalog and the data set but the data set data file could not be deleted.");
      } else {
         alert("Error: The request to delete failed. Please try again later.");
      }
    }
  } else {
    alert("Error: The request to delete failed. Please try again later.");
  }
};

edda.prototype.handleCancelResponse = function(data, textStatus, jqXHR) {
  var response = data.updateResponse;

  var status = response.status[0].value;

  if (status == '1') {
    alert("The request to publish this variable has been successfully cancelled.");
    var cbData = {
      dataFields : {
        dataField : response.result[0].dataField
      }
    };
    this.dataFieldsCB(cbData, textStatus, jqXHR);
    this.unsubmittedDataFieldInfoCB(cbData, textStatus, jqXHR);
  } else {
    alert("Error: Cancel request failed. Please try again later");
  }
};

//edda.prototype.handleAddResponse = function(data, textStatus, jqXHR) {
//  var response = data.updateResponse;
//
//  var status = response.status[0].value;
//
//  if (status == '1') {
//    alert("The variable was successfully added.");
//  } else if (status == '2') {
//    alert("Error: Add unsuccessful. The data field might have already been added concurrently. Please try again.");
//  } else {
//    alert("Error: Add unsuccessful. Please try again later");
//  }
//  // refresh the data field list - the saved field would have changed state
//  var dataProdId = extractValues(response.result[0].dataField[0].dataFieldProductId[0])[0];
//  this.getDataFields(dataProdId);
//};

edda.prototype.dataFieldClose = function(fieldId) {
};

edda.prototype.addDataProduct = function(navBack) {
  $("#intro").css("display", "none");
  $("#prodBrowse").css("display", "none");
  $("#prodCreate").css("display", "block");
  $("#prodView").css("display", "none");

  if (!navBack) {
    this.navLocations.push([ "Add a new data set", "addDataProduct", true ]);
  } else {
    while (this.navLocations[this.navLocations.length - 1][0] != "Add a new data set") {
      this.navLocations.pop();
    }
  }
  this.updateNavBar();

  //  $("#newProdShortName").val('');
  //  $("#newProdShortNameDiv").hide();
  //  $("#newProdVerId").val('');
  //  $("#newProdVerIdDiv").hide();
  $("#createInfo").hide();

  // make a DIF ID request
  // if dif ID list is empty - AND -
  // either a dif ID request has not been made or the request didn't succeed
  if (this.difIdSrc == null && (this.difIdRequest == null || (this.difIdRequest.status && this.difIdRequest.status != 200))) {
    this.getDifEntryIdList();
  }
};

edda.prototype.getNewDataProductInfoFromCMR = function(sName, verId, provId) {
  $("#createInfo").hide();
  this.showWaitCursor();
  var verIdStr = verId ? ("&versionId=" + verId) : "";
  var provIdStr = verId ? ("&providerId=" + provId) : "";
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getNewDataProductInfo?shortName=" + sName + verIdStr + provIdStr,
    success : this.newDataProductInfoCB,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.getNewDataProductInfo = function(difId, sName, verId) {
  $("#createInfo").hide();
  this.showWaitCursor();
  var shortNmStr = sName ? ("&shortName=" + sName) : "";
  var verIdStr = verId ? ("&versionId=" + verId) : "";
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getNewDataProductInfo?gcmdDifEntryId=" + difId + shortNmStr + verIdStr,
    success : this.newDataProductInfoCB,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.getNewDataProductInfoFromXMLFile = function(path,file) {
  $("#createInfo").hide();
  this.showWaitCursor();
  $.ajax({
    dataType : "json",
      url : edda.SCRIPT_BASE + "getNewDataProductInfo?path=" + encodeURIComponent(path) + "&gcmdDifEntryId=" + encodeURIComponent(file),
    success : this.newDataProductInfoCB,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.newDataProductInfoCB = function(obj) {
  var resp = obj.getNewDataProductInfoResponse;
  var status = resp.status[0].value;
  var dataProduct = resp.result[0].dataProduct[0];

  if (status == '1') {
    var ln = extractValues(dataProduct.dataProductIdentifiers[0].value[0].dataProductLongName[0])[0];
    var sn = extractValues(dataProduct.dataProductIdentifiers[0].value[0].dataProductShortName[0])[0];
    $("#createTitle").text((ln ? ln : "") + " " + (sn ? "(" + sn + ")" : ""));

    // var values = extractLabelTypeValues(dataProduct);
    var productId = extractValues(dataProduct.dataProductId[0])[0];
    var attrPrefix = productId.replace(/\./g, '_');

    $("#attributesEdit").empty();
    $("#createInfo").show();

    var htmlStr = '<table width="100%"><thead><tr><th width="30%"/><th width="70%"/></tr></thead><tbody>';
    for (attr in dataProduct) {
      var attrValue = (dataProduct[attr])[0];
      // attributes without label are not displayed
      if (attrValue.label && attrValue.label[0].value) {
        htmlStr += createEditHtml(attrPrefix, attr, attrValue);
      }
    }
    htmlStr += '</tbody></table>';
    $("#attributesEdit").append(htmlStr);

    // for ( var i = 0; i < values.length; i++) {
    // htmlStr = createEditHtml(values[i]);
    // $("#attributesEdit").append(htmlStr);
    // }

    $("#attributesEdit").append('<p class="actionPanel"><button id="addProduct">Add Data Set</button></p>');

    var self = this;
    $("#addProduct").click(function() {
      self.createNewDataProduct(dataProduct);
    });
  } else if (status == '2') {
    // check for existing product error code and redirect to product viewer
    // page, if reqd
    var errCode = resp.errorCode[0].value;
    if (errCode == 'PRODUCT_ALREADY_EXISTS') {
      var openProd = confirm(resp.errorMessage[0].value + ". Do you want to view that data set?");
      if (openProd) {
        // then go to data product view page
        var prod = resp.result[0].dataProduct[0];
        var prodId = prod.dataProductId[0].value[0].value;
        if (prodId) {
          this.getDataProductInfo(prodId);
        } else {
          alert("Error: Missing Data Set ID");
        }
      }
    } else if (errCode == "SHORTNAME_AND_VERSION_ID_MISSING") {
      alert(resp.errorMessage[0].value);
      $("#newProdShortName").val('');
      $("#newProdShortNameDiv").show();
      $("#newProdVerId").val('');
      $("#newProdVerIdDiv").show();
    } else if (errCode == "SHORTNAME_MISSING") {
      alert(resp.errorMessage[0].value);
      $("#newProdShortName").val('');
      $("#newProdShortNameDiv").show();
    } else if (errCode == "VERSION_ID_MISSING") {
      alert(resp.errorMessage[0].value);
      $("#newProdVerId").val('');
      $("#newProdVerIdDiv").show();
    } else {
      alert(resp.errorMessage[0].value);
    }
  } else {
    alert("Invalid status code " + status + " in getNewDataProductInfo response");
  }
};

edda.prototype.createNewDataProduct = function(dataProductInfo) {
  var productId = extractValues(dataProductInfo.dataProductId[0])[0];
  var attrPrefix = productId.replace(/\./g, '_');
  var saveDataProductInfo = this.createSaveObject(attrPrefix, dataProductInfo);
  if (saveDataProductInfo) {
    var saveObject = {
      dataProduct : saveDataProductInfo
    };
    this.showWaitCursor();
    $.ajax({
      type : "POST",
      data : JSON.stringify(saveObject),
      dataType : "json",
      contentType : "application/json; charset=UTF-8",
      url : edda.SCRIPT_BASE + "createNewDataProduct",
      success : this.newDataProductCB,
      complete: this.showDefaultCursor,      
      context : this
    });
  }
};

edda.prototype.newDataProductCB = function(obj) {
  var response = obj.createNewDataProductResponse;

  var status = response.status[0].value;

  if (status == '1') {
    alert("The data set was successfully added.");
    // since a new product has been added successfully,
    // set the data product table refresh flag
    this.dataProductRefreshFlag = true;
    // then go to data product view page
    var prod = response.result[0].dataProduct[0];
    var prodId = prod.dataProductId[0].value[0].value;
    if (prodId) {
      this.getDataProductInfo(prodId);
    } else {
      alert("Error: Missing Data Set ID");
    }
  } else if (status == '2') {
    alert(response.errorMessage[0].value);
  } else {
    alert("Invalid status code " + status + " in createNewDataProduct response");
  }
};

edda.prototype.getNewDataFieldInfo = function(prodId, fieldId) {
  $("#newField").empty();
  var qStr = "?";
  if (prodId) {
    qStr += "dataProductId=" + prodId + "&";
  }
  if (fieldId) {
    qStr += "dataFieldId=" + fieldId;
  }
  this.showWaitCursor();
  $.ajax({
    type : "GET",
    url : edda.SCRIPT_BASE + "getNewDataFieldInfo" + qStr,
    success : function(dataObj) {
      this.newDataFieldInfoCB(dataObj, prodId);
    },
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.newDataFieldInfoCB = function(obj, prodId) {
  var response = obj.getNewDataFieldInfoResponse;

  var dataField = response.result[0].dataField[0];
  // a dummy field ID
  var fieldId = "newFieldId";

  // $("#addNewDataField").attr('disabled', 'disabled'); // hide();

  $("#newField").html("<div class=\"editorLineItem\" id=\"" + fieldId + "\"></div>");

  // set dataFieldProductId in dataField
  dataField.dataFieldProductId[0].value[0].value = prodId;

  // since this is a new field, there is no field ID yet
  // so the dummy field ID is used as the prefix to the editable
  // HTML element IDs
  this.showDataFieldInfo(fieldId, dataField);

  $("#" + fieldId).append('<p class="actionPanel"><button id="newFieldAdd">Add Data Variable</button>&nbsp;&nbsp;<button id="newFieldCancel">Cancel</button></p>');
  $("#newField").show();

  $("#newFieldAdd").click(this, function(e) {
    e.data.createNewDataField(fieldId, dataField);
  });

  $("#newFieldCancel").click(this, function(e) {
    $("#newField").empty();
    $("#newField").hide();
    // $("#addNewDataField").removeAttr('disabled'); // show();
  });
};

edda.prototype.createNewDataField = function(dataFieldId, dataFieldInfo) {
  var saveDataFieldInfo = this.createSaveObject(dataFieldId, dataFieldInfo);
  if (saveDataFieldInfo) {
    var saveObject = {
      "dataField" : saveDataFieldInfo
    };
    this.showWaitCursor();
    $.ajax({
      type : "POST",
      data : JSON.stringify(saveObject),
      dataType : "json",
      contentType : "application/json; charset=UTF-8",
      url : edda.SCRIPT_BASE + "createNewDataField",
      success : this.newDataFieldCB,
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

edda.prototype.newDataFieldCB = function(obj) {
  var response = obj.createNewDataFieldResponse;

  var status = response.status[0].value;

  if (status == '1') {
    alert("The data variable was successfully added.");
    $("#newField").empty();
    $("#newField").hide();
    //$("#addNewDataField").removeAttr('disabled'); // show();
    // refresh the data field list - the added field should show up
    var dataProdId = extractValues(response.result[0].dataField[0].dataFieldProductId[0])[0];
    this.getDataFields(dataProdId);
  } else {
    alert(response.errorMessage[0].value);
  }
};

edda.prototype.sendFeedback = function(event, self) {
  var headerStr = "%0D%0D%0D------------------- Portal Data (used by the EDDA team) -------------------";
  //var hostMatchPattern = /^s4ptu-ts1/i;
  //var mailtoURL = hostMatchPattern.test(window.location.host) ? "mailto:ed.seiler@nasa.gov" : "mailto:chocka.chidambaram@nasa.gov";
  var mailtoURL = "mailto:gsfc-agiovanni-dev-disc@lists.nasa.gov";
  mailtoURL += "?subject=EDDA%20Feedback&body=" + headerStr;
  mailtoURL += "%0D%0DPortal%20URL%3A%20%20%0D";
  mailtoURL += encodeURIComponent(window.location.href);
  // attach user agent info
  mailtoURL += "%0D%0DUser%20Agent%3A%20%20%0D";
  mailtoURL += encodeURIComponent(navigator.userAgent);

  // open mail window
  var mailWin = window.open(mailtoURL, "agMailWindow", 'location=no,menubar=0,toolbar=0,status=0,titlebar=0,top=0,left=5000,height=1,width=1');
  // close the browser mail window since it will spawn the mail client
  mailWin.close();
};

edda.prototype.showWaitCursor = function() {
  if (this.pendingAjaxCalls == 0) {
    $("#mask").css('display', 'block');
  }
  this.pendingAjaxCalls++;
};

edda.prototype.showDefaultCursor = function() {
  this.pendingAjaxCalls--;
  if (this.pendingAjaxCalls == 0) {
    $("#mask").css('display', 'none');
  }
};

edda.prototype.getVariableStatus = function() {
  // open variable status window
  window.open(edda.SCRIPT_BASE+'getDataFieldsStatus', 'variableStatusWindow');
};

edda.prototype.updateDataProductInfo = function(dataProductInfo, rePubFlag, comment) {
  var productId = extractValues(dataProductInfo.dataProductId[0])[0];
  var attrPrefix = productId.replace(/\./g, '_');
  var saveDataProductInfo = this.createSaveObject(attrPrefix, dataProductInfo);
  if (saveDataProductInfo) {
    var saveObject = {
      "dataProduct" : saveDataProductInfo
    };
    var urlString = "updateDataProductInfo";
    if (rePubFlag) {
      var commentStr = comment ? "&comment="+encodeURIComponent(comment) : '';
      urlString += "?repub=1" + commentStr;
    }
    this.showWaitCursor();
    $.ajax({
      type : "POST",
      data : JSON.stringify(saveObject),
      dataType : "json",
      contentType : "application/json; charset=UTF-8",
      url : edda.SCRIPT_BASE + urlString,
      success : this.updateDataProductInfoCB,
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

edda.prototype.updateDataProductInfoCB = function(obj) {
  var response = obj.updateDataProductInfoResponse;

  var status = response.status[0].value;
  var prod = response.result[0].dataProduct[0];
  var prodId = prod.dataProductId[0].value[0].value;

  if (status == '1') {
    alert("The data set was successfully updated.");
    this.getUpdatedDataProductInfo(prodId);
  } else if (status == '2') {
    this.getUpdatedDataProductInfo(prodId);
    alert("Error: Saving was unsuccessful. The data set might have been edited concurrently. Please review the data set information and save again.");
  } else {
    alert("Error: Saving was unsuccessful. Please try again later.");
  }
};

edda.prototype.getUpdatedDataProductInfo = function(dataProdId) {

  this.showWaitCursor();
  $.ajax({
    dataType : "json",
    url : edda.SCRIPT_BASE + "getDataProductInfo?dataProductId=" + dataProdId,
    success : this.getUpdatedDataProductInfoCB,
    complete: this.showDefaultCursor,
    context : this
  });
};

edda.prototype.getUpdatedDataProductInfoCB = function(data, textStatus, jqXHR) {
  var dataProductInfo = data.dataProducts.dataProduct[0];
  var productId = extractValues(dataProductInfo.dataProductId[0])[0];
  var attrPrefix = productId.replace(/\./g, '_');

  var htmlStr = '';

  $("#attributes").empty();

  var htmlStr = '<table width="100%"><thead><tr><th width="30%"/><th width="70%"/></tr></thead><tbody>';
  for (key in dataProductInfo) {
    var attrValue = (dataProductInfo[key])[0];
    // attributes without label are not displayed
    if (attrValue.label && attrValue.label[0].value) {
      htmlStr += createEditHtml(attrPrefix, key, attrValue);
    }
  }
  htmlStr += '</tbody></table>'

  var buttonId = attrPrefix + "_update";  
  htmlStr += '<p class="actionPanel"><button id="' + buttonId + '">Save</button></p>';
  $("#attributes").append(htmlStr);

  $("#" + buttonId).click(this, function(e) {
    e.data.updateDataProductInfo(dataProductInfo);
  });  
}

edda.prototype.deleteDataProduct = function(dataProductInfo, comment) {
  var productId = extractValues(dataProductInfo.dataProductId[0])[0];
  var attrPrefix = productId.replace(/\./g, '_');
  var qStr = "?";
  if (productId) {
      qStr += "dataProductId=" + productId;
    if (comment) {
      qStr += "&comment="+encodeURIComponent(comment);
    }
    this.showWaitCursor();
    $.ajax({
      type : "GET",
      url : edda.SCRIPT_BASE + "deleteDataProduct" + qStr,
      success : function(dataObj) {
        this.deleteDataProductCB(dataObj, productId);
      },
      complete: this.showDefaultCursor,
      context : this
    });
  }
};

function displayHelp(url) {
  var w = window.open(url, 'helpWindow');
  w.focus();
  return false;
};

function createEditHtml(id, attrKey, attrValue, leftPadding) {
  var key = id + attrKey;
  if (!leftPadding)
    leftPadding = 1;
  var editable = true;
  var editStr = '';
  var cons = attrValue.constraints;
  if (cons && cons[0].editable[0].value == 'false') {
    editable = false;
    editStr = ' disabled="disabled"';
  }
  var reqStr = '';
  if (cons && cons[0].required[0].value == 'true') {
    reqStr = '<span class="reqd">*</span>';
  }

  var helpUrl = 'EDDA_help.html#' + attrKey;
  var htmlStr = '<tr><td style="padding-top:1em;padding-left:' + leftPadding + 'em">'
    + '<b>'
    + '<a href="js.html" onclick="return displayHelp(\'' + helpUrl + '\')">'
    + attrValue.label[0].value 
    + '</a>'
    + reqStr + '</b>'
    + '</td>';

  //TEMP FIX until a color map type is created
  if (attrKey=='dataFieldSld') {
    for ( var i = 0; i < attrValue.value.length; i++) {
      if (i > 0) {
        htmlStr += '<tr><td></td>';
      }
      if (!attrValue.value[0].value) {
        htmlStr += '<td></td></tr>';
        continue;
      }
      htmlStr += '<td style="padding-top:1em;">';
      htmlStr += '<input type="hidden" name="' + key + '" value="' + attrValue.value[i].value + '"/>';
      var sldInfo = getSldInfoByName(attrValue.value[i].value);
      if (sldInfo) {
        htmlStr += '<span class="colorPaletteInfo">';
        htmlStr += sldInfo.min ? '<label class="spacedCtrl">' + sldInfo.min + '</label>' : ' '; 
        htmlStr += '<img class="spacedCtrl" src="' + edda.sldMetaDataURLPrefix + sldInfo.thumbnail + '"/>';
        htmlStr += sldInfo.max ? '<label class="spacedCtrl">' + sldInfo.max + '</label>' : ' '; 
        htmlStr += '<label class="spacedCtrl">' + sldInfo.title + '</label>'; 
        htmlStr += '</span>';
      } else {
        htmlStr += '<span class="colorPaletteInfo">Unknown SLD ' + attrValue.value[i].value + '</span>';
      }
      htmlStr += '<button class="spacedCtrl" id="'+id+'DelPal'+i+'">Delete</button>';
      htmlStr += '</td></tr>';
    }
    htmlStr += '<tr><td></td><td style="padding-top:1em;">'
      + '<button id="' + id + 'AddPal">Add ' + attrValue.label[0].value + '</button></td></tr>';
  } else {
    switch (attrValue.type[0].value) {// TODO editable
    case 'list':
      htmlStr += '<td style="padding-top:1em;">';
      var multiple = attrValue.multiplicity[0].value == 'many';
      if (editable) {
        var mulStr = multiple ? ' multiple="multiple"' : '';
        htmlStr += '<select id="' + key + '" value="' + attrValue.value[0].value + '"' + mulStr + editStr + '>';
        if (!multiple) {
          htmlStr += '<option value=""></option>';
        }
        if (attrValue.valids[0].valid != null) {
          for ( var i = 0; i < attrValue.valids[0].valid.length; i++) {
            var selStr = '';
            for ( var j = 0; j < attrValue.value.length; j++) {
              if (attrValue.value[j].value == attrValue.valids[0].valid[i].value) {
                selStr = 'selected="selected"';
                break;
              }
            }
            htmlStr += '<option value="' + attrValue.valids[0].valid[i].value + '" ' + selStr + '>' + attrValue.valids[0].valid[i].value + '</option>';
          }
        }
        htmlStr += '</select>';
      } else {
        for ( var i = 0; i < attrValue.value.length - 1; i++) {
          htmlStr += (attrValue.value[i].value ? attrValue.value[i].value : '') + ', ';
        }
        htmlStr += (attrValue.value[i].value ? attrValue.value[i].value : '');
      }
      htmlStr += '</td></tr>';
      break;
    case 'url':
    case 'number':
    case 'datetime':
    case 'text':
      var exVal = '';
      if (attrValue.example) {
        exVal = '<br/><span class="exampleText">e.g.: ' + attrValue.example[0].value + '</span>';
      }
      if (attrValue.multiplicity[0].value == 'one') {
        if (editable) {
          htmlStr += '<td style="padding-top:1em;"><input id="' + key + '" type="text" size="100" value="'
              + (attrValue.value[0].value ? attrValue.value[0].value : '') + '"' + editStr + '></input>' + exVal + '</td>';
        } else {
          htmlStr += '<td style="padding-top:1em;"><label id="' + key + '">' + (attrValue.value[0].value ? attrValue.value[0].value : '') + '</label></td>';
        }
      } else if (attrValue.multiplicity[0].value == 'many') {
        for ( var i = 0; i < attrValue.value.length; i++) {
          if (i > 0) {
            htmlStr += '<tr><td></td>';
          }
          if (editable) {
            htmlStr += '<td style="padding-top:1em;"><input name="' + key + '" type="text" size="50" value="'
                + (attrValue.value[i].value ? attrValue.value[i].value : '') + '"' + editStr + '></input>';
            if (i > 0) {
              htmlStr += '<button class="spacedCtrl" onclick="removeRow(this);">Remove</button>' + '</td></tr>';
            } else {
              htmlStr += exVal + '</td></tr>';
            }
          } else {
            htmlStr += '<td style="padding-top:1em;"><label name="' + key + '">' + (attrValue.value[i].value ? attrValue.value[i].value : '') + '</label></td>';
          }
        }
        if (editable) {
          htmlStr += '<tr><td></td><td style="padding-top:1em;"><button onclick="addRow(this);">Add ' + attrValue.label[0].value + '</button></td></tr>';
        }
        // TODO add/remove buttons don't work as expected when removing/adding
        // last item in the multi value text group
      }
      break;
    case 'boolean':
      if (editable) {
        htmlStr += '<td style="padding-top:1em;"><input name="' + key + '" type="radio" value="true" '
          + (attrValue.value[0].value == 'true' ? 'checked="checked"' : '')
          + '/>True'
          + '<input name="' + key + '" type="radio" value="false" '
          + (attrValue.value[0].value == 'false' ? 'checked="checked"' : '')
          + '/>False'
          + '</td>';
      } else {
        htmlStr += '<td style="padding-top:1em;"><label id="' + key + '">' + (attrValue.value[0].value ? attrValue.value[0].value : '') + '</label></td>';
      }
      htmlStr += '</tr>';
      break;
    case 'container':
      htmlStr += '<td style="padding-top:1em;"></td></tr>';
      var subset = attrValue.value[0];
      for (element in subset) {
        value = (subset[element])[0];
        // attributes without label are not displayed for edit
        if (attrValue.label && value.label[0].value) {
          htmlStr += createEditHtml(key, element, value, leftPadding + 2);
        }
      }
      break;
    default:
      htmlStr += '<td style="padding-top:1em;"></td></tr>';
      console.log("Invalid type : " + attrValue.type[0].value + " for attribute label : " + attrValue.label[0].value
          + " in data variable : " + id);
      break;
    }
  } // TEMP FIX until a color map type is created
  return htmlStr;
};

function removeRow(button) {
  var row = button.parentNode.parentNode;
  var tbody = row.parentNode;
  tbody.removeChild(row);
};

function addRow(button) {
  var currentRow = button.parentNode.parentNode;
  var lastDataRow = currentRow.previousSibling;
  var tbody = currentRow.parentNode;

  var newRow = document.createElement("tr");
  newRow.appendChild(document.createElement("td"));
  var cell = lastDataRow.childNodes[1].cloneNode(true);
  cell.childNodes[0].value = '';
  if (cell.childNodes.length == 3) {
    cell.removeChild(cell.childNodes[2]); // remove the example text
    cell.removeChild(cell.childNodes[1]); // remove the <br> before the example text
    // append the 'remove' button
    cell.innerHTML += '<button class="spacedCtrl" onclick="removeRow(this);">Remove</button>';
  }
  newRow.appendChild(cell);
  tbody.insertBefore(newRow, currentRow);
};

function getSldInfoByFileName(name) {
  for (var i=0; i<edda.sldMetaData.length; i++) {
    if (name == edda.sldMetaData[i].file) 
      return edda.sldMetaData[i];
  }
  return null;
};

function getSldInfoByName(name) {
  for (var i=0; i<edda.sldMetaData.length; i++) {
    if (name == edda.sldMetaData[i].name) 
      return edda.sldMetaData[i];
  }
  return null;
};

var tempFieldId = null;
var tempAttrKey = null;
function customizeColorMapCB(obj) {
  var resp = obj.customizeColorMap;
  if (resp.code == 1) {
    var newSldInfo = resp.result;
    edda.sldMetaData[edda.sldMetaData.length] = newSldInfo;
    addColorMapToSelection(tempFieldId, tempAttrKey, newSldInfo.name);
  } else if (resp.code == 2) {
      var selVal = $("#paletteList").val();
      var sldInfo = getSldInfoByName(selVal);
      if (confirm("A SLD with that name exists already. Do you wish to overwrite it ?")) {
        $.ajax({
          dataType : "json",
          url : edda.SCRIPT_BASE+'customizeColorMap?srcName=' + sldInfo.name + '&destName=' + $("#paletteName").val() 
            + '&min=' + $("#paletteMin").val() + '&max=' + $("#paletteMax").val() + '&overwrite=1',
          success : customizeColorMapCB,
        });
      }
  } else {
    alert(resp.message);
  }
};

function addColorMapToSelection(fieldId, attrKey, value) {
  //alert("Add " + value + " to color map selection input " + fieldId + attrKey);
  var inputs = $("input[name="+fieldId+attrKey+"]");
  var editExisting = false;
  var currentCell = null;

  for (var i=0; i<inputs.length; i++) {
    if (inputs[i].value == value) {
      editExisting = true;
      currentCell = inputs[i].parentNode;
    }
  }

  var addButtonRow = $("#"+fieldId+" table tbody tr td button#"+fieldId+"AddPal").parent().parent();

  if (editExisting) {
    currentCell.childNodes[0].value = value;
    var htmlStr = '';
    var sldInfo = getSldInfoByName(value);
    if (sldInfo) {
      htmlStr += sldInfo.min ? '<label class="spacedCtrl">' + sldInfo.min + '</label>' : ' '; 
      htmlStr += '<img class="spacedCtrl" src="' + edda.sldMetaDataURLPrefix + sldInfo.thumbnail + '"/>';
      htmlStr += sldInfo.max ? '<label class="spacedCtrl">' + sldInfo.max + '</label>' : ' '; 
      htmlStr += '<label class="spacedCtrl">' + sldInfo.title + '</label>'; 
    } else {
      htmlStr += 'Unknown SLD ' + value;
    }
    currentCell.childNodes[1].innerHTML = htmlStr;
  } else {
    var newRow = document.createElement("tr");
    newRow.appendChild(document.createElement("td"));
    var cell = document.createElement("td");
    cell.setAttribute("style", "padding-top:1em;");
    var htmlStr = '<input type="hidden" name="' + fieldId + attrKey + '" value="' + value + '"/>';
    var sldInfo = getSldInfoByName(value);
    if (sldInfo) {
      htmlStr += '<span class="colorPaletteInfo">';
      htmlStr += sldInfo.min ? '<label class="spacedCtrl">' + sldInfo.min + '</label>' : ' '; 
      htmlStr += '<img class="spacedCtrl" src="' + edda.sldMetaDataURLPrefix + sldInfo.thumbnail + '"/>';
      htmlStr += sldInfo.max ? '<label class="spacedCtrl">' + sldInfo.max + '</label>' : ' '; 
      htmlStr += '<label class="spacedCtrl">' + sldInfo.title + '</label>'; 
      htmlStr += '</span>';
    } else {
      htmlStr += '<span class="colorPaletteInfo">Unknown SLD ' + value + '</span>';
    }
    htmlStr += '<button class="spacedCtrl" id="'+fieldId+'DelPal'+inputs.length+'">Delete</button>';
    cell.innerHTML = htmlStr;
    newRow.appendChild(cell);
    $(newRow).insertBefore(addButtonRow);
    // set listeners for edit/delete buttons
    $('#'+fieldId+'DelPal'+inputs.length).click( getDeleteFn(fieldId, attrKey, value) );
  }
};

function showPaletteDialog(fieldId, attrKey, paletteList) {
  if (!edda.colorPaletteDlg) {
    edda.colorPaletteDlg = $("#colorPaletteDlg").dialog({
      title : 'Add Color Palette',
      modal : true,
      width: 'auto',
      height: 'auto',
    });

    $("#palDlgCancel").click(function() {
      $("#colorPaletteDlg").dialog("close");
    });
  } else {
    edda.colorPaletteDlg.dialog("open");
  }

  // unbind and re-bind click handler for the OK button with the right data
  $("#palDlgOk").unbind("click");
  $("#palDlgOk").click(function() {
    $("#colorPaletteDlg").dialog("close");
    var selVal = $("#paletteList").val();
    addColorMapToSelection(fieldId, attrKey, selVal);
  });

  // rebuild the SLD color palette list
  $("#paletteList").empty();
  if (paletteList instanceof Array) {
    $("#paletteList").attr('size', paletteList.length);
    // sort the paletteList (first dynamic SLDs followed by static, both in ascending order of title)
    var paletteInfo = [];
    for (var i=0; i<paletteList.length; i++) {
      var sldInfo = getSldInfoByName(paletteList[i].value);
      if (sldInfo)
        paletteInfo.push(sldInfo);
      else
        paletteInfo.push(paletteList[i].value);
    }
    paletteInfo.sort(function(x,y) {
      if ((x.min==null && y.min==null) || (x.min!=null && y.min!=null)) {
        var left = x.title ? x.title : 'Unknown';
        var right = y.title ? y.title : 'Unknown';
        return left.localeCompare(right);
      } else if (x.min==null && y.min!=null) {
        return -1;
      } else if (x.min!=null && y.min==null) {
        return 1;
      }
    });
    // create entries for each SLD
    for (var i=0; i<paletteInfo.length; i++) {
      var sldInfo = paletteInfo[i];
      var htmlStr = '';
      if (!(sldInfo instanceof String)) {
        htmlStr = '<span>';
        htmlStr += sldInfo.min ? '<label class="spacedCtrl">' + sldInfo.min + '</label>' : ' '; 
        htmlStr += '<img class="spacedCtrl" src="' + edda.sldMetaDataURLPrefix + sldInfo.thumbnail + '"/>';
        htmlStr += sldInfo.max ? '<label class="spacedCtrl">' + sldInfo.max + '</label>' : ' '; 
        htmlStr += '<label class="spacedCtrl">' + sldInfo.title + '</label>'; 
        htmlStr += '</span>';
      } else {
        htmlStr += '<span>Unknown SLD ' + sldInfo + '</span>';
      }
      $("#paletteList").append($('<option/>').val(sldInfo.name).html(htmlStr));
    }
    $("#paletteList").removeAttr('disabled');
    $("#paletteList").val(paletteInfo[0].name);
  } else {
    $("#paletteList").attr('size', 2);
    var sldInfo = getSldInfoByName(paletteList);  
    var htmlStr = '';
    if (sldInfo) {
      htmlStr = '<span>';
      htmlStr += sldInfo.min ? '<label class="spacedCtrl">' + sldInfo.min + '</label>' : ' '; 
      htmlStr += '<img class="spacedCtrl" src="' + edda.sldMetaDataURLPrefix + sldInfo.thumbnail + '"/>';
      htmlStr += sldInfo.max ? '<label class="spacedCtrl">' + sldInfo.max + '</label>' : ' '; 
      htmlStr += '<label class="spacedCtrl">' + sldInfo.title + '</label>'; 
      htmlStr += '</span>';
    } else {
      htmlStr += '<span>Unknown SLD ' + paletteList + '</span>';
    }
    $("#paletteList").append($('<option/>').val(paletteList).html(htmlStr));
    $("#paletteList").attr('disabled', 'disabled');
    $("#paletteList").val(paletteList);
  }
  $("#paletteList").change();
};

function createViewHtml(data, noLabelAnchor) {
  var htmlStr = "<div class='viewerLineItem'><b>";
  if (!noLabelAnchor) {
    htmlStr += "<a target='helpWindow' href='EDDA_help.html#" + data.key + "'>" + data.label + "</a>";
  } else {
    htmlStr += data.label;
  }
  htmlStr += "</b> : ";
  if (isString(data.value[0])) {
    if (data.type == 'url') {
      for (var i=0; i<data.value.length; i++) {
        htmlStr += "<a target='_blank' href='" + data.value[i] + "'>" + data.value[i] + "</a>"; 
      }
    } else {
      htmlStr += data.value.join(', ');
    }
    htmlStr += "</div>";
  } else {
    htmlStr += "<br>";
    for ( var i = 0; i < data.value.length; i++) {
      var tmp = createViewHtml(data.value[i], true);
      htmlStr += tmp;
    }
    htmlStr += "</div>";
  }
  return htmlStr;
};

function extractLabelTypeValues(attributes) {
  var result = [];
  for (key in attributes) {
    var attr = (attributes[key])[0];

    var label;
    if (!attr.label) {
      label = "[no label element for attribute " + key + "]";
    } else if (!attr.label[0] || !attr.label[0].value) {
      // label = "[empty label for attribute " + key + "]";
      // empty label denotes items that don't have to be displayed
      continue;
    } else {
      label = attr.label[0].value;
    }

    var type;
    if (!attr.type) {
      type = "[no type element for attribute " + key + "]";
    } else if (!attr.type[0] || !attr.type[0].value) {
      type = "[empty type for attribute " + key + "]";
    } else {
      type = attr.type[0].value;
    }

    var value = extractValues(attr);

    if (!value && type=='container' /* && !isString(attr.value[0]) */) {
      result.push({
        "key" : key,
        "label" : label,
        "type" : type,
        "value" : extractLabelTypeValues(attr.value[0])
      });
    }
    if (value && type != 'container') {
      result.push({
        "key" : key,
        "label" : label,
        "type" : type,
        "value" : value
      });
    }
  }
  return result;
};

function extractValues(obj) {
  if (obj.type[0] && obj.value) {
    switch (obj.type[0].value) {
    case 'list':
    case 'text':
    case 'url':
    case 'datetime':
    case 'number':
    case 'boolean':
      var values = [];
      if (obj.multiplicity[0]) {
        var tmp;
        if ("one" == obj.multiplicity[0].value) {
          tmp = (obj.value[0] && obj.value[0].value) ? obj.value[0].value : '';
          values.push(tmp);
        } else if ("many" == obj.multiplicity[0].value) {
          for ( var j = 0; j < obj.value.length; j++) {
            tmp = (obj.value[j] && obj.value[j].value) ? obj.value[j].value : '';
            values.push(tmp);
          }
        }
      } else {
        console("Invalid JSON: missing multiplicity. Obj: " + obj);
      }
      return values;
    default:
      return null;
    }
  }
  return null;
};

function isString(s) {
  return typeof (s) === 'string' || s instanceof String;
};
