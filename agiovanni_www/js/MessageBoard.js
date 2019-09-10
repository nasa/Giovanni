//$Id: MessageBoard.js,v 1.28 2015/02/03 18:41:42 kbryant Exp $ 
//-@@@ Giovanni, Version $Name:  $
/*****************************************
 * Class Name: MessageBoard
 * Author: Xiaopeng Hu
 *         (301) 614-5794
 * 
 *****************************************/

/*
 * Create MessageBoard in giovanni.ui namespace
 */
giovanni.namespace("ui");

/********************************************************************************
 * MessageBoard is a user interface for polling a DISC rss feed for news items relevant to
 * a particular portal. UI caches web-page (does not re-retrieve a feed 
 * unless it has changed), and does not re-create GUI items for the news that
 * are already on the screen. Removes deleted news from the screen as-needed.
 ********************************************************************************/
 /****************************
 ** @new(mbId, url, pInterval, portal) -- MessageBoard constructor:
 **		Arguments:  
 **			mbId -- a div id for message board
 **			url  -- a rss proxy url
 **			pInterval -- a polling interval, denominated by minutes
 **			portal -- indicates a portal name like "GIOVANNI"
 ** @return {giovanni.ui.MessageBoard} object
 ** @example:
 **		var msgBoard = giovanni.ui.MessageBoard('messageBoardId', 
 **											'http://s4ptu-ts2.ecs.nasa.gov/daac-bin/getNewsItem.pl',
 **                                         5,
 **                                         'giovanni');
 **	@author: Xiaopeng Hu
 *****************************/
giovanni.ui.MessageBoard = function(mbId, url, pInterval, portal) {
        // container id
        this.id = this.rssContainerId = mbId ? mbId : 'agMessageBoard';
        var defaultAlertsUrl = "https://disc.gsfc.nasa.gov/uui/api/alerts";
        // build the URL out of the origion, sandbox, and UUI alerts path
        this.rssUrl= url ? url : defaultAlertsUrl;
	this.pollingInterval= pInterval ? (pInterval * 60 * 1000) : 600000;  // default to 10 minutes
	this.portal = portal ? portal : "GIOVANNI";
	this.queryString = "?portal="+this.portal;
        

	//Class data members
	this.rssDiv;
	this.rssBanner;
	this.newsDivs={};
	this.parsedItems=new Array();
	this.bannerButton; 
	this.maxAttempts=3;
	this.attemptsAfterFailure=0;
	this.pollId; 
	
	this.container = document.getElementById(this.rssContainerId);
	
	// XML/Parsed object keys
	this.subjectKey = 'dc:subject';
	this.dateKey = 'dc:date';

	this.render(); 
}

/*********************************************************
**	this function sets up all html <div> elements and panel for populating news item
	Name: render()
	@parameter{}: none
	@return{void}
	@example: 
		this.render() 
	@Author: X. Hu
**********************************************************/
giovanni.ui.MessageBoard.prototype.render = function () {

	var elem = YAHOO.util.Dom.get(this.rssContainerId); 
	// content
	this.rssDiv = document.createElement('div');
	this.rssDiv.id = "messageLineDiv";
	this.rssDiv.innerHTML = "&nbsp;";
	elem.appendChild(this.rssDiv);

	// to create a message board panel
	this.messagePanelDiv = document.createElement('div');
	this.messagePanelDiv.id = "messagePanel";
	elem.appendChild(this.messagePanelDiv);
	try {
		this.newsPanel = new YAHOO.widget.Panel("messagePanel", {
			resize: true,
			constraintoviewport: true, 
			close: true,
			visible: false,
			draggable: true,
			zindex: 10000, // because map z-indices are regularly in the 100's
			autofillheight: "body"
		});

		this.newsPanel.setHeader(this.portal + "&nbsp;Latest News");
		this.newsPanel.setBody("Loading latest news ..."); 
		this.newsPanel.render();

		YAHOO.util.Event.addListener('headlineMore', "click", this.newsPanel.show, this.newsPanel, true);

	} catch (e) {
		//alert("Error: " + e.message);
	}	
	
	this.startPolling (this.pollingInterval);
};

