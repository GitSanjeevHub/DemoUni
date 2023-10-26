/**
* @author  Vanita Walia
* @date    12/07/2022
* @description : This class is used for filtering the PRM leads and calling helper methods
*/

public class L_PR_LeadTriggerHandler {
	public static void execute() {        
        
        try{       
        	if(Trigger.isAfter) {
            	if(Trigger.isInsert || Trigger.isUpdate) {
                	//variable declaration
                 	map<Id,L_PR_Idea__c> mapOldLead = (map<Id,L_PR_Idea__c>)Trigger.oldMap;
        			Map<Id,Id> lAffMap = new Map<Id,Id>();
        			Map<Id,Id> removelAffMap = new Map<Id,Id>();
                    set<Id> leadIdSet = new Set<Id>();
                    Set<String> staffIds = new Set<String>();
                    Map<Id, Set<String>> leadStaffMap = new Map<Id, Set<String>>();
                    Map<Id,String> leadStatusMap = new Map<Id,String>();
                    Map<Id,Id> leadOrgMap = new Map<Id,Id>();
        			Map<Id,Id> removeLeadOrgMap = new Map<Id,Id>();
                     Map<Id,Id> leadInternalOrgMap = new Map<Id,Id>();
        			Map<Id,Id> removeLeadInternalOrgMap = new Map<Id,Id>();
                                   		    
                    for(L_PR_Idea__c lead : (List<L_PR_Idea__c>)Trigger.new){                        
                        // check if affiliation is not blank or value is updated
                        if(lead.L_PR_Affiliation__c != Null && (Trigger.isInsert || (Trigger.isUpdate && lead.L_PR_Affiliation__c != mapOldLead.get(lead.Id).L_PR_Affiliation__c))){                           
                            lAffMap.put(lead.Id,lead.L_PR_Affiliation__c);                               
                        }
                        else if(Trigger.isUpdate && lead.L_PR_Affiliation__c == Null && lead.L_PR_Affiliation__c != mapOldLead.get(lead.Id).L_PR_Affiliation__c){ 
                            //remove the record from list
                            removelAffMap.put(lead.Id,mapOldLead.get(lead.Id).L_PR_Affiliation__c);
                        }
                        
                        // check if the lead status is closed & closed reason is not null
                        if(Trigger.isUpdate && lead.L_PR_Lead_Status__c == 'Closed' && lead.L_PR_Closed_Reason__c != Null){
                            // collect the LeadIds
                            leadIdSet.add(lead.Id);
                        }
                        
                        // check if status is updated (to update on lead organisation field)
                        if(lead.L_PR_Lead_Status__c != Null && Trigger.isUpdate && lead.L_PR_Lead_Status__c != mapOldLead.get(lead.Id).L_PR_Lead_Status__c){
                            leadStatusMap.put(lead.Id,lead.L_PR_Lead_Status__c);
                        }
                        // check if organisation is not blank or value is updated
                        if(lead.L_PR_Organisation__c != Null  && (Trigger.isInsert || (Trigger.isUpdate && lead.L_PR_Organisation__c != mapOldLead.get(lead.Id).L_PR_Organisation__c))){                           
                            leadOrgMap.put(lead.Id,lead.L_PR_Organisation__c);                               
                        }
                        else if(Trigger.isUpdate && lead.L_PR_Organisation__c == Null && lead.L_PR_Organisation__c != mapOldLead.get(lead.Id).L_PR_Organisation__c){ 
                            //remove the record from list
                            removeLeadOrgMap.put(lead.Id,mapOldLead.get(lead.Id).L_PR_Organisation__c);
                        }
                        
                        // check if La trobe organisation unit is not blank or value is updated
                        if(lead.L_PR_La_Trobe_Organisation_Unit__c != Null && (Trigger.isInsert || (Trigger.isUpdate && lead.L_PR_La_Trobe_Organisation_Unit__c != mapOldLead.get(lead.Id).L_PR_La_Trobe_Organisation_Unit__c))){                           
                            leadInternalOrgMap.put(lead.Id,lead.L_PR_La_Trobe_Organisation_Unit__c);                               
                        }
                        else if(Trigger.isUpdate && lead.L_PR_La_Trobe_Organisation_Unit__c == Null && lead.L_PR_La_Trobe_Organisation_Unit__c != mapOldLead.get(lead.Id).L_PR_La_Trobe_Organisation_Unit__c){ 
                            //remove the record from list
                            removeLeadInternalOrgMap.put(lead.Id,mapOldLead.get(lead.Id).L_PR_La_Trobe_Organisation_Unit__c);
                        }
                        
                    }
                    // call helper method to create or update lead affiliation record & isPrimary checkbox
                    if(!lAffMap.isEmpty() || !removelAffMap.isEmpty()){                    	
                    	L_PR_LeadTriggerHelper.createUpdateLeadAffiliations(lAffMap,removelAffMap);
                    }
                    
                    // call helper method to create or update lead organisation record & isPrimary checkbox
                    if(!leadOrgMap.isEmpty() || !removeLeadOrgMap.isEmpty()){                    	
                    	L_PR_LeadTriggerHelper.createUpdateLeadOrganisations(leadOrgMap,removeLeadOrgMap);
                    }
                    
                     // call helper method to create or update lead organisation record & isPrimary checkbox for la trobe organisation unit
                    if(!leadInternalOrgMap.isEmpty() || !removeLeadInternalOrgMap.isEmpty()){                    	
                    	L_PR_LeadTriggerHelper.createUpdateLeadOrganisations(leadInternalOrgMap,removeLeadInternalOrgMap);
                    }
                    
                    //call helper method to update status on related lead organisation records when leadc status changes
                    if(!leadStatusMap.isEmpty())
                        L_PR_LeadTriggerHelper.updateLeadOrganisatioStatus(leadStatusMap);
                    
                    // Send Salesforce notification to staff affiliation users
                    if(!leadIdSet.isEmpty()){
                        for(L_PR_Idea_Affiliation__c leadAff : [Select Id, L_PR_Affiliation__c, L_PR_Idea__c,L_PR_Affiliation__r.I_RM_Role__c,
                                                                		L_PR_Affiliation__r.I_RM_Contact__c, L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c
                                                                  		from L_PR_Idea_Affiliation__c where L_PR_Idea__c in:leadIdSet
                                                                  		AND L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c != Null
                                       									AND L_PR_Affiliation__r.I_RM_Role__c ='La Trobe Staff']){
                             
                             system.debug('userid' +leadAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c);
                             if(!leadStaffMap.isEmpty() && leadStaffMap.get(leadAff.L_PR_Idea__c) != Null){
                             	leadStaffMap.get(leadAff.L_PR_Idea__c).add(leadAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c);                                                 
                             }
                             else{
                                 leadStaffMap.put(leadAff.L_PR_Idea__c, new Set<String>{leadAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c});                                               
                             }
							 staffIds.add(leadAff.L_PR_Affiliation__r.I_RM_Contact__r.I_RS_Related_User__c);
                         }
                    }
                    if(!leadStaffMap.isEmpty()){
                        L_PR_LeadTriggerHelper.createCustomSFNotification(leadStaffMap);
                    }
    			}
			}
        }catch(exception e){
            system.debug('exception' + e);   
        }
    }
}