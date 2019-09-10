/*
 ** $Id: Session.js,v 1.46 2015/02/12 21:10:14 dedasilv Exp $
 ** -@@@ Giovanni, Version $Name:  $
 */

// establish the component namespace
giovanni.namespace("app");
// constructor
giovanni.app.SessionManager = function (config) {
    // make sure we have a valid object
    config = (config == null ? {} : config);
    // set service manager URL - this is how the front end communicates with the
    // back end
    this.serviceManagerURL = (config.serviceManagerURL == undefined || config.serviceManagerURL == null) ? 
      "./daac-bin/service_manager.pl?" : config.serviceManagerURL;
    this.portal = (config.portal == undefined || config.portal == null) ? 
      "GIOVANNI" : config.portal;
    this.application = (config.application == undefined || config.application == null) ?
      "GIOVANNI-DEV" : config.application;
    // user id - just a string
    this.userId = undefined;
    // user sessions - contains JSON structure of users, their giovanni apps, and their sessions
    // e.g., kbryant -> giovanni-dev -> <session id>'
    this.userSessions = undefined;
    // session id
    this.sessionId = undefined; 
    // register for login events
    if (login) login.loginCheckedEvent.subscribe(this.handleLoginCheckedEvent, this);
    if (login) login.loginEvent.subscribe(this.handleLoginEvent, this);
    // check for session events
    this.sessionCheckingEvent = new YAHOO.util.CustomEvent("SessionCheckingEvent",this);
    this.sessionCheckedEvent = new YAHOO.util.CustomEvent("SessionCheckedEvent",this);
    // config for the actual session object
    this.sessionConfig = {
      serviceManagerURL : this.serviceManagerURL,
      portal: this.portal,
      application: this.application
    }
    // create session object - builds all of the UI objects and
    // support plot initiation, etc.
    if (!session)
      session = new giovanni.app.Session("session", this.sessionConfig);
};

giovanni.app.SessionManager.prototype.handleLoginCheckedEvent = function (type, args, o) {
  // if the user is logged in, set the user id on the class member
  // and attempt to restore the user's session
  if (login.checked) { 
    console.log("SessionManager.handleLoginCheckedEvent(): login.checked is true");
    if (login.isLoggedIn) {
      console.log("SessionManager.handleLoginCheckedEvent():  user is logged in");
      o.userId = login.profile ? login.profile.uid : login.getUid();
      giovanni.util.removeGuest();
    } else {
      console.log("SessionManager.handleLoginCheckedEvent: login.checked is false");
    }
    o.getSession();
  }
}

giovanni.app.SessionManager.prototype.handleLoginEvent = function (type, args, o) {
  if (!login.isLoggedIn) {
    console.log("SessionManager.handleLoginEvent(): login.isLoggedIn is false");
    o.getNewSession();
  } else {
    console.log("SessionManager.handleLoginEvent(): login.isLoggedIn is true");
  }
};

giovanni.app.SessionManager.prototype.getUser = function () {
  return giovanni.util.readCookie('giovanniUid');
}

giovanni.app.SessionManager.prototype.getUserSessionsFromProfile = function () {
  return login && login.profile && login.profile.user_sessions ?
        login.profile.user_sessions : undefined;
}

giovanni.app.SessionManager.prototype.storeUserSessionsInProfile = function () {
  // write to the login profile object
  //if (login && login.profile) login.profile.user_sessions = this.userSessions.userSessions;
  // and send request to server side
  if (login) login.updateUserSessions();
}

giovanni.app.SessionManager.prototype.storeUserSession = function (user,sessionId) {
 /*
  * uses this JSON model
  * {
  *   "userSessions" : {
  *        {
  *          "kbryant": {
  *             "giovanni-dev": {
  *                 { "session":"123456" },
  *                 { "view":"dataSelection" }
  *             },
  *             "giovanni-test": {
  *                 { "session":"123457" },
  *                 { "view":"workspace" }
  *             },
  *             "giovanni-ops": {
  *                 { "session":"123458" },
  *                 { "view":"workspace" }
  *             }
  *          }
  *        },
  *        { 
  *          "eseiler": {
  *             {"giovanni-dev": "234567"}
  *          }
  *       }
  *    } 
  * } 
  * 
  **/
  // make sure user sessions object is up-to-date
  var userSessions = this.getUserSessionsFromProfile() ? this.getUserSessionsFromProfile() : 
    (giovanni.util.readCookie(USESSIONS) ? JSON.parse(giovanni.util.readCookie(USESSIONS)) : undefined);
  if (!userSessions) {
    // can't find user sessions in cookie or login.profile
    // so create 'userSessions' for the 'first' time
    giovanni.util.createCookie(USESSIONS,'{"'+USESSIONS+'":{}}');
    userSessions = JSON.parse(giovanni.util.readCookie(USESSIONS));
  }
  /* if there is no 'user' in userSessions, create the 'user' object */
  if (!userSessions.userSessions[user]) userSessions.userSessions[user] = {};
  /* if there is no 'application' in userSessions, create the 'application' object */
  if (!userSessions.userSessions[user][this.application]) userSessions.userSessions[user][this.application] = {};
  /* finally, add the session */
  userSessions.userSessions[user][this.application].session = sessionId;
  /* using the userSessions object, write the cookie */
  giovanni.util.createCookie(USESSIONS,JSON.stringify(userSessions));
  /* update the server side user_sessions state via the login object */
  if (login && login.isLoggedIn) login.updateUserSessions();
} 

