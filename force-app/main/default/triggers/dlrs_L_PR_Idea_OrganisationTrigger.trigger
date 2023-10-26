/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_L_PR_Idea_OrganisationTrigger on L_PR_Idea_Organisation__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(L_PR_Idea_Organisation__c.SObjectType);
}