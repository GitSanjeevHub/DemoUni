public class ProjectProposalHelper {
    
    private static Boolean isBeforeUpdateFirstRun = true;
    
    @testVisible
    private static Boolean isAfterUpdateFirstRun = true;
    
    //This method is used to avoid recursion for after update scenario
    public static Boolean isFirstRunAfter(){
        Boolean retAfterUpdateVal;
        if(isAfterUpdateFirstRun){
            retAfterUpdateVal = true;
            isAfterUpdateFirstRun = false;
        }
        else{
            retAfterUpdateVal = isAfterUpdateFirstRun;
        }
        return retAfterUpdateVal;
    }
    
    public void deleteRelatedProjectProposalTeamMembers(set<Id> projectProposalIds){
        
        List<Project_Team_Member__c> ppTeamMembers = [SELECT ID FROM Project_Team_Member__c WHERE I_RS_Project_Proposal__c IN :projectProposalIds LIMIT 9999];
        Database.delete(ppTeamMembers, false);
    }
    
    private static Set<String> getEmailAddresses(String customLabelValue) {
        Set<String> emailSet = new Set<String>();
        String listEmaiFromCustomLabel = (String.isNotBlank(customLabelValue)) ? customLabelValue.trim() : '';
        emailSet.addAll(GlobalUtility.trimStringList(listEmaiFromCustomLabel.split(GlobalConstants.COMMA)));
        return emailSet;
    }
    
    public static void sendEmailToTheTeamMembers(Map<Id,Project_Proposal__c> oldMap, Map<Id,Project_Proposal__c> newMap) {
        
        Set<Id> projectProposalModifiedForStatusSuccess = new Set<Id>();
        Set<Id> projectProposalModifiedForStatusReject = new Set<Id>();
        Set<Id> projectProposalModifiedForStatus = new Set<Id>();
        
        for(Project_Proposal__c pp: newMap.values()){
            if(((oldMap.get(pp.Id).I_RS_Status__c != newMap.get(pp.Id).I_RS_Status__c)
                && newMap.get(pp.Id).I_RS_Status__c == GlobalConstants.PROJECT_PROPOSAL_STATUS_SUCCESSFUL)) {
                    projectProposalModifiedForStatus.add(pp.Id);
                }
        }
        List<Project_Team_Member__c> projectTeamMember = new List<Project_Team_Member__c>();
        if(projectProposalModifiedForStatus != null) {
            projectTeamMember = [SELECT Id,
                                 I_RS_Team_Member_User__r.Email,
                                 I_RS_Team_Member_User__c,
                                 I_RS_Team_Member_User__r.ContactId,
                                 I_RS_Team_Member_User__r.Contact.Email,
                                 I_RS_Role__c,
                                 I_RS_Active__c,
                                 I_RS_Project_Proposal__r.I_RS_First_Approver__c,
                                 I_RS_Project_Proposal__r.I_RS_First_Approver__r.Email,
                                 I_RS_Project_Proposal__r.I_RS_Second_Approver__c,
                                 I_RS_Project_Proposal__r.I_RS_Second_Approver__r.Email
                                 FROM Project_Team_Member__c
                                 WHERE I_RS_Project_Proposal__c IN :projectProposalModifiedForStatus
                                 AND I_RS_Active__c = true];
        }
        System.debug('-->projectTeamMember-->'+projectTeamMember);
        
        try{
            Map<Id,Project_Team_Member__c> mapProjectProposalWithLCIEmail = getProjectProposalAndLCIEmailOnly(projectTeamMember);
            System.debug('-->mapProjectProposalWithLCIEmail-->'+mapProjectProposalWithLCIEmail);
            
            Map<Id,List<String>> projectProposalWithEmailAddressSuccess = getEmailIdsFromTeamMember(projectTeamMember,mapProjectProposalWithLCIEmail);
            System.debug('-->projectProposalWithEmailAddressSuccess-->'+projectProposalWithEmailAddressSuccess);
            
            EmailTemplate emailTemplateForProjectProposalSuccess = [SELECT Id 
                                                                    FROM EmailTemplate 
                                                                    WHERE developerName = 'Project_Proposal_Approved' 
                                                                    LIMIT 1];
            System.debug('-->emailTemplateForProjectProposalSuccess-->'+emailTemplateForProjectProposalSuccess.Id);
            
            if(mapProjectProposalWithLCIEmail != null 
               && mapProjectProposalWithLCIEmail.size()>0 
               && emailTemplateForProjectProposalSuccess!= null) {
                   sendEmail(projectProposalWithEmailAddressSuccess,mapProjectProposalWithLCIEmail,emailTemplateForProjectProposalSuccess.Id,newMap);
               }
        }
        catch (Exception e) {
            Logger.log( 
                new Map<String, Object>{
                    Logger.LOG_TYPE => Logger.LOG_TYPE_VALUE_ERROR,
                        Logger.RELATED_TO_ID => (new list<Id>(newMap.KeySet()) )[0],
                        Logger.CLASS_NAME => 'ProjectProposalHelper',
                        Logger.CLASS_METHOD_NAME => 'sendEmailToTheTeamMembers',
                        Logger.TRANSACTION_DESCRIPTION => 'Send email to Lead Chief Investigator when Project proposal status is successful',
                        Logger.EXCEPTION_MESSAGE => e.getMessage(),
                        Logger.EXCEPTION_STACK_TRACE => e.getStackTraceString()
                        });
        }

    }
    
    private static void sendEmail(Map<Id,List<String>> mapProProWithEmailAddSuccess, 
                                  Map<Id,Project_Team_Member__c> mapProjPropTeamMemberLeadCI,
                                  Id emailTemplateId,
                                  Map<Id,Project_Proposal__c> newMap) {
                                      List<Messaging.SingleEmailMessage> listEmailMessages = new List<Messaging.SingleEmailMessage>();
                                      for(Id projPropId: mapProProWithEmailAddSuccess.keySet()) {
                                          
                                          Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateId, 
                                                                                                                   mapProjPropTeamMemberLeadCI.get(projPropId).I_RS_Team_Member_User__c, 
                                                                                                                   projPropId);
                                          
                                          String emailSubject = email.getSubject();
                                          String emailTextBody = email.getPlainTextBody();
                                          
                                          email.setTargetObjectId(mapProjPropTeamMemberLeadCI.get(projPropId).I_RS_Team_Member_User__c);
                                          email.setSubject(emailSubject);
                                          email.setPlainTextBody(emailTextBody);
                                          email.setSaveAsActivity(false);
                                          email.setCcAddresses(mapProProWithEmailAddSuccess.get(projPropId));
                                          email.setToAddresses(new List<String>{mapProjPropTeamMemberLeadCI.get(projPropId).I_RS_Team_Member_User__r.Email});
                                          listEmailMessages.add(email);
                                      }
                                      if(listEmailMessages != null && listEmailMessages.size()>0) {
                                          System.debug('-->listEmailMessages-->'+listEmailMessages);
                                          Messaging.SendEmailResult[] results = Messaging.sendEmail(listEmailMessages); 
                                      }
                                  }
    
    //returns the Map of ProjectProposalIds and their Email address receipients for Successful project
    private static Map<Id,List<String>> getEmailIdsFromTeamMember(List<Project_Team_Member__c> listPtm, Map<Id,Project_Team_Member__c> mapPPWithLCIEmail) {
        Map<Id, List<String>> mapProjPropEmailAddress = new Map<Id, List<String>>();
        for(Project_Team_Member__c ptm: listPtm) {
            if(getEmailAddresses(Label.Team_Member_Role_for_Email_When_Project_Successful).Contains(ptm.I_RS_Role__c)) {
                if(mapProjPropEmailAddress.containsKey(ptm.I_RS_Project_Proposal__c)) {
                    List<String> emailAddress = mapProjPropEmailAddress.get(ptm.I_RS_Project_Proposal__c);
                    if(String.isNotBlank(ptm.I_RS_Team_Member_User__r.Email))  {
                        if(emailAddress.contains(ptm.I_RS_Team_Member_User__r.Email)) {
                            //do not add again
                        }
                        else {
                            if(ptm.I_RS_Team_Member_User__r.Email != mapPPWithLCIEmail.get(ptm.I_RS_Project_Proposal__c).I_RS_Team_Member_User__r.Email) {
                                emailAddress.add(ptm.I_RS_Team_Member_User__r.Email);
                                System.debug('-->If emailAddress updated-->'+emailAddress);
                                mapProjPropEmailAddress.put(ptm.I_RS_Project_Proposal__c,emailAddress);
                            }
                        }//if(emailAddress)
                    }//if(String.isNotBlank)
                }//if(mapProjPropEmailAddress.containsKey)
                else {
                    List<String> emailInitial = new List<String>();
                    String firstApproverEmail = String.isNotBlank(ptm.I_RS_Project_Proposal__r.I_RS_First_Approver__r.Email) ? ptm.I_RS_Project_Proposal__r.I_RS_First_Approver__r.Email : '';
                    if(firstApproverEmail != '' 
                       && firstApproverEmail != mapPPWithLCIEmail.get(ptm.I_RS_Project_Proposal__c).I_RS_Team_Member_User__r.Email) emailInitial.add(firstApproverEmail);
                    
                    String secondApproverEmail = String.isNotBlank(ptm.I_RS_Project_Proposal__r.I_RS_Second_Approver__r.Email) ? ptm.I_RS_Project_Proposal__r.I_RS_Second_Approver__r.Email : '';
                    if(secondApproverEmail != '' 
                       && secondApproverEmail != firstApproverEmail
                       && secondApproverEmail != mapPPWithLCIEmail.get(ptm.I_RS_Project_Proposal__c).I_RS_Team_Member_User__r.Email) emailInitial.add(secondApproverEmail);
                    
                    if(!emailInitial.contains(ptm.I_RS_Team_Member_User__r.Email)
                       && (ptm.I_RS_Team_Member_User__r.Email != mapPPWithLCIEmail.get(ptm.I_RS_Project_Proposal__c).I_RS_Team_Member_User__r.Email))  {
                           emailInitial.add(ptm.I_RS_Team_Member_User__r.Email);
                       }
                    System.debug('--> Else emailAddress updated --> '+emailInitial);
                    mapProjPropEmailAddress.put(ptm.I_RS_Project_Proposal__c, emailInitial);
                }
            }//if successful
        }//for(Project_Team_Member__c ptm: listPtm)
        System.debug('-->mapProjPropEmailAddress-->'+mapProjPropEmailAddress);
        return mapProjPropEmailAddress;
    }
    
    private static Map<Id,Project_Team_Member__c> getProjectProposalAndLCIEmailOnly(List<Project_Team_Member__c> listPtm) {
        Map<Id,Project_Team_Member__c> mapProjectProposalIdVsLCIEmail = new Map<Id,Project_Team_Member__c>();
        for(Project_Team_Member__c ptm: listPtm) {
            if(!mapProjectProposalIdVsLCIEmail.containsKey(ptm.I_RS_Project_Proposal__c)) {
                if(GlobalConstants.PROJECT_TEAM_MEMBER_ROLE_LEAD_CI.equalsIgnoreCase(ptm.I_RS_Role__c)) {
                    mapProjectProposalIdVsLCIEmail.put(ptm.I_RS_Project_Proposal__c,ptm);
                    System.debug('-->Lead CI Is --> '+mapProjectProposalIdVsLCIEmail.get(ptm.I_RS_Project_Proposal__c));
                }
            }
        }
        return mapProjectProposalIdVsLCIEmail;
    }
    
    public static Set<String> getLockedProposalStatuses(){
        String lockedProposalStatusesConcat = System.label.Project_Proposal_Locked_Statuses;
        return new Set<String>(lockedProposalStatusesConcat.split(','));
    }
}