//This is a utility class for common resuable code components 
public class GlobalUtility {
    
    static {
        //any pre logic
    }
    
    private static User currentUser;
    
    public static boolean currentUserIsResearcher(){
        if ((currentUser == null) || (Test.isRunningTest())){
            currentUser = [SELECT Id, Name, I_RS_Is_Researcher_User__c FROM User WHERE Id = :UserInfo.getUserId()];    
        }
        return (currentUser.I_RS_Is_Researcher_User__c == '1');
    }
    
    public static Id getIdValueOf(String strVal){        
        if ((strVal == null) || (strVal.trim() == '')) {
            return null;
        } else {
            return Id.valueOf(strVal);
        }
    }
    
    /**
* @description       This method is used to identify which objects have been marked for skip trigger
* @param             String 
* @return            Boolean
* @throws            NA
*/
    public static Boolean isTriggerDisabled(String objType){
        Boolean isDisabled = false;
        if(String.isNotBlank(objType)){
            System_Switch__c custSettings = System_Switch__c.getInstance();
            if(custSettings != null){
                String objsDisabled = custSettings.I_RS_ObjectTriggersToBeDisabled__c != null ?
                    custSettings.I_RS_ObjectTriggersToBeDisabled__c.trim() : null ;
                if(String.isNotBlank(objsDisabled)){
                    Set<String> objSet = new Set<String>();
                    objSet.addAll(trimStringList(objsDisabled.split(GlobalConstants.COMMA)));
                    System.debug('** objSet ==>'+objSet);
                    if(objSet.contains(objType) && custSettings.I_RS_DisableTriggers__c){
                        isDisabled = true;
                    }
                }
            }
        }
        System.debug('** Triggers Disabled ==>'+isDisabled);
        return isDisabled;
    }
    
