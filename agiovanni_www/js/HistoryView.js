/**
 * $Id: HistoryView.js,v 1.43 2015/06/09 15:05:34 kbryant Exp $
 * -@@@ aGiovanni, $Name:  $
 * 
 * Creates a view of the giovanni.app.History. It renders the 
 * snapshot of the Giovanni History which includes all Results 
 * in a session.
 */

giovanni.namespace('giovanni.ui.HistoryView');

/**
 * Constructor
 * 
 * @constructor
 * @this {giovanni.ui.HistoryView}
 * @param {String, containerId}
 * @returns {giovanni.ui.HistoryView}
 * @author M. Hegde
 */
giovanni.ui.HistoryView = function (containerId,historyObj)
{
    // Save ID of the container
    this.containerId = containerId;
    // Save the History object
    this.historyObject = historyObj;
    // An associative array to hold tree nodes for results; keys are result IDs and values
    // are tree nodes
    this.resultNodeList = {};
    // An associative array to hold current selection
    this.curSelection = { id:null, context:null };
    // A flag to indicate whether the tree has been rendered (should happen only once)
    this.renderFlag = false;

    // By default, the render type is 'tree'
    this.renderType = 'tree';
    if ( window.browserChecker && window.browserChecker.name === 'Firefox' ){
        // On Firefox, render type is 'list'
        this.renderType = 'list';
    }   
    // Create a custom event, 'ResultSelectionEvent', to be triggered when user
    // selects a result
    this.resultSelectionEvent=new YAHOO.util.CustomEvent("ResultSelectionEvent");
    // Create a string array to hold labels for sub nodes of a result node
    this.subNodeLabels = 
        ['User Input', 'Plots', 'Downloads', 'Lineage', 'Debug'];
    
    // Create a tool tip objective array to hold tool tips
    this.toolTip = { 
                    Result: "Click to obtain status.",
              'User Input': "View/edit user input",
                     Plots: "Click to display plots", 
            'Plot Options': "Click to edit options used to render plots",
                 Downloads: "Click to display links to data files ready for downloading", 
                   Lineage: "Click to display data lineage",
                   Debug: "Click to view session files"
                   };
    // At last, render the tree
    this.render();
};

