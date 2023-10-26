public without sharing class adhocProjectProposalSharingCalcBatch  implements Database.batchable<SObject> {
    
    public String queryStr;
    public set<Id> contactSet;
    public set<Id> projectProposalIds;
    public final set<Schema.sObjectType> objTypes;
    public final List<Id> rIds;
    public final List<Id> cIds;
    
    //To act on Project Proposal
    public adhocProjectProposalSharingCalcBatch(set<Schema.sObjectType> objectTypes, List<Id> recIds, List<Id> contactIds){
        System.debug('ObjectTypes: ' + objectTypes);
        objTypes = objectTypes;
        rIds = recIds;
        cIds = contactIds;
    
        queryStr = '';
        projectProposalIds = new Set<Id>();
        
        //populate contacts in set
        contactSet = new set<Id>();
        for (Id ctId: contactIds) {
            contactSet.add(ctId);
        }
        
        System.debug('ContactIds Input: ' + contactIds);
        System.debug('contactSet batch variable: ' + contactSet);
        
        //get all ProjectProposal IDs
        for (Id ppId: recIds) {
            if (ppId.getSObjectType() == Project_Proposal__c.SobjectType) {
                projectProposalIds.add(ppId);    
            }
        }
        
        if ((projectProposalIds.size() > 0) || (objectTypes.contains(Project_Proposal__c.SobjectType))) {
            queryStr = 'SELECT Id FROM Project_Proposal__c';
            if (projectProposalIds.size() > 0) {
                queryStr = queryStr + ' WHERE Id IN :projectProposalIds';
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
        List<Id> ppIds = new List<Id>();
        //List of PTM whose apex sharing should be calculated
        List<Project_Team_Member__c> ptmList = new List<Project_Team_Member__c>();
        //build list of project proposal and its members whose hierarchy's sharing should be calculated.
        Map<Id, set<Id>> projectProposalTMContactMap = new Map<Id, set<Id>>();
        
        for (SObject objRec: scope) {
            if (objRec instanceof Project_Proposal__c){
                Project_Proposal__c ppRec = (Project_Proposal__c)objRec;
            	ppIds.add(ppRec.Id);
            }
        }
        
        if (ppIds.size() >0) {
            Set<Id> ptmContacts;
            for (Project_Team_Member__c ptm: [SELECT Id, I_RS_Project_Proposal__c, I_RS_Project_Team_Member__c FROM Project_Team_Member__c WHERE I_RS_Project_Proposal__c IN :ppIds]) {
                if (!projectProposalTMContactMap.containsKey(ptm.I_RS_Project_Proposal__c)) {
					ptmContacts =  new Set<Id>();
                } else {
					ptmContacts =  projectProposalTMContactMap.get(ptm.I_RS_Project_Proposal__c);
                }
				               
                if (contactSet.size() == 0) { //we have to do for all project team member
                    System.debug('no contacts passed as parameters');
                	ptmList.add(ptm);
                    ptmContacts.add(ptm.I_RS_Project_Team_Member__c);
                } else {// for specific contact if they are part of the team
                    if (contactSet.contains(ptm.I_RS_Project_Team_Member__c)) {
                    	System.debug('contacts passed as parameter: ' + ptm.I_RS_Project_Team_Member__c);
                		ptmList.add(ptm);
                    	ptmContacts.add(ptm.I_RS_Project_Team_Member__c);
                    }    
                }
                projectProposalTMContactMap.put(ptm.I_RS_Project_Proposal__c, ptmContacts);
            }
            
            if (ptmList.size() > 0) {
            	ProjectTeamMemberAccess4.runForTeamMembers(ptmList, 'all', false, false);    
            }
            if (projectProposalTMContactMap.size() > 0) {
            	ProjectTeamMemberHierarchyAccess.initialiseStaticMapsVariables();  
                System.debug('projectProposalTMContactMap:' + projectProposalTMContactMap);
        		ProjectTeamMemberHierarchyAccess.recalculateAllRelatedObjectHierarchyShares(projectProposalTMContactMap.Keyset(), ProjectTeamMemberHierarchyAccess.getProposalHierarchyUserMap(projectProposalTMContactMap));
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        if (contactSet.size()>0){
            System.debug('finish contactSet: ' + contactSet);
        	System.enqueueJob(new HierarchySharesForContactsQueueable(contactSet, null, false, false));
        }
        Database.executeBatch(new adhocEthicsSharingCalcBatch(objTypes, rIds, cIds));
    }
}