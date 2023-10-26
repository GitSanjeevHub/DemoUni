@isTest
public with sharing class EventTriggerTest {
    public static testmethod void eventTriggerTest() {

        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Theme__c = 'No theme alignment ';
        insert pp;

        insert TestUtility.newEvent(pp.Id);

    }
}