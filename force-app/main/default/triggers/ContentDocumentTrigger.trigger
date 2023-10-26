trigger ContentDocumentTrigger on ContentDocument (before delete) {
    //verify if triggers are disabled
    if(!GlobalUtility.isTriggerDisabled(String.valueOf(ContentDocument.sObjectType))){     
        //ContentDocument trigger handler dispatches appropriate event
        ContentDocumentTriggerHandler.execute();
    }
}