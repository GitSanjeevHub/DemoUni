/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_L_PR_External_Org_Opportua3OTrigger on L_PR_External_Org_Opportunity_Relation__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(L_PR_External_Org_Opportunity_Relation__c.SObjectType);
}