trigger I_ST_ApplicationTrigger on I_ST_Application__c (after insert, after update) {
    if(!GlobalUtility.isTriggerDisabled('I_ST_Application__c')) {
        I_ST_ApplicationTriggerHandler.execute();
    }
}