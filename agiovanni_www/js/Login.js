// establish the component namespace
giovanni.namespace("app");

giovanni.app.Login = function() {
    this.loginEvent = new YAHOO.util.CustomEvent("LoginEvent",this);
    this.loginCheckingEvent = new YAHOO.util.CustomEvent("LoginCheckingEvent",this);
    this.loginCheckedEvent = new YAHOO.util.CustomEvent("LoginCheckedEvent",this);
}

giovanni.app.Login.prototype.initialize = function(id, config) {
    this.containerId = id;
    if (this.containerId == null) {
        console.log('giovanni.app.Login: container id cannot be null');
        return;
    }
    // get the container element
    this.container = document.getElementById(this.containerId);
    if (this.container == null) {
        console.log('giovanni.app.Login: container element with id ' +
            this.containerId + 'not found');
        return;
    }

    config = (config == null ? {} : config);

    if (config.clientId == undefined || config.clientId == null) {
        console.log('giovanni.app.Login: clientId cannot be null');
        return;
    }

    // Construct authorization URL
    this.baseURL = (config.baseURL == undefined || config.baseURL == null) ? "https://urs.earthdata.nasa.gov" : config.baseURL;
    this.baseApiURL = this.baseURL+'/api/';
    this.authorizeURL = (config.authorizeURL == undefined || config.authorizeURL == null) ? this.baseURL+"/oauth/authorize?response_type=code" :
        this.baseURL+config.authorizeURL;
    this.logoutURL = this.baseURL+'/logout';
    this.clientId = config.clientId;
    this.redirectURI = (config.redirectURI == undefined || config.redirectURI == null) ? "https://disc.gsfc.nasa.gov/urs-redirect" :
        config.redirectURI;
    var loginURL = this.authorizeURL + '&client_id=' + this.clientId + '&redirect_uri=' + this.redirectURI;
    this.loginURL = loginURL;

    this.profile = null;
    this.enabled = null;
    this.checked = null;
    this.isLoggedIn = false;
    this.checkFailed = false;

    // Construct Login link element
    var link = document.createElement("span");
    link.setAttribute('class', 'bannerLink');
    link.setAttribute('id', 'loginLink');
    link.innerHTML = "Login";
    link.title = "Use your Earthdata login credentials to login to Giovanni";
    this.loginLink = link;

    if(config.enabled && config.enabled === 1) {
        this.enabled = 1;
        $('.bannerLogin').css('display','inline-block');
    }

    /*
     * The commented code below was used before checkLogin was
     * called immediately after creating the Login object.
     * Now that checkLogin is going to be called immediately after creating
     * the Login object, we won't add the link element until after
     * we have determined that the user is not already logged in.

    if (this.container.firstChild) {
        this.container.replaceChild(link, this.container.firstChild);
    } else {
        this.container.appendChild(link);
    }

    // Bind an event handler to the login link
    //$('#loginLink').click(this.doLogin.bind(this));
    $('#loginLink').click(this.checkLogin.bind(this));
    */

    // Click function for the link will add a state parameter to the
    // authorizaton URL with a value equal to the current (encoded) URL
    /*
    $('#loginLink').click(function() {
        // Save the current fragment and use it as the value of the
        // state parameter
        var savedURL = encodeURIComponent(window.location.hash);
        $(location).attr('href', loginURL+'&state='+savedURL);
        return false;
    });
    */

}

giovanni.app.Login.prototype.checkLogin = function() {

    /*
     * This is the function for the login link.
     * Check if user is already logged in and if the application
     * is authorized.
     * Response should be JSON containing "auth_status" with a value
     * of 'true' (logged in and authorized), 'false' (logged in and
     * not authorized), and 'user not logged in'.
     * Use of withCredentials allows cross-domain request, and adherence
     * to CORS allows check_auth_status to determine status via cookies.
     */
    var authStatusURL = login.baseApiURL + 'session/check_auth_status?client_id=' + login.clientId;
    $.ajax({
               type : "GET",
               dataType : "json",
               url : authStatusURL,
               cache: false,
               xhrFields : { withCredentials : true },
               success : this.doLogin,
               error : function (jqXHR, textStatus, errorThrown) {
                   console.log("checkLogin status: " + textStatus + ", error thrown: " + errorThrown );
                   // Because this is a cross-domain request of type 'json'
                   // rather than 'jsonp', if there is an error,
                   // jqXHR.status will be 0 no matter what the HTTP status
                   // code, so the best we can do is display a generic message
                   alert( "There was an unexpected error trying to communicate with Earthdata to determine if you are logged in. You may continue with limited access and try logging in later.");
                   // If we cannot tell if a user is logged in, assume that
                   // they are not, and make sure that no cookies associated
                   // with a logged in user exist
                   this.handleFailedLoginResponse();
                   return false;
               },
               context : this
           });
    return false;
}

