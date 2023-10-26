/**
* @author  Vanita Walia
* @date    01/09/2022
* @description : This class is used for filtering the opportunity records and calling helper methods
*/
public without sharing class L_PR_OpportunityTriggerHandler{
    public static void execute() {        
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>() ;
        try{   
            if(Trigger.isBefore) {
                if(Trigger.isInsert || Trigger.isUpdate) {
                    map<Id,Opportunity> mapOldOpp = (map<Id,Opportunity>)Trigger.oldMap; 
                    Id prmOppRecordType =[select Id from RecordType where SobjectType ='Opportunity' and DeveloperName='PRM_Opportunity'].Id;
             
                    for(Opportunity opp : (List<Opportunity>)Trigger.new){                        
                        if(opp.RecordTypeId ==prmOppRecordType){ 
                            if(opp.StageName != Null && (Trigger.isInsert || (Trigger.isUpdate && opp.StageName != mapOldOpp.get(opp.Id).StageName)) 
                               && (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost')){
                                   opp.CloseDate = system.today();
                               }
                        }
                    }
                }
            }
                 
        	if(Trigger.isAfter) {
            	if(Trigger.isInsert || Trigger.isUpdate) {
                	//variable declaration
                 	map<Id,Opportunity> mapOldOpp = (map<Id,Opportunity>)Trigger.oldMap;        			
                    set<Id> oppIdSet = new Set<Id>();
                    Set<String> staffIds = new Set<String>();
                    Map<Id, Set<String>> oppStaffMap = new Map<Id, Set<String>>();
                    Map<Id,String> oppStatusMap = new Map<Id,String>();
                    Map<Id,Id> oppOrgMap = new Map<Id,Id>();
        			Map<Id,Id> removeOppOrgMap = new Map<Id,Id>();
                     Map<Id,Id> oppInternalOrgMap = new Map<Id,Id>();
        			Map<Id,Id> removeOppInternalOrgMap = new Map<Id,Id>();
                    Map<Id,Id> leadOppMap = new Map<Id,Id>();
                    Id prmOppRecordType =[select Id from RecordType where SobjectType ='Opportunity' and DeveloperName='PRM_Opportunity'].Id;
             
                    for(Opportunity opp : (List<Opportunity>)Trigger.new){                        
                        if(opp.RecordTypeId ==prmOppRecordType){                      
                                    
                        	// check if the opportunity status is closed lost & closed reason is not null
                        	if(Trigger.isUpdate && opp.StageName == 'Closed Lost' && opp.L_PR_Closed_Reason__c != Null ){
                            	// collect the opportunityIds
                            	oppIdSet.add(opp.Id);
                        	}
                        
                        	// check if status is updated (to update on opportunity organisation field)
                        	if(opp.StageName != Null && Trigger.isUpdate && opp.StageName != mapOldOpp.get(opp.Id).StageName){
                            	oppStatusMap.put(opp.Id,opp.StageName);
                        	}
                        	// check if organisation is not blank or value is updated
                        	if(opp.AccountId != Null  && (Trigger.isInsert || (Trigger.isUpdate && opp.AccountId != mapOldOpp.get(opp.Id).AccountId))){                           
                            	oppOrgMap.put(opp.Id,opp.AccountId);                               
                        	}
                        	else if(Trigger.isUpdate && opp.AccountId == Null && opp.AccountId != mapOldOpp.get(opp.Id).AccountId){ 
                            	//remove the record from list
                            	removeOppOrgMap.put(opp.Id,mapOldOpp.get(opp.Id).AccountId);
                        	}
                        
                        	// check if La trobe organisation unit is not blank or value is updated
                        	if(opp.L_PR_La_Trobe_Org_Unit__c != Null && (Trigger.isInsert || (Trigger.isUpdate && opp.L_PR_La_Trobe_Org_Unit__c != mapOldOpp.get(opp.Id).L_PR_La_Trobe_Org_Unit__c))){                           
                            	oppInternalOrgMap.put(opp.Id,opp.L_PR_La_Trobe_Org_Unit__c);                               
                        	}
                        	else if(Trigger.isUpdate && opp.L_PR_La_Trobe_Org_Unit__c == Null && opp.L_PR_La_Trobe_Org_Unit__c != mapOldOpp.get(opp.Id).L_PR_La_Trobe_Org_Unit__c){ 
                            	//remove the record from list
                            	removeOppInternalOrgMap.put(opp.Id,mapOldOpp.get(opp.Id).L_PR_La_Trobe_Org_Unit__c);
                        	}
                            
                            //check if opportunity is converted from lead
                            if(Trigger.isInsert && opp.L_PR_Idea__c != Null){
                                leadOppMap.put(opp.L_PR_Idea__c,opp.Id);                                    
                            }
                        } 
                    }                    
                    //call helper methods to copy related records from PRM Lead to opportunity
                    if(!leadOppMap.isEmpty()){
                        L_PR_OpportunityTriggerHelper.copyOrgDataFromLead(leadOppMap);
                        L_PR_OpportunityTriggerHelper.copyAffiliationDataFromLead(leadOppMap);
                        L_PR_OpportunityTriggerHelper.moveActivityDataFromLead(leadOppMap);
                        L_PR_OpportunityTriggerHelper.moveNotesNFilesDataFromLead(leadOppMap);
                        L_PR_OpportunityTriggerHelper.updateLeadStatusClosedConverted(leadOppMap);
                    }
                    
                    // call helper method to create or update opportunity organisation record & isPrimary checkbox
                    if(!oppOrgMap.isEmpty() || !removeOppOrgMap.isEmpty()){                    	
                    	L_PR_OpportunityTriggerHelper.createUpdateOppOrganisations(oppOrgMap,removeOppOrgMap,'External Org');
                    }
                    
                     // call helper method to create or update opportunity organisation record & isPrimary checkbox for la trobe organisation unit
                    if(!oppInternalOrgMap.isEmpty() || !removeOppInternalOrgMap.isEmpty()){                    	
                    	L_PR_OpportunityTriggerHelper.createUpdateOppOrganisations(oppInternalOrgMap,removeOppInternalOrgMap,'La Trobe Org');
                    }
                    
                    //call helper method to update status on related opportunity organisation records when opportunity status changes
                    if(!oppStatusMap.isEmpty())
                        L_PR_OpportunityTriggerHelper.updateExtOrgOpptStageField(oppStatusMap);
                    
                    // Send Salesforce notification to staff affiliation users
                      if(!oppIdSet.isEmpty()){
                      for(L_PR_Opportunity_Affiliation_Relation__c oppAff : [Select Id, L_PR_Affiliation__c, L_PR_Opportunity__c,L_PR_Affiliation__r.I_RM_Role__c,
                                                                		L_PR_Affiliation__r.I_RM_Contact__c, L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c
                                                                  		from L_PR_Opportunity_Affiliation_Relation__c where L_PR_Opportunity__c in:oppIdSet
                                                                  		AND L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c != Null
                                       									AND L_PR_Affiliation__r.I_RM_Role__c ='La Trobe Staff']){
                             
                            if(!oppStaffMap.isEmpty() && oppStaffMap.get(oppAff.L_PR_Opportunity__c) != Null){
                             	oppStaffMap.get(oppAff.L_PR_Opportunity__c).add(oppAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c);                                                 
                             }
                             else{
                                 oppStaffMap.put(oppAff.L_PR_Opportunity__c, new Set<String>{oppAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c});                                               
                             }
							 staffIds.add(oppAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c);
                         }
                    }
                    if(!oppStaffMap.isEmpty()){
                        L_PR_OpportunityTriggerHelper.createCustomSFNotification(oppStaffMap);
                    }                    
                   
    			}
			}
        }catch(exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHandler',Apex_Class_Method_Name__c = 'execute method',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
        }
}