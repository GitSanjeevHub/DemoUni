({
    onInit: function(component, event, helper) {
        if (component.get("v.sortable")) {
            component.set("v.compareFunction", helper.getCompareFunction(component.get("v.sortField")));
        }
    },

    toggleSort: function(component, event, helper) {
        event.stopPropagation();
        helper.toggleSort(component);
    }
})