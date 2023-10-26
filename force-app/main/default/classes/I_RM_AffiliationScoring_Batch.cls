/* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_AffiliationScoring_Batch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
  @JIRA           LTU360-867
  @Description	  This class is used to calculate Contact Score on Affiliation
   @Params	  	  <sObjectName>: Object API Name, <recordTypeIds>: Set of RecordTypeIds for Score Calculation, lastNumberOfHours: Run batch past N Hours
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-02-18      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class I_RM_AffiliationScoring_Batch implements Database.Batchable<sObject>,Database.Stateful {
    
    private Map<String, List<I_ST_Lead_Scoring__mdt>> mapExtractPicklistFields;
    private String sObjectName;
    private Set<Id> setRecordTypeId;
    private Integer lastNumberOfHours;
    private List<String> inactiveStatus;
    
    public I_RM_AffiliationScoring_Batch(String sObjectName, Set<Id> recordTypeIds, Integer lastNumberOfHours){
        this.sObjectName = sObjectName; 
        setRecordTypeId = recordTypeIds; 
        inactiveStatus = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');
        this.lastNumberOfHours = (lastNumberOfHours > 0) ? lastNumberOfHours : 6;  
        mapExtractPicklistFields = new Map<String, List<I_ST_Lead_Scoring__mdt>>();
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
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Datetime currentTime = System.now();
        Datetime durationPastHoursCurrentTime = System.now().addHours(-lastNumberOfHours);
        
        List<String> allFields =  new List<String>();
        if(mapExtractPicklistFields!= null && mapExtractPicklistFields.size() > 0) {
            for(String fieldAPIName : mapExtractPicklistFields.keySet()){
                allFields.add(fieldAPIName);
            }
        }
        
        String affiliationFields = String.join(allFields,', ');
        String strRecordTypeIDs = String.join((Iterable<String>)setRecordTypeId, ', ');
        String strInactiveStatus = String.join(inactiveStatus,', ');
        String strQuery = 'SELECT Id,' + affiliationFields + ' FROM I_RM_Affiliation__c ';
       
        strQuery += ' WHERE LastModifiedDate >: durationPastHoursCurrentTime AND LastModifiedDate <=: currentTime';
        if(setRecordTypeId !=null && !setRecordTypeId.isEmpty()) {
                strQuery += ' AND RecordTypeId ' + ' IN : setRecordTypeId ';                
            }
        strQuery += ' AND I_RM_Calculate_Affiliation_Score__c = TRUE ';
        strQuery += ' AND I_RM_Status__c ' + 'NOT IN : inactiveStatus';
        strQuery += ' WITH SECURITY_ENFORCED ORDER BY Id DESC';        
        
        return database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<I_RM_Affiliation__c>  affiliations) {
        List<I_RM_Affiliation__c> updateToAffiliation = GlobalUtility.calculateScoreonObjectFields(mapExtractPicklistFields, affiliations, 'I_RM_Score__c', 'I_RM_Affiliation__c',null);
        if(updateToAffiliation.size() > 0){         
            List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
            try{
                //Do not call trigger method for setting the Calculate Score on affiliation
                I_RM_AffiliationTriggerHandler.runmarkCalculateAffiliationScoreToTrue = True;
                Database.SaveResult[] results = Database.update(updateToAffiliation,false);
                errorLogs = GlobalUtility.constructErrorLogsForDMLErrors(results,updateToAffiliation,'I_RM_AffiliationScoring_Batch','execute'); 
            }
            catch(DmlException e){
                System.debug('Error in contact scoring records - ' + e.getMessage());
            }
        }
    }
    global void finish(Database.BatchableContext BC){
        
        I_ST_BatchScoring__c batchScoringCustomSetting = [SELECT Id,I_ST_Last_N_Hour__c,I_ST_RecordType_SFIDs__c,I_ST_BatchSize__c 
                                                          FROM I_ST_BatchScoring__c 
                                                          WHERE Name =: GlobalConstants.I_ST_CASESCORING LIMIT 1];
        
        Integer lastNHours = (Integer)batchScoringCustomSetting.I_ST_Last_N_Hour__c;
        
        Set<Id> recordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_CASESCORING).I_ST_RecordType_SFIDs__c);        
        
        Integer batchSize = integer.valueOf(batchScoringCustomSetting.I_ST_BatchSize__c);
        I_ST_ActivityScoring_Batch activityScoringBatch = new I_ST_ActivityScoring_Batch(GlobalConstants.CASE_OBJECT_API_NAME,recordTypeIds,lastNHours);
        Database.executeBatch(activityScoringBatch,Integer.valueOf(batchSize));
        
    }
}