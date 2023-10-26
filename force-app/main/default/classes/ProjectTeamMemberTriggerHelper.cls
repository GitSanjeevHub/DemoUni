public with sharing class ProjectTeamMemberTriggerHelper {

    //public static Boolean updateLegacyActiveCheckboxBasedOnDates = true;
    public static Boolean forceSharingRecalculation = false;
    
    /*public static List<Project_Team_Member__c> markLegacyActiveCheckbox(List<Project_Team_Member__c> projectTeamMembers){
        
        System.debug('markLegacyActiveCheckbox');
        
        if (updateLegacyActiveCheckboxBasedOnDates) {
            for (Project_Team_Member__c teamMember : projectTeamMembers){
                System.debug(teamMember.I_RS_Is_currently_in_progress__c);
                teamMember.I_RS_Active__c = teamMember.I_RS_Is_currently_in_progress__c;
            }
            
        }
        return projectTeamMembers;
        
    }*/
    
    
    public static void updateTeamMemberUser(List<Project_Team_Member__c> newPTMs) {
        map<Id, Id> ContactUserMap = new Map<Id, Id>();
        map<Id, Contact> IdContactMap = new Map<Id, Contact>();

            System.debug('newPTMs: ' + newPTMs);
        for (Project_Team_Member__c ptm: newPTMs) {
            if (ptm.I_RS_Project_Team_Member__c != null) {
				ContactUserMap.put(ptm.I_RS_Project_Team_Member__c, null);
            }
            System.debug('Project_Team_Member__c ptm: ' + ptm);
        }
        List<Contact> contacts = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE Id IN :ContactUserMap.KeySet()];
        for (Contact c: contacts) {
            ContactUserMap.put(c.Id, c.I_RS_Related_User__c);
            IdContactMap.put(c.Id, c);
        }
        
            System.debug('ContactUserMap: ' + ContactUserMap);
        for (Project_Team_Member__c ptm:  newPTMs){
            if (ptm.I_RS_Project_Team_Member__c != null) {
                ptm.I_RS_Team_Member_User__c = ContactUserMap.get(ptm.I_RS_Project_Team_Member__c);
                ptm.I_RS_Person_Name__c = IdContactMap.get(ptm.I_RS_Project_Team_Member__c).Name;
            } else {
            	ptm.I_RS_Team_Member_User__c = null;    
            }
            System.debug('ptm.I_RS_Team_Member_User__c: ' + ptm.I_RS_Team_Member_User__c);
        } 
    }
    
    
    
    public static void checkForOverlappingMembers(
        List<Project_Team_Member__c> teamMembersAfterDML, 
        Map<Id, Project_Team_Member__c> teamMembersBeforeDML)
    {
        System.debug('checkForOverlappingMembers');
        
        List<Project_Team_Member__c> teamMembersToEvaluate = new List<Project_Team_Member__c>();
		Set<Id> projectProposalIds = new Set<Id>();
    	Boolean isInsert = teamMembersBeforeDML == NULL;

        if (isInsert){
            teamMembersToEvaluate.addAll(teamMembersAfterDML);
			projectProposalIds.addAll(GlobalUtility.getParentIds(teamMembersToEvaluate, 'I_RS_Project_Proposal__c'));
        }
        else {
	        for (Project_Team_Member__c teamMember : teamMembersAfterDML){
				Project_Team_Member__c teamMemberBeforeUpdate = teamMembersBeforeDML.get(teamMember.Id);

                Boolean dateFieldsChanged = 
                    teamMember.I_RS_Date_Added__c != teamMemberBeforeUpdate.I_RS_Date_Added__c ||
                    teamMember.I_RS_Date_Removed__c != teamMemberBeforeUpdate.I_RS_Date_Removed__c;
                
                Boolean roleChanged = teamMember.I_RS_Role__c != teamMemberBeforeUpdate.I_RS_Role__c;

                if (dateFieldsChanged || roleChanged){
                    teamMembersToEvaluate.add(teamMember);
                    projectProposalIds.add(teamMember.I_RS_Project_Proposal__c);
                }
			}
        }	
        System.debug('projectProposalIds '+projectProposalIds);
        
        if (!projectProposalIds.isEmpty()){

            List<Project_Proposal__c> projectProposalAndTeamMembers = [
                SELECT Id, 
                    (SELECT Id, I_RS_Project_Proposal__c, 
                    I_RS_Project_Team_Member__c, I_RS_Project_Team_Member__r.FirstName, I_RS_Project_Team_Member__r.LastName, 
                    I_RS_Role__c, I_RS_Date_Added__c, I_RS_Date_Removed__c, 
                    I_RS_Is_currently_in_progress__c FROM Team_Members__r WHERE I_RS_Date_Added__c != NULL) 
                FROM Project_Proposal__c WHERE Id IN :projectProposalIds
            ];

            if (!projectProposalAndTeamMembers.isEmpty()){

                Map<Id, Project_Proposal__c> projectProposalMap = 
                    new Map<Id, Project_Proposal__c>(projectProposalAndTeamMembers);

                Map<String, String> roleValueToLabelMap = new Map<String, String>();
                for (Schema.PicklistEntry f : Project_Team_Member__c.I_RS_Role__c.getDescribe().getPicklistValues()){
		        	roleValueToLabelMap.put(f.getValue(), f.getLabel());
                }
                
                for (Project_Team_Member__c teamMember : teamMembersToEvaluate){
                    
                    Set<String> excludedRoles = new Set<String>(System.label.Project_Team_Member_roles_to_skip_overlap_check.split(','));
					if (!excludedRoles.contains(teamMember.I_RS_Role__c)){
                        
                        System.debug('Checking '+teamMember);
                        
                        List<Project_Team_Member__c> adjacentTeamMembers = 
                            projectProposalMap.get(teamMember.I_RS_Project_Proposal__c).getSObjects('Team_Members__r');

                        for (Project_Team_Member__c queriedTeamMember : adjacentTeamMembers){
                            
                            if (!excludedRoles.contains(queriedTeamMember.I_RS_Role__c)){

                                Boolean notTheSameTeamMember = teamMember.Id != queriedTeamMember.Id;
                                if (notTheSameTeamMember){
                                
                                    Boolean sameProjectProposal = teamMember.I_RS_Project_Proposal__c == queriedTeamMember.I_RS_Project_Proposal__c;
                                    Boolean samePerson = teamMember.I_RS_Project_Team_Member__c == queriedTeamMember.I_RS_Project_Team_Member__c;
                                    Boolean bothAreLCI = ptmsHaveSameUniqueRole(teamMember, queriedTeamMember);

                                    if (sameProjectProposal && (samePerson || bothAreLCI)){
            
                                        System.debug('Against '+queriedTeamMember);

                                        //BOTH HAVE START DATE BUT NO END DATE, SO ARE BOTH IN-FLIGHT
                                        if (teamMember.I_RS_Date_Removed__c == NULL && queriedTeamMember.I_RS_Date_Removed__c == NULL){
                                            teamMember.addError(getOverlapErrorMessage(queriedTeamMember, bothAreLCI, roleValueToLabelMap));
                                        }
                                        
                                        //ONE HAS END DATE AND ONE DOESN'T - THIS IS FINE IS THE END DATE ONE ENDS BEFORE THE OTHER
                                        else if (
                                            //Current one is missing end date - existing one should end before new one starts
                                            teamMember.I_RS_Date_Removed__c == NULL && queriedTeamMember.I_RS_Date_Removed__c != NULL &&
                                            teamMember.I_RS_Date_Added__c <= queriedTeamMember.I_RS_Date_Removed__c) {
                                                teamMember.addError(getOverlapErrorMessage(queriedTeamMember, bothAreLCI, roleValueToLabelMap));
                                            }
                                            
                                        else if (
                                            //Existing one is missing end date - new one should end before existing starts
                                            teamMember.I_RS_Date_Removed__c != NULL && queriedTeamMember.I_RS_Date_Removed__c == NULL &&
                                            teamMember.I_RS_Date_Removed__c >= queriedTeamMember.I_RS_Date_Added__c) 
                                            {
                                                teamMember.addError(getOverlapErrorMessage(queriedTeamMember, bothAreLCI, roleValueToLabelMap));
                                            }
                                        
                                        //ADVANCED OVERLAPPING - BOTH HAVE START AND END DATES
                                        else {
                                            Boolean startDateOverlaps = 
                                                //Upserted PTM Start date is between other PTMs dates
                                                (teamMember.I_RS_Date_Added__c >= queriedTeamMember.I_RS_Date_Added__c &&
                                                teamMember.I_RS_Date_Added__c <= queriedTeamMember.I_RS_Date_Removed__c) 
                                                    ||
                                                //Other PTM start date is between upserted PTM dates
                                                (queriedTeamMember.I_RS_Date_Added__c >= teamMember.I_RS_Date_Added__c &&
                                                queriedTeamMember.I_RS_Date_Added__c <= teamMember.I_RS_Date_Removed__c);
                                            
                                            Boolean endDateOverlaps = 
                                                //Upserted PTM end date is between other PTM dates
                                                (teamMember.I_RS_Date_Removed__c >= queriedTeamMember.I_RS_Date_Added__c &&
                                                teamMember.I_RS_Date_Removed__c <= queriedTeamMember.I_RS_Date_Removed__c)
                                                    ||
                                                //Other pTM end date is between upserted PTM dates
                                                (queriedTeamMember.I_RS_Date_Removed__c >= teamMember.I_RS_Date_Added__c &&
                                                queriedTeamMember.I_RS_Date_Removed__c <= teamMember.I_RS_Date_Removed__c);
                                            
                                            if (startDateOverlaps || endDateOverlaps){
                                                teamMember.addError(getOverlapErrorMessage(queriedTeamMember, bothAreLCI, roleValueToLabelMap));
                                            }
                                        }
                                    } 
                                }

                            }
                            
                        }
                        
                    }
                }
            }
        }
    }

    
    static Boolean ptmsHaveSameUniqueRole(Project_Team_Member__c teamMember1, Project_Team_Member__c teamMember2){
        
        Set<String> uniqueRoles = new Set<String>(System.label.Project_Team_Member_Unique_Roles.split(','));
        return uniqueRoles.contains(teamMember1.I_RS_Role__c) && teamMember1.I_RS_Role__c == teamMember2.I_RS_Role__c;
        
    }
    
    static String getOverlapErrorMessage(Project_Team_Member__c queriedTeamMember, Boolean differentPeopleBothUniqueRole, 
                                         Map<String, String> roleValueToLabelMap){

        System.debug('getOverlapErrorMessage');

        String errorMessage; 

        String firstName = queriedTeamMember.I_RS_Project_Team_Member__r.FirstName;
        String lastName = queriedTeamMember.I_RS_Project_Team_Member__r.LastName;
        String role = roleValueToLabelMap.get(queriedTeamMember.I_RS_Role__c);

        String startDate = GlobalUtility.getDateString(queriedTeamMember.I_RS_Date_Added__c);
        String endDate = GlobalUtility.getDateString(queriedTeamMember.I_RS_Date_Removed__c);

        if (endDate != ''){

            if (!differentPeopleBothUniqueRole){
                errorMessage = 'Team Member can only have one role at a time on this project. '+
                                                'They already have a role of ' + role + 
                                                ' from ' + startDate + 
                                                ' to ' + endDate + 
                                                '. Please remove overlap.';
            }
            else {
                errorMessage = 'Project can only have one '+role+' at a time. '+
                    firstName+' '+lastName+' is already in this role from '+startDate+' to '+endDate+
                    '. Please remove overlap.';
            }
        }
        
        else {
            if (!differentPeopleBothUniqueRole){
                errorMessage = 'Team Member can only have one role at a time on this project. '+
                    'They already have a role of ' + role + 
                    ' from ' + startDate + 
                    ' onwards. Please remove overlap.';
            }
            else {
                errorMessage = 'Project can only have one '+role+' Investigator at a time. '+
                    firstName+' '+lastName+' is already in this role from '+startDate+
                    ' onwards. Please remove overlap.';
            }
        }
        
        System.debug('errorMessage '+errorMessage);
        return errorMessage;

    }
    
    
    public static void dispatchSharingCalculationViaTrigger(List<Project_Team_Member__c> teamMembersAfterDML, Map<Id, Project_Team_Member__c> teamMembersBeforeDML, Boolean isDelete){
        
        List<Project_Team_Member__c> projectTeamMembersToCalculate = new List<Project_Team_Member__c>();
        
        //Insert
        if (!isDelete && teamMembersBeforeDML == NULL){
            
            for (Project_Team_Member__c teamMemberAfterDML : teamMembersAfterDML){
                
                Boolean isPRIMEResearcher = teamMemberAFterDML.I_RS_Contact_is_PRIME_Researcher__c;
                if (isPRIMEResearcher)
					projectTeamMembersToCalculate.add(teamMemberAfterDML);
            }
        }
        //Update
        else if (!isDelete && teamMembersBeforeDML != NULL){
            
            for (Project_Team_Member__c teamMemberAfterUpdate : teamMembersAfterDML){
            	Project_Team_Member__c teamMemberBeforeUpdate = teamMembersBeforeDML.get(teamMemberAfterUpdate.Id);
                
				Boolean triggerFieldChanged = (teamMemberAfterUpdate.I_RS_Active__c != teamMemberBeforeUpdate.I_RS_Active__c);
                Boolean isPRIMEResearcher = teamMemberAfterUpdate.I_RS_Contact_is_PRIME_Researcher__c;
                
                if ((forceSharingRecalculation || triggerFieldChanged) && isPRIMEResearcher)
                    projectTeamMembersToCalculate.add(teamMemberAfterUpdate);
            }
            
        }
        //Delete
        else {
            
            for (Project_Team_Member__c teamMemberBeforeDelete : teamMembersBeforeDML.values()){
                
                Boolean isPRIMEResearcher = teamMemberBeforeDelete.I_RS_Contact_is_PRIME_Researcher__c;
                if (isPRIMEResearcher)
            		projectTeamMembersToCalculate.add(teamMemberBeforeDelete);
            }
        }

        if (!projectTeamMembersToCalculate.isEmpty()){
        	ProjectTeamMemberAccess4.runForTeamMembers(projectTeamMembersToCalculate, 'All', isDelete, false);
		}
            
    }

}