//Trigger helper for ContentVersion
public class ContentVersionTriggerHelper {
        private static String projPropKeyPrefix = Project_Proposal__c.sObjectType.getDescribe().getKeyPrefix();
        private static String roKeyPrefix = Research_Opportunity__c.sObjectType.getDescribe().getKeyPrefix();
        private static String erKeyPrefix = Ethics_Request__c.sObjectType.getDescribe().getKeyPrefix();
        private static String epaKeyPrefix = Ethics_Post_Approval__c.sObjectType.getDescribe().getKeyPrefix();
    
    private static Set<String> erPermittedStatus = new Set<String>{'Draft'};
    private static Set<String> epaPermittedStatus = new Set<String>{'Draft'};
        
    
    public static void disableContentVersionUpload(List<ContentVersion> contentVersionList) {
        
        Map<Id,Id> contentVersionIdVsLinkedEntityId = new Map<Id,Id>();
        Map<Id,Id> ethicsCVIdVsLinkedEntityId = new Map<Id,Id>();
        Map<Id,Id> ethicsPostApprovalCVIdVsLinkedEntityId = new Map<Id,Id>();
        
        Set<Id> projectProposalIds = new Set<Id>();
        Map<Id, ContentVersion> roContentVersionMap = new Map<Id, ContentVersion>();
        List<ContentVersion> erContentVersionMap = new List<ContentVersion>();
        List<ContentVersion> epaContentVersionMap = new List<ContentVersion>();
        
        boolean erCVAdded = false;
        boolean epaCVAdded = false;
        for(ContentVersion cv: contentVersionList)
        {
            if(cv.ContentDocumentId != null)
            {
        		erCVAdded = false;
        		epaCVAdded = false;
                List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId =: cv.ContentDocumentId];
                for(ContentDocumentLink cdlnk: cdlList) {
                    if(String.valueOf(cdlnk.LinkedEntityId).left(3) == projPropKeyPrefix) {
                        contentVersionIdVsLinkedEntityId.put(cv.Id, cdlnk.LinkedEntityId);
                        projectProposalIds.add(cdlnk.LinkedEntityId);
                    }
                    
                    if (String.valueOf(cdlnk.LinkedEntityId).left(3) == roKeyPrefix) {
                        if (!roContentVersionMap.containsKey(cv.Id)){
                            roContentVersionMap.put(cv.Id, cv);
                        }    
                    }
                    
                    if ((String.valueOf(cdlnk.LinkedEntityId).left(3) == erKeyPrefix) ) {
                        if (!erCVAdded) {
                            erCVAdded = true;
                        	erContentVersionMap.add(cv);
                        }
                        if (cv.ContentDocumentId == cdlnk.ContentDocumentId){
                            ethicsCVIdVsLinkedEntityId.put(cdlnk.ContentDocumentId, cdlnk.LinkedEntityId);
                        }
                    }

                    if ((String.valueOf(cdlnk.LinkedEntityId).left(3) == epaKeyPrefix) ) {
                        if (!epaCVAdded) {
                            epaCVAdded = true;
                        	epaContentVersionMap.add(cv);
                        }
                        if (cv.ContentDocumentId == cdlnk.ContentDocumentId){
                            ethicsPostApprovalCVIdVsLinkedEntityId.put(cdlnk.ContentDocumentId, cdlnk.LinkedEntityId);
                        }
                    }
                }
            }
        }
        
        if (projectProposalIds.size() > 0){
        	handleProjectProposalDocument(projectProposalIds, contentVersionIdVsLinkedEntityId, contentVersionList);    
        }
        
        if(roContentVersionMap.size() > 0) {
        	handleResearchOpportunityDocument(roContentVersionMap.values());    
        }
        
        if(erContentVersionMap.size() > 0) {
        	handleEthicsRequestDocument(erContentVersionMap, ethicsCVIdVsLinkedEntityId);    
        }
        
