public with sharing class I_ST_InformationRolloverBatch implements Database.Batchable<sobject>{
    public final List<I_ST_Scheduled_Information_Rollover__mdt> rolloverMappings;
    public final Map<String, Set<String>> mappingMap;
    public final Map<String, String> rolloverMap;
    public I_ST_InformationRolloverBatch(){
        mappingMap = new Map<String, Set<String>>();
        rolloverMap = new Map<String, String>();
        rolloverMappings = [SELECT I_ST_Field_API_Name__c, I_ST_From__c, I_ST_To__c FROM I_ST_Scheduled_Information_Rollover__mdt WHERE I_ST_Active__c = True];
        for(I_ST_Scheduled_Information_Rollover__mdt rolloverMapping: rolloverMappings){
            rolloverMap.put(rolloverMapping.I_ST_From__c, rolloverMapping.I_ST_To__c);
            if(!mappingMap.containsKey(rolloverMapping.I_ST_Field_API_Name__c)){
                mappingMap.put(rolloverMapping.I_ST_Field_API_Name__c, new Set<String>{rolloverMapping.I_ST_From__c});
            } else{
                mappingMap.get(rolloverMapping.I_ST_Field_API_Name__c).add(rolloverMapping.I_ST_From__c);
            }
        }
    }
    public Database.Querylocator start (Database.BatchableContext BC) {
        String query = 'SELECT Name, ' + String.join(new List<String>(mappingMap.keySet()),', ') + ' FROM I_RM_Affiliation__c';       
        query += ' WHERE I_RM_Contact__r.I_RS_Deceased__c = FALSE';
        query += ' AND I_RM_Contact__r.I_ST_Sanctioned_Student__c = FALSE';
        query += ' AND I_RM_Status__c != \'Inactive\'' ;
        query += ' AND (I_RM_Time_Frame_to_Study__c != null';
        query += ' OR I_RM_Enquirer_Type__c != null)';
        query += ' AND I_RM_Role__c IN (\'Applicant\', \'Domestic Lead\')';
                 
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<I_RM_Affiliation__c> rolloverContacts) {
        String contactFieldValue;
       for(I_RM_Affiliation__c rolloverContact: rolloverContacts){
            //mappingMap not kept from global setting
            for(String mappedField: mappingMap.keySet()){
                contactFieldValue = (String) rolloverContact.get(mappedField);
                if(contactFieldValue != null && rolloverMap.keySet().contains(contactFieldValue)){
                    rolloverContact.put(mappedField, rolloverMap.get(contactFieldValue));
                }
                 
            }
          
        }
        
        Database.SaveResult[] uList = Database.update(rolloverContacts, false); 
        
    }  
    public void finish(Database.BatchableContext bc){
    } 
}