giovanni.app.Login.prototype.doLogin = function(authResponse, textStatus, jqXHR) {

    /*
     * After request to check authorization status, look at the response
     * to determine if the user is logged in and the application is
     * authenticated.
     * Open a new window that is directed to the authorization URL login.loginURL.
     * If the user is already logged in, there is no need to display the
     * window, so blur the focus of the popup until we are done with the
     * window and can close it.
     *
     * When authorization has completed, the new window should be redirected
     * to login.redirectURI. The timer checks each time to see if the
     * URL of the new window matches login.redirectURI, and when it does,
     * it expects to be able to find a query parameter named "code".
     * The value of the "code" parameter is extracted and passed to
     * processAuthorizeResponse().
     */
    var winSpecs;
    var winSpecsSmall = 'left=16383, top=16383, width=100, height=100, menubar=no, status=no';
    var winSpecsParent;
    if ('screenLeft' in window) {
        winSpecsParent = 'left=' + window.screenLeft + ', top=' + window.screenTop;
    }
    if ('screenX' in window) {
        winSpecsParent = 'left=' + window.screenX + ', top=' + window.screenY;
    }
    //alert("status is " + authResponse.auth_status);
    if (authResponse.auth_status === 'true') {
        var giovanniUid = readCookie('giovanniUid');
        if (giovanniUid) {
            // TBD:
            // We know that the user is already logged in, and the giovanniUid
            // cookie has been set with the user's id, so if we can
            // trust the giovanniUid cookie, we can try to read the stored
            // profile instead of requesting it from Earthdata.
            // TBD: Possibly avoid request to Earthdata by reading
            // profile via Giovanni CGI
        }
    }
    if (authResponse.auth_status === 'true') {
        // User has already logged in. Try to make the popup small and out of the way.
        winSpecs = winSpecsSmall;
        if ( !login.checked ) {
            login.checked = 1;
            // Bind an event handler to the login link
            $('#loginLink').click(login.checkLogin.bind(login));
        }
        login.isLoggedIn = true;
    } else {
        login.isLoggedIn = false;
        if ( !login.checked ) {
            // If user is not logged in and this is the first time we checked,
            // then don't redirect to the login, let the user login via the link.
            login.checked = 1;

            // If checkLogin is going to be called immediately after creating
            // the Login object, then add the link element after
            // we have determined that the user is not already logged in.
            if (login.container.firstChild) {
                login.container.replaceChild(login.loginLink, login.container.firstChild);
            } else {
                login.container.appendChild(login.loginLink);
            }
            // Bind an event handler to the login link
            $('#loginLink').click(login.checkLogin.bind(login));

            // Clear cookie identifying user if user has not logged in
            eraseCookie('giovanniUid');

            // fire a loginChecked event
            login.loginCheckedEvent.fire();
            return false;
        }
        // User has not logged in.
        // Make the popup have the same size and position as the parent window.
        winSpecs = winSpecsParent;
    }
    var popup = window.open(login.loginURL, "authPopup", winSpecs);
    if (popup==null) {
        alert("Please allow popup windows for this website in order to enable the login capability.");
        // fire a loginChecked event
        login.checkFailed = true;
        login.checked = 1;
        // Treat user as guest because we could not obtain the profile
        this.handleFailedLoginResponse();
        return true;
    } else {
        if (authResponse.auth_status === 'true') {
            // Already logged in and application is authorized.
            popup.blur();
            window.focus();
            login.isLoggedIn = true;
            eraseCookie('profileErrorUrl');
            // fire a login event
            login.loginEvent.fire();
        }
        var counter = 0;
        var maxCount = 100;
        var reopened;
        var pollTimer = window.setInterval(function() {
            try {
                // Expect that when the redirectURI is loaded, it will set a cookie
                // named profileCode to the value of the 'code' parameter that was
                // found in the query string.
                var profileErrorUrl = readCookie('profileErrorUrl');
                var profileCode = readCookie('profileCode');
                if (profileErrorUrl) {
                    // An error occurred.
                    if (!reopened && (authResponse.auth_status === 'true')) {
                        // Expect the popup to be small. Close the popup, erase the cookie,
                        // and then open another, larger popup.
                        popup.close();
                        eraseCookie('profileErrorUrl');
                        reopened = 1;
                        popup = window.open(profileErrorUrl, "authError", winSpecsParent);
                    } else {
                        // Expect the popup to be large. Leave it open.
                    }
                    window.clearInterval(pollTimer);
                } else {
                    if (profileCode) {
                        // Once we have the code, we can close the popup and erase the cookie,
                        // and then use the code to obtain a profile.
                        window.clearInterval(pollTimer);
                        popup.close();
                        eraseCookie('profileCode');
                        login.processAuthorizeResponse(profileCode);
                    } else {
                        // No redirection has occurred, or the cookie was not set after
                        // redirection.
                        // The user may be taking a long time, or may have closed the window,
                        // or the window is small and the user didn't notice it. We have no
                        // way to tell which of these may have occurred.
                    }
                }
            } catch(e) {
                console.log('caught ' + e);
            }
        }, 100);
        // fire a loginChecked event
        // Don't fire loginCheckedEvent before handleLoginResponse?
        //console.log("after redirect loginCheckedEvent");
        //login.loginCheckedEvent.fire();
        //hideProgress();
        return false;
    }
}

