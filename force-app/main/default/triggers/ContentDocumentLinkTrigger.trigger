/**
* Created by burnside on 2019-04-24.
*/

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, before update) {
    
    //verify if triggers are disabled
    if(!GlobalUtility.isTriggerDisabled(String.valueOf(ContentDocumentLink.sObjectType))){     
        //ContentDocumentLink trigger handler dispatches appropriate event
        system.debug('--> ContentDocumentLink Trigger -->');
        ContentDocumentLinkTriggerHandler.execute();
    }//end - if(!GlobalUtility)
    
}