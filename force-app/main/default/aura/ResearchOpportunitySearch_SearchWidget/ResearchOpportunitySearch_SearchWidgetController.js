/**
 * Created by burnside on 2019-05-20.
 */
({

    doInit : function(component, event, helper){

        component.set("v.filterLogicHelpText",
            "Use for more complex logic. Example: 1 OR (2 AND 3) OR (4 AND 5). "+
                 "Reference every filter once. Text search must be at least 2 characters long."+
                 "Use brackets whenever mixing ANDs and ORs e.g. '1 AND 2 OR 3' is invalid; instead use '1 AND (2 OR 3)' "+
                     "or '(1 AND 2) OR 3'");

        if (component.get("v.buttonVariant_saveSearch"))
            component.find("saveSearchButton").set("v.variant", component.get("v.buttonVariant_saveSearch"));

    },

    loadSavedSearchButtonClicked : function(component, event, helper){
        helper.loadSavedUserSearch(component, event, helper);
    },

    saveSearchButtonClicked : function(component, event, helper){
        helper.saveSearch(component, event, helper);
    },

    handleKeyDown : function(component, event, helper){
        let enterButtonPressed = event.which === 13;
        
        if (enterButtonPressed)
            helper.search(component, event, helper);
    },
    
    searchButtonClicked : function(component, event, helper){
        helper.search(component, event, helper);
    },

    addFilterButtonClicked : function(component, event, helper){
        helper.addFilter(component, event, helper);
    },

    handleFilterDelete : function(component, event, helper){
        helper.deleteFilter(component, event, helper);
    },

    clearSearchButtonClicked : function(component, event, helper){
        helper.clearAllSearchData(component, event, helper);
    }
})