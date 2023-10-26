/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Junction_LinkageTrigger on Junction_Linkage__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    if (!GlobalUtility.isTriggerDisabled('Junction_Linkage__c')){
        dlrs.RollupService.triggerHandler(Junction_Linkage__c.SObjectType);
    }
}