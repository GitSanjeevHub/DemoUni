/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_InteractionScoring_Batch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* @Description	  This class is used to calculate Activity Score on Affiliation
* @Params	  	  <sObjectName>: Object API Name, <recordTypeIds>: Set of RecordTypeIds for Score Calculation, lastNumberOfHours: Run batch past N Hours
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/
global class I_ST_InteractionScoring_Batch implements Database.Batchable<sObject>,Database.Stateful {
    
    private String sObjectName;
    private Set<Id> recordTypeIds;
    private Integer lastNumberOfHours;
    
    
    global I_ST_InteractionScoring_Batch(String sObjectName, Set<Id> recordTypeIds, Integer lastNumberOfHours) 
    {                                          
        this.sObjectName = sObjectName; 
        this.recordTypeIds = recordTypeIds; 
        this.lastNumberOfHours = (lastNumberOfHours > 0) ? lastNumberOfHours : 6;        
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('Batch Start');
        Datetime currentTime = System.now();
        Datetime durationPastHoursCurrentTime = System.now().addHours(-lastNumberOfHours);
       
        String strQuery = 'SELECT Id,I_RM_Affiliation__c,I_ST_Incremental_Score__c,CreatedDate';//I_ST_Contact__c,I_ST_Incremental_Score__c
        strQuery += ' From ' + sObjectName + ' WHERE ';
        strQuery += ' CreatedDate >: durationPastHoursCurrentTime AND CreatedDate  <=: currentTime';
        if(recordTypeIds !=null && !recordTypeIds.isEmpty()) {
            strQuery += ' AND RecordTypeId ' + ' IN : recordTypeIds ';  
        }
        strQuery += ' AND I_ST_Score_Calculated__c = FALSE';
        strQuery += ' WITH SECURITY_ENFORCED ORDER BY I_RM_Affiliation__c DESC'; //I_ST_Contact__c
        
       
        return database.getQueryLocator(strQuery);
    }
    
    //Collect all the Interactions in Scope and Aggregate the Incremental Score for each Contact
    global void execute(Database.BatchableContext BC, List<I_ST_Interaction__c> Interactions) {
        
        List<I_ST_Interaction__c> scopeInteractions = Interactions;
        List<sObject> updateToSobject = new List<sObject>();
        Map<Id, List<I_ST_Interaction__c>> mapAffiliationWithInteraction = new Map<Id, List<I_ST_Interaction__c>>();
        Map<Id,decimal> mapAffiliationWithIncrementalScore = new Map<Id,decimal>();
        Set<Id> affiliationIdsForInteraction = new Set<Id>();
        Set<Id> InteractionIds = new Set<Id>();
        if(scopeInteractions != null && scopeInteractions.size()>0) {
            for(I_ST_Interaction__c eachInteraction: scopeInteractions) {
                if(eachInteraction.I_RM_Affiliation__c != null){
				
                       InteractionIds.add(eachInteraction.Id);
                       affiliationIdsForInteraction.add(eachInteraction.I_RM_Affiliation__c);                     
                   }
            }
            
        }
        
        List<I_RM_Affiliation__c> affiliationsToUpdate = new List<I_RM_Affiliation__c>();
        if(InteractionIds != null && InteractionIds.size()>0) {
            for(I_RM_Affiliation__c affiliation: [SELECT Id, I_RM_Incremental_Score__c, 
                              (
                                  SELECT I_RM_Affiliation__c, I_ST_Incremental_Score__c
                                  FROM Interactions__r
                                  WHERE ID IN: InteractionIds
                              )
                              FROM I_RM_Affiliation__c
                              WHERE ID IN: affiliationIdsForInteraction]) {
                                  Decimal contactScore = 0;
                                  if(affiliation.I_RM_Incremental_Score__c != null){
                                      contactScore = affiliation.I_RM_Incremental_Score__c;
                                  }
                                  Decimal interactionScoreForEachContact = 0; 
                                  List<I_ST_Interaction__c> interactionsToUpdate = new List<I_ST_Interaction__c>();
                                  for(I_ST_Interaction__c interactionsRec: affiliation.Interactions__r) {
                                      I_ST_Interaction__c updatedInteraction = interactionsRec;
                                      updatedInteraction.I_ST_Score_Calculated__c = true;
                                      interactionsToUpdate.add(updatedInteraction);
                                      interactionScoreForEachContact = interactionScoreForEachContact + interactionsRec.I_ST_Incremental_Score__c;                                     
                                  }                                  
                                  
                                  affiliationsToUpdate.add(new I_RM_Affiliation__c(Id=affiliation.Id, I_RM_Incremental_Score__c=interactionScoreForEachContact+contactScore));
                                  
                               updateToSobject.addall(interactionsToUpdate);
                              }
              updateToSobject.addall(affiliationsToUpdate);
            
        }
        if(updateToSobject != null && updateToSobject.size() > 0){			
            List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
            try{
                
               	I_RM_AffiliationTriggerHandler.runmarkCalculateAffiliationScoreToTrue = True;
                I_ST_InteractionTriggerHandler.setFired();
                Database.SaveResult[] results = Database.update(updateToSobject,false);
                errorLogs = GlobalUtility.constructErrorLogsForDMLErrors(results,updateToSobject,'I_ST_Interaction_ActivityScoring_Batch','execute');
            }
            catch(DmlException e){
                System.debug('Error in Activity Scoring records - ' + e.getMessage());
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
        
    }
}