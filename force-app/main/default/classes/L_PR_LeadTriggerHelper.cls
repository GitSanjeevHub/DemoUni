/**
* @author  Vanita Walia
* @date    12/07/2022
* @description : This class contains helper methods
*/
public class L_PR_LeadTriggerHelper {
    
    // Method to create or update lead affiliation record & IsPrimary checkbox field 
    public static void createUpdateLeadAffiliations(Map<Id,Id> lAffMap,Map<Id,Id> removelAffMap){
        List<L_PR_Idea_Affiliation__c> leadAffList = new List<L_PR_Idea_Affiliation__c>();
        try{
            if(lAffMap != Null){
                  //check if the current lead affiliation pair exist in lead affiliation relationship records                      
                  List<L_PR_Idea_Affiliation__c> ExistlAffList = [Select Id, L_PR_Idea__c,L_PR_Affiliation__c, L_PR_IsPrimary__c from L_PR_Idea_Affiliation__c
                                                                  where L_PR_Idea__c in: lAffMap.keySet() AND L_PR_Affiliation__c in: lAffMap.values()];
                      if(!ExistlAffList.isEmpty()){
                       // if Found, mark IsPrimary True for that record
                      		for(L_PR_Idea_Affiliation__c exLAff : ExistlAffList){
                                //  update existing lead affiliation relationship
                           		L_PR_Idea_Affiliation__c leadAff = new L_PR_Idea_Affiliation__c();
                                leadAff.Id = exLAff.Id;
                            	leadAff.L_PR_IsPrimary__c = True; 
                            	leadAffList.add(leadAff);
                            }
                        }
                        else{
                            // if no existing record found, create new record with lead & affiliation relationship and isPrimary true
                            for(Id lead : lAffMap.keySet()){
                             	//create Lead Affiliation relationship record
                            	L_PR_Idea_Affiliation__c leadAff = new L_PR_Idea_Affiliation__c();
                            	leadAff.L_PR_Affiliation__c = lAffMap.get(lead);
                            	leadAff.L_PR_Idea__c = lead;
                            	leadAff.L_PR_IsPrimary__c = True;
                            	leadAffList.add(leadAff);
                            }
                        }
                        // find all lead affiliation relationships where lead is present and isPrimary ticked
                        // or any other lead affiliation relationship is present with isprimary true
                        for(L_PR_Idea_Affiliation__c ActivelAffList : [Select Id, L_PR_Idea__c,L_PR_Affiliation__c, L_PR_IsPrimary__c from L_PR_Idea_Affiliation__c
                                                                      where (L_PR_Idea__c in: lAffMap.keySet() AND L_PR_Affiliation__c NOT IN: lAffMap.values() AND L_PR_IsPrimary__c = TRUE)
                                                                    		OR (L_PR_Idea__c in: removelAffMap.keySet() AND L_PR_Affiliation__c in: removelAffMap.values())]){
                                //  update existing lead affiliation relationship
                           		L_PR_Idea_Affiliation__c leadAff = new L_PR_Idea_Affiliation__c();
                                leadAff.Id = ActivelAffList.Id;
                            	leadAff.L_PR_IsPrimary__c = False; 
                            	leadAffList.add(leadAff);                                            
                        	}  
                    }
                   
                    if(leadAffList != Null){
                        upsert leadAffList;
                    }
        		}catch(exception e){
                   system.debug('exception' + e);   
                }                    
    }
    