/*
 * Given a user id, a 'userSessions' cookie and/or a window.name,
 * the application (e.g., 'GIOVANNI-DEV'), attempt to find the 
 * session id
 */
giovanni.app.SessionManager.prototype.getSession = function () {
    // make sure we're showing progress
    showProgress();
    var sessionId = undefined;
    var userId = this.userId ? this.userId : 
      (this.getUser() ? this.getUser() : giovanni.util.getGuest());
    if (userId) {
      console.log("SessionManager.getSession(): userId is "+userId);
      sessionId = this.getUserSessionId(userId);
      // The only way the session id can be null at this point is if the userSession
      // cookie was removed.  Is the window.name populated with a guest session?  If so, 
      // try pulling the session from there, otherwise, get a new session
      if (userId.includes('guest'))
        sessionId = userId.replace('guest+','');
      // if there is a session id, try to restore the session data
      if (sessionId) {
        console.log("SessionManager.getSession(): session id is " + sessionId);
        // Make sure to set the session id class member variable
        this.sessionId = sessionId;
        // and make sure the session is stored
        this.storeUserSession(userId,sessionId);
        // merge id? if there is a guest+sessionid stored in window.name, attempt to merge
        //var mergeId = window.name.includes('guest') ? window.name.replace('guest+','') : undefined;
        // restore the session data 
        this.restoreSessionData(sessionId);
      } else { // no session id found; get a new session
        console.log("SessionManager.getSession(): sessionId is undefined; getting new session");
        this.getNewSession();
      }
    } else { // no user id; get a new session
      this.getNewSession();
    }
}

/*
 * Ask service manager for a new session id
 */
giovanni.app.SessionManager.prototype.getNewSession = function () {
    // show progress
    showProgress();
    console.log("SessionManager.getNewSession(): getting new session");
    var url = this.serviceManagerURL + 'format=json';
    $.ajax({
      url: url,
      success: this.handleGetNewSessionSuccess,
      error: function (obj) {
        alert("Sorry, but we could not create a new session.  Please try again or click 'Feedback'");
      },
      dataType: "json",
      context: this
    })
};

/*
 * Store the new session id
 */
giovanni.app.SessionManager.prototype.handleGetNewSessionSuccess = function (o) {
    try {
        // set class member
        this.sessionId = o.session.id;
        if (this.sessionId == undefined || this.sessionId == null) {
            alert("Sorry, but we could not create a new session.  The returned session ID was null.  Please reload, open Giovanni in a new window or click 'Feedback'");
        } else {
          // store user (including guest) and session id in
          // session cookie
          var user = this.getUser() ? this.getUser() : "guest+" + this.sessionId;
          this.storeUserSession(user, this.sessionId); // requires valid userId and application
          if (user.includes("guest"))
            giovanni.util.setGuest(user);
          console.log("SessionManager.handleGetNewSessionSuccess()\n  User:  " + user + "\n  Session id is " + this.sessionId);
          // set id on session object
          if (session) {
              session.setSessionId(this.sessionId);
              // clear existing workspace and results
              session.clear();
              // if there is a workspace, set to data selection page
              if (session.workspace) session.workspace.showDataSelector(null, null);
              //this.sessionCheckedEvent.fire();
          }
        }
        // in case the progress icon is still there...
        hideProgress();
    } catch (x) {
        alert("Error parsing session ID. Cannot initiate a session with the server.");
        // in case the progress icon is still there...
        hideProgress();
    }
};

/*
 * Given a user id, get the associated session from the 'userSessions' cookie
 */
giovanni.app.SessionManager.prototype.getUserSessionId = function (userId) {
    var user = userId ? userId : this.userId;
    // is userSession set?  If not, check cookie
    
    // check login.profile.user_session first?
    // if the user sessions cookie is not there for some reason,
    // check the login profile
    var userSessions;
    if (login && login.profile && login.profile.user_sessions)
      userSessions = login.profile.user_sessions;
    if (!userSessions) 
      userSessions = JSON.parse(giovanni.util.readCookie(USESSIONS));
    return user && 
        userSessions && 
        userSessions.userSessions[user] &&
        userSessions.userSessions[user][this.application] ? 
            JSON.stringify(userSessions.userSessions[user][this.application].session).replace(/\"/g,"") : undefined;
};

/*
 * Given a user id, get the associated view from the 'userSessions' cookie;
 * default view is 'dataSelection'
 */
giovanni.app.SessionManager.prototype.getUserView = function () {
  if (typeof (Storage) === "undefined") {
    console.log("Browser does not support Web Storage");
    return "dataSelection";
  } else {
    return sessionStorage.getItem('giovanni-view') ? sessionStorage.getItem('giovanni-view') : 'dataSelection';
  }
}

/*
 * Given a user id (using the class member variable) and a view, store the 
 * view in 'userSessions' cookie  
 */
giovanni.app.SessionManager.prototype.setUserView = function (view) {
  if (typeof (Storage) === "undefined") {
    console.log("Can't store view.  Browser does not support Web Storage");
  } else {
    sessionStorage.setItem('giovanni-view',view);
  }
}

/*
 * Use Session object to restore session data
 */
giovanni.app.SessionManager.prototype.restoreSessionData = function (sessionId,mergeId) {
  if (!session) console.log("SessionManager.restoreSessionData():  session object is null");
  if (!session) session = new giovanni.app.Session('session',this.sessionConfig);
  // set the class member session id
  this.sessionId = sessionId;
  // set the session id on the Session object
  session.setSessionId(sessionId);
  // restore session data using Session class
  session.restoreSessionTree(sessionId, (mergeId !== sessionId ? mergeId : undefined));
}

