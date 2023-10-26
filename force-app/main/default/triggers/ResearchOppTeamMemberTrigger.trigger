/**
 * Created by burnside on 2019-05-02.
 */

trigger ResearchOppTeamMemberTrigger on Research_Opportunity_Team_Member__c (after insert, after update, after delete) {

    if (!GlobalUtility.isTriggerDisabled('Research_Opportunity_Team_Member__c')){
        ResearchOppTeamMemberTriggerHandler.execute();
    }

}