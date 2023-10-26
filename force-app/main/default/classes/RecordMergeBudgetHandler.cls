public without sharing class RecordMergeBudgetHandler implements Queueable {

    Set<Id> parentRecordIds;
    String objectTriggeredFrom;

    public RecordMergeBudgetHandler(Set<Id> parentRecordIds, String objectTriggeredFrom){
        this.parentRecordIds = parentRecordIds;
        this.objectTriggeredFrom = objectTriggeredFrom;
    }
    
    public void execute(System.QueueableContext qc) {

        if (objectTriggeredFrom != NULL){
            
            refreshBudgets();

            refreshBudgetLineItems();

        }
        
    }

    void refreshBudgets(){

        String budgetQuery = 'SELECT Id, '+
            'I_RS_Project_Proposal__r.I_RS_Account_Organisation__r.I_RS_Maximum_Allowed_On_Cost__c, '+
            'I_RS_Actual_Overhead__c, I_RS_Actual_Profit__c, I_RS_Actual_Non_Salary_Overhead__c '+
            'FROM Budget__c WHERE I_RS_Status__c = \'Draft\' ';

        if (objectTriggeredFrom == 'Account'){
            budgetQuery += 'AND I_RS_Project_Proposal__r.I_RS_Account_Organisation__c IN :parentRecordIds';
        }
        else if (objectTriggeredFrom == 'Contact'){
            budgetQuery += 'AND I_RS_Project_Proposal__r.I_RS_Lead_Chief_Investigator__c IN :parentRecordIds';
        }
        System.debug('budgetQuery '+budgetQuery);
        List<Budget__c> budgets = Database.query(budgetQuery);
        
        Set<Id> budgetIds = new Set<Id>();
        if (!budgets.isEmpty()){

            //Update max-on-cost field on Budget, which in turn shows up in layouts and reports 
            if (objectTriggeredFrom == 'Account'){
                
                for (Budget__c budget : budgets){
                    budget.I_RS_Maximum_Allowed_On_Cost__c = 
                        budget.I_RS_Project_Proposal__r.I_RS_Account_Organisation__r.I_RS_Maximum_Allowed_On_Cost__c;
                }
            
            }

            //For Contact
            if (objectTriggeredFrom == 'Contact'){
                BudgetRateHelper.provideDailyChargeoutRates(budgets);
            }

            List<Database.SaveResult> updateResults = Database.update(budgets, false);
            GlobalUtility.constructErrorLogsForDMLErrors(
                updateResults, budgets, 'RecordMergeBudgetHandler', 'refreshBudgets');

        }

    }

    void refreshBudgetLineItems(){

        String budgetLineItemQuery = 
        'SELECT Id, I_RS_Organisation__c,I_Rs_Contact__c,I_RS_Budget__c,'+
        'I_RS_Category__c,I_RS_Sub_Category__c,RecordTypeId,I_RS_Unit_of_Time__c,'+
        'Unit_Price__c,I_RS_In_Kind__c,Year_1_Quantity__c,Year_2_Quantity__c,'+
        'Year_3_Quantity__c,Year_4_Quantity__c,Year_5_Quantity__c,Year_6_Quantity__c,'+
        'Year_7_Quantity__c,I_RS_Short_Fall__c,I_RS_Amount__c '+
        'FROM Budget_LIne_Item__c WHERE I_RS_Budget__r.I_RS_Status__c = \'Draft\'';

        if (objectTriggeredFrom == 'Account'){
            budgetLineItemQuery += ' AND I_RS_Organisation__c IN :parentRecordIds';
        }
        else if (objectTriggeredFrom == 'Contact'){
            budgetLineItemQuery += ' AND I_RS_Contact__c IN :parentRecordIds';
        }
        System.debug('budgetLineItemQuery '+budgetLineItemQuery);
        List<Budget_Line_Item__c> budgetLineItems = Database.query(budgetLineItemQuery);

        if (!budgetLineItems.isEmpty()){
            new BudgetCalculator(budgetLineItems).recalculateAndSave();
        }

    }

}