/**
 * Renderer for HistoryView: creates root node of the history tree
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {}
 * @returns {}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.render = function()
{
    // Allow rendering only once
    if ( this.renderFlag ) {
        return;
    }
    // Carve out containers for a title and a tree
    var parentDiv = YAHOO.util.Dom.get(this.containerId);
    var treeDiv = new YAHOO.util.Element(document.createElement('div'));
    treeDiv.set( 'id', this.containerId+'HistoryTree' );
    // Add tree node to the DOM so that they show up
    parentDiv.appendChild(treeDiv.get('element'));  
    var titleId = this.containerId + 'HistoryTreeTitle';
    if (this.renderType === 'list' ) {
        // Create a span to display title
        var titleSpan = document.createElement('div');
        titleSpan.setAttribute('id',titleId);
        titleSpan.setAttribute('class','historyViewTitle');
        titleSpan.appendChild(document.createTextNode('Browse History'));
        parentDiv.appendChild(titleSpan);
        this.rootNode = document.createElement('ul');
        this.rootNode.setAttribute('id', this.containerId + 'HistoryViewList');
        this.rootNode.setAttribute('class','historyViewList');
        parentDiv.appendChild(this.rootNode);
    } else if ( this.renderType === 'tree'){
        // Create an empty YUI tree
        this.historyTree = new YAHOO.widget.TreeView(treeDiv);
        this.historyTree.singleNodeHighlight = true;
        // Create a root node that also serves for displaying tree title
        var rootStr = "<div id='" + titleId + "' class='historyViewTitle'>Browse History</div>";
        this.rootNode = new YAHOO.widget.HTMLNode(rootStr, this.historyTree.getRoot(), false);
        // Clicking a node fires a 'ResultSelectionEvent'
        // Subscribe to events on tree nodes
        this.historyTree.subscribe("clickEvent", function(args) {
            var node = args.node;
            // if the event target is the delete icon and the user confirms,
            // set the delete flag to true and pass it along
            var deleteFlag = false;
            if (args.event.target.id === 'del'+node.data.value.id) {
                deleteFlag =
                    confirm("Are you sure you want to permanently delete this plot?") ? true : false;
                if (deleteFlag) {
                    if ( node.data.value && node.data.value.type ) {
                        node.data.value.resultSelectionEvent.fire({ id:node.data.value.id, type:'Delete' });
                        return false;
                    }
                } else {
                    return false;
                }
            } else {
                // Highlight tree node that is selected unless it is 'User Input' node
                if ( node.data.value.type != 'User Input') {
                    if ( node.data.value.hasOwnProperty("self") ) {
                        var self = node.data.value.self;
                        // Set the proper context by highlighting/un-highlighting nodes
                        self.setContext(node.data.value.id, node.data.value.type);
                    }
                }
                 // if we're not deleting the node, store it for later reference during reloading of session
                if (typeof(Storage) !== "undefined") {
                    var user = sessionManager.getUser() ? sessionManager.getUser() : giovanni.util.getGuest();
                    sessionStorage.setItem(user+'CurrentResult', JSON.stringify({
                        'id':node.data.value.id,
                        'type':node.data.value.type,
                        'criteria':node.data.value.self.resultNodeList[node.data.value.id].node.data.value.result.criteria.query[0].value
                    }));
                }
                // Fire the result selection event
                node.data.value.resultSelectionEvent.fire({ id: node.data.value.id, type: node.data.value.type });
                return (node.data.value.type=='Status' ? false : true);

            }
        });
        // Render the YUI TreeView
        this.historyTree.render();
    }    
    // Once rendered, set the renderFlag
    this.renderFlag = true;
};

/**
 * Handles click events in the result node of history tree 
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {YAHOO.util.Event, eventData}
 * @returns {false}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.resultClickHandler = function(e,obj)
{
    // Stop event propagation
    YAHOO.util.Event.stopEvent(e);
    // set delete flag
    var deleteFlag = false;
    if (e.target.id === 'del'+obj.id) { 
        deleteFlag = confirm("Are you sure you want to permanently delete this plot??") ? true : false;
        if (deleteFlag) {
            obj.resultSelectionEvent.fire({id: obj.id, type: 'Delete'});
        }
        return false;
    } else {
        // Fire the result selection event
        obj.resultSelectionEvent.fire({id: obj.id, type: obj.type});
        // Highlight the selected leaf
        if ( obj.hasOwnProperty("self")) {
            var self = obj.self;
            self.setContext(obj.id, obj.type);
        }
        // Store the selected node in sessionStorage
        // unless the node is being deleted
        if (typeof(Storage) !== "undefined") {
            var user = sessionManager.getUser() ? sessionManager.getUser() : giovanni.util.getGuest();
            var results = obj.self.historyObject.results;
            for (var i=0;i<results.length;i++) {
                if (results[i].id === obj.id) {
                    sessionStorage.setItem(user+'CurrentResult', JSON.stringify({
                        'id':obj.id,
                        'type':obj.type,
                        'criteria':results[i].criteria ? results[i].criteria.query[0].value : ''
                    }));
                    break;
                }
            }
        }
    }
    // Prevent further propagation of events
    return false;
};
/**
 * Adds a result to list view of history
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {giovanni.app.Result, result}
 * @returns {}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.createResultListNode = function(result)
{
    // A function to create a hyperlink element
    var hyperLink = function(id, label, title, data){
        var deleteIcon = document.createElement('i');
        deleteIcon.setAttribute('id','del'+result.getId());
        deleteIcon.setAttribute('class','fa fa-times historyItemDel');
        deleteIcon.setAttribute('title','Delete plot');
        deleteIcon.style = "display:inline-block";
        var link = document.createElement('a');
        link.appendChild(deleteIcon);
        link.appendChild(document.createTextNode(label));
        link.setAttribute('href','#');
        link.setAttribute('title',title);
        link.setAttribute('id',id);
        return link;
    };  

    // Get the result ID
    var id = result.getId();
    // Get the result title
    var title = result.getIndex() + ".  " + result.getTitle().replace('*','');
    // set the doc title since this is what we're working on...
    document.title = "Giovanni - "+title;
    // Get the reuslt description
    var descr = result.getDescription();
    // The result node is rendered as list item
    var resultNode = document.createElement('li');
    resultNode.setAttribute('id',id);
    var toolTip = RegExp(/\S+/).test(descr) ? descr: this.toolTip.Result;
    // Data passed to the event handler
    var eventData = { self:this, node:resultNode, id:id, type:'Status', resultSelectionEvent:this.resultSelectionEvent };
    var linkId = id + 'ResultLink';
    resultNode.appendChild(hyperLink(linkId, title, toolTip, eventData));
    YAHOO.util.Event.addListener(linkId,'click',giovanni.ui.HistoryView.resultClickHandler,eventData);
    YAHOO.util.Event.addListener('del'+id,'click',giovanni.ui.HistoryView.resultClickHandler,eventData);
    // Append the newly created result node
    if ( this.rootNode.childNodes.length ) {
        // Append before existing results
        this.rootNode.insertBefore(resultNode,this.rootNode.childNodes[0]);
    }else{
        this.rootNode.appendChild(resultNode);
    }
    // Create all options under a result node in history tree; they are not sensitive to begin
    // with.
    var resultOptionsNode = document.createElement('ul');
    resultOptionsNode.setAttribute('class','historyItem');
    for ( var j=0, nodeCount=this.subNodeLabels.length; j<nodeCount; j++ ){
        var subNode = document.createElement('li');
        subNode.setAttribute('class','historyItem');
        var label = this.subNodeLabels[j];
        // check label values; if 'Debug', only render if there is a debug url
        if (label != "Debug" || (label == "Debug" && result.getDebugUrl())) {
          subNode.appendChild(document.createTextNode(label));
          resultOptionsNode.appendChild(subNode);
        }
    }
    resultNode.appendChild(resultOptionsNode);
    return resultNode;
};

/**
 * Adds a result to tree view of history
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {giovanni.app.Result, result}
 * @returns {}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.createResultTreeNode = function(result)
{
    // Get the result ID
    var id = result.getId();
    // If the result node exists already, nothing else to do
    if ( this.resultNodeList[id] ) {
        return;
    }
    // Get the first result node if one exists as new result node is always made
    // the first child
    var firstNode = this.rootNode.hasChildren() ? this.rootNode.children[0] : null;
    
    var label = result.getIndex() + ".  " + result.getTitle().replace('*','');
    // Set the doc title since this is what Giovanni is currently processing
    document.title = "Giovanni - "+label;
    var descr = result.getDescription();
    var title = RegExp(/\S+/).test(descr) ? descr : this.toolTip.Result;
    // Configuration for the tree node to be created
    var nodeConfig = { 
            label:label,
            editable:true,
            expanded:true,
            value:{ id:id, type:'Status', result:result, resultSelectionEvent:this.resultSelectionEvent, self:this }, 
            title:title,
            html: '<i id="del'+id+'" class="fa fa-times historyItemDel" style="display:inline-block;" title="Delete plot"></i><div class="historyItemLabel" title="'+title+'">'+label+'</div>'
     };
    // Create a YUI text node
    var resultNode = new YAHOO.widget.HTMLNode( nodeConfig, this.rootNode );
    // Insert the new node as the first child tree root     
    if ( firstNode !== null ) {
        this.historyTree.popNode(resultNode);
        resultNode.insertBefore(firstNode);
    }
    // this.setContext(id, 'Status');
    // Expand the new node by default
    resultNode.expand();
    // Refresh the tree and keep it expanded by default
    resultNode.parent.refresh();
    resultNode.parent.expand();
    return resultNode;
};

/**
 * Adds a result to the view (tree or list) of history
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {giovanni.app.Result, result}
 * @returns {Boolean}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.addResultNode = function(result) {
    // If the tree has not been created, don't proceed further
    if ( !this.renderFlag ){
        return false;
    }
    // If the result is not defined, nothing else to do 
    if ( !result ){
        return false;
    }
    // Get the result ID
    var id = result.getId();
    // If the result ID is not found, can't proceed further
    if ( !id ){
        return false;
    }
    // Subscribe to result update events
    result.resultUpdateEvent.subscribe(this.updateResultNode,{result:result, self:this});
    // Creation of DOM elements for the result are postponed until result events
    // start firing. This is because result title/description are not ready at the start
    return true;
};


/**
 * Updates the result node in response to ResultUpdateEvent
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {String,"ResultUpdateEvent"}
 * @param {Array,[]}
 * @param {Object,{result:giovanni.app.Result, self:giovanni.ui.HistoryView}}
 * @returns {}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.updateResultNode = function(type, args, listenerData)
{
    var self=listenerData.self;
    // A function to create a hyperlink element
    var hyperLink = function(id, label, title, data){
        var link = document.createElement('a');
        link.appendChild(document.createTextNode(label));
        link.setAttribute('href','#');
        link.setAttribute('title',title);
        link.setAttribute('id',id);
        return link;
    };  

    self.restoreFlag = (args.length > 0 && args[0].restore) ? args[0].restore : false;

    var result = listenerData.result;
    var id = result.getId();

    // if this is a new result, not a restoration,
    // store it as the current result
    if (!self.restoreFlag && typeof(Storage) !== "undefined") {
        var user = sessionManager.getUser() ? sessionManager.getUser() : giovanni.util.getGuest();
        sessionStorage.setItem(user+'CurrentResult', JSON.stringify({
            id: id,
            type: 'Status',
            criteria: result.criteria.query[0].value
        }));
    }

    var resultNode = self.resultNodeList[id];
    // Get the result status code
    var code = result.getStatus().getCode();
    // create dom node
    if ( self.resultNodeList[id] == null ) {
        var domNode=null;
        if ( self.renderType === 'list') {
            domNode=self.createResultListNode(result);
        }else if ( self.renderType === 'tree'){
            domNode=self.createResultTreeNode(result);
        }else{
            return;
        }
        // Store the newly created result node
        self.resultNodeList[id] = { node:domNode, subNodeList:{ 'Status':domNode } };
        resultNode = self.resultNodeList[id];
        // set the context
        self.setContext(id,'Status');
    }
    // Get the DOM element for the result node
    var node = resultNode.node;
    // If the workflow was canceled (or the result was 'deleted'), remove the result from tree and return
    if ( code == -1 || (code > 0 && result.getStatus().getMessage().indexOf('cancel') > -1) ) {
        switch ( self.renderType ) {
            case 'list' :
                node.parentNode.removeChild(node);
                break;
            case 'tree' :
                var parent=node.parent;
                self.historyTree.removeNode(node);
                parent.refresh();
                break;
        }
        return;
    }
    for ( var j=0, nodeCount=self.subNodeLabels.length; j<nodeCount; j++ ){
        var label = self.subNodeLabels[j];
        // If the sub-node has been realized, nothing else needs to be done
        if ( resultNode.subNodeList[label] ){
            continue;
        }
        // Check whether the result has the necessary info for display
        var flag = false;
        switch (label){
            case 'User Input':
                flag = result.hasCriteria();
                break;
            case 'Plots':
                flag = result.hasPlots();
                break;
            case 'Plot Options':
                flag = result.hasPlotOptions();
                break;
            case 'Downloads':
                flag = result.hasData();
                break;
            case 'Lineage':
                flag = result.hasLineage();
                break;
            case 'Debug':
                flag = result.getDebugUrl();
                if (flag && self.renderType == 'list') self.restoreDebugNode(node); 
                break;
            default:
                break;
         }
        // If the sub-node is not ready to be shown, skip rest of the logic
        if ( !flag ){
            continue;
        }
        var linkId = (id + label).replace(/\s+/g,'');
        // Event data
        var eventData = { self:self, id:id, type:label, resultSelectionEvent:self.resultSelectionEvent };
        switch ( self.renderType ) {
            case 'list':
                // Handle the 'list' rendering case
                var subHtmlNodes=node.childNodes[1].childNodes;
                var toolTip = self.toolTip[self.subNodeLabels[j]];
                var link = hyperLink(linkId, label, toolTip, eventData);
                // Replace existing options: delete all followed by appending the new link
                for ( var k=0; k<subHtmlNodes[j].childNodes.length; k++){
                    subHtmlNodes[j].removeChild(subHtmlNodes[j].childNodes[k]);
                }
                subHtmlNodes[j].appendChild(link);
                YAHOO.util.Event.addListener(linkId,'click',giovanni.ui.HistoryView.resultClickHandler,eventData);
                self.resultNodeList[id].subNodeList[label] = subHtmlNodes[j];
                self.enableDeleteIcon(self.historyObject.getResultById(node.id));
                console.log('HV.update, passed enable delete');
                break;
             case 'tree':
                var nodeConfig = { label:label, title:self.toolTip[self.subNodeLabels[j]], value:eventData };
                var numLeaf=node.children.length;
                var leaf=new YAHOO.widget.TextNode( nodeConfig, node);
                // Re-order leaves based on their expected order of appearance
                if ( numLeaf > j){
                        leaf.insertBefore(node.children[j]);
                }else if ( numLeaf < j ) {
                    for ( var k=0; k<numLeaf; k++ ){
                        if ( node.children[k].data.value.index > j ){
                            leaf.insertBefore(node.children[k]);
                        }
                    }
                }
                node.parent.refresh();
                node.parent.expand();
                self.resultNodeList[id].subNodeList[label] = leaf;
                if (node.depth && node.depth === 1)
                    self.enableDeleteIcon(node.data.value.result);
                break;
        }
    }
};

/**
 * Sets the context/focus given a result ID
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {String,resultId}
 * @param {String,context}
 * @returns {Boolean}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.setContext = function(resultId, context)
{
    if ( this.curSelection.hasOwnProperty('id') ) {
        // Reset the current selection
        var curId = this.curSelection.id ;
        var curContext = this.curSelection.context;
        var curNode = curId ? (this.resultNodeList[curId] ? this.resultNodeList[curId].subNodeList[curContext] : null ) : null;
        if ( curNode ) {
            switch ( this.renderType ) {
                case 'list':
                    // List based rendering
                    var itemNode = curNode.childNodes[0];
                    var className = itemNode.className;
                    //className = className.replace("historyItemSelected", "historyItem" );
                    //className = className.replace(/\s+$/, "");
                    className = "";
                    itemNode.className = className;
                    //itemNode.parentNode.className = className;
                    //$('#'+resultId+'ResultLink').css('font-weight','normal');
                    break;
                case 'tree':
                    // YUI Tree type rendering
                    curNode.contentStyle = "";
                    if(curNode.parent){
                        var parentLabel = $('#'+curNode.parent.labelElId);
                        parentLabel.css('font-weight','normal');
                        curNode.parent.refresh();
                    }
                    break;
            }
            // Reset the current selection
            this.curSelection = { id:null, context:null };
        }
    }
    // Set the new selection
    var node = this.resultNodeList[resultId] ? this.resultNodeList[resultId].subNodeList[context] : null;
    if ( node ) {
        switch ( this.renderType ) {
            case 'list':
                // List based rendering
                var itemNode = node.childNodes[0];
                itemNode.className = "historyItemSelected";
                break;
            case 'tree':
                // YUI Tree type rendering
                node.contentStyle = node.contentStyle + " historyItemSelected";
		if(node.parent !== null){
                        var parentLabel = $('#'+node.parent.labelElId);
                        parentLabel.css('font-weight','bold');
                	node.parent.refresh();
                }
                break;
            default:
                return false;
                break;
        }
        // Set the current selection
        this.curSelection = { id:resultId, context:context };
        return true;
    }
    return false;
};

/**
 * Gets the context/focus; returns an array whose elements are the result ID and the context of selected result
 * 
 * @this {giovanni.ui.HistoryView}
 * @param {}
 * @returns {Associative Array}
 * @author M. Hegde
 */
