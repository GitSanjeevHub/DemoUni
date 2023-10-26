//Trigger helper for ContentDocument
public class ContentDocumentTriggerHelper {
        private static String projPropKeyPrefix = Project_Proposal__c.sObjectType.getDescribe().getKeyPrefix();
        private static String roKeyPrefix = Research_Opportunity__c.sObjectType.getDescribe().getKeyPrefix();
        private static String erKeyPrefix = Ethics_Request__c.sObjectType.getDescribe().getKeyPrefix();
    
    public static void blockAttachmentDeleteWhenProjectlocked(List<ContentDocument> oldConDoc) {
      
        Map<Id, ContentDocument> contentDocMap = new Map<Id, ContentDocument>();
        Map<Id, Id> ppMap = new Map<Id, Id>();
        
        for(ContentDocument con : oldConDoc){
            contentDocMap.put(con.Id, con);
        }
        
        //get all the content document link for the project proposal only
        if(contentDocMap != null && contentDocMap.size()>0){
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN : contentDocMap.keySet()]){
                if(String.valueOf(cdl.LinkedEntityId).left(3) == projPropKeyPrefix)  {
                    ppMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
                
                if(String.valueOf(cdl.LinkedEntityId).left(3) == roKeyPrefix){
                	handleResearchOpportunityDocument(contentDocMap.get(cdl.ContentDocumentId));    
                }
                
                if(String.valueOf(cdl.LinkedEntityId).left(3) == roKeyPrefix){
                	handleEthicsRequestDocument(contentDocMap.get(cdl.ContentDocumentId));    
                }
            }
        }
        
        if (ppMap.size() > 0) {
        	handleProjectProposalDocument(ppMap, oldConDoc);    
        }
        
    }
    
    private static void handleProjectProposalDocument(Map<Id, Id> ppMap, List<ContentDocument> oldConDoc){
        //create a map of project proposal for which the attachments are deleted
        Map<Id,Project_Proposal__c> mapLockedProjectProposals;
        if(ppMap.values() != null) {
            mapLockedProjectProposals = new Map<Id,Project_Proposal__c>([Select I_RS_Status__c, I_RS_Allow_Updates_on_Approval__c FROM Project_Proposal__c WHERE Id IN :ppMap.values()]);
        }
        
        if(mapLockedProjectProposals != null && mapLockedProjectProposals.size()>0) {
            for(ContentDocument cdoc : oldConDoc){
                if(mapLockedProjectProposals.get(ppMap.get(cdoc.Id)) != null) {
                    if(projPropKeyPrefix == String.valueOf(ppMap.get(cdoc.Id)).left(3) 
                       && !mapLockedProjectProposals.get(ppMap.get(cdoc.Id)).I_RS_Allow_Updates_on_Approval__c
                       && (GlobalConstants.PROJECT_PROPOSAL_STATUS_REVIEW_BY_RESEARCH_OFFICE.EqualsIgnoreCase(mapLockedProjectProposals.get(ppMap.get(cdoc.Id)).I_RS_Status__c)
                           || GlobalConstants.PROJECT_PROPOSAL_STATUS_APPROVALS.EqualsIgnoreCase(mapLockedProjectProposals.get(ppMap.get(cdoc.Id)).I_RS_Status__c))){
                               System.debug('--> ContentDocumentTrigger throw error -->');
                               cdoc.addError(GlobalConstants.ADDED_ERROR_ATTACHMENT_UPLOAD_PROECT_IN_REVIEW);
                           }
                }
            }
        }
    }
    
    private static void handleResearchOpportunityDocument(ContentDocument cdoc){
        if (GlobalUtility.currentUserIsResearcher()) {
    		cdoc.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
        }
    }

    private static void handleEthicsRequestDocument(ContentDocument cdoc){
        if (GlobalUtility.currentUserIsResearcher()) {
    		cdoc.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
        }
    }
}