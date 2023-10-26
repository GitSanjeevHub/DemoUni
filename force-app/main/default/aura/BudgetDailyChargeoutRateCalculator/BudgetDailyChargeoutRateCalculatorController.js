({

    handleRecordLoad : function(component, event, helper){
        
        helper.handleRecordLoad(component, event, helper);

    },
    
    handleProjectRatePicklistChange : function(component, event, helper) {
        console.log("handleProjectRatePicklistChange");
        
		component.set("v.budgetRecord.I_RS_Actual_Project_Rate__c", event.getParam("detail"));
        
        component.set("v.errorMessage", null);

        helper.processBudgetOnServer(component, event, helper, "rateTypeChange");
		
	},


    handleBudgetRateFieldBlur : function(component, event, helper){
      
        helper.setEmptyNumberFieldsToZero(component);
        
    },
    
    
    handleBudgetRateFieldChange : function(component, event, helper){
        
        component.set("v.errorMessage", null);
        
        helper.processBudgetOnServer(component, event, helper, "rateChange");
        
    },
    

    handleAnyRecordFieldChange : function(component, event, helper){
      
        if (!component.get("v.showSaveButton")){
            helper.copyFieldValuesToOutputDesignAttributes(component, event, helper);
        }
        
    }, 
    
    
    saveRecord : function(component, event, helper){
        
        component.set("v.errorMessage", null);
        component.set("v.showLoadingScreen", true);
        component.set("v.currentLoadingMessage", component.get("v.loadingMessage_SavingRecord"));

		component.find("recordLoader").saveRecord($A.getCallback(function(response) {
            if (component.isValid() && response.state == "SUCCESS") {
         
                let recalculateLineItems = component.get("v.recalculateLineItems");
                
                if (recalculateLineItems){
                    
                    console.log("Recalculate line items");

                    component.set("v.currentLoadingMessage", component.get("v.loadingMessage_RecalcLineItems"));
                    
                    /*component.find("salaryItems").recalculateRecords();
                	component.find("nonSalaryItems").recalculateRecords();*/
                }
                else {
                    helper.closeQuickAction(component);
                }
                
            }
            else if (response.state === "ERROR") {
                console.log(response.error[0]);
                component.set("v.errorMessage", response.error[0].message);
                component.set("v.showLoadingScreen", false);

            }
            
        }));
        
        //If in visual workflow, we're using two-way binding
        
        //If in quick action, we'll use button, then call event that closes (should it be in this component?). Or, 
        //just let the user save it themselves
        
        //If on page, we'll have the save button 
        //
        //
    },
        
      
    handleChildGridSuccessfulSave : function(component, event, helper){
        
        console.log('handleChildGridSuccessfulSave');
        let recordType = event.getParam("recordTypeName");
        
        if (recordType == "I_RS_Salary"){
            component.set("v.salaryItemsRecalculated", true);
            console.log("salary recalculated");
        }
        else if (recordType == "I_RS_Non_Salary"){
            component.set("v.nonSalaryItemsRecalculated", true);
            console.log("non-salary recalculated");
        }

        if (component.get("v.salaryItemsRecalculated") === true && 
            component.get("v.nonSalaryItemsRecalculated")  === true){
            
            console.log("Both line item types recalculated. Closing...");
            helper.closeQuickAction(component);
        }
    }
    
})