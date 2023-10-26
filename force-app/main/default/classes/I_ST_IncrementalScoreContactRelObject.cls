/**
─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_IncrementalScoreContactRelObject
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author Teja Yenduri
* @date 2022-02-18
* 
* 
* 
* @description : This class is used to calculate incremental score of related objects of Affiliation
* * @Params  : String sObjectName, String sObjectIncrementScorefield, Set<Id> objectRecordTypeIds,List<sObject> sObjectRecords 
* * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class I_ST_IncrementalScoreContactRelObject{
    
    // calculate final lead score based on field match with diferent condition
    public static void calcIncrementalScoreContactRelObject(String sObjectName, String sObjectIncrementScorefield, Set<Id> recordTypeIds,
                                                  
                                                            List<sObject> sObjectRecords,Map<Id,sObject> oldMap){
                                                                
                                                                Map<String, List<I_ST_Lead_Scoring__mdt>> mapExtractPicklistFields = new Map<String, List<I_ST_Lead_Scoring__mdt>>();
                                                                
                                                                //Populate the map of Custom Metadata Field (as key) with their corresponding available records for the mapping attribute
                                                                for(I_ST_Lead_Scoring__mdt leadScoringMappingRec: I_ST_Lead_Scoring__mdt.getAll().values()) {
                                                                    if((leadScoringMappingRec.I_ST_Active__c) && leadScoringMappingRec.I_ST_Object__c == sObjectName) {
                                                                        if(mapExtractPicklistFields.containsKey(leadScoringMappingRec.I_ST_Field_API_Name__c)) {
                                                                            List<I_ST_Lead_Scoring__mdt> listMetadata = mapExtractPicklistFields.get(leadScoringMappingRec.I_ST_Field_API_Name__c);
                                                                            listMetadata.add(leadScoringMappingRec);
                                                                            mapExtractPicklistFields.put(leadScoringMappingRec.I_ST_Field_API_Name__c, listMetadata);
                                                                        } else {
                                                                            mapExtractPicklistFields.put(leadScoringMappingRec.I_ST_Field_API_Name__c, new List<I_ST_Lead_Scoring__mdt> { leadScoringMappingRec });
                                                                        }
                                                                    }
                                                                }
                                                                
                                                                List<sObject> updateToSobject = new List<sObject>();
                                                                List<sObject> sObjectQueryRecords = new List<sObject>();
                                                                
                                                                sObjectQueryRecords = I_ST_IncrementalScoreContactRelObject.getSobjectRecords(sObjectRecords,sObjectName,recordTypeIds,mapExtractPicklistFields.keySet());           
                                                                //Calculate Incremental score based on object fields
                                                                updateToSobject = GlobalUtility.calculateScoreonObjectFields(mapExtractPicklistFields,sObjectQueryRecords,sObjectIncrementScorefield,sObjectName,oldMap); 
                                                                //Process list of sObject records to update.
                                                                if(updateToSobject.size() > 0){
                                                                    
                                                                    if(sObjectName.equalsIgnoreCase(GlobalConstants.CASE_OBJECT_API_NAME)){
                                                                        I_ST_CaseTriggerHandler.setFired();
                                                                    }
                                                                    if(sObjectName.equalsIgnoreCase(GlobalConstants.INTERACTION_OBJECT_API_NAME)){
                                                                        I_ST_InteractionTriggerHandler.setFired();
                                                                    }                                                                    
                                                                    
                                                                    List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
                                                                    try{
                                                                        Database.SaveResult[] results = Database.update(updateToSobject,false);
                                                                        errorLogs = GlobalUtility.constructErrorLogsForDMLErrors(results,updateToSobject,'I_ST_IncrementalScoreContactRelObject','calcIncrementalScoreContactRelObjec');
                                                                        
                                                                    }
                                                                    catch(DmlException e){
                                                                        System.debug('Error in affiliation scoring records - ' + e.getMessage());
                                                                    }
                                                                }            
                                                            }
    
    
    //get sojbect records
    public static List<sObject> getSobjectRecords(List<sObject> sObjectRecords, String sObjectName, Set<Id> recordTypeIds, Set<String> fieldsForQuery){
        List<String> allFields =  new List<String>();
        
        if(fieldsForQuery!= null && fieldsForQuery.size() > 0) {
            for(String fieldAPIName : fieldsForQuery){
                allFields.add(fieldAPIName);
            }
        }
        
        String strFields = String.join(allFields,', ');
        
        String strQuery = 'SELECT Id, '+strFields+ ' FROM ' + sObjectName + ' WHERE';
        
        strQuery += '  Id IN : sObjectRecords ';
        
        if(recordTypeIds != null && recordTypeIds.size()>0){
            strQuery += ' AND recordtypeId IN :recordTypeIds';
        }
        
        strQuery += ' WITH SECURITY_ENFORCED';
        
        system.debug('strquery:'+strQuery);
        
        List<sObject> sObjectQueryRecords = Database.query(strQuery);
        return sObjectQueryRecords;
    }
    
}