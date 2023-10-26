/**
* @author  Vanita Walia
* @date    01/09/2022
* @description : This class contains helper methods related to opportunity
*/
public with sharing class L_PR_OpportunityTriggerHelper {
    static List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>() ;
    
     // Method to create or update opportunity organisation record & IsPrimary checkbox field 
    public static void createUpdateOppOrganisations(Map<Id,Id> lOrgMap,Map<Id,Id> removelOrgMap, String orgType){
        List<L_PR_External_Org_Opportunity_Relation__c> oppOrgList = new List<L_PR_External_Org_Opportunity_Relation__c>();
        try{
            if(lOrgMap != Null){
                  //check if the current opportunity organisation pair exist in opportunity organisation relationship records                      
                  List<L_PR_External_Org_Opportunity_Relation__c> ExistlOrgList = [Select Id, L_PR_Opportunity_Name__c,L_PR_Organisation_Name__c, L_PR_IsPrimary__c from L_PR_External_Org_Opportunity_Relation__c
                                                                  where L_PR_Opportunity_Name__c in: lOrgMap.keySet() AND L_PR_Organisation_Name__c in: lOrgMap.values()];
                      if(!ExistlOrgList.isEmpty()){
                       // if Found, mark IsPrimary True for that record
                      		for(L_PR_External_Org_Opportunity_Relation__c exLOrg : ExistlOrgList){
                                //  update existing opportunity organisation relationship
                           		L_PR_External_Org_Opportunity_Relation__c oppOrg = new L_PR_External_Org_Opportunity_Relation__c();
                                oppOrg.Id = exLOrg.Id;
                            	oppOrg.L_PR_IsPrimary__c = True; 
                            	oppOrgList.add(oppOrg);
                            }
                        }
                        else{
                            // if no existing record found, create new record with opportunity & organisation relationship and isPrimary true
                            for(Id opp : lOrgMap.keySet()){
                             	//create Lead organisation relationship record
                            	L_PR_External_Org_Opportunity_Relation__c oppOrg = new L_PR_External_Org_Opportunity_Relation__c();
                            	oppOrg.L_PR_Organisation_Name__c = lOrgMap.get(opp);
                            	oppOrg.L_PR_Opportunity_Name__c = opp;
                            	oppOrg.L_PR_IsPrimary__c = True;
                            	oppOrgList.add(oppOrg);
                            }
                        }
                        // find all opportunity organisation relationships where opportunity is present and isPrimary ticked
                        // or any other opportunity organisation relationship is present with isprimary true
                        for(L_PR_External_Org_Opportunity_Relation__c ActivelOrgList : [Select Id, L_PR_Opportunity_Name__c,L_PR_Organisation_Name__c, L_PR_IsPrimary__c,L_PR_Organisation_Type__c from L_PR_External_Org_Opportunity_Relation__c
                                                                      where (L_PR_Opportunity_Name__c in: lOrgMap.keySet() AND L_PR_Organisation_Name__c NOT IN: lOrgMap.values() AND L_PR_IsPrimary__c = TRUE)
                                                                    		OR (L_PR_Opportunity_Name__c in: removelOrgMap.keySet() AND L_PR_Organisation_Name__c in: removelOrgMap.values())]){
                                //  update existing lead organisation relationship
                                if(orgType =='External Org' && (ActivelOrgList.L_PR_Organisation_Type__c == 'External Organisation' || ActivelOrgList.L_PR_Organisation_Type__c == 'Educational Institution')){
                           			L_PR_External_Org_Opportunity_Relation__c oppOrg = new L_PR_External_Org_Opportunity_Relation__c();
                                	oppOrg.Id = ActivelOrgList.Id;
                            		oppOrg.L_PR_IsPrimary__c = False; 
                            		oppOrgList.add(oppOrg);   
                                }
                                else if(orgType =='La Trobe Org' && ActivelOrgList.L_PR_Organisation_Type__c == 'La Trobe Organisation Unit'){
                           			L_PR_External_Org_Opportunity_Relation__c oppOrg = new L_PR_External_Org_Opportunity_Relation__c();
                                	oppOrg.Id = ActivelOrgList.Id;
                            		oppOrg.L_PR_IsPrimary__c = False; 
                            		oppOrgList.add(oppOrg);   
                                }
                        	}  
                    }
                   
                    if(oppOrgList != Null){
                        upsert oppOrgList;
                    }
        		}catch(exception ex){                    
            		errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'createUpdateOppOrganisations',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
                }                    
    }
    
    
     // Method to create salesforce notification for staff affiliation users
    public static void createCustomSFNotification(Map<Id, Set<String>> oppStaffMap){
        
        try{
            if(!oppStaffMap.isEmpty()){
                // Get the Id for our custom notification type
        		CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Lead_Notification'];
                
                for(Opportunity opp: [Select Id,Name, L_PR_Closed_Reason__c from Opportunity where Id IN:oppStaffMap.keyset()]){
                    // Create a new custom notification
        			Messaging.CustomNotification notification = new Messaging.CustomNotification();

        			// Set the contents for the notification
        			String title = opp.Name;
       				String bodyContent = opp.L_PR_Closed_Reason__c;
        			notification.setTitle(title);
        			notification.setBody(bodyContent);

        			// Set the notification type and target
        			notification.setNotificationTypeId(notificationType.Id);
        			notification.setTargetId(opp.Id);
                    // Actually send the notification
            		notification.send(oppStaffMap.get(opp.Id));
                }
            }
        }catch(exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'createCustomSFNotification',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
                }
    }
    
    // Method to update opportunity organisation record on status update 
    public static void updateExtOrgOpptStageField(Map<Id,String> opptStageMap){

        List<L_PR_External_Org_Opportunity_Relation__c> extOrgOptsToUpdate = new List<L_PR_External_Org_Opportunity_Relation__c>();
        
        try{
            if(opptStageMap != null){
                for(L_PR_External_Org_Opportunity_Relation__c extOrgOpp : [Select Id, L_PR_IsPrimary__c, L_PR_Opportunity_Name__c, L_PR_OpportunityStage__c, L_PR_Organisation_Name__c
                                                                           From L_PR_External_Org_Opportunity_Relation__c Where L_PR_Opportunity_Name__c IN : opptStageMap.keySet()]){
                                                                            
                    L_PR_External_Org_Opportunity_Relation__c extOrg = new L_PR_External_Org_Opportunity_Relation__c();
                    extOrg.Id = extOrgOpp.Id;
                    extOrg.L_PR_OpportunityStage__c = opptStageMap.get(extOrgOpp.L_PR_Opportunity_Name__c);                                             
                    extOrgOptsToUpdate.add(extOrg);
                }
            }

            if(!extOrgOptsToUpdate.isEmpty()){
                update extOrgOptsToUpdate;
            }

        }catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'updateExtOrgOpptStageField',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }
    
     // Method to copy prm lead organisation records to opportunity organisation relationships 
    public static void copyOrgDataFromLead(Map<Id,Id> leadOppMap){
        try{
			//copy related records from lead Organisations to Opportunity Organisation Relationships
			List<L_PR_External_Org_Opportunity_Relation__c> oppOrgList = new List<L_PR_External_Org_Opportunity_Relation__c>();
			
            for(L_PR_Idea_Organisation__c leadOrg : [Select Id,L_PR_Organisation__c,L_PR_IsPrimary__c,L_PR_Idea__c
                                                    	from L_PR_Idea_Organisation__c 
                                                    where L_PR_Idea__c in:leadOppMap.keyset()]) {
                 //create new opportunity organisation relationship record
                 L_PR_External_Org_Opportunity_Relation__c oppOrg = new L_PR_External_Org_Opportunity_Relation__c();
                 oppOrg.L_PR_Organisation_Name__c = leadOrg.L_PR_Organisation__c;
                 oppOrg.L_PR_IsPrimary__c = leadOrg.L_PR_IsPrimary__c;
                 oppOrg.L_PR_Opportunity_Name__c = leadOppMap.get(leadOrg.L_PR_Idea__c);
				oppOrgList.add(oppOrg);                                                        
             }
            
            if(!oppOrgList.isEmpty()){
                insert oppOrgList;
            }
        }catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'copyOrgDataFromLead',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }
    
     // Method to copy prm lead Affiliation records to opportunity affiliation relationships 
    public static void copyAffiliationDataFromLead(Map<Id,Id> leadOppMap){
        try{
			//copy related records from lead Organisations to Opportunity Organisation Relationships
			List<L_PR_Opportunity_Affiliation_Relation__c> oppAffList = new List<L_PR_Opportunity_Affiliation_Relation__c>();
			
            for(L_PR_Idea_Affiliation__c leadAff : [Select Id,L_PR_Affiliation__c,L_PR_Idea__c
                                                    	from L_PR_Idea_Affiliation__c 
                                                    where L_PR_Idea__c in:leadOppMap.keyset()]) {
                 //create new opportunity affiliation relationship record
                 L_PR_Opportunity_Affiliation_Relation__c oppAff = new L_PR_Opportunity_Affiliation_Relation__c();
                 oppAff.L_PR_Affiliation__c = leadAff.L_PR_Affiliation__c;
                 oppAff.L_PR_Opportunity__c = leadOppMap.get(leadAff.L_PR_Idea__c);
				oppAffList.add(oppAff);                                                        
             }
            
            if(!oppAffList.isEmpty()){
                insert oppAffList;
            }
        }catch(Exception ex){
             errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'copyAffiliationDataFromLead',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }
     // Method to move tasks/emails/calls related to prm lead to opportunity 
    public static void moveActivityDataFromLead(Map<Id,Id> leadOppMap){
        try{
			//move related activity records from prm lead to Opportunity
			List<Task> tskList = new List<Task>();
			For(Task ts : [Select Id, ActivityDate, WhatId, WhoId,TaskSubtype from Task where whatId=:leadOppMap.keyset()]){
				ts.whatId = leadOppMap.get(ts.whatId);
    			tskList.add(ts);
			}            
            if(!tskList.isEmpty()){
                update tskList;
            }
        }catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'moveActivityDataFromLead',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }
    
    // Method to move tasks/emails/calls related to prm lead to opportunity 
    public static void moveNotesNFilesDataFromLead(Map<Id,Id> leadOppMap){
        try{
			//move related notes & files records from prm lead to Opportunity
			List<ContentDocumentLink> cnList = new List<ContentDocumentLink>();
			List<ContentDocumentLink> cnDList = new List<ContentDocumentLink>();
			for(ContentDocumentLink conLinks : [select Id, LinkedEntityId,ContentDocumentId,
                                    ContentDocument.LatestPublishedVersion.Title,
                                    ContentDocument.LatestPublishedVersion.VersionData,
                                    ShareType, Visibility
                                    from ContentDocumentLink where LinkedEntityId IN :leadOppMap.keyset()]){
   				
    			ContentDocumentLink cdl = new ContentDocumentLink();
				cdl.ContentDocumentId = conLinks.ContentDocumentId; 
				cdl.LinkedEntityId = leadOppMap.get(conLinks.LinkedEntityId);
				cdl.ShareType = conLinks.ShareType;
				cdl.Visibility = conLinks.Visibility;
    			cnList.add(cdl);
    			cnDList.add(conLinks); 	
			}
        	if(!cnList.isEmpty())
				insert cnList;
            if(!cnDList.isEmpty())
				delete cnDList;

			
        }catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'moveNotesNFilesDataFromLead',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }
    // Method to update prm lead status to closed converted 
    public static void updateLeadStatusClosedConverted(Map<Id,Id> leadOppMap){
        try{
            List<L_PR_Idea__c> prmLeads = new List<L_PR_Idea__c>();
            for(Id prmLeadId : leadOppMap.keyset()){
                L_PR_Idea__c prmLead = new L_PR_Idea__c(Id=prmLeadId);
                prmLead.L_PR_Lead_Status__c ='Closed – Converted';
                prmLead.L_PR_Converted_Date__c = System.Today();
                prmLeads.add(prmLead);
            }
            if(!prmLeads.isEmpty())
                update prmLeads;
			
        }catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'L_PR_OpportunityTriggerHelper',Apex_Class_Method_Name__c = 'updateLeadStatusClosedConverted',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }
}