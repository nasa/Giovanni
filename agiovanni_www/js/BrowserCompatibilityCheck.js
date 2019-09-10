//$Id: BrowserCompatibilityCheck.js,v 1.10 2015/02/05 21:18:44 dedasilv Exp $ 
//-@@@ Giovanni, Version $Name:  $


giovanni.namespace("giovanni.util");

giovanni.util.BrowserChecker = function () {
    var dataBrowser = [
        {
            string: navigator.vendor,
            subString: "Apple",
            identity: "Safari",
            versionSearch: "Version"
		}, {
            string: navigator.vendor,
            subString: "iCab",
            identity: "iCab"
		}, {
            string: navigator.vendor,
            subString: "KDE",
            identity: "Konqueror"
		}, {
            string: navigator.vendor,
            subString: "Camino",
            identity: "Camino"
		}, {
            prop: window.opera,
            identity: "Opera",
            versionSearch: "Version"
		}, {
            string: navigator.userAgent,
            subString: "Edge",
            identity: "Edge"
		}, {
            string: navigator.userAgent,
            subString: "OmniWeb",
            identity: "OmniWeb",
            versionSearch: "OmniWeb/"
		}, {
            string: navigator.userAgent,
            subString: "Firefox",
            identity: "Firefox"
		}, {
            string: navigator.userAgent,
            subString: "Mobile Safari",
            identity: "Mobile Safari",
            versionSearch: "Version"
		}, {
            // for newer Netscapes (6+)
            string: navigator.userAgent,
            subString: "Netscape",
            identity: "Netscape"
		}, {
            string: navigator.userAgent,
            subString: "MSIE",
            identity: "Internet Explorer",
            versionSearch: "MSIE"
		}, {
            string: navigator.userAgent,
            subString: "Chrome",
            identity: "Chrome"
                }, {
            string: navigator.userAgent,
            subString: "Gecko",
            identity: "Mozilla",
            versionSearch: "rv"
		}, {
            // for older Netscapes (4-)
            string: navigator.userAgent,
            subString: "Mozilla",
            identity: "Netscape",
            versionSearch: "Mozilla"
		}
	];

    var dataOS = [
        {
            string: navigator.userAgent,
            subString: "iPhone",
            identity: "iPhone/iPod"
    }, {
            string: navigator.userAgent,
            subString: "iPad",
            identity: "iPad"
		}, {
            string: navigator.userAgent,
            subString: "Android",
            identity: "Android"
		}, {
            string: navigator.platform,
            subString: "Win",
            identity: "Windows"
		}, {
            string: navigator.platform,
            subString: "Mac",
            identity: "Mac"
		}, {
            string: navigator.platform,
            subString: "Linux",
            identity: "Linux"
		}
	];

    this.name = searchString(dataBrowser);
    this.version = searchVersion(navigator.userAgent) || searchVersion(navigator.appVersion) || "unknown";
    this.platform = searchString(dataOS);

    function searchString(data) {
        for (var i = 0; i < data.length; i++) {
            var dataString = data[i].string;
            var dataProp = data[i].prop;
            this.versionSearchString = data[i].versionSearch || data[i].identity;
            if (dataString) {
                if (dataString.indexOf(data[i].subString) != -1)
                    return data[i].identity;
            } else if (dataProp) {
                return data[i].identity;
            }
        }
        return "unknown";
    }

    function searchVersion(dataString) {
        var index = dataString.indexOf(this.versionSearchString);
        if (index == -1) return;
        // parsing to float doesn't allow more than one subversion
        // for eg: chrome version 22.0.1229.96 was converted to just 22 (parsing stops right at the second dot after 22.0)
        // so save the version as a string
        //return parseFloat(dataString.substring(index+this.versionSearchString.length+1));
        var versionStr = dataString.substring(index + this.versionSearchString.length + 1);
        return versionStr.split(/[^0-9.]/)[0];
    }
};

giovanni.util.BrowserChecker.BrowserInfo = function (platform, name, version) {
    this.platform = platform;
    this.name = name;
    this.version = version;
};

