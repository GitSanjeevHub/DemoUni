/**
 * Created by burnside on 2019-05-02.
 */
@isTest
public with sharing class ResearchOppTeamMemberRecordAccessTest {
    public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
     
    

    static Database.DMLOptions allowDuplicates = TestUtility.getAllowDuplicatesDMLOption();
    
  @TestSetup
    static void setup(){

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        ContactTriggerHandler.runHierarchySharing = false;
	    ContactTriggerHandler.runProjectTeamMemberSharing = false;
    	ContactTriggerHandler.runResearchPersonnelSharing = false;
        ContactTriggerHandler.runLeadAccountCleanup = false;
        ContactTriggerHandler.runBudget = false;
        ProjectProposalHandler.executeInTest = false;
        ContactTriggerHandler.createLeadAccount = false;

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' Limit 1];
        Profile profile1;//'System Administrator'
        Profile portalProfile;//'LTU Partner Community Login User'
        for (Profile p: [SELECT Id, Name FROM Profile WHERE Name IN ('System Administrator', 'LTU Partner Community Login User') ]){
            if (p.Name == 'LTU Partner Community Login User'){
            	    portalProfile = p;
            }   
            if (p.Name == 'System Administrator'){
            	profile1 = p;    
            }
        }

        User portalAccountOwner1 = TestUtility.newUser('accountOwner', profile1.Id, portalRole.Id, null);
        insert(portalAccountOwner1);
		System.runAs ( portalAccountOwner1 ) {
			List<SObject> genericSObjectList = new List<SObject>();
     		
            I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
            insert objAffiliationSettings;
    
            Account portalAccount = TestUtility.newEmptyExternalAccount('TestAccount');
            insert(portalAccount);

            Contact contact1 = TestUtility.newContact(portalAccount.Id);
            genericSObjectList.add(contact1);
            Contact contact2 = TestUtility.newContact(portalAccount.Id);
            genericSObjectList.add(contact2);
            Database.insert(genericSObjectList, allowDuplicates);
            genericSObjectList.clear();
            
             I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID = affiliationStaffRecordTypeId,
                                                        I_RM_Contact__c=contact1.Id,
                                                        I_RM_Role__c='La Trobe Staff',I_RM_Email__c='caseoftypeenquiry@ibm.com',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Mobile_Phone__c='0415822666');
             insert aff;

            I_RM_Affiliation__c aff2=new I_RM_Affiliation__c(RecordTypeID = affiliationStaffRecordTypeId,
            I_RM_Contact__c=contact2.Id,
            I_RM_Role__c='La Trobe Staff',I_RM_Email__c='caseoftypeenquiry@abc.com',
            I_RM_Status__c='Active',
            I_RM_Mobile_Phone__c='0415822667');
			genericSObjectList.add(aff2);
            insert genericSObjectList;
            genericSObjectList.clear();
            


            User portalUser1 = TestUtility.newUser('portalone', portalProfile.Id, null, contact1.Id);
            genericSObjectList.add(portalUser1);
            User portalUser2 = TestUtility.newUser('portaltwo', portalProfile.Id, null, contact2.Id);
            genericSObjectList.add(portalUser2);
            insert genericSObjectList;
            genericSObjectList.clear();

            contact1.I_RS_Related_User__c = portalUser1.Id;
            genericSObjectList.add(contact1);
            contact2.I_RS_Related_User__c = portalUser2.Id;
            genericSObjectList.add(contact2);
            Database.update(genericSObjectList, allowDuplicates);
            genericSObjectList.clear();

            Research_Opportunity__c researchOpportunity1 = TestUtility.newResearchOpportunity(true);
            genericSObjectList.add(researchOpportunity1);
            System.debug(researchOpportunity1);
            Research_Opportunity__c researchOpportunity2 = TestUtility.newResearchOpportunity(true);
            genericSObjectList.add(researchOpportunity2);
            insert genericSObjectList;
            genericSObjectList.clear();
            System.debug(researchOpportunity2);
        }
    }

    public static testMethod void researchOppTeamMemberRecordAccessTest(){
 
        String Username = 'accountOwner' + UserInfo.getOrganizationId() + '@test.com';
        User portalAccountOwner1 = [SELECT Id, profileId, portalRole, Username FROM User WHERE Username = :Username LIMIT 1];

        System.runAs ( portalAccountOwner1 ) {
            Account portalAccount = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount' LIMIT 1];

            Contact contact1, contact2;
            for (Contact c: [Select Id, FirstName, LastName, AccountId, Email FROM Contact WHERE AccountId = :portalAccount.Id]) {
                if (contact1 == null) {
                    contact1 = c;
                }else if (contact2 == null) {
                    contact2 = c;
                }
            }
            
            I_RM_Affiliation__c aff, aff2;
            for(I_RM_Affiliation__c a: [SELECT Id, RecordTypeID, I_RM_Contact__c, I_RM_Role__c, I_RM_Status__c, I_RM_Mobile_Phone__c FROM I_RM_Affiliation__c WHERE I_RM_Contact__c IN (:contact1.Id, :contact2.Id)]){
                if (a.I_RM_Contact__c == contact1.Id) {
                    aff = a;
                } else if (a.I_RM_Contact__c == contact2.Id) {
                    aff2 = a;
                }    
            }
            
            

            User portalUser1, portalUser2;
            for (User u : [SELECT Id, Name, ContactId FROM User WHERE ContactId IN (:contact1.Id, :contact2.Id)]){
                if (u.ContactId == contact1.Id) {
                	portalUser1 = u;    
                }else if (u.ContactId == contact2.Id) {
                	portalUser2 = u;    
                }   
            }

            
            Research_Opportunity__c researchOpportunity1, researchOpportunity2;
            for (Research_Opportunity__c r : [SELECT Id, Name, I_RS_Status__c, I_RS_Source__c, I_RS_Proposal_to_be_Submitted_By__c, I_RS_Start_Date__c, I_RS_Private__c, I_RS_Submission_Date__c FROM Research_Opportunity__c]){
                if (researchOpportunity1 == null) {
                	researchOpportunity1 = r;    
                } else if (researchOpportunity2 == null) {
                	researchOpportunity2 = r;    
                }   
            }

            Test.startTest();


            //INSERT TEAM MEMBERS - SHOULD ALSO CREATE SHARING
            Research_Opportunity_Team_Member__c teamMember0 =
                    new Research_Opportunity_Team_Member__c(
                            I_RS_Team_Member__c = contact1.Id,
                            I_RS_Research_Opportunity__c = researchOpportunity1.Id,
                            I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED
                    );
            insert teamMember0;
            Research_Opportunity_Team_Member__c teamMember1 =
                    new Research_Opportunity_Team_Member__c(
                            I_RS_Team_Member__c = contact1.Id,
                            I_RS_Research_Opportunity__c = researchOpportunity2.Id,
                            I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED
                    );
            insert teamMember1;     

            Research_Opportunity_Team_Member__c teamMember2 =
                    new Research_Opportunity_Team_Member__c(
                            I_RS_Team_Member__c = contact2.Id,
                            I_RS_Research_Opportunity__c = researchOpportunity1.Id,
                            I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED
                    );
            insert teamMember2;

            Research_Opportunity_Team_Member__c teamMember3 =
                    new Research_Opportunity_Team_Member__c(
                            I_RS_Team_Member__c = contact2.Id,
                            I_RS_Research_Opportunity__c = researchOpportunity2.Id,
                            I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED
                    );
            insert teamMember3;

            Test.stopTest();

            System.assertEquals(4, [SELECT COUNT() FROM Research_Opportunity__Share WHERE RowCause = :Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c]);


            System.runAs(portalUser1) {
                System.assertEquals(researchOpportunity1.Id, [SELECT Id FROM Research_Opportunity__c][0].Id);
                System.assertEquals(researchOpportunity2.Id, [SELECT Id FROM Research_Opportunity__c][1].Id);

                System.assertEquals(4, [SELECT COUNT() FROM Research_Opportunity_Team_Member__c]);

            }

            System.runAs(portalUser2) {
                System.assertEquals(researchOpportunity1.Id, [SELECT Id FROM Research_Opportunity__c][0].Id);
                System.assertEquals(researchOpportunity2.Id, [SELECT Id FROM Research_Opportunity__c][1].Id);

                System.assertEquals(4, [SELECT COUNT() FROM Research_Opportunity_Team_Member__c]);

            }


            //DUMMY UPDATE MEMBERS - NO CHANGE SHOULD OCCUR
            update teamMember0;
            update teamMember1;
            update teamMember2;
            update teamMember3;

            System.assertEquals(4, [SELECT COUNT() FROM Research_Opportunity__Share WHERE RowCause = :Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c]);


            //CHANGE TEAM MEMBER STATUSES - SHARING SHOULD BE REMOVED

            teamMember0.I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_REJECTED;
            update teamMember0;
            teamMember3.I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_REJECTED;
            update teamMember3;


            System.assertEquals(2, [SELECT COUNT() FROM Research_Opportunity__Share WHERE RowCause = :Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c]);
            
            System.runAs(portalUser1) {
                System.debug('Run as internalUser1 - after rejecting');
                System.debug([select Id FROM Research_Opportunity__c]);

                System.assertEquals(researchOpportunity2.Id, [SELECT Id FROM Research_Opportunity__c].Id);

                System.assertEquals(2, [SELECT COUNT() FROM Research_Opportunity_Team_Member__c]);

            }

            System.runAs(portalUser2) {
                System.debug('Run as internalUser2 - after rejecting');

                System.assertEquals(researchOpportunity1.Id, [SELECT Id FROM Research_Opportunity__c].Id);

            }


            //DELETE TEAM MEMBER(S) - SHARES SHOULD BE REMOVED

            delete teamMember1;
            System.assertEquals(1, [SELECT COUNT() FROM Research_Opportunity__Share WHERE RowCause = :Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c]);


            System.runAs(portalUser1) {
                System.debug('Run as internalUser1 - after deleting');
                System.assert([SELECT Id FROM Research_Opportunity__c].isEmpty());

            }


            System.debug('SOQL Queries: ' + Limits.getQueries());
            System.debug('DML Rows: '+Limits.getDMLRows());

        }

    }


    public static testmethod void stressTest(){


        Integer fundingOppCount = 500;
        


        String Username = 'accountOwner' + UserInfo.getOrganizationId() + '@test.com';
        User portalAccountOwner1 = [SELECT Id, profileId, portalRole, Username FROM User WHERE Username = :Username LIMIT 1];

        System.runAs ( portalAccountOwner1 ) {
            Account portalAccount = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount' LIMIT 1];

            Contact contact1, contact2;
            for (Contact c: [Select Id, FirstName, LastName, AccountId, Email FROM Contact WHERE AccountId = :portalAccount.Id]) {
                if (contact1 == null) {
                    contact1 = c;
                }else if (contact2 == null) {
                    contact2 = c;
                }
            }
            
            I_RM_Affiliation__c aff, aff2;
            for(I_RM_Affiliation__c a: [SELECT Id, RecordTypeID, I_RM_Contact__c, I_RM_Role__c, I_RM_Status__c, I_RM_Mobile_Phone__c FROM I_RM_Affiliation__c WHERE I_RM_Contact__c IN (:contact1.Id, :contact2.Id)]){
                if (a.I_RM_Contact__c == contact1.Id) {
                    aff = a;
                } else if (a.I_RM_Contact__c == contact2.Id) {
                    aff2 = a;
                }    
            }


            List<Research_Opportunity__c> researchOpportunityList = new List<Research_Opportunity__c>();
            for (Integer i=0; i<fundingOppCount; i++){
                researchOpportunityList.add(TestUtility.newResearchOpportunity(true));
            }
            insert researchOpportunityList;


            Test.startTest();

                List<Research_Opportunity_Team_Member__c> teamMembers = new List<Research_Opportunity_Team_Member__c>();
                for (Research_Opportunity__c researchOpportunity : researchOpportunityList){

                        teamMembers.add(
                            new Research_Opportunity_Team_Member__c(
                                    I_RS_Team_Member__c = contact1.Id,
                                    I_RS_Research_Opportunity__c = researchOpportunity.Id,
                                    I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED
                            )
                        );

                        teamMembers.add(
                            new Research_Opportunity_Team_Member__c(
                                    I_RS_Team_Member__c = contact2.Id,
                                    I_RS_Research_Opportunity__c = researchOpportunity.Id,
                                    I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED
                            )
                        );


                }

                insert teamMembers;

            Test.stopTest();

        }

    }


}