trigger L_PR_External_Org_Opportunity_RelationTrigger on L_PR_External_Org_Opportunity_Relation__c (after insert, after update) {
	if(!GlobalUtility.isTriggerDisabled('L_PR_External_Org_Opportunity_Relation__c')) {
        L_PR_Ext_Org_Oppt_RelationTriggerHandler.execute();
    }
}