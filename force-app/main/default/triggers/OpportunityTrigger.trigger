trigger OpportunityTrigger on Opportunity (before insert, before update,after insert, after update) {
    if(!GlobalUtility.isTriggerDisabled('Opportunity')) {
        L_PR_OpportunityTriggerHandler.execute();
    }
}