giovanni.util.BrowserChecker.prototype.validate = function (userInvoked) {
    var brChkRef = this;
    var callback = {
        success: giovanni.util.BrowserChecker.prototype.handleResponse,
        failure: function (obj) {
            if (userInvoked)
                alert("Could not retrieve browser compatibility information from the server");
        },
        timeout: 5000,
        argument: [brChkRef, userInvoked]
    };
    YAHOO.util.Connect.asyncRequest('GET', "daac-bin//getSupportedBrowsers.pl", callback, null);
};

giovanni.util.BrowserChecker.prototype.handleResponse = function (resp) {
    var brChkRef = resp.argument[0];
    var userInvoked = resp.argument[1];
    var tested = false;

    // current browser info
    var currBrowser = new giovanni.util.BrowserChecker.BrowserInfo(
        brChkRef.platform, brChkRef.name, brChkRef.version);
    var browserInfoMsg = '\nYou are using ' + currBrowser.name + ' ' + currBrowser.version + ' on ' + currBrowser.platform + '. ';

    var nonSuppBrowserList = null;
    var suppBrowserList = null;

    // get browser info list from XML response
    var brLstElem = resp.responseXML.getElementsByTagName("BrowserList")[0];
    if (brLstElem != undefined) {
        // parse for non-supported browsers in the browser info list
        var nonSuppBrLstElem = brLstElem.getElementsByTagName("NonSupportedBrowsers")[0];
        if (nonSuppBrLstElem != undefined && nonSuppBrLstElem.getElementsByTagName("Browser").length > 0) {
            var nonSuppBrowserElem = nonSuppBrLstElem.getElementsByTagName("Browser");
            nonSuppBrowserList = new Array(nonSuppBrowserElem.length);
            for (var i = 0; i < nonSuppBrowserElem.length; i++) {
                var tmp1 = nonSuppBrowserElem[i].getElementsByTagName("Platform")[0];
                var pfm = (tmp1 && tmp1.firstChild ? tmp1.firstChild.nodeValue : null);
                var tmp2 = nonSuppBrowserElem[i].getElementsByTagName("Version")[0];
                var ver = (tmp2 && tmp2.firstChild ? tmp2.firstChild.nodeValue : null);
                nonSuppBrowserList[i] = new giovanni.util.BrowserChecker.BrowserInfo(
                    pfm, nonSuppBrowserElem[i].getElementsByTagName("Name")[0].firstChild.nodeValue, ver);
            }
        }

        // parse for supported browsers in the browser info list
        var suppBrLstElem = brLstElem.getElementsByTagName("SupportedBrowsers")[0];
        if (suppBrLstElem != undefined && suppBrLstElem.getElementsByTagName("Browser").length > 0) {
            var suppBrowserElem = suppBrLstElem.getElementsByTagName("Browser");
            suppBrowserList = new Array(suppBrowserElem.length);
            for (var i = 0; i < suppBrowserElem.length; i++) {
                suppBrowserList[i] = new giovanni.util.BrowserChecker.BrowserInfo(
                    suppBrowserElem[i].getElementsByTagName("Platform")[0].firstChild.nodeValue,
                    suppBrowserElem[i].getElementsByTagName("Name")[0].firstChild.nodeValue,
                    suppBrowserElem[i].getElementsByTagName("Version")[0].firstChild.nodeValue);
            }
        }
    }

    // processing for non-supported browsers
    if (nonSuppBrowserList != null) {
        // compare the current browser info against the non-supported browser list
        for (var i = 0; i < nonSuppBrowserList.length; i++) {
            var nonSuppBrowser = nonSuppBrowserList[i];
            if ((nonSuppBrowser.platform == null || nonSuppBrowser.platform == currBrowser.platform) && nonSuppBrowser.name == currBrowser.name && (nonSuppBrowser.version == null || nonSuppBrowser.version == currBrowser.version)) {
                // navigate to the non compatible browser notification page
                var target = "non_compatible_browser.html";
                if (document.URL.match(target + "$") != target) {
                    // disable all unload event intercepts on the window
                    YAHOO.util.Event.removeListener(window, "beforeunload");
                    window.location.replace("../giovanni/non_compatible_browser.html");
                } else {
                    // if already in the non compatible browser notification page
                    // construct and display the supported browser list 
                    var str = "<ul>";
                    for (var i = 0; i < suppBrowserList.length; i++) {
                        str += "<li>" + suppBrowserList[i].name + " " + suppBrowserList[i].version + " on " + suppBrowserList[i].platform + "</li>";
                    }
                    str += "</ul>";
                    document.getElementById("suppBrowsers").innerHTML = str;
                }
                // non-supported browser list has precedence over supported list.
                // return here to avoid processing the supported list, 
                // when the current browser is in the non-supported list
                return;
            }
        }
    }

    // processing for supported browsers
    if (suppBrowserList != null) {
        // compare the current browser name, version and platform with the supported browser info list
        for (var i = 0; i < suppBrowserList.length; i++) {
            var suppBrowser = suppBrowserList[i];
            if (suppBrowser.platform == currBrowser.platform && suppBrowser.name == currBrowser.name && compareVersions(suppBrowser.version, currBrowser.version) != 1) {
                tested = true; // if a match is found, the browser is flagged as tested
                break;
            }
            // DEBUG alerts, use if required
            /*
  		else if (suppBrowser.platform == currBrowser.platform
  		  && suppBrowser.name == currBrowser.name)
  		{
  		  alert("suppBrowser.version (" + suppBrowser.version +") <= currBrowser.version (" 
  		    + currBrowser.version + ") = " + (suppBrowser.version <= currBrowser.version)
  		    +"\n suppBrowser.version (" + suppBrowser.version +") > currBrowser.version (" 
  		    + currBrowser.version + ") = " + (suppBrowser.version > currBrowser.version));
  		}
      */
        }

        // this is only to handle the situation when the non compatible msg page URL is loaded MANUALLY on a supported browser
        // this is not expected to happen thru the portal
        var target = "non_compatible_browser.html";
        if (document.URL.match(target + "$") == target) {
            var msgStr = (tested ? 'This website is compatible with your browser. ' : 'This website has NOT been tested on your browser. ') + browserInfoMsg;
            document.getElementById("non_comp_msg").innerHTML = msgStr;

            var brStr = "<ul>";
            for (var i = 0; i < suppBrowserList.length; i++) {
                brStr += "<li>" + suppBrowserList[i].name + " " + suppBrowserList[i].version + " on " + suppBrowserList[i].platform + "</li>";
            }
            brStr += "</ul>";
            document.getElementById("suppBrowsers").innerHTML = brStr;
            return;
        }

        // add supported browser info to the message being displayed 
        browserInfoMsg += '\n\nThis website has been tested on the following browsers : ';
        for (var i = 0; i < suppBrowserList.length; i++) {
            browserInfoMsg += '\n * ' + suppBrowserList[i].name + ' ' + suppBrowserList[i].version + ' and above on ' + suppBrowserList[i].platform;
        }
    }

    // display warning msg if the browser is NOT tested
    if (!tested) {
        alert('This website has NOT been tested on your browser. ' + browserInfoMsg);
    }
    // if the validation was invoked by the user, display info msg even when the browser is supported
    else if (userInvoked) {
        alert('This website is compatible with your browser. ' + browserInfoMsg);
    }
};

function compareVersions(version1, version2) {
    var tokens1 = version1.split(".");
    var tokens2 = version2.split(".");
    for (var i = 0; i < tokens1.length; i++) {
        if (tokens2.length > i) {
            if (parseInt(tokens1[i]) < parseInt(tokens2[i])) {
                return -1;
            } else if (parseInt(tokens1[i]) > parseInt(tokens2[i])) {
                return 1;
            }
        } else {
            return 1;
        }
    }
    if (tokens2.length > i) {
        return -1;
    } else {
        return 0;
    }
};

// validate the browser on page load
window.browserChecker = new giovanni.util.BrowserChecker();
//TODO temp fix to YUI connection_min not being available until page load