giovanni.app.Login.prototype.processAuthorizeResponse = function(code) {
    /*
     * Function that is invoked upon callback from Earthdata Login
     * which makes an ajax request to a server script that will use the 'code'
     * parameter to obtain a token, use the token to obtain profile info,
     * and then use the user id from the profile to look up roles in the
     * UUI database.
     * The response from the ajax request is handled by the callback
     * to handleLoginResponse
     */
    var login_url = "daac-bin/earthdataLogin.pl";

    // The timeout limit (in milliseconds)is set to be long enough for the
    // server script to complete, but short enough to avoid waiting too long.
    var tlimit = 30000;

    // Begin process of obtaining the user profile
    login.loginCheckingEvent.fire();

    $.ajax({
               type : "GET",
               dataType : "json",
               url : login_url + "?code=" + code,
               timeout: tlimit,
               success : this.handleLoginResponse,
               error : function (jqXHR, textStatus, errorThrown) {
                   console.log("processAuthorizeResponse status: " + textStatus + ", error thrown: " + errorThrown );
                   login.isLoggedIn = false;
                   if (jqXHR.status == 500) {
                       alert( "It appears that Giovanni is unable to communicate with Earthdata right now to obtain your user profile. You may continue with limited access and try logging in later.");
                       this.handleFailedLoginResponse();
                       return false;
                   } else {
                       alert( "There was an unexpected error trying to communicate with Earthdata to obtain your user profile. You may continue with limited access and try logging in later.");
                       this.handleFailedLoginResponse();
                       return false;
                   }
               },
               //complete: this.showDefaultCursor,
               context : this
           });
}

giovanni.app.Login.prototype.handleLoginResponse = function(profile, textStatus, jqXHR) {
    /*
     * Success function for processAuthorizeResponse Ajax request.
     * profile is the JSON response from a server script that has requested
     * a token, used the token to request the user profile, used the user UID
     * to obtain roles from the UUI database (if configured), and combined the
     * profile and the roles into a JSON response.
     */
    this.profile = profile;

    // Construct a logout link and replace the login link with it
    var link = document.createElement("span");
    link.setAttribute('class', 'bannerLink');
    link.setAttribute('id', 'logoutLink');
    link.innerHTML = "Log out" + " (" + this.profile.uid + ")";
    link.title = "Log out from Giovanni and Earthdata";
    if (this.container.firstChild) {
        this.container.replaceChild(link, this.container.firstChild);
    } else {
        this.container.appendChild(link);
    }

    // Bind an event handler to the logout link
    $('#logoutLink').click(this.logout.bind(this));

    login.isLoggedIn = true;

    // fire a login event
    login.checked = 1;
    login.loginCheckedEvent.fire();
    login.loginEvent.fire();
}

giovanni.app.Login.prototype.handleFailedLoginResponse = function() {
    /*
     * Failure function for processAuthorizeResponse Ajax request.
     * There was a problem in running the server side script, with the request
     * for a token, or the request for the user profile. Usually an indication
     * of either a problem with Earthdata login, or a problem running scripts
     * on the Giovanni server.
     */

    // Make sure that a login link is available
    if (login.container.firstChild) {
        login.container.replaceChild(login.loginLink, login.container.firstChild);
    } else {
        login.container.appendChild(login.loginLink);
    }
    // Bind an event handler to the login link
    $('#loginLink').off('click');
    $('#loginLink').click(login.checkLogin.bind(login));

    // Clear profile
    login.profile = null;

    // If we failed to get a profile, make sure that
    // there are no cookies associated with a logged in user
    login.isLoggedIn = false;
    eraseCookie('giovanniUid');
    eraseCookie('giovanniRoles');

    // fire a loginChecked event
    login.checkFailed = true;
    login.checked = 1;
    login.loginCheckedEvent.fire();
    return false;
}

