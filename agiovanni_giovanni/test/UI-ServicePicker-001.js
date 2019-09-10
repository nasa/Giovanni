/**
 * @this
 * UI-ServicePicker-001
 * @Richard Strub, refactored @Andrey Zasorin
 */

describe("UI-ServicePicker-001", function() {

  var log;
  var srv;
  var setup = { numberOfServices: 22 };

    
  // This function is what you want beforeAll() to run 
  beforeAll(function(done){

    // This expects the login event to be available immediately
    log = login.loginEvent 

    // This is saying: wait 5 secs 
    // then see if the servicePicker exists
    // then tell Jasmine you are done with beforeAll() 
    setTimeout(function(){
      srv = session.dataSelector.servicePicker;
      done();
    }, 5000);

  // we are not using the optional timeout for BeforeAll() 
  });     

  it("There exists a 'Select Plot' component", function () {
    srv = session.dataSelector.servicePicker;
    expect(srv).not.toBe(null);
  });

  it("Select Plot component has " + setup["numberOfServices"] + " of Services", function () {
    var servicesArray = new Array();
    var catalog = srv.dataSourceURL();
    servicesArray = srv.loadFromCatalog(catalog); 
    expect(servicesArray.length).toBe(setup["numberOfServices"]);
  });

  it("Select Plot component has a legend = 'Select Plot'", function () {  
    var legends = document.getElementsByTagName('legend');
    expect(legends[0].innerHTML).toBe("Select Plot");
  });

  it("Select Plot component has 5 group controls", function(){
    var groupControls = $('.groupControl');
    expect(groupControls.length).toEqual(5);
  });

  it("Expect group control names to be rendered", function(){
    var groupControlsSpans = $('.groupControl .groupLabel > span:first-child');
    var controlsToExpect = ['Maps: ', 'Comparisons: ', 'Vertical: ', 'Time Series: ', 'Miscellaneous: '];
    var controlsFromUI = [];
    groupControlsSpans.each(function(){
      controlsFromUI.push($(this).text());
    });
    expect(controlsFromUI).toEqual(controlsToExpect);

  });

  it("Expect TmAvMaps to be selected by default", function (){
    expect($('input#maps').is(':checked')).toBeTruthy();
    expect($('#service_maps\\+TmAvMp').is(':checked')).toBeTruthy();
  });

  it("Expect mapsPanel to have 6 options", function(){
    var mapPanel = $('#mapsPanel .row');
    expect(mapPanel.length).toEqual(6);
  });

  it("Expect comparisonPanel to have 5 options", function(){
    var comparisonPanel = $('#comparisonPanel .row');
    expect(comparisonPanel.length).toEqual(5);
  });

  it("Expect verticalPanel to have 4 options", function(){
    var verticalPanel = $('#verticalPanel .row');
    expect(verticalPanel.length).toEqual(4);
  });

  it("Expect timeseriesPanel to have 5 options", function(){
    var timeseriesPanel = $('#timeseriesPanel .row');
    expect(timeseriesPanel.length).toEqual(5);
  });

  it("Expect MiscPanel to have 2 options", function(){
    var MiscPanel = $('#MiscPanel .row');
    expect(MiscPanel.length).toEqual(2);
  });

  it("Expect Map, Correlations to be selected for Comparisons panel by default", function (){
    expect($('#service_comparison\\+CoMp').is(':checked')).toBeTruthy();
  });

  it("Expect Area-Averaged to be selected for Time Series panel by default", function (){
    expect($('#service_timeseries\\+ArAvTs').is(':checked')).toBeTruthy();
  });

  it("Expect Cross Section, Latitude-Pressure to be selected for Vertical panel by default", function (){
    expect($('#service_vertical\\+CrLt').is(':checked')).toBeTruthy();
  });

  it("Expect Zonal Mean to be selected for Miscellaneous panel by default", function (){
    expect($('#service_Misc\\+ZnMn').is(':checked')).toBeTruthy();
  });

  it("Expect Map, Correlations to be selected for Comparisons panel by default", function (){
		expect($('#service_comparison\\+CoMp').is(':checked')).toBeTruthy();
	});

  it("Expect Area-Averaged to be selected for Time Series panel by default", function (){
		expect($('#service_timeseries\\+ArAvTs').is(':checked')).toBeTruthy();
	});

  it("Expect Cross Section, Latitude-Pressure to be selected for Vertical panel by default", function (){
		expect($('#service_vertical\\+CrLt').is(':checked')).toBeTruthy();
	});

  it("Expect Zonal Mean to be selected for Miscellaneous panel by default", function (){
		expect($('#service_Misc\\+ZnMn').is(':checked')).toBeTruthy();
	});

});

