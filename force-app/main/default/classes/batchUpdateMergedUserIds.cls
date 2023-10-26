public without sharing class batchUpdateMergedUserIds implements Database.batchable<Sobject> {    
    //it is assumed that winning contact of one merge is not again merged with another contact as a loosing one
    //In constructor get all the deleted contacts due to merge operations and their respective winning contacts
    
    
    public  Database.QueryLocator start(Database.BatchableContext info) {
        String query = 'select id, name, IsDeleted, MasterRecordId, I_RS_Related_User__c, CreatedDate, LastModifiedDate from Contact  where isDeleted = true  ALL ROWS';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext info, List<Contact> scope) {
        set<Id> contactIds = new set<Id>();
        for (Contact c: scope) {
            contactIds.add(c.MasterRecordId);
        }
        System.debug('execute masterContacts: ' + contactIds);
        System.debug('execute MasterContact query return: ' + [SELECT Id, I_RS_Related_User__c FROM Contact Where Id IN :contactIds]);
        Map<Id, Contact> newContactsMap = new Map<Id, Contact>([SELECT Id, I_RS_Related_User__c FROM Contact Where Id IN :contactIds]);
        System.debug('execute scope' + scope);
        System.debug('execute newContactsMap' + newContactsMap);
        PopulatePTMs(scope, newContactsMap);
        RecalculateShareRecords(scope, newContactsMap);
    }
    
    
    public void finish(Database.BatchableContext BC){
    }
    
    private void PopulatePTMs(List<Contact> oldContacts, Map<Id, Contact> newContactsMap){
        List<SObject> updateObjects = new List<SObject>();
        Id newUser;

        // Update Project Proposal
        boolean recModified;
        for (Project_Proposal__c pp: [SELECT Id, I_RS_Lead_Chief_Investigator__c, I_RS_LeadChiefInvestigator__c, OwnerId FROM Project_Proposal__c WHERE I_RS_Lead_Chief_Investigator__c IN : newContactsMap.keySet()]) {
            recModified = false;
            newUser = newContactsMap.get(pp.I_RS_Lead_Chief_Investigator__c).I_RS_Related_User__c;
            if (pp.I_RS_LeadChiefInvestigator__c != newUser) {
                pp.I_RS_LeadChiefInvestigator__c = newUser;
            	recModified = true;
            }
            if (pp.ownerId != newUser) {
                pp.ownerId = newUser;
            	recModified = true;
            }
            updateObjects.add(pp);    
        }

        // Update Ethics Request
        for (Ethics_Request__c er: [SELECT Id, I_RS_Principal_Investigator_Contact__c, I_RS_Principal_Investigator__c, OwnerId FROM Ethics_Request__c WHERE I_RS_Principal_Investigator_Contact__c IN : newContactsMap.keySet()]) {
            recModified = false;
            newUser = newContactsMap.get(er.I_RS_Principal_Investigator_Contact__c).I_RS_Related_User__c;
            if (er.I_RS_Principal_Investigator__c != newUser) {
                er.I_RS_Principal_Investigator__c = newUser;
            	recModified = true;
            }
            if (er.ownerId != newUser) {
                er.ownerId = newUser;
            	recModified = true;
            }
            updateObjects.add(er);    
        }
        if (updateObjects.size() > 0) {
        	update updateObjects;
        }
        //System.debug('PopulatePTMs updateObjects' + updateObjects);
    }
    
    private void RecalculateShareRecords(List<Contact> oldContacts, Map<Id, Contact> newContactsMap){
        List<SObject> insertObjects = new List<SObject>();
        List<SObject> deleteObjects = new List<SObject>();
        Set<String> rowCauseSet = new set<String>();
    	Map<Id, Id> oldContactIdUserMap = new Map<Id, Id>();
    	Map<Id, Id> userOldNewMap = new Map<Id, Id>();
        for (Contact c: oldContacts){
            if (c.MasterRecordId != null) {
                oldContactIdUserMap.put(c.Id, c.I_RS_Related_User__c);
                userOldNewMap.put(c.I_RS_Related_User__c, newContactsMap.get(c.MasterRecordId).I_RS_Related_User__c);
            }
        }
        //System.debug('RecalculateShareRecords oldContactIdUserMap' + oldContactIdUserMap);
        //System.debug('RecalculateShareRecords userOldNewMap' + userOldNewMap);
        
        rowCauseSet.add(Schema.Project_Proposal__Share.rowCause.Project_Proposal_Team_Member__c);
        rowCauseSet.add(Schema.Project_Proposal__Share.rowCause.Project_Proposal_Team_Member_Manager__c);
        //calculate Project share records
        for (Project_Proposal__share pps: [SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM Project_Proposal__share WHERE UserOrGroupId IN :oldContactIdUserMap.values() AND RowCause IN :rowCauseSet]) {
            if (pps.UserOrGroupId != userOldNewMap.get(pps.UserOrGroupId)) {
                deleteObjects.add(pps);  
                insertObjects.add(new Project_Proposal__share(ParentId = pps.ParentId, RowCause = pps.RowCause, AccessLevel = pps.AccessLevel, UserOrGroupId = userOldNewMap.get(pps.UserOrGroupId)));
            }
        }

        //calculate Agreement share records
        for (Contract__share cs: [SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM Contract__share WHERE UserOrGroupId IN :oldContactIdUserMap.values() AND RowCause IN :rowCauseSet]) {
            if (cs.UserOrGroupId != userOldNewMap.get(cs.UserOrGroupId)) {
                deleteObjects.add(cs);  
                insertObjects.add(new Contract__share(ParentId = cs.ParentId, RowCause = cs.RowCause, AccessLevel = cs.AccessLevel, UserOrGroupId = userOldNewMap.get(cs.UserOrGroupId)));
            }
        }

        //calculate Ethics share records
        //System.debug('Ethics SOQL: '+[SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM Ethics_Request__share]);
        //System.debug('Old Users: '+oldContactIdUserMap.values());
		for (Ethics_Request__share ers: [SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel FROM Ethics_Request__share WHERE UserOrGroupId IN :oldContactIdUserMap.values()]) {
            if (ers.UserOrGroupId != userOldNewMap.get(ers.UserOrGroupId)) {
                deleteObjects.add(ers);  
                insertObjects.add(new Ethics_Request__share(ParentId = ers.ParentId, RowCause = ers.RowCause, AccessLevel = ers.AccessLevel, UserOrGroupId = userOldNewMap.get(ers.UserOrGroupId)));
            }
        }
        
        //System.debug('RecalculateShareRecords insertObjects' + insertObjects);
        //System.debug('RecalculateShareRecords deleteObjects' + deleteObjects);
        if (insertObjects.size() > 0) {
        	insert insertObjects;
        }
        
        if (deleteObjects.size() > 0) {
        	delete deleteObjects;
        }
    }
}