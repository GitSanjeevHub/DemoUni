public with sharing class BudgetLineItemTriggerHandler {
    
    
    public static void execute(){


        if (Trigger.isBefore){

            if (Trigger.isDelete){
                DeletionBlocker.blockDelete('Budget_Line_Item__c', Trigger.Old);
            }

        }

    }



}