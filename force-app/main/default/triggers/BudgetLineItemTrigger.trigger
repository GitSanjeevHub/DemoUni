trigger BudgetLineItemTrigger on Budget_Line_Item__c (before delete) {

    if (!GlobalUtility.isTriggerDisabled('Budget_Line_Item__c')){
        BudgetLineItemTriggerHandler.execute();
    }

}