({
	runSearch : function(component, event, helper){
        var action = component.get("c.getPotentialDuplicateFunders");
        action.setParams({ searchTerm : component.get("v.searchTerm") });

        component.set("v.searchInProgress", true);
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.matchingFunders", response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            
            component.set("v.searchInProgress", false);
    	});
        
        $A.enqueueAction(action);
    },
    
    
    runSyncWizard : function(component, funderRecordId){

        let funderId = component.get("v.record.I_RS_Primary_Funder_Id__c");
        
        let flowInputVariables = [
            {
                name: 'Staging_Opportunity_Record_Id',
                type: 'String',
                value: component.get("v.recordId")
            }
        ];
        if (funderRecordId != null){

            flowInputVariables.push(
            {
                name : 'Funder_Record_Id',
                type : 'String',
                value : funderRecordId
            });
        }
        
        let flowVariables = {
            flowName : "Sync_Staging_Opportunities_to_Funder",
        	inputVariables : flowInputVariables
        };
        
        $A.createComponent("c:FlowContainer", flowVariables,
           function(content, status) {
               if (status === "SUCCESS") {
                   component.find('overlayLib').showCustomModal({
                       header: 'Sync Staging Opportunity to Funder',
                       body: content,
                       showCloseButton: true
                   })
               }
           });
        
    }
})