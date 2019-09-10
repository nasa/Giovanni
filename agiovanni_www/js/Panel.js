/*
 * Panel.js,v 1.0 2014/03/18 19:53:39 kbryant Exp $
 * -@@@ aGiovanni, $Name:  $
 * 
 * Creates a panel, generally a popup, in which to put content
 */

giovanni.namespace('giovanni.ui.Panel');

/**
 * Constructor
 * 
 * @constructor
 * @this {giovanni.ui.Panel}
 * @param {String, containerId}
 * @returns {giovanni.ui.Panel}
 * @author K. Bryant
 */
giovanni.ui.Panel = function (config){
  this.config = config ? config : null;
  this.containerId = this.config.containerId ? this.config.containerId : null;
  this.associateId = this.config.associateId ? this.config.associateId : null;
  this.headerStr = this.config.headerStr ? this.config.headerStr : "";
  this.footerStr = this.config.footerStr ? this.config.footerStr : "";
  this.headerClass = this.config.headerClass ? this.config.headerClass : "";
  this.footerClass = this.config.footerClass ? this.config.footerClass : "";
  this.contentClass = this.config.contentClass ? this.config.contentClass : "";
  this.topMargin = this.config.topMargin ? this.config.topMargin : "10";
  this.leftMargin = this.config.leftMargin ? this.config.leftMargin : "0";
  this.content = null;
  this.header = null;
  this.footer = null;
  this.master = null;
  this.inPanel = false;
  this.hideTimeout = null;
  this.showTimeout = null;
  this.render();
}

giovanni.ui.Panel.prototype.render = function () {
  var container = document.getElementById(this.containerId);
  this.master = document.createElement('div');
  this.master.setAttribute('class','popup');
  container.appendChild(this.master);
  if(this.headerStr){
    this.header = document.createElement('div');
    this.header.setAttribute('class','popupHeader');
    var headerLbl = document.createElement('div');
    headerLbl.setAttribute('class','popupLabel');
    headerLbl.innerHTML = this.headerStr;
    var closeBtn = document.createElement('div');
    closeBtn.setAttribute('class','popupCloseBtn');
    closeBtn.innerHTML = 'X';
    this.header.appendChild(headerLbl);
    this.header.appendChild(closeBtn);
    this.master.appendChild(this.header);
  }
  this.content = document.createElement('div');
  this.content.setAttribute('class','popupContent ' + this.contentClass );
  this.master.appendChild(this.content);
  if(this.footerStr){
    this.footer = document.createElement('div');
    this.footer.innerHTML = this.footerStr;
    this.master.appendChild(this.footer);
  }
  YAHOO.util.Event.addListener(container,'mouseenter',this.setInPanel,{},this);
  YAHOO.util.Event.addListener(container,'mouseleave',this.startHideCheck,{'inPanel':false},this);
  YAHOO.util.Event.addListener(closeBtn,'click',this.hide,{},this);
  
  YAHOO.util.Event.addListener(container,'keypress',this.handleKeyboardEvents,{},this);

  YAHOO.util.Event.addListener(container,'focusin',this.setInPanel,{},this);

}

giovanni.ui.Panel.prototype.addElement = function (elem) {
  this.content.appendChild(elem);
}

giovanni.ui.Panel.prototype.show = function (e,o) {
    // set the 'inPanel' flag
    this.inPanel = (o!=null && o.inPanel!=null) ? o.inPanel : false;
    // show the panel
    this.master.setAttribute('class','popup popupVisible');
    // attempt to update panel location 
    var targ = e ? giovanni.util.getTarget(e) : undefined;
    if(targ){
        var targBbox = targ.getBoundingClientRect();
        this.master.parentNode.style.top = targBbox.bottom - parseInt(this.topMargin) + 'px';
        this.master.parentNode.style.left = targBbox.left - parseInt(this.leftMargin) + 'px';
    }else{
        console.log("giovanni.ui.Panel.show:  target was null so cannot update panel location");
    }
}

giovanni.ui.Panel.prototype.forceHide = function (e,o) {
    var targ = null;
    var parentNode = null;
    if(e!=undefined) targ = giovanni.util.getTarget(e);
    if(targ!=null) parentNode = targ.parentNode;
    //if (e == null || e.type != 'click' ||
    //    (e.type=='click' && parentNode.getAttribute('class')=='popupContent'))
    if (e == null || e.type != 'click') 
        this.hide();
    clearTimeout(this.hideTimeout);
    //if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
}

giovanni.ui.Panel.prototype.hide = function () {
    this.inPanel = false;
    this.master.setAttribute('class','popup');
}

/*
 * Handle the mouseover interaction between a control and it's panel - 
 * time when to hide the panel
 */
giovanni.ui.Panel.prototype.startHideCheck = function (e,o) {
  // set time to check 'inPanel'; if not 'inPanel' by time up, hide the panel
  if(o.inPanel!=null) this.inPanel = o.inPanel;
  this.hideTimeout = window.setTimeout(
    function (x) {
      return function () {
        if(!x.isInPanel()){
          x.hide();
        }
      };
    }(this),
  100 );
  if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
}
/*
 * Is the cursor in the panel?
 */
giovanni.ui.Panel.prototype.isInPanel = function () {
  return this.inPanel;
}
/*
 * Set whether the cursor is over the panel
 */
giovanni.ui.Panel.prototype.setInPanel = function (e,o) {
  this.inPanel = true;
  if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
}

giovanni.ui.Panel.prototype.isVisible = function () {
  return this.master.getAttribute('class').indexOf('Visible')>-1;
}

giovanni.ui.Panel.prototype.handleKeyboardEvents = function (e,o) {
  var kc = e.keyCode;
  if(kc == 13){
    this.inPanel = false;
    this.hide();
  }
  if(e!=undefined) YAHOO.util.Event.stopPropagation(e);
}