/**********************************************************************
	This function uses XHRDataSource to call a RSS proxy to extract RSS news from DISC at an interval specified by
	'pollInterval'
	@parameter{pollInterval} -- polInterval: an integer number, denoting in milliseconds
	@return{void}
	@example: this.startPolling(30000);
	@author: X. Hu
	
***********************************************************************/
giovanni.ui.MessageBoard.prototype.startPolling = function(pollInterval) {
  // make sure headline is hidden until we have news
	this.container.style.visibility = 'hidden';
	
	var parsedItems = [];
	var myDataSource = new YAHOO.util.XHRDataSource(this.rssUrl); 
	myDataSource.responseType = YAHOO.util.DataSource.TYPE_XML;
	myDataSource.maxCacheEntries = 1; //HTTP cache

	/*****
	Safari on Mac and chrome uses "localName" for the compund tag names (ex: 'dc:sujbect')
	to reference parsed XML element node names
	*****/
	if(navigator.userAgent.indexOf("Chrome")>-1 || (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Mac') != -1 )){
		this.subjectKey = 'subject';
		this.dateKey = 'date';
	}
	myDataSource.responseSchema = {resultNode: "item", fields: ["title","link","description",this.subjectKey,{key:this.dateKey,parse:function (ds) {
          var d = new Date();
          var b = d.parse( ds );
          return b ? ds : "not a date";
        }}]}; 
	myDataSource.subscribe('responseParseEvent',function(oArgs) {
		parsedItems=[];
		var subject = ""; 
		var pdate;
		for (var i=0;i<oArgs.response['results'].length;i++) {
			subject = navigator.userAgent.indexOf("Chrome")>-1 ? 
				oArgs.response['results'][i]['subject'] : oArgs.response['results'][i]['dc:subject']; 
			pdate = navigator.userAgent.indexOf("Chrome")>-1 ? 
				oArgs.response['results'][i]['date'] : oArgs.response['results'][i]['dc:date'];
			 
			parsedItems.push(oArgs.response['results'][i]); 
		}
	});

	var rssCallback = { 
		success: function() {
			//called after a successful XML parsing
			var itemsToAdd=[];
			var divsToRemove={};
			var newsDivs = this.newsDivs;
			for (var key in newsDivs) {
				divsToRemove[key]=newsDivs[key];
			}

      if(parsedItems.length > 0) {
        // make sure headline is viewable
	      this.container.style.visibility = 'visible';
	
        
        //go through parsed items and see which of them are already displayed, and which are not
        for (var i=0;i<parsedItems.length;i++) {
          var key=parsedItems[i]['title']+parsedItems[i][this.dateKey];
          if (key in divsToRemove) {
            delete divsToRemove[key];
          } else {
            itemsToAdd.push(parsedItems[i]);
          }
        }

        this.newsHtml = "";
        this.newsItems = "";

        //add new items to the page
        for (var i=0;i<itemsToAdd.length;i++) { 
          var dStr = itemsToAdd[i][this.dateKey];
                                  if(new Date().parse(dStr)){
                                    var currDate = new Date(dStr);
            this.newsItems += "<div><span class='messageItemDate'>"
                                      + currDate.toDateString()
                                      + "</span>";
                                  }
        
          this.newsItems += " - <span class='messageItemTitle'><a href='" 
                                    + itemsToAdd[i]['link'] 
                                    + "' target='_blank' >" 
                                    + itemsToAdd[i]['title'] 
                                    + "</a></span>";
          this.newsItems += "<div class='messageItemDesc'>"
                                    + this.trimToWord(itemsToAdd[i]['description'])
                                    + "</div>";
          this.newsItems += "<div class='messageItemFoot'><a href='"
                                    + itemsToAdd[i]['link']
                                    + "' target='_blank'>Read More</a></div></div>";
          if (i == 0) {
            var headline = itemsToAdd[i]['title'];  
            this.newsHtml += "<span id='headline'>";
            this.newsHtml += "<span id='headlineText'>";
            this.newsHtml += headline.substring(0,120) + " ...";
            this.newsHtml += "</span>";
            this.newsHtml += "<span id='headlineCount'>[1 of "+itemsToAdd.length+" messages]</span>";
            this.newsHtml += "<span id='headlineMore'>Read More</span>"; 
            this.newsHtml += "</span>";
          }
        };
        if (this.newsItems != '') {
          this.newsPanel.setBody(this.newsItems);
        }

        if(this.newsHtml!=''){
          this.rssDiv.innerHTML = this.newsHtml;
        }
        this.attemptsAfterFailure = 0;
      } else {
        this.container.style.visibility = 'hidden';
      }
		}, 
		failure: function(e) {  
			this.attemptsAfterFailure++;
			if(this.attemptsAfterFailure>this.maxAttempts){
				console.log("Error: callback failure - " + e);
				myDataSource.clearInterval(this.pollId);
			}
		}, 
		scope: this
	} ;

 	// initial query
 	var firsPollId = myDataSource.sendRequest(this.queryString, rssCallback); 
 	// subsequent queries
	this.pollId = myDataSource.setInterval(this.pollingInterval, this.queryString, rssCallback); 

};

/**
 * Used to trim the alert description so it doesn't overrun the panel;
 * returns the trimmed string
 *
 * @author K. Bryant
 * @this giovanni.ui.MessageBoard
 * @params {String}
 * @returns {String}
 **/
giovanni.ui.MessageBoard.prototype.trimToWord = function (inStr) {
  var str = inStr;
  var strLen = inStr.length;
  var maxLength = 140; // maximum number of characters to extract

  //trim the string to the maximum length
  var trimmedStr = str.substr(0, maxLength);
  //re-trim if we are in the middle of a word
  trimmedStr = trimmedStr.substr(0, Math.min(trimmedStr.length, trimmedStr.lastIndexOf(" ")));
  trimmedStr = trimmedStr.replace(/\n|\r/g," ");
  // remove <p> tags
  trimmedStr = trimmedStr.replace(/\<p\>/g,"").replace(/\<\/p\>/g,"");
  // add an ellipsis if necessary
  trimmedStr = maxLength === strLen ? trimmedStr : trimmedStr + " <strong>...</strong>";

  return trimmedStr;
};