giovanni.ui.HistoryView.prototype.getContext = function()
{
    return this.curSelection;
};

/**
 * Enable (make visible) the delete icon if the result is complete; hide it (display:none)
 * if the result is not complete
 **/
giovanni.ui.HistoryView.prototype.enableDeleteIcon = function (result) {
  var delElm = document.getElementById('del'+result.getId());
  if (delElm) {
    var percent = parseFloat(result.status.percentComplete);
    var code = parseInt(result.status.code);
    delElm.style.display = (percent === 100 || code < 0 || code >= 1) ? "inline-block" : "none";
  } else {
    console.log("HistoryView.enableDeleteIcon():  no element for " + result.getId());
  }
}

giovanni.ui.HistoryView.prototype.clear = function () {
  if (this.historyObject) {
    var results = this.historyObject.results;
    if (results.length > 0) {
      var result;
      for (var i=0;i<results.length;i++) {
        // unsubscribe for updates to each result
        result = results[i];
        if (result && result.queryData) {
          result.resultUpdateEvent.unsubscribeAll();
        }
      }
      var self = this;
      // remove the nodes from the tree/list
      for (var key in self.resultNodeList) {
        var node = self.resultNodeList[key].node;
        switch ( self.renderType ) {
          case 'list' :
                var parent=node.parentNode;
                if (parent) {
                  parent.removeChild(node);
                }
                break;
            case 'tree' :
                var parent=node.parent;
                if (parent) {
                  self.historyTree.removeNode(node);
                  parent.refresh();
                }
                break;
        }
      }
      // establish a new result node list
      self.resultNodeList = {};
      // clear the results in the history object (giovanni.app.History)
      self.historyObject.clear();
    }
  }
}

