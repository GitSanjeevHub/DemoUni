({
    handleRecordLoad : function(component, event, helper){
        
        let recordLoadComplete = component.get("v.recordLoadComplete");
        if (!recordLoadComplete){

            
        	this.processBudgetOnServer(component, event, helper, "rateChange");
            let leadChiefInvestigator = 
                component.get("v.budgetRecord.I_RS_Project_Proposal__r.I_RS_Lead_Chief_Investigator__c");
            console.log('leadChiefInvestigator '+leadChiefInvestigator);

            component.set("v.budgetRecord.I_RS_Lead_Chief_Investigator__c", leadChiefInvestigator);


            component.set("v.recordLoadComplete", true);
            
            var budgetRecord = component.get("v.budgetRecord");

            let isValidRecord = this.evaluateRecordForInitialLoad(component, budgetRecord);
            component.set("v.recordLoadSuccessful", isValidRecord);
            
            component.set("v.showLoadingScreen", false);
        } 
    },



    evaluateRecordForInitialLoad : function(component, budgetRecord){

        if (budgetRecord.I_RS_Status__c !== "Draft"){
            component.set("v.errorMessage", component.get("v.errorMessage_NonDraftBudget"));    
            return false;
        }

        return true;

    },


	processBudgetOnServer : function(component, event, helper, actionName) {
        
        console.log('processBudgetOnServer '+actionName);
		var action;
        if (actionName === "rateTypeChange") action = component.get("c.provideActualRatesBasedOnRateType_Aura");
        else if (actionName === "rateChange") action = component.get("c.provideDailyChargeoutRates_Aura");
        
		console.log(component.get("v.budgetRecord"));
        
        action.setParams(
            { budgetsToProcess : [component.get("v.budgetRecord")] }
        );
        
		

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                let processedBudget = response.getReturnValue()[0];
                console.log(processedBudget);

                if (actionName === "rateTypeChange"){
                    component.set("v.budgetRecord.I_RS_Actual_Overhead__c", processedBudget.I_RS_Actual_Overhead__c);
                    component.set("v.budgetRecord.I_RS_Actual_Profit__c", processedBudget.I_RS_Actual_Profit__c);
                    component.set("v.budgetRecord.I_RS_Actual_Non_Salary_Overhead__c", processedBudget.I_RS_Actual_Non_Salary_Overhead__c);
                    
                    this.processBudgetOnServer(component, event, helper, "rateChange");
                }
                else if (actionName === "rateChange"){
                    component.set("v.budgetRecord.I_RS_Daily_On_Costs__c", processedBudget.I_RS_Daily_On_Costs__c);
                    component.set("v.budgetRecord.I_RS_Daily_Overheads__c", processedBudget.I_RS_Daily_Overheads__c);
                    component.set("v.budgetRecord.I_RS_Daily_Profits__c", processedBudget.I_RS_Daily_Profits__c);
                    component.set("v.budgetRecord.I_RS_Daily_Salary__c", processedBudget.I_RS_Daily_Salary__c);
                    component.set("v.budgetRecord.I_RS_Base_Salary__c", processedBudget.I_RS_Base_Salary__c);
                }

                console.log('processedRecord');
                console.log(component.get("v.budgetRecord"));
                
                /*component.set("v.budgetRecord", processedBudget);
                
                if (actionName === "rateTypeChange"){
                	this.processBudgetOnServer(component, event, helper, "rateChange");
                }*/
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
        });

        $A.enqueueAction(action);
    },
    
    
    setEmptyNumberFieldsToZero : function(component){
        
        console.log('setEmptyFieldsToZero');
        
        if (component.get("v.budgetRecord")){
            if (!(component.get("v.budgetRecord.I_RS_Maximum_Allowed_On_Cost__c") >= 0))
                component.set("v.budgetRecord.I_RS_Maximum_Allowed_On_Cost__c", 0);
                
            if (
                !component.get("v.budgetRecord.I_RS_Actual_Overhead__c") ||
                !(component.get("v.budgetRecord.I_RS_Actual_Overhead__c") >= 0))
                    component.set("v.budgetRecord.I_RS_Actual_Overhead__c", 0);
            
            if (!component.get("v.budgetRecord.I_RS_Actual_Non_Salary_Overhead__c") ||
                !(component.get("v.budgetRecord.I_RS_Actual_Non_Salary_Overhead__c") >= 0))
                    component.set("v.budgetRecord.I_RS_Actual_Non_Salary_Overhead__c", 0);
            
            if (!component.get("v.budgetRecord.I_RS_Actual_Profit__c") ||
                !(component.get("v.budgetRecord.I_RS_Actual_Profit__c") >= 0))
                component.set("v.budgetRecord.I_RS_Actual_Profit__c", 0);
            
            console.log(component.get("v.budgetRecord"));
            console.log('setEmptyFieldsToZero - complete');
            
        }
    },
    
    
    copyFieldValuesToOutputDesignAttributes : function(component, event, helper){

		let budget = component.get("v.budgetRecord");

        component.set("v.outputField_LeadChiefInvestigator", budget.I_RS_Lead_Chief_Investigator__c);

        component.set("v.outputField_projectRate", budget.I_RS_Actual_Rate_Type__c);        
        component.set("v.outputField_salaryOverhead", budget.I_RS_Actual_Overhead__c);
        component.set("v.outputField_nonSalaryOverhead", budget.I_RS_Actual_Non_Salary_Overhead__c);
        component.set("v.outputField_salaryProfit", budget.I_RS_Actual_Profit__c);
		
        component.set("v.outputField_baseSalary", budget.I_RS_Base_Salary__c);        
        
        component.set("v.outputField_dailySalaryOnCosts", budget.I_RS_Daily_On_Costs__c);
        component.set("v.outputField_dailySalaryOverhead", budget.I_RS_Daily_Overheads__c);
        component.set("v.outputField_dailySalaryProfit", budget.I_RS_Daily_Profits__c);
        component.set("v.outputField_dailyBaseSalary", budget.I_RS_Daily_Salary__c);
        
    },

    
    closeQuickAction : function(component){
        
        console.log('closeQuickAction');

        component.find('notifLib').showToast({
            "message": "Charge Out Rate Saved",
            "variant" : "success"
        });
        
        $A.get('e.force:refreshView').fire();

        

        console.log("Firing screen complete event");
        $A.get("e.c:BudgetChargeOutRateScreenComplete").fire();

        var closeQuickActionEvent = $A.get("e.force:closeQuickAction");
        if (closeQuickActionEvent){
            closeQuickActionEvent.fire();
        }
        
    }

})