public without sharing class adhocThesisSharingCalcBatch implements Database.batchable<SObject> {

    public String queryStr;
    public set<Id> contactSet;
    public Set<Id> thesisIds;

    public adhocThesisSharingCalcBatch(set<Schema.sObjectType> objectTypes, List<Id> recIds, List<Id> contactIds){
        queryStr = '';
        thesisIds = new Set<Id>();
        
        //populate contacts in set
        contactSet = new set<Id>();
        for (Id ctId: contactIds) {
            contactSet.add(ctId);
        }
        
        //get all ProjectProposal IDs
        for (Id thId: recIds) {
            if (thId.getSObjectType() == Graduate_Research_Examination__c.SobjectType) {
                thesisIds.add(thId);    
            }
        }
        
        if ((thesisIds.size() > 0) || (objectTypes.contains(Graduate_Research_Examination__c.SobjectType))) {
            queryStr = 'SELECT Id, I_RS_Student__c, I_RS_Student_User__c, I_RS_Principal_Supervisor__c, I_RS_PS_User__c, '+
                       'I_RS_Alternate_Supervisor__c, I_RS_AS_User__c, I_RS_Director_of_Graduate_Research__c, '+
                       'I_RS_DGR_User__c, I_RS_Substitute_DirectorGraduateResearch__c, I_RS_SDGR_User__c, '+
                	   'I_RS_Board_of_Graduate_Research__c, I_RS_BGR_User__c, I_RS_Substitute_Board_Graduate_Research__c, '+
                		'I_RS_SDGR_Approver_User_Id__c, '+
                       'I_RS_SBGR_User__c FROM Graduate_Research_Examination__c';
            if (thesisIds.size() > 0) {
                queryStr = queryStr + ' WHERE Id IN :thesisIds';
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
    	Map<Id, Graduate_Research_Examination__c> oldList = new Map<Id, Graduate_Research_Examination__c>();
    	Map<Id, Graduate_Research_Examination__c> newList = new Map<Id, Graduate_Research_Examination__c>();
        Graduate_Research_Examination__c oldRec;
        for (SObject objRec: scope) {
            if (objRec instanceof Graduate_Research_Examination__c){
                Graduate_Research_Examination__c greRec = (Graduate_Research_Examination__c) objRec;
                oldRec = new Graduate_Research_Examination__c(Id = greRec.Id) ;
                if (contactSet.size() == 0) {
                    oldList.put(greRec.Id, oldRec);
                    newList.put(greRec.Id, greRec);
                } else if ((contactSet.Contains(greRec.I_RS_Student__c)) || 
                           (contactSet.Contains(greRec.I_RS_Principal_Supervisor__c)) || 
                           (contactSet.Contains(greRec.I_RS_Alternate_Supervisor__c)) || 
                           (contactSet.Contains(greRec.I_RS_Director_of_Graduate_Research__c)) || 
                           (contactSet.Contains(greRec.I_RS_Substitute_DirectorGraduateResearch__c)) || 
                           (contactSet.Contains(greRec.I_RS_Board_of_Graduate_Research__c)) || 
                           (contactSet.Contains(greRec.I_RS_Substitute_Board_Graduate_Research__c))){
                               
                               if (!contactSet.Contains(greRec.I_RS_Student__c)) {
                                    oldRec.I_RS_Student__c = greRec.I_RS_Student__c;  
                               }
                               if (!contactSet.Contains(greRec.I_RS_Principal_Supervisor__c)) {
                                    oldRec.I_RS_Principal_Supervisor__c = greRec.I_RS_Principal_Supervisor__c;  
                               }
                               if (!contactSet.Contains(greRec.I_RS_Alternate_Supervisor__c)) {
                                    oldRec.I_RS_Alternate_Supervisor__c = greRec.I_RS_Alternate_Supervisor__c;  
                               }
                               if (!contactSet.Contains(greRec.I_RS_Director_of_Graduate_Research__c)) {
                                    oldRec.I_RS_Director_of_Graduate_Research__c = greRec.I_RS_Director_of_Graduate_Research__c;  
                               }
                               if (!contactSet.Contains(greRec.I_RS_Substitute_DirectorGraduateResearch__c)) {
                                    oldRec.I_RS_Board_of_Graduate_Research__c = greRec.I_RS_Board_of_Graduate_Research__c;  
                               }
                               if (!contactSet.Contains(greRec.I_RS_Board_of_Graduate_Research__c)) {
                                    oldRec.I_RS_Substitute_DirectorGraduateResearch__c = greRec.I_RS_Substitute_DirectorGraduateResearch__c;  
                               }
                               if (!contactSet.Contains(greRec.I_RS_Substitute_Board_Graduate_Research__c)){
                                    oldRec.I_RS_Substitute_Board_Graduate_Research__c = greRec.I_RS_Substitute_Board_Graduate_Research__c;  
                               }
                    oldList.put(greRec.Id, oldRec);
                    newList.put(greRec.Id, greRec);
                }            
        	}
        }
        if (newList.size() > 0) {
            GraduateResearchExaminationHelper.calculateAccessForAffectedThesis(newList, oldList);
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}