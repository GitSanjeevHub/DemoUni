trigger L_PR_Idea_OrganisationTrigger on L_PR_Idea_Organisation__c (after insert) {
	if(!GlobalUtility.isTriggerDisabled('L_PR_Idea_Organisation__c')) {
        L_PR_Idea_OrganisationTriggerHandler.execute();
    }
}