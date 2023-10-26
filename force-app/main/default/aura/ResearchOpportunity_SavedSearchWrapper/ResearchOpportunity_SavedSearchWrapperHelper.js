/**
 * Created by burnside on 2019-05-29.
 */
({
    loadSavedUserSearch : function(component, event, helper){

        //console.log('loadSavedUserSearch');

        var action = component.get("c.getUserSavedSearch");

        action.setCallback(this, function(response) {

            var state = response.getState();

            //console.log(state);
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                console.log(data);

                if (data){
                    component.set('v.keywordsToSearch', data.keywordsToSearch);
                    component.set('v.keywordsToExclude', data.keywordsToExclude);
                    component.set("v.filters", data.filters);
                    component.set("v.useFilterLogic", data.useFilterLogic);
                    component.set("v.filterLogic", data.filterLogic);

                    if (!component.get("v.showTable")){
                        component.set("v.showTable", true);
                    }
                    else
                        component.find("dataTable").search();
                }

                component.set("v.doneLoading", true);

            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    //console.log("Unknown error");
                }

            }

            ////console.log('End of getDataList');

        });

        $A.enqueueAction(action);

    },


    openFilterModal : function(component, event, helper){

        var variables = {
            filters : component.get("v.filters"),
            keywordsToSearch : component.get('v.keywordsToSearch'),
            keywordsToExclude : component.get('v.keywordsToExclude'),
            useFilterLogic : component.getReference("v.useFilterLogic"),
            filterLogic : component.getReference("v.filterLogic"),
            showSearchButton : false,
            showLoadSearchButton : false,
            buttonVariant_saveSearch : "brand",
            label_cardTitle : "Define Search",
            label_baselineFilterCopy : component.get("v.label_baselineFilterCopy")
        }
        //console.log(variables);


        $A.createComponent("c:ResearchOpportunitySearch_SearchWidget", variables, function(content, status, errorMessage) {

               //console.log(status);

               if (status === "SUCCESS") {
                   component.find('overlayLib').showCustomModal({
                       header: component.get("v.label_buttonSetSavedSearch"),
                       body: content,
                       showCloseButton: true,
                       //cssClass: "slds-modal_medium",
                       closeCallback: function() {

                             helper.loadSavedUserSearch(component, event, helper);
                       }
                   })
               }
               else {
                //console.log('Error: '+errorMessage);
                if (!component.get("v.alreadyAlreadyOccurred"))
                    helper.openFilterModal(component, event, helper);
                else
                    component.set("v.alreadyAlreadyOccurred", true);
                }
            });

    },


    goToFullSearchPage : function(component, event, helper){

        window.location.assign("/s/my-relevant-opportunities");

    }


})