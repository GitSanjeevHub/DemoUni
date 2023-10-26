/**
* Created by burnside on 2019-05-06.
*/

public class ContentDocumentLinkTriggerHandler {
    
    public static void execute(){
        
        List<ContentDocumentLink> triggerNew = (List<ContentDocumentLink>) Trigger.new;
        List<Profile> profileCurrentUser = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        
        if (Trigger.isBefore){
            if (Trigger.isInsert){
                ContentDocumentLinkTriggerHelper.surfaceFilesOnCommunity(triggerNew);
                //Block upload of File for researchers only, if the Project Proposal is locked
                if(profileCurrentUser != null 
                   && GlobalConstants.COMMUNITYPROFILENAMES.contains(profileCurrentUser[0].Name)) {
                       ContentDocumentLinkTriggerHelper.disableFileUploadForParentLocked(triggerNew);
                   }
            }
        }//End - if(Trigger.isBefore)
        
    }
    
}