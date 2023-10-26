/**
 * Created by burnside on 2019-05-20.
 */
({

    doInit : function(component, event, helper){
        console.log('doInit '+component.get("v.filter.index"));

        helper.setFilterSelectionOptions(component, event, helper);

        helper.mapFilterTypeBasedOnFilterSelection(component, event, helper);

        helper.renderOperatorsByUserSelectedFilterType(component, event, helper);

        helper.setUIBasedOnValues(component, event, helper);

    },

    handleFilterSelectionChange : function(component, event, helper){
        console.log('handleFilterSelectionChange');

        component.set("v.displayValue", null);
        
        helper.mapFilterTypeBasedOnFilterSelection(component, event, helper);

        helper.renderOperatorsByUserSelectedFilterType(component, event, helper);

        helper.writeUserFilterPreferencesToJson(component, event, helper);
    },

    /*handleFilterTypeChange : function(component, event, helper){

        console.log('handleFilterTypeChange '+component.get("v.filter.index"));
        helper.renderOperatorsByUserSelectedFilterType(component, event, helper);

        component.set("v.displayValue", null);
    },*/

    handleFilterOperatorChange : function(component, event, helper){
        console.log('handleFilterOperatorChange '+component.get("v.filter.index"));
        
        helper.writeUserFilterPreferencesToJson(component, event, helper);
    },

    handleLookupValueChange : function(component, event, helper){
        console.log('handleLookupChange '+component.get("v.filter.index"));

        component.set("v.displayValue", component.get("v.lookupValue"));
        helper.writeUserFilterPreferencesToJson(component, event, helper);
    },

    handlePicklistValueChange : function(component, event, helper){
        console.log('handlePicklistValueChange '+component.get("v.filter.index"));
        console.log(JSON.stringify(event));

        component.set("v.displayValue", event.getParam("value"));
        helper.writeUserFilterPreferencesToJson(component, event, helper);
    },

    handleFilterValueChange : function(component, event, helper){
        console.log('handleFilterValueChange '+component.get("v.filter.index"));
        helper.writeUserFilterPreferencesToJson(component, event, helper);
    },

    handleRemoveFilter : function(component, event, helper){

        var cmpEvent = component.getEvent("filterDelete");
        cmpEvent.setParam("index",component.get("v.filter.index"));
        cmpEvent.fire();

    },



})