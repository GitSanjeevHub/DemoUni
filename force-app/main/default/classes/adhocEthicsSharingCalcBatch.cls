public without sharing class adhocEthicsSharingCalcBatch  implements Database.batchable<SObject> {
    
    public String queryStr;
    public set<Id> contactSet;
    public Set<Id> ethicsRequestIds;
    public final set<Schema.sObjectType> objTypes;
    public final List<Id> rIds;
    public final List<Id> cIds;

    public adhocEthicsSharingCalcBatch(set<Schema.sObjectType> objectTypes, List<Id> recIds, List<Id> contactIds){
        objTypes = objectTypes;
        rIds = recIds;
        cIds = contactIds;

        queryStr = '';
        ethicsRequestIds = new Set<Id>();
        
        //populate contacts in set
        contactSet = new set<Id>();
        for (Id ctId: contactIds) {
            contactSet.add(ctId);
        }
        
        //get all ProjectProposal IDs
        for (Id erId: recIds) {
            if (erId.getSObjectType() == Ethics_Request__c.SobjectType) {
                ethicsRequestIds.add(erId);    
            }
        }
        
        if ((ethicsRequestIds.size() > 0) || (objectTypes.contains(Ethics_Request__c.SobjectType))) {
            queryStr = 'SELECT Id FROM Ethics_Request__c';
            if (ethicsRequestIds.size() > 0) {
                queryStr = queryStr + ' WHERE Id IN :ethicsRequestIds';
            }
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('Query String: ' + queryStr);
        //if empty query string, query user record as a dummy operation
        if (queryStr == '') {
            Id uId = UserInfo.getUserId();
            queryStr = 'SELECT Id, Name FROM User WHERE Id = :uId';
        }
        return Database.getQueryLocator(queryStr);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Id> erIds = new List<Id>();
        //List of Research Perosnnel whose apex sharing should be calculated
        List<Research_Personnel__c> rpList = new List<Research_Personnel__c>();
        
        for (SObject objRec: scope) {
            if (objRec instanceof Ethics_Request__c){
                Ethics_Request__c erRec = (Ethics_Request__c)objRec;
            	erIds.add(erRec.Id);
            }
        }
        
        System.debug('ethicsRequestIds: ' + ethicsRequestIds);
        System.debug('erIds: ' + erIds);
        if (erIds.size() > 0) {
            Set<Id> rpContacts;
            for (Research_Personnel__c rp: [SELECT Id, I_RS_Ethics_Request__c, I_RS_Contact_Researcher__c, I_RS_Reseracher_User_Id__c FROM Research_Personnel__c WHERE I_RS_Ethics_Request__c IN :erIds]) {
        		System.debug('rp: ' + rp);
        		System.debug('rp.I_RS_Contact_Researcher__c: ' + rp.I_RS_Contact_Researcher__c);
                if(rp.I_RS_Contact_Researcher__c <> null){
                    if (contactSet.size() == 0) {
                		rpList.add(rp);    
                    } else if (contactSet.contains(rp.I_RS_Contact_Researcher__c)){
                		rpList.add(rp);    
                    }
                }
            }
        }
        
        System.debug('rpList: ' + rpList);
        if (rpList.size() >0) {
            Id userId;
            Set<String> rpKeys = new Set<String>();
            Set<Id> rpUserIds = new Set<Id>();
            Set<Id> rpEthcisRequestIds = new Set<Id>();
            List<Ethics_Request__share> grantList = new List<Ethics_Request__share>();
            for (Research_Personnel__c rp: rpList){
                if (rp.I_RS_Reseracher_User_Id__c != null) {
                    userId = Id.Valueof(rp.I_RS_Reseracher_User_Id__c);
                    rpKeys.add(''+rp.I_RS_Ethics_Request__c + userId);
                    rpUserIds.add(userId);
                    rpEthcisRequestIds.add(rp.I_RS_Ethics_Request__c);
                    
                    Ethics_Request__share erShare = new Ethics_Request__share();
                    erShare.ParentId = rp.I_RS_Ethics_Request__c;
                    erShare.UserOrGroupId = rp.I_RS_Reseracher_User_Id__c;
                    erShare.RowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;                        
                    erShare.AccessLevel = GlobalConstants.ETHICS_TEAM_MEMBER_SHARING_ACCESS;
                    grantList.add(erShare);
                }
            }
            
            //get existing similar share records for deletions
            String delKey;
            List<Ethics_Request__share> revokeList = new List<Ethics_Request__share>();
            for (Ethics_Request__share ers: [SELECT Id, ParentId, UserOrGroupId FROM Ethics_Request__share WHERE ParentId IN :rpEthcisRequestIds AND UserOrGroupId IN :rpUserIds AND RowCause = :Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c ]) {
            	delKey = '' + ers.ParentId+ers.UserOrGroupId;
                if (rpKeys.contains(delKey)){
                	revokeList.add(ers);    
                }
            }
            
            if (revokeList.size() > 0){
                Database.delete(revokeList, false);
            }
            
            if (grantList.size() > 0) {
                Database.insert(grantList, false);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        Database.executeBatch(new adhocThesisSharingCalcBatch(objTypes, rIds, cIds));
    }
}