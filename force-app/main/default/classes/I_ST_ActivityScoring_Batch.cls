/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_ActivityScoring_Batch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* @Description	  This class is used to calculate Activity Score on Affiliation
* @Params	  	  <sObjectName>: Object API Name, <recordTypeIds>: Set of RecordTypeIds for Score Calculation, lastNumberOfHours: Run batch past N Hours
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/
global class I_ST_ActivityScoring_Batch implements Database.Batchable<sObject>,Database.Stateful {
    
    private String sObjectName;
    private Set<Id> recordTypeIds;
    private Integer lastNumberOfHours;
    
    global I_ST_ActivityScoring_Batch(String sObjectName, Set<Id> recordTypeIds, Integer lastNumberOfHours) 
    {                                          
        this.sObjectName = sObjectName; 
        this.recordTypeIds = recordTypeIds; 
        this.lastNumberOfHours = (lastNumberOfHours > 0) ? lastNumberOfHours : 6;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime currentTime = System.now();
        Datetime durationPastHoursCurrentTime = System.now().addHours(-lastNumberOfHours);
        String strQuery = '';
        if(test.isRunningTest()){
            strQuery = 'SELECT Id,I_RM_Affiliation__c,I_ST_Incremental_Score__c,CreatedDate';
            strQuery += ' FROM ' + sObjectName + ' WHERE ';
            strQuery += ' LastModifiedDate >: durationPastHoursCurrentTime AND LastModifiedDate <=: currentTime';
            if(recordTypeIds !=null && !recordTypeIds.isEmpty()) {
                strQuery += ' AND RecordTypeId ' + ' IN : recordTypeIds ';
                
            }
            strQuery += ' AND I_ST_Score_Calculated__c = FALSE';
            strQuery += ' WITH SECURITY_ENFORCED ORDER BY I_RM_Affiliation__c DESC LIMIT 10';
        }
        else{
            strQuery = 'SELECT Id,I_RM_Affiliation__c,I_ST_Incremental_Score__c,CreatedDate FROM ' + sObjectName + ' WHERE LastModifiedDate >: durationPastHoursCurrentTime AND LastModifiedDate <=: currentTime';
            if(recordTypeIds !=null && !recordTypeIds.isEmpty()) {
                strQuery += ' AND RecordTypeId ' + ' IN : recordTypeIds ';                
            }
            strQuery += ' AND I_ST_Score_Calculated__c = FALSE WITH SECURITY_ENFORCED ORDER BY I_RM_Affiliation__c DESC'; 
        }//contactId      
        system.debug('return records:'+ database.getQueryLocator(strQuery));
        return database.getQueryLocator(strQuery);
    }
    
    //Collect all the Cases in Scope and Aggregate the Incremental Score for each affiliation//Contact
    global void execute(Database.BatchableContext BC, List<Case> cases) {
        List<Case> scopeCases = cases;
        List<sObject> updateToSobject = new List<sObject>();
        List<I_RM_Affiliation__c> affiliationsToUpdate = new List<I_RM_Affiliation__c>();//List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, List<Case>> mapContactWithSetOfCases = new Map<Id, List<Case>>();
        Set<Id> affiliationIdsForCases = new Set<Id>();//Set<Id> contactIdsForCases = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        if(scopeCases != null && scopeCases.size()>0) {
            for(Case eachcase: scopeCases) {//Replaced ContactId with I_RM_Affiliation__c.			
                if(eachcase.I_RM_Affiliation__c != null) {
                       //The only those Cases who's CreatedDate is Greater thanrelated Contact's Watermark Date
                       caseIds.add(eachcase.Id);
                       affiliationIdsForCases.add(eachcase.I_RM_Affiliation__c);
			   }
            }
        }
        //Get the aggregate incremental score of all cases the Contacts               
    	if(caseIds != null && caseIds.size()>0) {
            //Replaced contact to I_RM_Affiliation__c.			
            for(I_RM_Affiliation__c affiliation: [SELECT Id, I_RM_Incremental_Score__c, 
                              (
                                  SELECT I_RM_Affiliation__c, I_ST_Incremental_Score__c,
                                  I_ST_Prior_Incremental_Score__c
                                  FROM Cases__r
                                  WHERE ID IN: caseIds
                                  AND I_ST_Do_not_Score__c = False
                                  AND I_RM_Affiliation__c != NULL
                              ) 
                              FROM I_RM_Affiliation__c
                              WHERE Id IN: affiliationIdsForCases WITH SECURITY_ENFORCED]){
                                  //Create instance of I_RM_Affiliation__c for update with Aggregate of Incremental Score from related Cases
                                  Decimal contactScore = 0;
                                  if(affiliation.I_RM_Incremental_Score__c != null){
                                      contactScore = affiliation.I_RM_Incremental_Score__c;
                                  }
                                  
                                  Decimal caseScoreForEachContact = 0;
                                  Decimal casePriorScoreForEachContact = 0;
                                  List<Case> caseToUpdate = new List<Case>();
                                  
                                  for(Case eachCase: affiliation.Cases__r) {
                                     
                                      Case updatedCase = eachCase;
                                      updatedCase.I_ST_Score_Calculated__c = true;                                      
                                      caseToUpdate.add(updatedCase);
                                      
                                      if(eachCase.I_ST_Incremental_Score__c != null){
                                      caseScoreForEachContact = caseScoreForEachContact + eachCase.I_ST_Incremental_Score__c;
                                       }
                                      if(eachCase.I_ST_Prior_Incremental_Score__c != null){
                                          casePriorScoreForEachContact = casePriorScoreForEachContact + eachCase.I_ST_Prior_Incremental_Score__c;   
                                      	                                      }
                                  }
                                  //TJ: Add below I_RM_Affiliation__c list to list of sObjects(
                                  I_RM_Affiliation__c objNewAffiliation = new I_RM_Affiliation__c();
                                  objNewAffiliation.id = affiliation.Id;
                                  objNewAffiliation.I_RM_Incremental_Score__c = contactScore+(caseScoreForEachContact-casePriorScoreForEachContact);
                                  affiliationsToUpdate.add(objNewAffiliation);                                     
                                 
                                  updateToSobject.addall(caseToUpdate);
                                 
                              }
                        updateToSobject.addall(affiliationsToUpdate);
        }
    
    	if(updateToSobject != null && updateToSobject.size() > 0){			
            List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
            try{
                //Do not call trigger method for setting the Calculate Score on Affiliation				
                I_RM_AffiliationTriggerHandler.runmarkCalculateAffiliationScoreToTrue = True;
				
                I_ST_CaseTriggerHandler.setFired();
                Database.SaveResult[] results = Database.update(updateToSobject,false);
               
                errorLogs = GlobalUtility.constructErrorLogsForDMLErrors(results,updateToSobject,'I_ST_ActivityScoring_Batch2','execute');
            }
            catch(DmlException e){
                System.debug('Error in Activity Scoring records - ' + e.getMessage());
            }
    	}
	}

global void finish(Database.BatchableContext BC){
    
    I_ST_BatchScoring__c batchScoringCustomSetting = [SELECT Id,I_ST_Last_N_Hour__c,I_ST_BatchSize__c 
                                                      FROM I_ST_BatchScoring__c 
                                                      WHERE Name =: GlobalConstants.I_ST_INTERACTIONSCORING LIMIT 1];
    
    Integer lastNHours = (Integer)batchScoringCustomSetting.I_ST_Last_N_Hour__c;
    
    Set<Id> recordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_INTERACTIONSCORING).I_ST_RecordType_SFIDs__c);
    
    Integer batchSize = (Integer)batchScoringCustomSetting.I_ST_BatchSize__c;
    I_ST_InteractionScoring_Batch activityScoringBatch = new I_ST_InteractionScoring_Batch(GlobalConstants.INTERACTION_OBJECT_API_NAME,recordTypeIds,lastNHours);
    Id JobId = Database.executeBatch(activityScoringBatch,Integer.valueOf(batchSize));
    
    
}
}