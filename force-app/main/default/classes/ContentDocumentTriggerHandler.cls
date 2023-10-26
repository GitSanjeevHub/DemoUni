//Trigger handler for ContentDocument trigger
public with sharing class ContentDocumentTriggerHandler {
    //Execute method which is invoked from OpportunityLineItem trigger
    public static void execute(){
        // Check for event type of trigger
        if(Trigger.isBefore ){
            beforeHandler();
        }
    }
    
    private static void beforeHandler(){
        if(Trigger.isDelete) {
            // Methods to be invoked for before update event
            List<Profile> profileCurrentUser = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            if(profileCurrentUser != null 
                && GlobalConstants.COMMUNITYPROFILENAMES.contains(profileCurrentUser[0].Name)) {   
                   ContentDocumentTriggerHelper.blockAttachmentDeleteWhenProjectlocked((List<ContentDocument>)Trigger.Old);
               }
        }
    }
}