/*
 * Used to restore debug nodes if necessary. 
 * This function checks for the existence of a node 
 * containing the text "Debug", and if it doesn't find one, it adds one
 */
giovanni.ui.HistoryView.prototype.restoreDebugNode = function (node) {
  var debugElem = false;
  var subHtmlNodes=node.childNodes[1].childNodes;
  var debugLabel = this.subNodeLabels[4];
  var label;
  for ( var k=0; k<subHtmlNodes.length; k++){
    var label = subHtmlNodes[k].textContent;
    if (label === debugLabel) {
       debugElem = true;
       break;
    }
  }
  if (!debugElem) {
    var li = document.createElement('li');
    li.setAttribute('class','historyItem');
    li.appendChild(document.createTextNode(debugLabel));
    node.childNodes[1].appendChild(li);
  }
}

giovanni.ui.HistoryView.prototype.setContextUsingCriteria = function (storedResult) {
  var result;
  var compCriteria = storedResult ? storedResult.criteria : undefined;
  if (compCriteria) {
    for (var idx in this.historyObject.results) {
      result = this.historyObject.results[idx];
      if (result.criteria.query[0].value === compCriteria) {
        this.setContext(result.id,storedResult.type); 
        this.resultSelectionEvent.fire({ id:result.id, type:storedResult.type });
        break;
      }
    }
  } else { // set the default
    var count = this.historyObject.results.length - 1;
    var resultId = this.historyObject.results[count].id;
    this.setContext(resultId,'Status');
    this.resultSelectionEvent.fire({ id:resultId, type:'Status' });
  }
}
