public without sharing class ProjectTeamMemberAccess4 {

    static Map<String, Schema.SObjectType> objectDescribes = Schema.getGlobalDescribe();
    
    static Boolean isDeleteOperation;

    static Set<Id> input_TeamMemberIds;

    static List<Apex_Debug_Log__c> errorLogs;
    
    
    public static void runForTeamMembers(List<Project_Team_Member__c> input_TeamMembers, String objectToRecalculateSharingFor, Boolean isDelete, Boolean simulateOnly)
    {
     
        isDeleteOperation = isDelete;

        Map<String, SObject> unhandledExistingShares_project = new Map<String, SObject>();
        Map<String, SObject> validExistingShares_project = new Map<String, SObject>();
        Map<String, SObject> shareRecordsToInsert_project = new Map<String, SObject>();
        Map<String, SObject> shareRecordsToDelete_project = new Map<String, SObject>();
        
        Map<String, SObject> unhandledExistingShares_ag = new Map<String, SObject>();
        Map<String, SObject> validExistingShares_ag = new Map<String, SObject>();
        Map<String, SObject> shareRecordsToInsert_ag = new Map<String, SObject>();
        Map<String, SObject> shareRecordsToDelete_ag = new Map<String, SObject>();
        
        List<SObject> shareRecordsToInsert = new List<SObject>();
        List<SObject> shareRecordsToDelete = new List<SObject>();

        errorLogs = new List<Apex_Debug_Log__c>();

        try {
        
            input_TeamMemberIds = new Map<Id, Project_Team_Member__c>(input_TeamMembers).keySet();
    
            Set<Id> input_ProjectProposalIds = GlobalUtility.getParentIds(input_TeamMembers, 'I_RS_Project_Proposal__c');
    
            List<Project_Team_Member__c> teamMembers = [
                SELECT Id, I_RS_Active__c, 
                I_RS_Related_User_Id__c, I_RS_Project_Proposal__c,
                I_RS_Contact_is_PRIME_Researcher__c,
                I_RS_Project_Team_Member__c, 
                I_RS_Project_Team_Member__r.I_RS_Manager__c,
                I_RS_Project_Team_Member__r.I_RS_Manager__r.I_RS_Is_Researcher_User__c
                FROM Project_Team_Member__c 
                WHERE I_RS_Project_Proposal__c IN :input_ProjectProposalIds 
                AND I_RS_Active__c = TRUE 
                AND I_RS_Project_Team_Member__r.I_RS_Related_User__r.IsActive = TRUE
                AND I_RS_Contact_is_PRIME_Researcher__c = TRUE];
    
            Set<Id> input_RelatedUserIds = GlobalUtility.getParentIds(teamMembers, 'I_RS_Related_User_Id__c');
            Set<Id> input_ContactIds = GlobalUtility.getParentIds(teamMembers, 'I_RS_Project_Team_Member__c');
                
            //Get existing Project Proposal data
            List<Project_Proposal__c> existingProjectProposalDataList = [
                SELECT Id, Name, 
                    (SELECT I_RS_Project_Proposal__c, Id, Name from Agreements__r)
                FROM Project_Proposal__c WHERE Id IN :input_ProjectProposalIds];
            
            Map<Id, Project_Proposal__c> existingProjectProposalDataMap = new Map<Id, Project_Proposal__c>(existingProjectProposalDataList);
            
            
            
    
            //Contruct share maps
            
            List<SObject> existingProjectProposalShares = getExistingShareRecords('Project_Proposal__share', input_RelatedUserIds, input_ProjectProposalIds);
            
            unhandledExistingShares_project.putAll(constructRecordShareMap('Project_Proposal__share', existingProjectProposalShares));
            
            
            List<Contract__c> existingAgreements = new List<Contract__c>();
                
            for (Project_Proposal__c existingProjectProposalData : existingProjectProposalDataList){
                for (Contract__c existingAgreement : existingProjectProposalData.Agreements__r){
                    existingAgreements.add(existingAgreement);
                }
            }
            
            
            Set<Id> existingAgreementIds = new Map<Id, Contract__c>(existingAgreements).keySet();
            List<Contract__share> existingAgreementShares = getExistingShareRecords('Contract__share', input_RelatedUserIds, existingAgreementIds);
            
            unhandledExistingShares_ag.putAll(constructRecordShareMap('Contract__share', existingAgreementShares));
            
            
            //Get manager maps
            
            Map<Id, Contact> teamMemberContactMap = new Map<Id, Contact>(
                [SELECT Id, I_RS_Manager__c, I_RS_Manager__r.IsActive, I_RS_Manager__r.I_RS_Is_Researcher_User__c 
                FROM Contact WHERE Id IN :input_ContactIds]
            );
            
            
            //For the PTMs being passed in, process record sharing for Project Proposal and other objects
            
            for (Project_Team_Member__c inputTeamMember : teamMembers){
                
                //System.debug('Evaluating PTM sharing calc: '+inputTeamMember);
                
                Id relatedUserId = inputTeamMember.I_RS_Related_User_Id__c;
                Id projectProposalId = inputTeamMember.I_RS_Project_Proposal__c;
                
                Contact teamMemberContact = teamMemberContactMap.get(inputTeamMember.I_RS_Project_Team_Member__c);
                Id managerId = null;
                Boolean grantManagerAccess = false;

                if (teamMemberContact != null){
                    managerId = (Id) teamMemberContact.get('I_RS_Manager__c');
                    if (managerId != null){
                        Boolean managerIsActive = 
                            teamMemberContact.getSObject('I_RS_Manager__r').get('IsActive') == true;

                        Boolean managerIsResearcher =
                            teamMemberContact.getSObject('I_RS_Manager__r').get('I_RS_Is_Researcher_User__c') == '1';
                        
                        grantManagerAccess = managerIsActive && managerIsResearcher;
                    }   
                }
                
                Project_Proposal__c relatedProjectProposal = existingProjectProposalDataMap.get(projectProposalId);
    
                if (!isDeleteOperation ||
                        (isDeleteOperation && !input_TeamMemberIds.contains(inputTeamMember.Id))){
                    
                    //System.debug('Sharing for '+inputTeamMember.Id+' is valid. Checking against existing list...');
                    
    
                    if (isRunningCalculationOnObject('Project_Proposal__c', objectToRecalculateSharingFor)){
                    
                        addSharingForRecord(
                            unhandledExistingShares_project,
                            validExistingShares_project,
                            shareRecordsToInsert_project,
                            'Project_Proposal__share', 
                            relatedUserId, 
                            projectProposalId, 
                            'Project_Proposal_Team_Member__c');
                        
                        if (grantManagerAccess){
                            addSharingForRecord(
                                unhandledExistingShares_project,
                                validExistingShares_project,
                                shareRecordsToInsert_project,
                                'Project_Proposal__share', 
                                managerId, 
                                projectProposalId, 
                                'Project_Proposal_Team_Member_Manager__c'
                                );
                        }
                    
                    }

                    
                    if (isRunningCalculationOnObject('Contract__c', objectToRecalculateSharingFor)){
                    
                        List<Contract__c> relatedAgreements = relatedProjectProposal.getSObjects('Agreements__r');
                        if (relatedAgreements != null){
                            for (Contract__c agreement : relatedAgreements){
                                addSharingForRecord(
                                    unhandledExistingShares_ag,
                                    validExistingShares_ag,
                                    shareRecordsToInsert_ag,
                                    'Contract__share', 
                                    relatedUserId, 
                                    agreement.Id, 
                                    'Project_Proposal_Team_Member__c'
                                    );
                                
                                if (grantManagerAccess){
                                    addSharingForRecord(
                                        unhandledExistingShares_ag,
                                        validExistingShares_ag,
                                        shareRecordsToInsert_ag,
                                        'Contract__share', 
                                        managerId, 
                                        agreement.Id, 
                                        'Project_Proposal_Team_Member_Manager__c');
                                }
                            }
                        }
                        
                    }
                    
                }
                 
            }
            shareRecordsToInsert.addAll(shareRecordsToInsert_project.values());
            shareRecordsToInsert.addAll(shareRecordsToInsert_ag.values());

            
            //Any existing share records that are not valid should be deleted
            for (SObject ppshare : unhandledExistingShares_project.values()){
                checkShareRecordForDeletion(
                    validExistingShares_project,
                    shareRecordsToInsert_project,
                    shareRecordsToDelete_project,
                    ppShare, 
                    'Project_Proposal__share');
            }
            shareRecordsToDelete.addAll(shareRecordsToDelete_project.values());

            for (SObject ashare : unhandledExistingShares_ag.values()){
                checkShareRecordForDeletion(
                    validExistingShares_ag,
                    shareRecordsToInsert_ag,
                    shareRecordsToDelete_ag,
                    ashare, 
                    'Contract__share');
            }
            shareRecordsToDelete.addAll(shareRecordsToDelete_ag.values());
                

            if (!simulateOnly){
                if (!shareRecordsToInsert.isEmpty()){
                    List<Database.SaveResult> shareRecordInsertResults = Database.insert(shareRecordsToInsert, false);
                    errorLogs.addAll(GlobalUtility.constructErrorLogsForDMLErrors(shareRecordInsertResults, shareRecordsToInsert, 'ProjectTeamMemberRecordAccess4', 'insert'));
                }
                if (!shareRecordsToDelete.isEmpty()){
                    List<Database.DeleteResult> shareRecordDeleteResults = Database.delete(shareRecordsToDelete, false);
                    errorLogs.addAll(GlobalUtility.constructErrorLogsForDMLErrors(shareRecordDeleteResults, shareRecordsToDelete, 'ProjectTeamMemberRecordAccess4', 'delete'));
                }
            }

        } 
        catch (Exception e){
            addApexDebugLog(e, 'runForTeamMembers');
        }
        finally {
            if (!errorLogs.isEmpty()){
                insert errorLogs;
            }
        }
        
    }

    
    static Boolean isRunningCalculationOnObject(String expectedObjectName, String actualObjectName){
        
        return (expectedObjectName.toLowerCase() == actualObjectName.toLowerCase()) || actualObjectName.toLowerCase() == 'all';
        
    }
    
    
    static void addApexDebugLog(Exception e, String methodName){
        
        errorLogs.add(
            new Apex_Debug_Log__c(
            	Apex_Class_Name__c = 'ProjectTeamMemberAccess4',
                Apex_Class_Method_Name__c = methodName,
                Exception_message__c = e.getMessage(),
                Exception_Stack_Trace__c = e.getStackTraceString()
            )
        );
        
    }
    
	    
    static void addSharingForRecord(
        Map<String, SObject> unhandledExistingShares,
        Map<String, SObject> validExistingShares,
        Map<String, SObject> shareRecordsToInsert,
        String shareType, 
        Id relatedUserId, 
        Id recordToShareId, 
        String rowCause){
        
        try {
                                           
            String key = getRecordToShareKey(shareType, relatedUserId, recordToShareId, rowCause);            

            SObject existingShareRecord = unhandledExistingShares.get(key);
                Boolean shareAlreadyStagedForInsert = shareRecordsToInsert.get(key) != null;

            if (existingShareRecord == null && !shareAlreadyStagedForInsert){
                
                    SObject newShare = newRecordShare(shareType, relatedUserId, recordToShareId, rowCause);
                    shareRecordsToInsert.put(key, newShare);
                unhandledExistingShares.remove(key);

            }
            else {
                validExistingShares.put(key, existingShareRecord);
            }

        }
        catch (Exception e){
            addApexDebugLog(e, 'addSharingForRecord');
        }
        
    }
    
    
    static void checkShareRecordForDeletion(
        Map<String, SObject> validExistingShares,
        Map<String, SObject> shareRecordsToInsert,
        Map<String, SObject> shareRecordsToDelete,
        SObject shareRecord, 
        String shareRecordType){
        String key = getRecordToShareKey(
            shareRecordType, 
            (String) shareRecord.get('UserOrGroupId'),  
            (String) shareRecord.get('ParentId'), 
            (String) shareRecord.get('RowCause'));
        
        System.debug('Might delete record with key '+key);
        
        if (validExistingShares.get(key) == null && shareRecordsToInsert.get(key) == null){
            System.debug('Will delete');
            shareRecordsToDelete.put(key, shareRecord);
        }
    }
    
    
    static SObject newRecordShare(String shareType, Id userId, Id recordToShareId, String sharingReason){
        
        sObject newShare = objectDescribes.get(shareType).newSObject();
                    
        newShare.put('UserOrGroupId', userId);
        newShare.put('ParentId', recordToShareId);
        newShare.put('RowCause', sharingReason);
        newShare.put('AccessLevel', 'Edit');
        
		System.debug('Creating new ' + shareType + ': '+newShare);
        
		return newShare;
        
    }
    
    
    static List<SObject> getExistingShareRecords(String shareRecordObjectName, Set<Id> relatedUserIds, Set<Id> parentIds){
        
        String existingShareRecordQuery = 
            'SELECT Id, UserOrGroupId, ParentId, RowCause FROM ' + shareRecordObjectName + ' ' +
                'WHERE (RowCause = \'Project_Proposal_Team_Member__c\' OR RowCause = \'Project_Proposal_Team_Member_Manager__c\') AND '+
                'ParentId IN :parentIds';
        //System.debug('Query for existing shares: '+existingShareRecordQuery);
        
        List<SObject> existingShareRecords = Database.query(existingShareRecordQuery);
        
        return existingShareRecords;
        
    }
    
    
    static Map<String, SObject> constructRecordShareMap(String shareRecordType, List<SObject> shareRecords){
        Map<String, SObject> unhandledExistingShares = new Map<String, SObject>();
        for (SObject shareRecord : shareRecords){
            String key = getShareRecordKey(shareRecordType, shareRecord);
            
            unhandledExistingShares.put(key, shareRecord);
        }
        //System.debug('Constructed share map: '+unhandledExistingShares);
        return unhandledExistingShares;
    }
    
    static String getRecordToShareKey(String shareRecordType, Id userId, Id recordToShareId, String rowCause){
        return shareRecordType + '|' + ((String) userId).left(15) + '|' + ((String) recordToShareId).left(15) + '|' + RowCause;
    }
    
    static String getShareRecordKey(String shareRecordType, SObject shareRecord){
        return shareRecordType + '|' +  ((String) shareRecord.get('UserOrGroupId')).left(15) + '|' + 
            ((String) shareRecord.get('ParentId')).left(15) + '|' + shareRecord.get('RowCause');
    }
    
}