giovanni.app.Login.prototype.logout = function() {
    // Do logout stuff here

    var winSpecs = 'left=16383, top=16383, width=1, height=1, menubar=no, status=no';
    var popup = window.open(this.logoutURL, "logoutPopup", winSpecs);
    if (popup==null) {
        alert("Please allow popup windows for this website in order to enable the login capability.");
        return true;
    } else {
        var id;
        var lobject = this;
        try {
            if (popup.location.href) {
                // This is a fugly hack to delay the closing of the popup window until after
                // it has had a chance to fully load. Using a load handler did not seem to do
                // the trick.
                $(popup).ready(function(){
                   id = setTimeout(function(){ prepareLogin(popup,lobject); }, 500);
                });
            }
        } catch (e) {
            if (e.description.toLowerCase().indexOf('permission denied') !== -1) {
                // Handle the case of browsers that do not allow access to the properties
                // of a window that was opened with a URL in a different domain.
                // Other than that, it is the same hack as above. It is making a guess
                // that 500 ms is long enough.
                console.log('Cannot access popup properties');
                id = setTimeout(function(){ prepareLogin(popup,lobject); }, 500);
            } else {
                // Error other than permission
                console.log('caught ' + e);
            }
        }
        return false;
    }
}

function prepareLogin(popup,lobject) {
    // Clear profile
    lobject.profile = null;

    // Replace logout link with login link
    login.container.replaceChild(login.loginLink, login.container.firstChild)
;
    // Remove any existing click event handlers and add checkLogin
    $('#loginLink').off('click');
    $('#loginLink').click(login.checkLogin.bind(login));
    popup.close();
    login.isLoggedIn = false;
    login.checkFailed = false;
    login.loginEvent.fire();
    var logoutURL = 'daac-bin/profileLogout.pl';
    $.ajax({
               type : "GET",
               dataType : "json",
               url : logoutURL,
               success : lobject.doLogout,
               error : function (jqXHR, textStatus, errorThrown) {
                   alert( "Logout error: " + textStatus + " " + errorThrown );
                   eraseCookie('giovanniUid');
                   eraseCookie('giovanniRoles');
               },
               context : lobject
           });
}

giovanni.app.Login.prototype.doLogout = function(logoutResponse, textStatus, jqXHR) {
    // Successfully updated status in stored profile
    // Expect that the AJAX call deleted all cookies associated with
    // the user id.
    console.log('logout response: ' + logoutResponse.status);
}

giovanni.app.Login.prototype.updateUserSessions = function() {
    // Update the stored profile with the current value of the userSessions cookie
    var updateURL = 'daac-bin/updateUserSessions.pl';
    $.ajax({
               type : "GET",
               dataType : "json",
               url : updateURL,
               success : this.userSessionsUpdated,
               error : function (jqXHR, textStatus, errorThrown) {
                   alert( "Error updating userSessions: " + textStatus + " " + errorThrown );
               },
               context : this
           });
    return false;
}

giovanni.app.Login.prototype.userSessionsUpdated = function(updateResponse, textStatus, jqXHR) {
    // Successfully updated stored profile with the current value of the
    // userSessions cookie
    console.log('update response: ' + updateResponse.status);
}

function createCookie(name,value,days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = encodeURIComponent(name) + "=" + encodeURIComponent(value) + expires + "; path=/";
}

function readCookie(name) {
    var nameEQ = encodeURIComponent(name) + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return decodeURIComponent(c.substring(nameEQ.length,c.length));
    }
    return null;
}

function eraseCookie(name) {
    createCookie(name,"",-1);
}

// Functions to return fields of the Earthdata login profile

giovanni.app.Login.prototype.getRoles = function() {
    if (this.profile) {
        return this.profile.roles;
    }
}

giovanni.app.Login.prototype.getFullName = function() {
    if (this.profile) {
        return this.profile.first_name + ' ' + this.profile.last_name;
    }
}

giovanni.app.Login.prototype.getFirstName = function() {
    if (this.profile) {
        return this.profile.first_name;
    }
}

giovanni.app.Login.prototype.getLastName = function() {
    if (this.profile) {
        return this.profile.last_name;
    }
}

giovanni.app.Login.prototype.getUid = function() {
    if (this.profile) {
        return this.profile.uid;
    }
}

giovanni.app.Login.prototype.getEmailAddress = function() {
    if (this.profile) {
        return this.profile.email_address;
    }
}

giovanni.app.Login.prototype.getUserSessions = function() {
    // Return the value of user_sessions from the profile that
    // was obtained at login time. Note that the stored profile may be
    // updated with newer values of the userSessions cookie afterwards.
    if (this.profile) {
        return this.profile.user_sessions;
    }
}
