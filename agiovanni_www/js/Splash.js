/* Used by index.html and index-debug.html. Modal design is used to construct the giovanni Splash Page.
 *  */
giovanni.namespace('widget');

/*
 *constructor
 * args:
 * containerId - the ID of the element used as the container for the component 
 * @author Mike Nardozzi
 */

giovanni.widget.Splash = function(id, cookie, config) {

    this.containerId = id;
    if (this.containerId == null) {
        console.log('giovanni.widget.Splash: container id cannot be null');
        return;
    }

    //  get the container element
    this.container = document.getElementById(this.containerId);
    if (this.container == null) {
        console.log('giovanni.widget.Splash: container element with id ' +
            this.containerId + ' not found');
        return;
    }
    if (config === undefined) {
        config = {};
    }
    this.render();

    // Event listeners
    var closeBtn = document.getElementsByClassName('splash-close')[0];
    var continueBtn = document.getElementById('continueButton');
    var doNotShowAgainCheck = document.getElementById('modalCheckmark');
    var doNotShowAgainBox = document.getElementById('modalCheckbox');
    var loginBtn = document.getElementById('loginButton');
    var container = this.container; // local var to pass to event handlers
    closeBtn.addEventListener('click', function (e) { closeModal(e,container); });
    window.addEventListener('click', function (e) { clickOutside(e,container); });
    continueBtn.addEventListener('click', function (e) { continueModal(e,container); });
    doNotShowAgainBox.addEventListener('click', checkboxModal);
    loginBtn.addEventListener('click', login.checkLogin.bind(login));
}

giovanni.widget.Splash.prototype.render = function() {
    // Assemble html elements
    this.renderContent();
    this.renderHeader();
    this.renderFaClose();
    this.renderTitle();
    this.renderBodyContent();
    this.renderFooter();
    this.renderFooterContent();
}

// Functions specific to rendering of Splash Page
giovanni.widget.Splash.prototype.renderContent = function() {
    var self = this;
    var splashContent = document.createElement('div');
    splashContent.setAttribute('id', 'splashContent');
    splashContent.setAttribute('class', 'splash-content');
    this.container.appendChild(splashContent);
}

giovanni.widget.Splash.prototype.renderHeader = function() {
    var modalHeader = document.createElement('div');
    modalHeader.setAttribute('id', 'modalHeader');
    modalHeader.setAttribute('class', 'splash-header');
    splashContent.appendChild(modalHeader);
}

giovanni.widget.Splash.prototype.renderFaClose = function() {
    var faClose = document.createElement('span');
    faClose.setAttribute('id', 'faClose');
    faClose.setAttribute('aria-hidden', 'true');
    faClose.setAttribute('class', 'splash-close');
    var fatimesCircle = document.createElement('i');
    fatimesCircle.setAttribute('id', 'fatimesCircle');
    fatimesCircle.setAttribute('class', 'splash-fa splash-fa-times-circle fa-2x');
    modalHeader.appendChild(faClose);
    faClose.appendChild(fatimesCircle);
}

giovanni.widget.Splash.prototype.renderTitle = function() {
    var modalHeaderTitle = document.createElement('h3');
    modalHeaderTitle.setAttribute('id', 'sitetourModalLabel');
    modalHeaderTitle.setAttribute('class', 'splash-title');
    modalHeaderTitle.innerHTML = "Welcome to Giovanni";
    modalHeader.appendChild(modalHeaderTitle);
}

