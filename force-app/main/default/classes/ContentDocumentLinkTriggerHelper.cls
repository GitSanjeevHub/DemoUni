/**
* Created by burnside on 2019-05-06.
*/

public class ContentDocumentLinkTriggerHelper {
    
    public static void surfaceFilesOnCommunity(List<ContentDocumentLink> cdls){
        
        for (ContentDocumentLink link : cdls) {
            link.Visibility = 'AllUsers';
        }
    }
    
    public static void disableFileUploadForParentLocked(List<ContentDocumentLink> cdls) {
        
        Set<Id> ppIds = new Set<Id>();
        Set<Id> roIds = new Set<Id>();
        
        for(ContentDocumentLink cdl : cdls) {
            if(cdl.LinkedEntityId.getSobjectType() == Project_Proposal__c.SobjectType){
                ppIds.add(cdl.LinkedEntityId);
            } 
            
            if(cdl.LinkedEntityId.getSobjectType() == Research_Opportunity__c.SobjectType){
        		handleResearchOpportunityDocumentLink(cdl);
            }
            
            if((cdl.LinkedEntityId.getSobjectType() == Ethics_Request__c.SobjectType) || 
               (cdl.LinkedEntityId.getSobjectType() == Ethics_Post_Approval__c.SobjectType)){
        		handleEthicsRequestDocumentLink(cdl);
            }
        }
        
        if (ppIds.size() > 0){
        	handleProjectProposalDocumentLink(ppIds, cdls);
        }
    }
    
    private static void handleProjectProposalDocumentLink(Set<Id> ppIds, List<ContentDocumentLink> cdls){
        Set <Id> projectProposalsLockedForReview = new Set <Id>();
        System.debug('--> ppIds --> '+ppIds);
        if(ppIds != null && ppIds.size()>0) {
            for(Project_Proposal__c projProp : [SELECT I_RS_Allow_Updates_on_Approval__c
                                                ,I_RS_Status__c
                                                FROM Project_Proposal__c 
                                                WHERE Id IN :ppIds] ) {
                                                    if(!projProp.I_RS_Allow_Updates_on_Approval__c
                                                       && (GlobalConstants.PROJECT_PROPOSAL_STATUS_REVIEW_BY_RESEARCH_OFFICE.EqualsIgnoreCase(projProp.I_RS_Status__c)
                                                           || GlobalConstants.PROJECT_PROPOSAL_STATUS_APPROVALS.EqualsIgnoreCase(projProp.I_RS_Status__c))) {
                                                               projectProposalsLockedForReview.add(projProp.Id);
                                                           }
                                                }
            for(ContentDocumentLink conDocLink : cdls){
                if(projectProposalsLockedForReview.contains(conDocLink.LinkedEntityId)) {
                    System.debug('--> ContentDocumentLinkTrigger throw error');
                    conDocLink.addError(GlobalConstants.ADDED_ERROR_ATTACHMENT_UPLOAD_PROECT_IN_REVIEW);
                }
            }
        }
    }
    
    private static void handleResearchOpportunityDocumentLink(ContentDocumentLink cdl){
        if (GlobalUtility.currentUserIsResearcher()) {
    		cdl.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
        }
    }

    private static void handleEthicsRequestDocumentLink(ContentDocumentLink cdl){
        cdl.ShareType = 'I';
        /*if (GlobalUtility.currentUserIsResearcher()) {
    		cdl.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
        }*/
    }
}