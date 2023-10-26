/**
 * Created by burnside on 2019-05-15.
 */
({

    doInit : function(component, event, helper){

        helper.getColumns(component, event, helper);

        helper.getDataList(component, event, helper);

    },

    prevPage : function(component, event, helper){

        component.set("v.currentPageIndex", component.get("v.currentPageIndex")-1);


        helper.getDataList(component, event, helper);
    },

    nextPage : function(component, event, helper){

        component.set("v.currentPageIndex", component.get("v.currentPageIndex")+1);

        helper.getDataList(component, event, helper);
    },


    handleRowAction : function(component, event, helper){

        //console.log('handleRowAction');
        var action = event.getParam('action');
        var row = event.getParam('row');

        //console.log(action);

        switch (action.name) {
            case 'show_details':
                helper.goToFullOpportunityRecord(component, event, helper, row);
                break;
            case 'express_interest':
                helper.expressInterest(component, event, helper, row);
                break;
            case 'recommend':
                helper.recommend(component, event, helper, row);
                break;
        }

    },

    handleSortChange : function(component, event, helper){

        //console.log('handleSortChange');
        //console.log(JSON.stringify(event.getParams()));

        var fieldName = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");

        component.set("v.orderBy", fieldName);
        component.set("v.orderDirection", sortDirection);

        helper.getDataList(component, event, helper);
    },

    handleSearchRequestFromEvent : function(component, event, helper){

        //console.log('handleSearchRequest');
        component.set("v.keywordsToSearch", event.getParam("keywordsToSearch"));
        component.set("v.keywordsToExclude", event.getParam("keywordsToExclude"));
        component.set("v.filters", event.getParam("filters"));
        component.set("v.filterLogic", event.getParam("filterLogic"));

        component.set("v.currentPageIndex", 0);

        helper.getDataList(component, event, helper);

    },

    handleSearchRequestFromParent : function(component, event, helper){
        component.set("v.currentPageIndex", 0);

        helper.getDataList(component, event, helper);

    }

})