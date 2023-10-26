/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Budget_Line_ItemTrigger on Budget_Line_Item__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    if (!GlobalUtility.isTriggerDisabled('Budget_Line_Item__c')){
        dlrs.RollupService.triggerHandler(Budget_Line_Item__c.SObjectType);
    }
}