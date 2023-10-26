/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* I_ST_Application__c Trigger Handler Class
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vanita Walia
* @version        2.0
* @created        17/03/2022
* @description    Handler class to filter the records based on trigger events and call the helper methods for action 
*/
public with sharing class I_ST_ApplicationTriggerHandler {
    // Boolean variable to avoid recursion so that helper method only execute once
    public static Boolean FirstRun = false;        
    public static List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
    
    public static void execute() {
        //variable initialization
        map<Id,I_ST_Application__c> mapOldApplication = (map<Id,I_ST_Application__c>)Trigger.oldMap;
        Map<Id, List<I_ST_Application__c>> affAppListMap = new Map<Id, List<I_ST_Application__c>>();
        List<String> InactiveStatus = new List<String>();
        Set<Id> affiliationIds = new Set<Id>();
        DateTime todayDate = System.today();               
                
        if(Trigger.isAfter) {
            // By Vanita Walia as part of LTU360-1324 
                if(Trigger.isInsert || Trigger.isUpdate) {
                try{
                    if(!FirstRun){
                        // Find the application with affiliation where status is changed or lapsed value is updated 
                        // and store the affiliation Ids in set 
                		for(I_ST_Application__c app : (List<I_ST_Application__c>)Trigger.new){
                    		if(app.I_RM_Affiliation__c != Null && (Trigger.isInsert  ||  (Trigger.isUpdate 
                                && (app.I_ST_Application_Status__c != mapOldApplication.get(app.Id).I_ST_Application_Status__c
                                || app.I_ST_Application_Lapsed__c != mapOldApplication.get(app.Id).I_ST_Application_Lapsed__c)))){
                        			affiliationIds.add(app.I_RM_Affiliation__c);  
                        	}
                		}
                   
                		
                		// find all the applications with same affiliation as of current record	
                		if(!affiliationIds.isEmpty()){
                            //fetch the inactive status values for application from the custom settings
        					InactiveStatus = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_INACTIVE_APPLICATION_SETTINGS].I_RM_Status__c.split(';');
        					 
                            
                			List<I_ST_Application__c> appList = [Select Id,I_RM_Affiliation__c,I_ST_Application_Status__c from I_ST_Application__c
                        		                           			where I_RM_Affiliation__c in:affiliationIds
                            		                       			AND I_ST_Application_Lapsed__c = False
                                		                   			AND I_ST_Application_Status__c NOT IN: InactiveStatus
                                    		                		AND (I_ST_Application_Census_Date__c >=: todayDate 
                                        		            		OR I_ST_Application_Census_Date__c = NULL) ORDER BY I_ST_Application_Status__c DESC];
                                            		       			
                			
                			if(appList.size()>0){
                    			for(I_ST_Application__c exApp : appList){
                            		// If any application related to affiliation record found put them in map
                        			
                            			if(!affAppListMap.isEmpty() && affAppListMap.containsKey(exApp.I_RM_Affiliation__c))
                                			affAppListMap.get(exApp.I_RM_Affiliation__c).add(exApp);
                            			else
                            				affAppListMap.put(exApp.I_RM_Affiliation__c,new List<I_ST_Application__c>{exApp});
                            	 		
                                    // remove the affiliation Id from the set where application is not the current record
                                     	affiliationIds.remove(exApp.I_RM_Affiliation__c);
                        			
                    			}
                			}
                    		
                    		// Perform the action on remaining affiliations where no other application found meeting criteria
                    		if(!affiliationIds.isEmpty() && !System.isBatch()){ 
                        		// Call helper class method to update affiliation status to Inactive
                    			I_ST_ApplicationTriggerHelper.updateAffiliationToInactive(affiliationIds);
                			}
                            
                            if(!affAppListMap.isEmpty() && !System.isBatch()){
                                I_ST_ApplicationTriggerHelper.updateAffiliationStatus(affAppListMap);
                            }
            			}                        
        			}
                }
                catch(Exception ex){
                   
                   	errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'I_ST_ApplicationTriggerHandler',Apex_Class_Method_Name__c = 'execute Method',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
               	}
               	finally {
           			if (!errorLogs.isEmpty() && errorLogs != Null)
               			insert errorLogs;            		
        		}
    		}
        }	   
	}
}