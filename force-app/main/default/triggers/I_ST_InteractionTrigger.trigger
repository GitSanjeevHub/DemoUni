trigger I_ST_InteractionTrigger on I_ST_Interaction__c (after insert,after update) {
    if (!GlobalUtility.isTriggerDisabled('I_ST_Interaction__c')){
        I_ST_InteractionTriggerHandler.execute();       
    }

}