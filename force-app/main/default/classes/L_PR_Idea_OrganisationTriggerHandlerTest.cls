@isTest
public class L_PR_Idea_OrganisationTriggerHandlerTest{

    public static Id acctEORecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('I_RS_External_Organisation').getRecordTypeId();
    public static Id acctLARecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('I_RS_La_Trobe_Organisation_Unit').getRecordTypeId();

    @TestSetup
    static void makeData(){
        
        Account acc = New Account();
        acc.Name = 'Test Acc1';
        acc.L_PR_Domestic_International__c = 'Domestic';
        acc.I_RS_Type_of_Organisation__c = 'Schools & Higher Education';
        acc.RecordTypeId = acctEORecType;
        insert acc;

        L_PR_Idea__c idea = New L_PR_Idea__c();
        idea.Name ='Test Lead1';
        idea.L_PR_Type__c = 'Research and Innovation';
        idea.L_PR_Sub_Type__c ='Access to equipment';
        idea.L_PR_Location__c = 'Domestic';
        idea.L_PR_Lead_Status__c = 'Open';
        idea.L_PR_Organisation__c = acc.Id;
        insert idea;
    }

    @isTest 
    public static void updateLeadStatusOnIdeaOrgJunction(){

        Test.startTest();
        Account[] acc = [Select Id, Name, L_PR_Domestic_International__c from Account ];
        acc[0].RecordTypeId = acctEORecType;
        update acc;
        L_PR_Idea__c[] idea = [Select Id, Name from L_PR_Idea__c];

        L_PR_Idea_Organisation__c ideaOrg = New L_PR_Idea_Organisation__c();
        ideaOrg.L_PR_Organisation__c = acc[0].Id;
        ideaOrg.L_PR_Idea__c = idea[0].Id;
        insert ideaOrg;

        L_PR_Idea_Organisation__c[] ideaOegJ = [Select Id, L_PR_LeadStatus__c from L_PR_Idea_Organisation__c];
        Test.stopTest();
        system.debug('@@@ideaOegJ'+ ideaOegJ);
        System.assertEquals('Open', ideaOegJ[0].L_PR_LeadStatus__c);
    }

    @isTest 
    public static void updateLeadStatusOnIdeaOrgJunction2(){

        Test.startTest();
        Account[] acc = [Select Id, Name, L_PR_Domestic_International__c from Account ];
        acc[0].RecordTypeId = acctEORecType;
        update acc;
        L_PR_Idea__c[] idea = [Select Id, Name from L_PR_Idea__c];

        L_PR_Idea_Organisation__c ideaOrg = New L_PR_Idea_Organisation__c();
        ideaOrg.L_PR_Organisation__c = acc[0].Id;
        ideaOrg.L_PR_Idea__c = idea[0].Id;
        insert ideaOrg;
        L_PR_Idea_Organisation__c[] ideaOegJ = [Select Id, L_PR_LeadStatus__c from L_PR_Idea_Organisation__c];
        system.debug('@@@222ideaOegJ'+ ideaOegJ[0].L_PR_LeadStatus__c);
        idea[0].L_PR_Lead_Status__c = 'Closed';
        idea[0].L_PR_Closed_Reason__c ='Test';
        update idea;

        L_PR_Idea_Organisation__c[] ideaOegJ2 = [Select Id, L_PR_LeadStatus__c from L_PR_Idea_Organisation__c];
        Test.stopTest();
        system.debug('@@@222ideaOegJ2'+ ideaOegJ2[0].L_PR_LeadStatus__c);
        System.assertEquals('Closed', ideaOegJ2[0].L_PR_LeadStatus__c);
    }
}