    /**
* @description       This method is used to trim content of list
* @param             strList - List<String> 
* @return            List<String>
* @throws            NA
*/
    public static List<String> trimStringList(List<String> strList){
        List<String> retList = new List<String>();
        for(String str : strList){
            retList.add(str.trim());
        }
        System.debug('** retList ==>'+retList);
        return retList;
    }
    
    
    /**
* @description       This method is used to return fields in any field set
* @param             fieldSetName - String,  objectName - String
* @return            List<Schema.FieldSetMember>
* @throws            NA
*/
    public static List<Schema.FieldSetMember> getFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        
        return fieldSetObj.getFields(); 
    }
    
    
    public static Map<Id, SObject> getParentRecordMap(String objectType, String fields, Set<Id> idsToQuery){
        
        String query = 'SELECT ' + fields + ' FROM ' + objectType + ' WHERE Id IN :idsToQuery';
        List<SObject> parentObjectList = Database.query(query);
        
        Map<Id, SObject> parentObjectMap = new Map<Id, SObject>(parentObjectList);
        
        return parentObjectMap;
        
    }
    
    
    public static Set<Id> getParentIdsInSet(List<SObject> childRecords, String parentFieldName){
        
        Set<Id> parentIds = new Set<Id>();
        for (SObject childRecord : childRecords){
            Id parentId = (Id) childRecord.get(parentFieldName);
            if (parentId != null)
                parentIds.add(parentId);
        }
        
        return parentIds;
        
    }
    
    
    
    
    /**
* @description       This method is used to return lookup field values on child records
* @param             childRecordList - List,  parentFieldName - String
* @return            Set<Id>
* @throws            NA
*/
    public static Set<Id> getParentIds(List<SObject> childRecordList, 
                                       String parentFieldName){
                                           
                                           Set<Id> parentIds = new Set<Id>();
                                           for (SObject childRecord : childRecordList){
                                               Id parentId = (Id) childRecord.get(parentFieldName);
                                               if (parentId != null)
                                                   parentIds.add(parentId);
                                           }
                                           
                                           return parentIds;
                                           
                                       } 
    
    
    public static List<Apex_Debug_Log__c> constructErrorLogsForDMLErrors(List<Object> dmlResults, 
                                                                         List<SObject> recordsBeingSaved, 
                                                                         String apexClassName, 
                                                      String apexMethodName)
    {
                                                                             System.debug('constructErrorLogsForDMLErrors');
                                                                             
                                                                             List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
                                                                             
                                                                             for (Integer index=0; index<dmlResults.size(); index++){
                                                                                 
                                                                                 Object saveResult = dmlResults[index];
                                                                                 
                                                                                 try {
                                                                                     System.debug('saveResult '+saveResult);
                                                                                     
                                                                                     Boolean isSuccess;
                                                                                     List<Database.Error> errors;
                                                                                     Id recordSaveId = (Id) recordsBeingSaved[index].get('Id');
                                                                                     
                                                                                     if (saveResult instanceOf Database.SaveResult){
                                                                                         isSuccess = ((Database.SaveResult) saveResult).isSuccess();
                                                                                         errors = ((Database.SaveResult) saveResult).getErrors();
                                                                                     }
                                                                                     else if (saveResult instanceOf Database.UpsertResult){
                                                                                         isSuccess = ((Database.UpsertResult) saveResult).isSuccess();
                                                                                         errors = ((Database.UpsertResult) saveResult).getErrors();
                                                                                     }
                                                                                     else if (saveResult instanceOf Database.DeleteResult){
                                                                                         isSuccess = ((Database.DeleteResult) saveResult).isSuccess();
                                                                                         errors = ((Database.DeleteResult) saveResult).getErrors();
                                                                                     }
                                                                                     
                                                                                     if (!isSuccess){
                                                                                         
                                                                                         SObject failedRecord = recordsBeingSaved[index];
                                                                                         
                                                                                         List<String> errorMessages = new List<String>();
                                                                                         for (Database.Error errorResult : errors){
                                                                                             errorMessages.add(errorResult.getMessage());
                                                                                         }
                                                                                         
                                                                                         errorLogs.add(
                                                                                             new Apex_Debug_Log__c(
                                                                                                 Log_Type__c = 'Error',
                                                                                                 Apex_Class_Name__c = apexClassName,
                                                                                                 Apex_Class_Method_Name__c = apexMethodName,
                                                                                                 Exception_message__c = String.join(errorMessages, ' | '),
                                                                                                 Request_Data__c = JSON.serializePretty(failedRecord),
                                                                                                 Related_To_Id__c = recordSaveId
                                                                                             )
                                                                                         );
                                                                                         
                                                                                     }
                                                                                 }
                                                                                 catch (Exception e){
                                                                                     System.debug('Error when constructing Apex logs');
                                                                                     System.debug(e.getMessage());
                                                                                     System.debug(e.getStackTraceString());
                                                                                     System.debug(saveResult);
                                                                                 }
                                                                             }
                                                                             return errorLogs;
                                                                         }
    
    
    public static String getDateString(Date dateInput){
        if (dateInput != null){
            return dateInput.day() + '/' + dateInput.month() + '/' + dateInput.year();
        }
        return '';
    }
    
    
    public static Boolean currentContextIsAsync(){
        return System.isQueueable() || System.isFuture() || System.isBatch();
    }
    
    //This function converts the comma separated String of IDs ONLY to Set<Id>
    public static Set<Id> convertCommaSeparatedStringsToSetIds(String commaseparatedString) {
        
        Set<String> stringOfIds = new Set<String>();
        //Use the utility method to convert the List into Set<String> split by comma
        stringOfIds.addAll(GlobalUtility.trimStringList((List<String>)commaseparatedString.split(GlobalConstants.COMMA)));
        //convert Set<String> to Set<Id> for valid Ids passed
        Set<Id> idSet = new Set<Id>( (List<Id>)new List<String>( stringOfIds ) );
        return idSet;
    }
    
    /**
* @methodName        calculateScoreonObjectFields
* @description       Returns list of record with Incremental score calculated 
* @param             Map<String, List<I_ST_Lead_Scoring__mdt>> mapExtractPicklistFields,List<sObject> lstObjectFields,String sObjectIncrementScorefield
* @return            List<sObject>    
*/
    //public static List<sObject> calculateScoreonObjectFields(map<String,List<I_ST_Lead_Scoring__mdt>> mapExtractPicklistFields,List<sObject> lstObjectFields,String sObjectIncrementScorefield,String sObjectName){
        public static List<sObject> calculateScoreonObjectFields(map<String,List<I_ST_Lead_Scoring__mdt>> mapExtractPicklistFields,List<sObject> lstObjectFields,String sObjectIncrementScorefield,String sObjectName,Map<Id,sObject> oldMap){
        system.debug('Size: '+ mapExtractPicklistFields.size() +' mapExtractPicklistFields: '+mapExtractPicklistFields);
        system.debug('Size: '+ lstObjectFields.size() +' lstObjectFields: '+lstObjectFields);
        system.debug(' sObjectIncrementScorefield: '+sObjectIncrementScorefield);
        system.debug(' sObjectName: '+sObjectName);
        
        List<sObject> lstUpdatedRecord = new List<sObject>();
        if(!lstObjectFields.isEmpty()){
            for(sObject sObjectRecord : lstObjectFields){ 
                Integer finalLeadScore = 0;                  
                for(String fieldName : mapExtractPicklistFields.keyset()){
                    for(I_ST_Lead_Scoring__mdt leadScoring : mapExtractPicklistFields.get(fieldName)){
                        
                        if(leadScoring.I_ST_Operator__c.tolowercase() == ('EQUALS').tolowercase()){ 
                            if(leadScoring.Label == sObjectRecord.get(fieldName)){
                                if(leadScoring.I_ST_Score__c != null){
                                    finalLeadScore += Integer.valueOf(leadScoring.I_ST_Score__c); 
                                }
                            }
                        }
                        
                        else if(leadScoring.I_ST_Operator__c.tolowercase() == ('ISTRUE').tolowercase()){
                            if(String.valueof(sObjectRecord.get(fieldName)).tolowercase() == ('True').tolowercase()){
                                if(leadScoring.I_ST_Score__c != null){
                                    finalLeadScore += Integer.valueOf(leadScoring.I_ST_Score__c);   
                                }
                            }
                        }
                        else if(leadScoring.I_ST_Operator__c.tolowercase() == ('ISPOPULATED').tolowercase()){
                            if(!String.IsBlank(String.valueof(sObjectRecord.get(fieldName)))){
                                if(leadScoring.I_ST_Score__c != null){
                                    finalLeadScore += Integer.valueOf(leadScoring.I_ST_Score__c);   
                                }
                            }
                        }
                        else if(leadScoring.I_ST_Operator__c.tolowercase() == ('VALIDPOSTCODE').tolowercase()){
                            if(!String.IsBlank(String.valueof(sObjectRecord.get(fieldName)))){
                                if(String.valueof(sObjectRecord.get(fieldName)).length() < 5){
                                    if(leadScoring.I_ST_Score__c != null){
                                        finalLeadScore += Integer.valueOf(leadScoring.I_ST_Score__c);   
                                    }
                                } 
                            }
                        }
                    }
                }
                sObjectRecord.put(sObjectIncrementScorefield,finalLeadScore);
                
               if(sObjectName.equalsIgnoreCase('I_RM_Affiliation__c')){
                    sObjectRecord.put('I_RM_Calculate_Affiliation_Score__c',false);
                }
                if(sObjectName.equalsIgnoreCase('Case')){
                    Map<Id,Case> caseOldMap = (Map<Id,Case>)oldMap;
                    //If the finalScore on Case record changes, update the Prior score value to the Prior_Incremental_Score__c field which is used in the Activity Scoring batch
                    //Also, update I_ST_Score_Calculated__c = false so that the updated record is picked up by the batch again
                    if(caseOldMap!= null && (finalLeadScore != caseOldMap.get(sObjectRecord.Id).I_ST_Incremental_Score__c)) {
                        sObjectRecord.put('I_ST_Prior_Incremental_Score__c',caseOldMap.get(sObjectRecord.Id).I_ST_Incremental_Score__c); 
                        sObjectRecord.put('I_ST_Score_Calculated__c',false);
                    }
                }
                lstUpdatedRecord.add(sObjectRecord);
            }
        }
        system.debug('lstUpdatedRecord :'+lstUpdatedRecord);
        return lstUpdatedRecord;        
    }
    
}