   // Method to create or update lead organisation record & IsPrimary checkbox field 
    public static void createUpdateLeadOrganisations(Map<Id,Id> lOrgMap,Map<Id,Id> removelOrgMap){
        List<L_PR_Idea_Organisation__c> leadOrgList = new List<L_PR_Idea_Organisation__c>();
        try{
            if(lOrgMap != Null){
                  //check if the current lead organisation pair exist in lead organisation relationship records                      
                  List<L_PR_Idea_Organisation__c> ExistlOrgList = [Select Id, L_PR_Idea__c,L_PR_Organisation__c, L_PR_IsPrimary__c from L_PR_Idea_Organisation__c
                                                                  where L_PR_Idea__c in: lOrgMap.keySet() AND L_PR_organisation__c in: lOrgMap.values()];
                      if(!ExistlOrgList.isEmpty()){
                       // if Found, mark IsPrimary True for that record
                      		for(L_PR_Idea_Organisation__c exLOrg : ExistlOrgList){
                                //  update existing lead organisation relationship
                           		L_PR_Idea_Organisation__c leadOrg = new L_PR_Idea_Organisation__c();
                                leadOrg.Id = exLOrg.Id;
                            	leadOrg.L_PR_IsPrimary__c = True; 
                            	leadOrgList.add(leadOrg);
                            }
                        }
                        else{
                            // if no existing record found, create new record with lead & organisation relationship and isPrimary true
                            for(Id lead : lOrgMap.keySet()){
                             	//create Lead organisation relationship record
                            	L_PR_Idea_Organisation__c leadOrg = new L_PR_Idea_Organisation__c();
                            	leadOrg.L_PR_organisation__c = lOrgMap.get(lead);
                            	leadOrg.L_PR_Idea__c = lead;
                            	leadOrg.L_PR_IsPrimary__c = True;
                            	leadOrgList.add(leadOrg);
                            }
                        }
                        // find all lead organisation relationships where lead is present and isPrimary ticked
                        // or any other lead organisation relationship is present with isprimary true
                        for(L_PR_Idea_Organisation__c ActivelOrgList : [Select Id, L_PR_Idea__c,L_PR_organisation__c, L_PR_IsPrimary__c from L_PR_Idea_Organisation__c
                                                                      where (L_PR_Idea__c in: lOrgMap.keySet() AND L_PR_organisation__c NOT IN: lOrgMap.values() AND L_PR_IsPrimary__c = TRUE)
                                                                    		OR (L_PR_Idea__c in: removelOrgMap.keySet() AND L_PR_organisation__c in: removelOrgMap.values())]){
                                //  update existing lead organisation relationship
                           		L_PR_Idea_Organisation__c leadOrg = new L_PR_Idea_Organisation__c();
                                leadOrg.Id = ActivelOrgList.Id;
                            	leadOrg.L_PR_IsPrimary__c = False; 
                            	leadOrgList.add(leadOrg);                                            
                        	}  
                    }
                   
                    if(leadOrgList != Null){
                        upsert leadOrgList;
                    }
        		}catch(exception e){
                   system.debug('exception' + e);   
                }                    
    }
    
    
     // Method to create salesforce notification for staff affiliation users
    public static void createCustomSFNotification(Map<Id, Set<String>> leadStaffMap){
        
        try{
            if(!leadStaffMap.isEmpty()){
                // Get the Id for our custom notification type
        		CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Lead_Notification'];
                
                for(L_PR_Idea__c ld: [Select Id,Name, L_PR_Closed_Reason__c from L_PR_Idea__c where Id IN:leadStaffMap.keyset()]){
                    // Create a new custom notification
        			Messaging.CustomNotification notification = new Messaging.CustomNotification();

        			// Set the contents for the notification
        			String title = ld.Name;
       				String bodyContent = ld.L_PR_Closed_Reason__c;
        			notification.setTitle(title);
        			notification.setBody(bodyContent);

        			// Set the notification type and target
        			notification.setNotificationTypeId(notificationType.Id);
        			notification.setTargetId(ld.Id);
                    // Actually send the notification
            		notification.send(leadStaffMap.get(ld.Id));
                }
            }
        }catch(exception e){
                   system.debug('exception in sending custom notification' + e);   
                }
    }
    
    // Method to update lead organisation record on status update 
    public static void updateLeadOrganisatioStatus(Map<Id,String> leadStatusMap){
        List<L_PR_Idea_Organisation__c> ideaOrgsToUpdate = new List<L_PR_Idea_Organisation__c>();
        try{
             if(leadStatusMap != Null){
                 List<L_PR_Idea_Organisation__c> ideaOrgList = [Select Id, L_PR_Idea__c,L_PR_Organisation__c, L_PR_LeadStatus__c 
                                                                		from L_PR_Idea_Organisation__c
                                                             			where L_PR_Idea__c in: leadStatusMap.keySet()];
                 if(!ideaOrgList.isEmpty()){
                    for(L_PR_Idea_Organisation__c exIdea : ideaOrgList){
                        L_PR_Idea_Organisation__c leadOrg = new L_PR_Idea_Organisation__c();
                        leadOrg.Id = exIdea.Id;
                        leadOrg.L_PR_LeadStatus__c =  leadStatusMap.get(exIdea.L_PR_Idea__c); 
                        ideaOrgsToUpdate.add(leadOrg);
                     }
                  }
             }
             if(!ideaOrgsToUpdate.isEmpty()){
                 update ideaOrgsToUpdate;
             }
        }catch(exception e){
                   system.debug('exception while updating status on lead organisations' + e);   
                }
    }
}