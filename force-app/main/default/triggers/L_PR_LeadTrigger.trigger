trigger L_PR_LeadTrigger on L_PR_Idea__c (after insert, after update) {
	if(!GlobalUtility.isTriggerDisabled('L_PR_Idea__c')) {
        L_PR_LeadTriggerHandler.execute();
    }
}