/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Related_Ethics_AgreementTrigger on Related_Ethics_Agreement__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Related_Ethics_Agreement__c.SObjectType);
}