giovanni.widget.Splash.prototype.renderBodyContent = function() {
    var modalBody = document.createElement('div');
    modalBody.setAttribute('class', 'splash-body splash-body-welcome');
    var modalBodyContent = document.createElement('p');
    var t = document.createTextNode("This application allows you to visualize selected geophysical parameters. If you are new to this application, please see the ");
    modalBodyContent.appendChild(t);
    modalBodyContent.appendChild(this.renderHTMLLink('helpDocLink', 'doc/UsersManualworkingdocument.docx.html', '_blank', 'Help'));
    var u = document.createTextNode(" page for a guide on how to use Giovanni. You may also visit the ");
    modalBodyContent.appendChild(u);
    modalBodyContent.appendChild(this.renderHTMLLink("tutorialLink", "https://www.youtube.com/user/NASAGESDISC/search?query=giovanni", "_blank", "NASA GESDISC channel"));
    var v = document.createTextNode(" for a quick look at Giovanni features. Please register with Earthdata and ");
    modalBodyContent.appendChild(v);
    loginLink = modalBodyContent.appendChild(this.createHTMLLink("loginLink", "login"));
    loginLink.addEventListener('click', login.checkLogin.bind(login));
    var x = document.createTextNode(" in order to gain full access to data and services within Giovanni. ");
    modalBodyContent.appendChild(x);
    splashContent.appendChild(modalBody);
    modalBody.appendChild(modalBodyContent);
}

giovanni.widget.Splash.prototype.createHTMLLink = function(element, text) {
    var element = document.createElement('span');
    element.setAttribute('class', 'splash-link');
    element.innerHTML = text;
    return element;
}

giovanni.widget.Splash.prototype.renderHTMLLink = function(element, url, target, text) {
    var element = document.createElement('span');
    element.setAttribute('class', 'splash-link');
    element.innerHTML = text;
    element.addEventListener('click', function () { window.open(url, target); });
    return element;
}

giovanni.widget.Splash.prototype.renderButton = function(buttonElement, type, buttonId, buttonClass, text) {
    var buttonElement = document.createElement('button');
    buttonElement.setAttribute('type', type);
    buttonElement.setAttribute('id', buttonId);
    buttonElement.setAttribute('class', buttonClass);
    buttonElement.innerHTML = text;
    return buttonElement;
}

giovanni.widget.Splash.prototype.renderFooter = function() {
    var modalFooter = document.createElement('div');
    modalFooter.setAttribute('id', 'modalFooter');
    modalFooter.setAttribute('class', 'splash-footer');
    splashContent.appendChild(modalFooter);
}

giovanni.widget.Splash.prototype.renderFooterContent = function() {
    var footerBodyContent = document.createElement('p');
    footerBodyContent.setAttribute('class', 'splash-pull-left');
    var footerLabel = document.createElement('label');
    footerLabel.setAttribute('class', 'splash-container');
    footerLabel.innerHTML = "Do not show again";
    var footerCheckbox = document.createElement('input');
    footerCheckbox.setAttribute('type', 'checkbox');
    footerCheckbox.setAttribute('id', 'modalCheckbox');
    var footerCheckmark = document.createElement('span');
    footerCheckmark.setAttribute('id', 'modalCheckmark');
    footerCheckmark.setAttribute('class', 'splash-checkmark');
    modalFooter.appendChild(footerBodyContent);
    footerBodyContent.appendChild(footerLabel);
    footerLabel.appendChild(footerCheckbox);
    footerLabel.appendChild(footerCheckmark);
    helpBtn = modalFooter.appendChild(this.renderHTMLLink("helpLink", "doc/UsersManualworkingdocument.docx.html", "_blank", ""));
    helpBtn.appendChild(this.renderButton("helpButton", "button", "helpButton", "splash-button", "Help"));
    loginBtn = modalFooter.appendChild(this.createHTMLLink("loginLink", ""));
    loginBtn.appendChild(this.renderButton("loginButton", "button", "loginButton", "splash-button", "Login"));
    continueBtn = modalFooter.appendChild(this.renderButton("continueButton", "button", "continueButton", "splash-continue-button", "Continue with limited access"));
}

// Cookie handling functions
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
    createCookie(name, "", -1);
}

// Functions specific to user events
function closeModal(e,container) {
    container.style.display = 'none';
}

function clickOutside(e,container) {
    if (e.target == container) {
        container.style.display = 'none';
    }
}

function continueModal(e,container) {
    container.style.display = 'none';
}

function checkboxModal() {
    // Create DoNotShowSplashPage cookie
    var valueOfSplashCookie;
    if (this.checked) {
        valueOfSplashCookie = "true";
    } else {
        valueOfSplashCookie = "false";
    }
    createCookie('doNotShowSplashPage', valueOfSplashCookie);
}
