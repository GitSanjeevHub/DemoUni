/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* I_ST_Application__c Trigger Helper
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vanita Walia
* @version        2.0
* @created        17/03/2022
*/
public with sharing class I_ST_ApplicationTriggerHelper {
    static List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>() ;
    
    /* @author        Vanita Walia	
	* @created        17/03/2022
	* @description	  Method to update the affiliation records status to Inactive and Set their End Date to Today. 
	*				  This methid accept Set of Affiliation Ids as input. Its part of LTU360-1324 
	*/
    public static void updateAffiliationToInactive(Set<Id> affIds){
       
        List<I_RM_Affiliation__c> affListUpdate = new  List<I_RM_Affiliation__c>();
        try{	
        	if(!affIds.isEmpty()){
            	
                // Set affiliation status as Inactive and end date as today
            	for(Id affiliation : affIds){
                	I_RM_Affiliation__c updateAff = new I_RM_Affiliation__c();
                	updateAff.Id = affiliation;
                	updateAff.I_RM_Status__c = 'Inactive';
                	updateAff.I_RM_EndDate__c = System.today();
                	affListUpdate.add(updateAff);
            	}
            	
            	// update the affiliation records and if any dml error comes add it to errorlogs
                if(affListUpdate.size() >0 && schema.SObjectType.I_RM_Affiliation__c.isUpdateable()){                    
                	I_ST_ApplicationTriggerHandler.FirstRun = True; // Set FirstRun to True to avoid recursion               	
                	List<Database.saveResult> updateResults = Database.Update(affListUpdate, false);
                   
                    errorLogs.addAll(GlobalUtility.constructErrorLogsForDMLErrors(updateResults, affListUpdate, 'I_ST_ApplicationTriggerHelper', 'updateAffiliationToInactive'));
                    insert errorLogs;  
        			errorLogs.clear();
        		}
            }
    	}
        catch(Exception ex){
            system.debug('exception' + ex);
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'I_ST_ApplicationTriggerHelper',Apex_Class_Method_Name__c = 'updateAffiliationToInactive',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            if (errorLogs != null && !errorLogs.isEmpty()){
               insert errorLogs;
            	errorLogs.clear();
            }
		}        
    }
    
    public static void updateAffiliationStatus(Map<Id, List<I_ST_Application__c>> affAppListMap){
       
        List<I_RM_Applicant_Status_Derivation__mdt> appStatusMtd = [Select Application_Status__c,Applicant_Affiliation_Status__c, Active__c, Priority__c From I_RM_Applicant_Status_Derivation__mdt order by Priority__c asc];

        List<I_ST_Application__c> appList = New List<I_ST_Application__c>();
        List<I_RM_Affiliation__c> allAffListUpdate = new  List<I_RM_Affiliation__c>();
        try{
            for(Id afflId : affAppListMap.keyset()){
                appList = affAppListMap.get(afflId);
                if(appList.size() >0){
                    allAffListUpdate.addAll(updateStatus(afflId, appList, appStatusMtd));
                }
            }
            if(!allAffListUpdate.isEmpty()){
                update allAffListUpdate;
            }
        }
        catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'I_ST_ApplicationTriggerHelper',Apex_Class_Method_Name__c = 'updateAffiliationStatus',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            if (errorLogs != null && !errorLogs.isEmpty()){
        		insert errorLogs;
                errorLogs.clear();
            }
		}   
    }

    public static List<I_RM_Affiliation__c> updateStatus(Id afflId, List<I_ST_Application__c> appList, List<I_RM_Applicant_Status_Derivation__mdt> appStatusMtd){
        List<I_RM_Affiliation__c> affListUpdate = new  List<I_RM_Affiliation__c>();
                   
        Boolean exitForLook = false;
        Integer count = 0;
        for(I_RM_Applicant_Status_Derivation__mdt mdt : appStatusMtd){
            count++;
           
            for(I_ST_Application__c appl : appList){
                
                if(appl.I_ST_Application_Status__c == mdt.Application_Status__c){
                    I_RM_Affiliation__c updateAff = new I_RM_Affiliation__c();
                    updateAff.Id = afflId;
                    updateAff.I_RM_Status__c = mdt.Applicant_Affiliation_Status__c;
                    affListUpdate.add(updateAff);
                    exitForLook = true;
                    break;
                }else if(count >= appStatusMtd.size()){                 
                    I_RM_Affiliation__c updateAff = new I_RM_Affiliation__c();
                    updateAff.Id = afflId;
                    updateAff.I_RM_Status__c = 'Unknown status';
                    affListUpdate.add(updateAff);
                    exitForLook = true;
                    break;
                }
            }
            if(exitForLook){
                break;
            }
        }
        return affListUpdate;
    }
}