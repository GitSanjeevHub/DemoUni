/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Project_ProposalTrigger on Project_Proposal__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    if (!GlobalUtility.isTriggerDisabled('Project_Proposal__c')){
        dlrs.RollupService.triggerHandler(Project_Proposal__c.SObjectType);
    }
}