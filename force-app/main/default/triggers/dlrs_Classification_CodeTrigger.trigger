/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Classification_CodeTrigger on Classification_Code__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    if (!GlobalUtility.isTriggerDisabled('Classification_Code__c')){
        dlrs.RollupService.triggerHandler(Classification_Code__c.SObjectType);
    }
}