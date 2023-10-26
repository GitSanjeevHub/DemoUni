trigger CaseTrigger on Case (after insert,before update,after update,before insert) {
    if (!GlobalUtility.isTriggerDisabled('case')){
        I_ST_CaseTriggerHandler.execute();       
    }
}