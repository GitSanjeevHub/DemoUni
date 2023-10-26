/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_InteractionTriggerHandler
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* @Description	  This class is used to schedule the batch job to calaculate Activity Score on Interaction
* @Params	  	  
*/
public class I_ST_InteractionTriggerHandler {
 	private static Boolean hasFired = false;
    public static String interactionRecordType = GlobalConstants.INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION;
    public static String interactionIncrementField = GlobalConstants.INTERACTION_INCREMENTAL_SCORE_FIELD;
    
    public static Boolean hasFired() {
        return hasFired;
    }
    
    public static void setFired() {
        hasFired = true;
    }
    
    public static void setNotFired() {
        hasFired = false;
    }
    
    public static void execute(){
        if (Trigger.isAfter && Trigger.isInsert){     
            if(!hasFired){
                List<I_ST_Interaction__c> newInteractionList = new List<I_ST_Interaction__c>();
                Set<Id> recordTypeIds = new Set<Id>();
                for(I_ST_Interaction__c newInteraction: (List<I_ST_Interaction__c>)Trigger.New){
                    if(isValidISTScoringInteractionRecordTypeId(newInteraction.RecordTypeId)) {
                        newInteractionList.add(newInteraction);
                        recordTypeIds.add(newInteraction.RecordTypeId);
                    }
                }
                if(newInteractionList.size() > 0) {                    
                    I_ST_InteractionTriggerHelper.calculateIncrementalScoreOnInteraction(GlobalConstants.INTERACTION_OBJECT_API_NAME,interactionIncrementField,recordTypeIds,newInteractionList);
                }
            }
            
        }
        
        if (Trigger.isAfter && Trigger.isUpdate){ 
            if(!hasFired){
                List<I_ST_Interaction__c> newInteractionList = new List<I_ST_Interaction__c>();
                Set<Id> recordTypeIds = new Set<Id>();
                for(I_ST_Interaction__c  newInteraction: (List<I_ST_Interaction__c>)Trigger.New){
                    if(isValidISTScoringInteractionRecordTypeId(newInteraction.RecordTypeId)) {
                        newInteractionList.add(newInteraction);
                        recordTypeIds.add(newInteraction.RecordTypeId);
                    }
                }
                if(newInteractionList.size() > 0) {
                  I_ST_InteractionTriggerHelper.calculateIncrementalScoreOnInteraction(GlobalConstants.INTERACTION_OBJECT_API_NAME,interactionIncrementField,recordTypeIds,newInteractionList);
                }
                setFired();
            }
        }
    }
    
    //check if the Case records record type Id is valid for Scoring
    private static Boolean isValidISTScoringInteractionRecordTypeId(Id recordTypeId) {
        Boolean validRecordType = false;
        String strRecordDevName = Schema.SObjectType.I_ST_Interaction__c.getRecordTypeInfosById().get(recordTypeId).getDeveloperName();
        if(GlobalConstants.INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION == strRecordDevName) {
            validRecordType = true;
        }
        return validRecordType;
    }
}