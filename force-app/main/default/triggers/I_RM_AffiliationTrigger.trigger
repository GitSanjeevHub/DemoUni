trigger I_RM_AffiliationTrigger on I_RM_Affiliation__c (before insert,after insert,before update,after update,after delete, after undelete) {
     
    if (!GlobalUtility.isTriggerDisabled('I_RM_Affiliation__c')){        
        I_RM_AffiliationTriggerHandler.execute();

        /* dupcheck.dc3Trigger triggerTool = new dupcheck.dc3Trigger(trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete);
        String errorString = triggerTool.processTrigger(trigger.oldMap, trigger.new); 

        if (String.isNotEmpty(errorString)) { 
            trigger.new[0].addError(errorString,false); 
        }    */
    } 
}