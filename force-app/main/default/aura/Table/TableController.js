({
    onInit: function(component, event, helper) {
        helper.linkColumns(component);
        helper.rebuildRows(component);
    },

    appendRows: function(component, event, helper) {
        helper.appendRows(component, event.getParam("arguments").items);
    },

    onRebuild: function(component, event, helper) {
        helper.linkColumns(component);
    },

    onFilter: function(component, event, helper) {
        helper.updateFilter(component);
    },

    onItemsChange: function(component, event, helper) {
        if (!component.get("v.suspendRowRebuild")) {
            helper.rebuildRows(component);
        }
    },

    updateSort: function(component, event, helper) {
        event.stopPropagation();
        helper.applySort(component, event.getParam("compareFunction"), event.getParam("sortOrder"), event.getParam("column"));
    },

    manualSort: function(component, event, helper) {
        helper.applySort(component, event.getParam("arguments.compareFunction"), event.getParam("arguments.sortOrder"), event.getParam("arguments.column"))
    }
})