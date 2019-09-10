/* 
 * Establish the giovanni widget namespace 
 */
giovanni.namespace("widget");

/**
 * Create a toolbar container for form elements like buttons; 
 * presents form elements, described in the config object,
 * in a toolbar (horizontal) layout
 * 
 * @constructor
 * @this {Giovanni.widget.Toolbar}
 * @param {String, Configuration}
 * @returns {giovanni.widget.Toolbar}
 * @author K. Bryant
 * @example : 
 *     var config = [
 *               {'type':'button','name':'plot','label':'Plot Data',
 *                       'title':'To generate a plot, fill out the form above and click this button!',
 * 			 'action':REGISTRY.getComponent('session').getData,'source':this,'cssClass':'appPlotButton'},
 *               {'type':'button','name':'reset','label':'Reset',
 *                       'title':'Reset selections to their defaults',
 *			 'action':this.resetSelections,'source':this},
 *               {'type':'button','name':'clear','label':'Clear',
 *                       'title':'Clear selections',
 *			 'action':this.selections,'source':this},
 *               {'type':'button','name':'feedback','label':'Send Us Feedback!',
 *                       'title':'Was there a problem with the portal?  Want to suggest a feature?  Please tell us!',
 *			 'action':this.sendFeedback,'args':{'page':'criteria'},'source':this},
 *               {'type':'button','name':'help','label':'Help',
 *                       'title':'Get Help!',
 * 			 'action':REGISTRY.getComponent('session').showHelp,'source':this}
 *     var id = 'toolbarContainer';
 *     var toolbar = new giovanni.widget.Toolbar(id,config);
 */
giovanni.widget.Toolbar = function (containerId,url,config) {
	/* set the incoming id to a class member */
	this.containerId = containerId;
	/* container element */
	this.container = undefined;
        
	/* set the container element */
	if(this.containerId==null||this.containerId==""){
		this.container = document.body;
	}else{
		this.container = document.getElementById(this.containerId);
	}
        //this.container.appendChild(this.panel);
	this.dataSourceUrl = url;
	/* set the incoming config to a class member */
	this.config = config==null ? [] : config;
	/* set the CSS class ref */
	this.className = config.className != null ? config.className : "";
	/* provide a place for form elements to be registered as belonging to the toolbar */
	this.controls = [];
	/* render the toolbar given the items specified in the config object */
	this.render();		
};

/**
 * Render the toolbar with it's form elements
 * 
 * @this {giovanni.widget.Toolbar}
 * @author K. Bryant
 */
giovanni.widget.Toolbar.prototype.render = function () {
        /* add required footer content */
        $('#'+this.containerId).html( giovanni.footer.getHTMLContent() );
	/* loop through the config and add the elements found */
	var obj;
	for ( var i=0; i < this.config.length; i++){
		if(this.config[i] instanceof Object){
			obj = this.config[i];
			// only handles button elements for the moment
			// a TODO would be to add other form elements and handle them appropriately;
			// drop-down lists and text fields are probably the next candidates
			if(obj.type=="button"){
				this.addControl(obj);
			}else if(obj.type=="link"){
				this.addControl(obj);
			}
		}
	}
	/* set the CSS class on the container */
	$('#'+this.containerId).addClass(this.className);
};

/**
 * Add a control - figures out what kind of control it is and then calls the appropriate method
 *
 * @this {giovanni.widget.Toolbar}
 * @param {obj}
 * @author K. Bryant 
 */
giovanni.widget.Toolbar.prototype.addControl = function (o) {
	var type = o.type != null ? o.type : "button";
	switch(type){
		case "button":
			this.addButton(o);
			break;
		case "link":
			this.addLink(o);
			break;
		default:
			alert("Don't know this Toolbar control type: "+o.type);
	}
};

/**
 * Add a button to the toolbar
 *
 * @this {giovanni.widget.Toolbar}
 * @param {Object}
 */
giovanni.widget.Toolbar.prototype.addButton = function (o) {
	// Handle arguments to pass to the method the button uses
	var argsToPass = {
		"self":o.source
	};
	if(o.args!=null){
		for(var name in o.args){
			argsToPass[name] = o.args[name];
		}
	}
	// Create the button with toolbar div tag as the container;
	// automatically adds the button to the toolbar
	var b = giovanni.util.createButton(
                this.containerId+o.name+"BTN",
                this.containerId,
                o.label,
                o.title!=""?o.title:o.label,
                { fn: o.action, obj: argsToPass, scope: o.source }

        );
	// Set the CSS class
	b.addClass(o.cssClass);
	// Set disabled condition
	b.set("disabled",o.disabled);
	// Add the button to the toolbar registry
	this.addToRegistry(o.name,b);
};

giovanni.widget.Toolbar.prototype.addLink = function (o) {
	var link = document.createElement('a');
        // Handle arguments
        var argsToPass = {
                "self":o.source
        };
        if(o.args!=null){
                for(var name in o.args){
                        argsToPass[name] = o.args[name];
                }
        }
	link.setAttribute('id',o.name);
	link.setAttribute('class',o.cssClass);
	link.setAttribute('title',o.title);
	link.setAttribute('href',o.args['url']);
	link.setAttribute('target',o.args['target']);
	if(o.args['newWindow']){
	    link.setAttribute('onclick','');
	}
	link.innerHTML = o.label;
	
	this.container.appendChild(link);
}

/**
 * Add a control element to the toolbar registry
 *
 * @this {giovanni.widget.Toolbar}
 * @param {String,Object}
 * @author K. Bryant
 */
giovanni.widget.Toolbar.prototype.addToRegistry = function (name,obj) {
	this.controls[name] = obj;
};

/**
 * Get the specific control element from the toolbar registry given a name
 *
 * @this {giovanni.widget.Toolbar}
 * @params {String}
 * @returns {Object} a control element (e.g., a button)
 * @author K. Bryant
 */ 
giovanni.widget.Toolbar.prototype.getControl = function (name) {
	return this.controls[name];
};

giovanni.widget.Toolbar.prototype.getControls = function () {
	return this.controls;
};
