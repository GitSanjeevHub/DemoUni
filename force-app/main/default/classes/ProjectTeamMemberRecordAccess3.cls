/**
 * Created by burnside on 2019-06-21.
 */

public without sharing class ProjectTeamMemberRecordAccess3 {

    public List<SObject> triggerNew = Trigger.New;
    public Map<Id, SObject> triggerOldMap = Trigger.OldMap;
    public Boolean isDelete = Trigger.isDelete;

    Set<Id> projectProposalIds = new Set<Id>();
    Map<Id, Project_Proposal__c> projectProposals = new Map<Id, Project_Proposal__c>();
    Map<Id, List<Id>> recordIdToProjectProposalIdsMap = new Map<Id, List<Id>>();
    Map<String, List<SObject>> objectNameToRecordLists = new Map<String, List<SObject>>();

    Map<String, Project_Team_Member_Object_Access__mdt> sharingSettings =
            new Map<String, Project_Team_Member_Object_Access__mdt>();

    List<Apex_Debug_Log__c> apexDebugLogs;

    void getSharingSettings(){

        List<Project_Team_Member_Object_Access__mdt> sharingSettingsList =
        [SELECT Id,
                I_RS_Default_Access_Level__c,
                I_RS_Fields_to_Query__c,
                I_RS_In_Between_Parent_Relationship__c,
                I_RS_Object_Name__c,
                I_RS_Object_Share_Name__c,
                I_RS_Project_Proposal_Lookup_Field__c,
        (SELECT I_RS_Object_Access__c,
                I_RS_Role__c,
                I_RS_Access_Level__c
                FROM Project_Team_Member_Record_Access_Levels__r)
        FROM Project_Team_Member_Object_Access__mdt
        WHERE I_RS_Active__c = TRUE];
        for (Project_Team_Member_Object_Access__mdt sharing : sharingSettingsList){
            sharingSettings.put(sharing.I_RS_Object_Name__c, sharing);
        }
        System.debug('Sharing settings '+sharingSettings);

    }

    
    public void runViaChildRecord(String objectName){

        getSharingSettings();

        apexDebugLogs = new List<Apex_Debug_Log__c>();

        Project_Team_Member_Object_Access__mdt sharing = sharingSettings.get(objectName);

        projectProposalIds = getProjectProposalIdsByParentReference(
                sharing.I_RS_In_Between_Parent_Relationship__c,
                sharing.I_RS_Project_Proposal_Lookup_Field__c,
                objectName);

        runOnSingleChild(objectName, sharing.I_RS_Object_Share_Name__c);

        if (!apexDebugLogs.isEmpty()){
            Database.insert(apexDebugLogs, false);
        }
    }




    public void runOnSingleChild(
            String objectName,
            String objectShareName
    ){

        getProjectProposalsAndTeamMembers(projectProposalIds);

        List<SObject> records = objectNameToRecordLists.get(objectName);
        purgeSharesForObject(records, objectShareName);
        addSharingForObject(records, objectName, objectShareName);

    }


    Set<Id> getProjectProposalIdsByParentReference(
            String parentRelationship,
            String lookupFieldName,
            String objectName){

        System.debug('getProjectProposalsByParentReference');

        Set<Id> projectProposalIds = new Set<Id>();

        Set<Id> triggerIds = new Set<Id>();
        if (triggerNew != null) triggerIds.addAll(new Map<Id, SObject>(triggerNew).keySet());
        if (triggerOldMap != null) triggerIds.addAll(triggerOldMap.keySet());

        String lookupReference = '';
        if (parentRelationship != null ) lookupReference += parentRelationship+'.';
        lookupReference += lookupFieldName;

        String query =  'SELECT ' + lookupReference + ' FROM ' + objectName;
        query += ' WHERE Id IN :triggerIds';
        //query += ' AND '+lookupReference+' != NULL';
        System.debug('query '+query);

        List<SObject> objects = Database.query(query);
        objectNameToRecordLists.put(objectName, objects);
        System.debug('objects '+objects);


        for (Integer index=0; index<objects.size(); index++){
            SObject record = objects[index];
            Id projectProposalId = getRecordProjectProposalId(record, parentRelationship, lookupFieldName);

            projectProposalIds.add(projectProposalId);
            recordIdToProjectProposalIdsMap.put(record.Id, new List<Id>{projectProposalId});

        }

        System.debug('recordIdToProjectProposalsMap '+recordIdToProjectProposalIdsMap);

        return projectProposalIds;
    }


    void getProjectProposalsAndTeamMembers(Set<Id> projectProposalIds){

        projectProposals = new Map<Id, Project_Proposal__c>([
            SELECT Id, (SELECT I_RS_Project_Proposal__c, I_RS_Active__c, I_RS_Role__c, I_RS_Team_Member_User__c,
                        I_RS_Team_Member_User__r.Contact.I_RS_Manager__c, 
                        I_RS_Team_Member_User__r.Contact.I_RS_Manager__r.I_RS_Is_Researcher_User__c,
                        I_RS_Team_Member_User__r.Contact.I_RS_Manager__r.IsActive
                         from Team_Members__r
                WHERE I_RS_Team_Member_User__c != NULL AND 
                    I_RS_Team_Member_User__r.I_RS_Is_Researcher_User__c = '1' AND
                    I_RS_Team_Member_User__r.IsActive = TRUE)
            FROM Project_Proposal__c WHERE Id IN :projectProposalIds
        ]);
        System.debug('projectProposals '+projectProposals);

    }



    void addSharingForObject(List<SObject> objectsToShare, String objectName, String objectShareName){

        System.debug('addSharing');

        List<SObject> sharesToInsert = new List<SObject>();
        SObjectType shareType = Schema.getGlobalDescribe().get(objectShareName);

        Map<Id, Id> managerMap = new Map<Id, Id>();



        for (SObject objectToShare : objectsToShare){

            List<Id> projectProposalIds = recordIdToProjectProposalIdsMap.get((Id) objectToShare.Id);
            for (Id projectProposalId : projectProposalIds){

                Project_Proposal__c projectProposal = projectProposals.get(projectProposalId);

                if (projectProposal != null) {
                    if (projectProposal.Team_Members__r != null) {

                        for (Project_Team_Member__c teamMember : projectProposal.Team_Members__r) {

                            System.debug('teamMember ' + teamMember);

                            SObject newShare_TeamMember = newShare(teamMember, 'I_RS_Team_Member_User__c', objectToShare, 
                                objectName, null, shareType, 'Project_Proposal_Team_Member__c');
                            if (newShare_TeamMember != null) {
                                
                                sharesToInsert.add(newShare_TeamMember);

                                if (teamMember.I_RS_Team_Member_User__r.Contact != null &&
                                        teamMember.I_RS_Team_Member_User__r.Contact.I_RS_Manager__c != null &&
                                        teamMember.I_RS_Team_Member_User__r.Contact.I_RS_Manager__r.I_RS_Is_Researcher_User__c == '1' &&
                                        teamMember.I_RS_Team_Member_User__r.Contact.I_RS_Manager__r.IsActive
                                    ){
                                    SObject newShare_Manager = newShare(teamMember, 'I_RS_Team_Member_User__r.Contact.I_RS_Manager__c', objectToShare, 
                                        objectName, 'Edit', shareType, 'Project_Proposal_Team_Member_Manager__c');
                                    if (newShare_Manager != null)
                                        sharesToInsert.add(newShare_Manager);

                                    }

                            }
                        }

                    }
                }

            }

        }

        System.debug('sharesToInsert '+sharesToInsert);
        if (!sharesToInsert.isEmpty()){
            if (!sharesToInsert.isEmpty()){
                List<Database.SaveResult> shareInsertResults = 
                    Database.insert(sharesToInsert, false);
                    
                apexDebugLogs.addAll(
                    GlobalUtility.constructErrorLogsForDMLErrors(
                        shareInsertResults, sharesToInsert, 
                        'ProjectTeamMemberRecordAccess3', 'addSharingForObject')
                );
            }
        }

    }


    void purgeSharesForObject(List<SObject> recordsToRevoke, String objectShareName){

        System.debug('purgeSharesForObject '+objectShareName+' '+recordsToRevoke);

        Set<Id> recordIdsToRevoke = new Map<Id, SObject>(recordsToRevoke).keySet();
        system.debug('recordIdsToRevoke '+recordIdsToRevoke);

        String query = 'SELECT Id, UserOrGroupId, ParentId, RowCause, AccessLevel from '+objectShareName+
                ' WHERE ParentId in :recordIdsToRevoke AND '+
                '(RowCause = \'Project_Proposal_Team_Member__c\' OR ' +
                'RowCause = \'Project_Proposal_Team_Member_Manager__c\')';
        System.debug(query);
        List<SObject> sharesToPurge = Database.query(query);
        System.debug('sharesToPurge '+ sharesToPurge);

        if (!sharesToPurge.isEmpty()){
            List<Database.DeleteResult> shareDeleteResults = 
                Database.delete(sharesToPurge, false);
                
            apexDebugLogs.addAll(
                GlobalUtility.constructErrorLogsForDMLErrors(
                    shareDeleteResults, sharesToPurge, 
                    'ProjectTeamMemberRecordAccess3', 'purgeSharesForObject')
            );
        }

    }


    Id getRecordProjectProposalId(SObject record, String parentRelationship, String lookupFieldName){

        Id projectProposalId;

        if (parentRelationship != null){
            SObject parentObjectReference = record;
            for (String parentObjRefLevel : parentRelationship.split('\\.')){

                parentObjectReference = parentObjectReference.getSObject(parentObjRefLevel);

            }
            projectProposalId = (Id) parentObjectReference.get(lookupFieldName);
        }
        else {
            projectProposalId = (Id) record.get(lookupFieldName);
        }

        return projectProposalId;

    }


    //new shares (return list)
        //regular checks like before
            //Get manager ids = do this earlier

     SObject newShare(Project_Team_Member__c teamMember, String userIdField,
            SObject recordToShare, String objectName, String staticTeamMemberAccessLevel, SObjectType shareType, String shareReason){

        if (isDelete && triggerOldMap.keySet().contains(teamMember.Id))
            return null;

        String teamMemberAccessLevel;
        if (staticTeamMemberAccessLevel == null){
            teamMemberAccessLevel = getTeamMemberAccess(teamMember, recordToShare, objectName);
            if (teamMemberAccessLevel == 'None')
                return null;
        }
        else 
            teamMemberAccessLevel = staticTeamMemberAccessLevel;
        
        SObject uppermostObjectReference = teamMember;
        List<String> assigneeFieldHierarchy = userIdField.split('\\.');
        System.debug('assigneeFieldHierarchy '+assigneeFieldHierarchy);

        if (assigneeFieldHierarchy.size() > 1){

            for (Integer parentLevelIndex=0; parentLevelIndex < assigneeFieldHierarchy.size() - 1; 
                parentLevelIndex++) {
                String level = assigneeFieldHierarchy[parentLevelIndex];
                uppermostObjectReference = uppermostObjectReference.getSObject(level);
            }
        }

        System.debug('uppermostObjectReference '+uppermostObjectReference);

        String assigneeLookupFieldName = assigneeFieldHierarchy[assigneeFieldHierarchy.size() - 1];
        System.debug('assigneeLookupFieldName '+assigneeLookupFieldName);

        Id userIdToGrantAccess = (Id) uppermostObjectReference.get(assigneeLookupFieldName);
        System.debug('userIdToGrantAccess '+userIdToGrantAccess);

        Id recordIdToShare = (Id) recordToShare.get('Id');

        SObject share = shareType.newSObject();
        share.put('UserOrGroupId', userIdToGrantAccess);
        share.put('ParentId', recordIdToShare);
        share.put('AccessLevel', teamMemberAccessLevel);
        share.put('RowCause', shareReason);

        return share;

    }


    


    String getTeamMemberAccess(Project_Team_Member__c teamMember, SObject recordToShare, String objectName){

        System.debug('getTeamMemberAccess');
        System.debug(teamMember);
        System.debug(objectName);

        if (teamMember.I_RS_Active__c) {

            String customRuleAccessLevel = getCustomRuleAccessLevel(teamMember, recordToShare, objectName);
            System.debug('customRuleAccessLevel '+customRuleAccessLevel);
            if (customRuleAccessLevel != null)
                return customRuleAccessLevel;

            Project_Team_Member_Object_Access__mdt objectSharingSetting = sharingSettings.get(objectName);

            System.debug('Matching sharing record '+objectSharingSetting);

            if (objectSharingSetting.Project_Team_Member_Record_Access_Levels__r != null){
                for (Project_Team_Member_Record_Access__mdt recordSharingSetting :
                        objectSharingSetting.Project_Team_Member_Record_Access_Levels__r){

                    if (recordSharingSetting.I_RS_Role__c == teamMember.I_RS_Role__c) {
                        String roleBasedAccessLevel = recordSharingSetting.I_RS_Access_Level__c;
                        System.debug('Role based access for '+
                                recordSharingSetting.I_RS_Role__c+
                                ' on '+objectName+
                                ' is '+roleBasedAccessLevel);
                        return roleBasedAccessLevel;
                    }
                }
            }

            String defaultAccessLevel = objectSharingSetting.I_RS_Default_Access_Level__c;
            System.debug('Reverting to default access level: '+defaultAccessLevel);
            return defaultAccessLevel;

        }
        else
            return 'None';

    }

    String getCustomRuleAccessLevel(Project_Team_Member__c teamMember, SObject recordToShare, String objectName){

        //deprecated
        return null;

    }
}