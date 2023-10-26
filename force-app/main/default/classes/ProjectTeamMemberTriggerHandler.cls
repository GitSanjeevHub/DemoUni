/**
 * Created by burnside on 2019-04-17.
 */

public with sharing class ProjectTeamMemberTriggerHandler {

    public static Boolean runHierarchySharing = true;
    public static void execute(){

        System.debug('ProjectTeamMemberTriggerHandler.execute');
        System.debug(Trigger.operationType);


        if (Trigger.isBefore){
            System.debug('newPTMs Before : ' + Trigger.New);
            if (Trigger.isInsert) {
            System.debug('newPTMs insert : ' + Trigger.New);
                //ProjectTeamMemberTriggerHelper.markLegacyActiveCheckbox(Trigger.New);
                
            	ProjectTeamMemberTriggerHelper.updateTeamMemberUser(Trigger.New);
            }

            if (Trigger.isUpdate) {
            System.debug('newPTMs update : ' + Trigger.New);
                //ProjectTeamMemberTriggerHelper.markLegacyActiveCheckbox(Trigger.New);
                
            	ProjectTeamMemberTriggerHelper.updateTeamMemberUser(Trigger.New);
            }

            if (Trigger.isDelete){
                ProjectTeamMemberTriggerHelper.dispatchSharingCalculationViaTrigger(NULL, (Map<Id, Project_Team_Member__c>) Trigger.OldMap, true);
            }

        }

        if (Trigger.isAfter){

            if (Trigger.isInsert) {
                ProjectTeamMemberTriggerHelper.checkForOverlappingMembers(Trigger.New, NULL);
                
                ProjectTeamMemberTriggerHelper.dispatchSharingCalculationViaTrigger(Trigger.New, NULL, false);
            } 

            if (Trigger.isUpdate) {
                ProjectTeamMemberTriggerHelper.checkForOverlappingMembers(Trigger.New, (Map<Id, Project_Team_Member__c>) Trigger.OldMap);
                
                ProjectTeamMemberTriggerHelper.dispatchSharingCalculationViaTrigger(Trigger.New, (Map<Id, Project_Team_Member__c>) Trigger.OldMap, false);
            }

            if (runHierarchySharing && ProjectTeamMemberHierarchyAccess.isFirstRunAfter()) {
                System.debug('ProjectTeamMemberTriggerHandler: ProjectTeamMemberHierarchyAccess.refreshTeamMemberHierarchyShare()');
                ProjectTeamMemberHierarchyAccess.refreshTeamMemberHierarchyShare();
            }
        }
    }

}