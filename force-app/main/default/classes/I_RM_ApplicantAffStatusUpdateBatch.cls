/* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_RM_ApplicantAffStatusUpdateBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
  @JIRA           LTU360-867
  @Description	  This class is used to update status field of Affiliation
   @Params	  	  <sObjectName>: Object API Name, <recordTypeIds>: Set of RecordTypeIds for Score Calculation, lastNumberOfHours: Run batch past N Hours
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-03-16      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class I_RM_ApplicantAffStatusUpdateBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    Integer numberOfRecordsProcessed = 0;
    public List<String> inactiveStatus = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_INACTIVE_APPLICATION_SETTINGS].I_RM_Status__c.split(';');
    Public List<String> inactiveStatusaff = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');
    public List<I_RM_Affiliation__c> lstAffiliations = new List<I_RM_Affiliation__c>();   
    DateTime todayDate = System.today();
     
    
    global Database.QueryLocator start(Database.BatchableContext bc) {       
       
       string strQuery = '';
       I_RM_Affiliation_Settings__c affiliationSettingBatch = I_RM_Affiliation_Settings__c.getValues('I_RM_ApplicantAffiliationStatusBatch');
        if(affiliationSettingBatch.Value__c =='onetime'){
       
         strQuery = 'SELECT Id,I_RM_Affiliation__c,I_ST_Application_Status__c FROM I_ST_Application__c Where I_RM_Affiliation__c != Null AND I_RM_Affiliation__r.I_RM_Status__c NOT IN: inactiveStatusaff';
        }
        else if(affiliationSettingBatch.Value__c =='daily'){
            
        strQuery ='SELECT Id,I_RM_Affiliation__c,I_ST_Application_Status__c, I_RM_Affiliation__r.I_RM_Status__c FROM I_ST_Application__c ';
        strQuery +=  'WHERE I_RM_Affiliation__r.I_RM_Status__c NOT IN: inactiveStatusaff ';
        strQuery +=  'AND I_RM_Affiliation__c != Null ';  
        strQuery += 'AND I_ST_Application_Lapsed__c = FALSE ';
        strQuery += 'AND (I_ST_Application_Census_Date__c <: todayDate '; 
        strQuery += 'AND I_ST_Application_Census_Date__c != NULL)';
        }
        else{
            Apex_Debug_Log__c errorLogs = new Apex_Debug_Log__c();errorLogs.Apex_Class_Name__c = 'I_RM_ApplicantAffStatusUpdateBatch';errorLogs.Log_Type__c = 'Error';errorLogs.Exception_message__c='Please set correct value in affiliationSettingBatch custom setting record I_RM_Affiliation_Settings__c';
            Insert errorLogs;return null;            
        }
        return database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext BC, List<I_ST_Application__c> lstProcessAffiliations){
        
      set<Id> uniqueAffiliationIds = new set<Id>();
      Map<Id, List<I_ST_Application__c>> mapAffIdVSApplications = new Map<Id, List<I_ST_Application__c>>();   
      for(I_ST_Application__c objApplication : [SELECT Id,I_RM_Affiliation__c,I_ST_Application_Status__c FROM I_ST_Application__c
                                                     Where I_RM_Affiliation__c != Null
                                               		AND ID  IN : lstProcessAffiliations]){
            if(objApplication.I_RM_Affiliation__c != null){
                uniqueAffiliationIds.add(objApplication.I_RM_Affiliation__c);                
               
            }
        } 
            
      
                                for(I_ST_Application__c exApp : [Select Id,I_RM_Affiliation__c,I_ST_Application_Status__c from I_ST_Application__c
                        		                           			where I_RM_Affiliation__c in:uniqueAffiliationIds
                            		                       			AND I_ST_Application_Lapsed__c = False
                                		                   			AND I_ST_Application_Status__c NOT IN: inactiveStatus
                                    		                		AND (I_ST_Application_Census_Date__c >=: todayDate 
                                        		            		OR I_ST_Application_Census_Date__c = NULL )]){
                                    
                                    // If any application related to affiliation record found put them in map
                                        if(!mapAffIdVSApplications.isEmpty() && mapAffIdVSApplications.containsKey(exApp.I_RM_Affiliation__c)){
                                             mapAffIdVSApplications.get(exApp.I_RM_Affiliation__c).add(exApp);
                                        }                                           
                                        else{
                                            mapAffIdVSApplications.put(exApp.I_RM_Affiliation__c,new List<I_ST_Application__c>{exApp});
                                        }
                                        // remove the affiliation Id from the set 
                                        uniqueAffiliationIds.remove(exApp.I_RM_Affiliation__c);   
                                }
                     
                if(!uniqueAffiliationIds.isEmpty()){ 
            // Call helper class method to update affiliation status to Inactive
            I_ST_ApplicationTriggerHelper.updateAffiliationToInactive(uniqueAffiliationIds);
            
        }
                             
        if(!mapAffIdVSApplications.isEmpty()){
            I_ST_ApplicationTriggerHelper.updateAffiliationStatus(mapAffIdVSApplications);
        }
        numberOfRecordsProcessed = numberOfRecordsProcessed + uniqueAffiliationIds.size() + mapAffIdVSApplications.size();
    }
    
    global void finish(Database.BatchableContext BC){
        
        Apex_Debug_Log__c errorLogs = new Apex_Debug_Log__c();
                        errorLogs.Apex_Class_Name__c = 'I_RM_ApplicantAffStatusUpdateBatch';
                        errorLogs.Transaction_Description__c = numberOfRecordsProcessed + 'Processed' + 'on' + system.today();
                        errorLogs.Log_Type__c = 'Info';
        Insert errorLogs;
       
    }
}