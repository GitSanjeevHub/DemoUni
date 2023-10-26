/**
 * Created by burnside on 2019-04-17.
 */

trigger ProjectTeamMemberTrigger on Project_Team_Member__c (before insert, before update, before delete, after insert, after update, after delete ) {
    if(!GlobalUtility.isTriggerDisabled('Project_Team_Member__c')){
        ProjectTeamMemberTriggerHandler.execute();
    }
}