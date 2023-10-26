/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Related_ContractTrigger on Related_Contract__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    if (!GlobalUtility.isTriggerDisabled('Related_Contract__c')){
        dlrs.RollupService.triggerHandler(Related_Contract__c.SObjectType);
    }
}