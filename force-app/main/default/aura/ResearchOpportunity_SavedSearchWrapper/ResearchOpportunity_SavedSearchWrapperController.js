/**
 * Created by burnside on 2019-05-29.
 */
({
    doInit : function(component, event, helper){
        helper.loadSavedUserSearch(component, event, helper);

        //helper.setupNavigationToSearchPageButton(component, event, helper);
    },

    setupDefaultSearchClicked : function(component, event, helper){
        helper.openFilterModal(component, event, helper);
    },

    goToSearchPageButtonClicked : function(component, event, helper){
        helper.goToFullSearchPage(component, event, helper);
    }
})