        if(epaContentVersionMap.size() > 0) {
        	handleEthicsPostApprovalDocument(epaContentVersionMap, ethicsPostApprovalCVIdVsLinkedEntityId);    
        }
    }
    
    private static void handleProjectProposalDocument(Set<Id> projectProposalIds, Map<Id,Id> contentVersionIdVsLinkedEntityId, List<ContentVersion> contentVersionList){
        Set <Id> projectProposalsLockedForReview = new Set <Id>();
        
        if(projectProposalIds != null && projectProposalIds.size()>0) {
            for(Project_Proposal__c projProp : [SELECT I_RS_Allow_Updates_on_Approval__c, I_RS_Status__c FROM Project_Proposal__c WHERE Id IN :projectProposalIds] ) {
                if(!projProp.I_RS_Allow_Updates_on_Approval__c
                   && (GlobalConstants.PROJECT_PROPOSAL_STATUS_REVIEW_BY_RESEARCH_OFFICE.EqualsIgnoreCase(projProp.I_RS_Status__c)
                       || GlobalConstants.PROJECT_PROPOSAL_STATUS_APPROVALS.EqualsIgnoreCase(projProp.I_RS_Status__c))) {
                           projectProposalsLockedForReview.add(projProp.Id);
                       }
            }
            for(ContentVersion conVersion : contentVersionList){
                if(contentVersionIdVsLinkedEntityId.get(conVersion.Id) != null 
                   && projectProposalsLockedForReview.contains(contentVersionIdVsLinkedEntityId.get(conVersion.Id))) {
                       conVersion.addError(GlobalConstants.ADDED_ERROR_ATTACHMENT_UPLOAD_PROECT_IN_REVIEW);
                   }
            }
        }
    }  
    
    private static void handleResearchOpportunityDocument(List<ContentVersion> contentVersionList){
        if (GlobalUtility.currentUserIsResearcher()) {
            for(ContentVersion conVersion : contentVersionList){
                conVersion.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
            }
        }
    }    

    private static void handleEthicsRequestDocument(List<ContentVersion> contentVersionList,Map<Id,Id> ethicsCVIdVsLinkedEntityId){
        if (GlobalUtility.currentUserIsResearcher()) {
            Map<Id, Ethics_request__c> erMap = new Map<Id, Ethics_request__c> ([SELECT Id, I_RS_Status__c 
                                                                               FROM Ethics_request__C 
                                                                               WHERE Id IN :ethicsCVIdVsLinkedEntityId.values()]);
            set<Id> cDocIds = new set<Id>();
            for (ContentVersion conVersion : contentVersionList){
            	cDocIds.add(conVersion.ContentDocumentId);    
            }
            Map<Id, ContentDocument> cDocList = new Map<Id, ContentDocument>([SELECT Id, OwnerId 
                                                                              FROM ContentDocument 
                                                                              WHERE Id IN :cDocIds]);
                
            for(ContentVersion conVersion : contentVersionList){
                Id erId = ethicsCVIdVsLinkedEntityId.get(conVersion.ContentDocumentId); 
                Ethics_request__c er = erMap.get(erId); 
                if ( (!erPermittedStatus.contains(er.I_RS_Status__c)) &&
                     (cDocList.get(conVersion.ContentDocumentId).OwnerId != conVersion.OwnerId)){
                	conVersion.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
                }
            }
        }
    }    
    private static void handleEthicsPostApprovalDocument(List<ContentVersion> contentVersionList,Map<Id,Id> ethicsPostApprovalCVIdVsLinkedEntityId){
        if (GlobalUtility.currentUserIsResearcher()) {
            Map<Id, Ethics_Post_Approval__C> epaMap = new Map<Id, Ethics_Post_Approval__C> ([SELECT Id, I_RS_Status__c 
                                                                               FROM Ethics_Post_Approval__C 
                                                                               WHERE Id IN :ethicsPostApprovalCVIdVsLinkedEntityId.values()]);
            set<Id> cDocIds = new set<Id>();
            for (ContentVersion conVersion : contentVersionList){
            	cDocIds.add(conVersion.ContentDocumentId);    
            }
            Map<Id, ContentDocument> cDocList = new Map<Id, ContentDocument>([SELECT Id, OwnerId 
                                                                              FROM ContentDocument 
                                                                              WHERE Id IN :cDocIds]);
                
            for(ContentVersion conVersion : contentVersionList){
                Id epaId = ethicsPostApprovalCVIdVsLinkedEntityId.get(conVersion.ContentDocumentId); 
                Ethics_Post_Approval__C er = epaMap.get(epaId); 
                if ( (!epaPermittedStatus.contains(er.I_RS_Status__c)) &&
                     (cDocList.get(conVersion.ContentDocumentId).OwnerId != conVersion.OwnerId)){
                	conVersion.addError(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER);
                }
            }
        }
    }    
}