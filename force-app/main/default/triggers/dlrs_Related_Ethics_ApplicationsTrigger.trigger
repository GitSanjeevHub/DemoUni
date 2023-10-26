/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Related_Ethics_ApplicationsTrigger on Related_Ethics_Applications__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Related_Ethics_Applications__c.SObjectType);
}