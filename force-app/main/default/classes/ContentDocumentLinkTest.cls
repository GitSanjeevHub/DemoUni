/**
* Created by burnside on 2019-05-06.
*/
@IsTest
public with sharing class ContentDocumentLinkTest {
    
	@testSetup static void setup() {
        
        Account testAcc = TestUtility.newEmptyExternalAccount('Test LTU Account');
        Insert testAcc;
        
        //Contact testContact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, testAcc.Id);
        Contact testContact = TestUtility.createContact(testAcc.Id);
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'LTU';
        insert testContact;
    }
    
    static testMethod void contentDocumentLinkTest()
    {
        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Theme__c = 'No theme alignment ';
        insert projectProposal;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');
        
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';
        cv.PathOnClient ='test';
        cv.VersionData =beforeblob;
        insert cv;
        
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=projectProposal.Id;
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        contentlink.ShareType = 'I';
        
        insert contentlink;
        
        update contentlink;
        
        System.assertequals('AllUsers', [select Visibility from ContentDocumentLink where Id = :contentLink.Id].Visibility);
    }
    
    private static Id getProjectPropsalRecTypeIdByDevName (String recordTypeAPIName) {
        return Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByDeveloperName().get(recordTypeAPIName).getRecordTypeId();
    }
    
    //This method tests the upload of new file against a locked proposal
    static testMethod void testNewFileUploadErrorWhenParentLocked2() {
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community Login User' Limit 1];
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        System.debug('-->testCommunityUser--> '+testCommunityUser);  
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);
        
        Test.startTest();
        System.runAs(testCommunityUser){
            
            Project_Proposal__c projectProposalLockedForReview = TestUtility.newProjectProposal();
            projectProposalLockedForReview.Name = 'LockedProposal';
            projectProposalLockedForReview.RecordTypeId = getProjectPropsalRecTypeIdByDevName('I_RS_Proposal');
            projectProposalLockedForReview.I_RS_Status__c = 'Review By Research Office';
            
            Project_Proposal__c projectProposalLockedForApprovals = TestUtility.newProjectProposal();
            projectProposalLockedForApprovals.Name = 'LockedProposal';
            projectProposalLockedForApprovals.RecordTypeId = getProjectPropsalRecTypeIdByDevName('I_RS_Proposal');
            projectProposalLockedForApprovals.I_RS_Status__c = 'Approvals';
            projectProposalLockedForApprovals.I_RS_Approval_Flag__c = true;
            
            List<SObject> soList = new List<sObject>();
            soList.add((sObject) projectProposalLockedForReview);
            soList.add((sObject) projectProposalLockedForApprovals);
            
            //Insert soList;
            
            Blob testBlobFile1 = Blob.valueOf('Testing Content Version1');
            
            //Insert test content version for the draft proposal
            ContentVersion testCv1 = new ContentVersion();
            testCV1.title = 'test content trigger error1';
            testCV1.PathOnClient ='test';
            testCV1.VersionData = testBlobFile1;
            testCV1.IsMajorVersion = true;
            testCV1.NetworkId = testCommunityNetwork.Id;
            soList.add((ContentVersion) testCV1);
            
            // statements to be executed by this test user.
            Blob testBlobFile2 = Blob.valueOf('Testing Content Version2');
            
            ContentVersion testCv2 = new ContentVersion();
            testCv2.title = 'test content trigger error2';
            testCv2.PathOnClient ='test';
            testCv2.VersionData = testBlobFile2;
            testCv2.IsMajorVersion = true;
            testCv2.NetworkId = testCommunityNetwork.Id;
            
            soList.add((ContentVersion) testCV2);
            
            //Insert project proposal and content versions
            Insert soList;
            
            List<SObject> soList1 = new List<sObject>();
            
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
            System.debug('--> documents -->'+documents1);
            
            ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
            testContentDoclink1.LinkedEntityId = projectProposalLockedForReview.Id;
            testContentDoclink1.ContentDocumentId = documents1[0].Id;
            testContentDoclink1.ShareType = 'I';
            
            soList1.add((ContentDocumentLink) testContentDoclink1);
            
            List<ContentDocument> documents2 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error2'];
            System.debug('--> documents -->'+documents2);
            
            ContentDocumentLink testContentDoclink2 = new ContentDocumentLink();
            testContentDoclink2.LinkedEntityId = projectProposalLockedForApprovals.Id;
            testContentDoclink2.ContentDocumentId = documents2[0].Id;
            testContentDoclink2.ShareType = 'I';
            
            soList1.add((ContentDocumentLink) testContentDoclink2);
            
            try {
                //Insert content document links
                Insert soList1;
            }
            catch(Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains('Project proposal is currently locked down until Research Office has approved') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            
        }
        Test.stopTest();
    }
    
    
    //This method tests the upload of new file against a locked proposal
    static testMethod void testNewFileUploadErrorWithFundingOpportunity() {
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community User' Limit 1];
        
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        System.debug('-->testCommunityUser--> '+testCommunityUser);  
        
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);
        
        Research_Opportunity__c roRec = TestUtility.newResearchOpportunity(false);
        insert roRec;
        
        Test.startTest();
        System.runAs(testCommunityUser){
            Blob testBlobFile1 = Blob.valueOf('Testing Content Version1');
            
            //Insert test content version for the draft proposal
            ContentVersion testCv1 = new ContentVersion();
            testCV1.title = 'test content trigger error1';
            testCV1.PathOnClient ='test';
            testCV1.VersionData = testBlobFile1;
            testCV1.IsMajorVersion = true;
            testCV1.NetworkId = testCommunityNetwork.Id;
            
            //Insert content versions
            Insert testCV1;
            
            List<SObject> soList1 = new List<sObject>();
            
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
            System.debug('--> documents -->'+documents1);
            
            ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
            testContentDoclink1.LinkedEntityId = roRec.Id;
            testContentDoclink1.ContentDocumentId = documents1[0].Id;
            testContentDoclink1.ShareType = 'I';
            
            soList1.add((ContentDocumentLink) testContentDoclink1);
            
            
            try {
                 //Insert content document links
                Insert soList1;
            }
            catch(Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            
        }
        Test.stopTest();
    }
    
}