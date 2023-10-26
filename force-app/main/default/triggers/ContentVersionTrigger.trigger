trigger ContentVersionTrigger on ContentVersion (before insert) {
    //verify if triggers are disabled
    if(!GlobalUtility.isTriggerDisabled(String.valueOf(ContentVersion.sObjectType))){     
        //ContentVersion trigger handler dispatches appropriate event
        system.debug('--> ContentVersion Trigger -->');
        ContentVersionTriggerHandler.execute();
    }//end - if(!GlobalUtility)
}