//Test class for ContentDocument trigger
@IsTest
public class ContentDocumentTriggerHelperTest {
  public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    
    @testSetup static void setup() {

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        Account testAcc = TestUtility.newEmptyExternalAccount('Test LTU Account');
        Insert testAcc;
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
        Contact testContact = TestUtility.newContact(testAcc.Id);
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'LTU';
        insert testContact;
        
        //Contact  = [SELECT Id FROM Contact WHERE I_ST_Personal_Email__c='test_unique0012@unique.com'];
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID = affiliationStaffRecordTypeId,
                                                        I_RM_Contact__c=testContact.Id,
                                                        I_RM_Role__c='La Trobe Staff',I_RM_Email__c='caseoftypeenquiry@ibm.com',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Mobile_Phone__c='0415822666');
        insert aff;
    }
    
    private static Id getProjectPropsalRecTypeIdByDevName (String recordTypeAPIName) {
        return Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByDeveloperName().get(recordTypeAPIName).getRecordTypeId();
    }
    
    static testMethod void testDeleteFileErrorWhenParentLocked() {
        
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community Login User' Limit 1];
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        insert testCommunityUser;
        System.debug('-->testCommunityUser--> '+testCommunityUser);
        
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);
        Test.startTest();
        //System.runAs(testCommunityUser){
        
        List<sObject> sObjectList = new List<sObject>();
        
        Project_Proposal__c projectProposalUnLocked = TestUtility.newProjectProposal();
        projectProposalUnLocked.Name = 'LockedProposal';
        projectProposalUnLocked.RecordTypeId = getProjectPropsalRecTypeIdByDevName('I_RS_Proposal');
        projectProposalUnLocked.I_RS_Status__c = 'Draft Proposal';
        projectProposalUnLocked.OwnerId = testCommunityUser.Id;
        
        sObjectList.add((Project_Proposal__c) projectProposalUnLocked);
        
        Blob testBlobFile1 = Blob.valueOf('Testing Content Version');
        
        //Insert test content version for the draft proposal
        ContentVersion testCv1 = new ContentVersion();
        testCV1.title = 'test content trigger error1';
        testCV1.PathOnClient ='test';
        testCV1.VersionData = testBlobFile1;
        testCV1.IsMajorVersion = true;
        testCV1.NetworkId = testCommunityNetwork.Id;
        
        sObjectList.add((ContentVersion) testCV1);
        
        Classification_Master__c testClassficationMaster = TestUtility.newClassificationMaster('TestCls001','2610','Type of Activity (TOA)',true);
        sObjectList.add((Classification_Master__c) testClassficationMaster);
        
        Insert sObjectList;
        System.debug('--> testClassficationMaster -->'+testClassficationMaster);
        
        Classification_Code__c testClassficationCode = TestUtility.newClassificationCode(testClassficationMaster.Id,null,projectProposalUnLocked.Id,null);
        testClassficationCode.I_RS_Percentage__c = 100;
        testClassficationCode.RecordTypeId = Schema.SObjectType.Classification_Code__c.getRecordTypeInfosByName().get('Type of Activity (TOA) codes').getRecordTypeId();
        Insert testClassficationCode;
        System.debug('--> testClassficationCode -->'+testClassficationCode.Id);
        System.debug('--> testClassficationCode -->'+testClassficationCode.I_RS_Percentage__c);
        
        
        List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
        System.debug('--> documents -->'+documents1);
        
        ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
        testContentDoclink1.LinkedEntityId = projectProposalUnLocked.Id;
        testContentDoclink1.ContentDocumentId = documents1[0].Id;
        testContentDoclink1.ShareType = 'I';
        
        Insert testContentDoclink1;
        
        Project_Proposal__c updatedProjectProposalToLock = new Project_Proposal__c(Id = projectProposalUnLocked.Id, I_RS_Status__c = 'Approvals', I_RS_Approval_Flag__c = true);
        Update updatedProjectProposalToLock;
        
        ContentDocument delConentDoc = [Select Id,Title FROM ContentDocument WHERE Title = 'test content trigger error1'];
        System.debug('--> documents 1-->'+delConentDoc);
        System.runAs(testCommunityUser){
            
            try {
                Delete delConentDoc;
            }
            catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains('Project proposal is currently locked down until Research Office has approved') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }
    
    static testMethod void testDeleteFileErrorForFundingOpportunity() {
        
        Test.startTest();
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community User' Limit 1];
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        insert testCommunityUser;
        
        queryTestCon.I_RS_Related_User__c = testCommunityUser.Id;
        update queryTestCon;
        System.debug('-->testCommunityUser--> '+testCommunityUser);
        System.debug('-->testCommunityUser.id--> '+testCommunityUser.id);
        
        
        Blob testBlobFile1 = Blob.valueOf('Testing Content Version');
        Research_Opportunity__c roRec = TestUtility.newResearchOpportunity(false);
        insert roRec;
        
        Research_Opportunity_Team_Member__c roTM = TestUtility.newFundingOpportunityTeamMember(roRec.Id, queryTestCon.Id, testCommunityUser.Id );
        insert roTM;
        System.debug('-->ROTM-->'+roTM);
        System.debug('--> RowCause for ROTM --> '+Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c);
        List<Research_Opportunity__Share> listROShare = [Select Id,UserOrGroupId,ParentId, RowCause
                                                         FROM Research_Opportunity__Share 
                                                         WHERE ParentId = :roRec.Id AND UserOrGroupId = :testCommunityUser.Id];
        System.debug('--> listROShare--> '+listROShare);
        
        /*System.debug('-->Funding Opp. Apex Sharing-->'+[Select Id,UserOrGroupId,ParentId 
        FROM Research_Opportunity__Share 
        WHERE ParentId = :roRec.Id AND RowCause = 'Research_Opportunity_Team_Member__c']);  */
        System.debug('-->RO Id-->'+roRec.Id);
        System.debug('-->ROTM Id-->'+roTM.Id);
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);
        
        //Insert test content version for the draft proposal
        ContentVersion testCv1 = new ContentVersion();
        testCV1.title = 'test content trigger error1';
        testCV1.PathOnClient ='test';
        testCV1.VersionData = testBlobFile1;
        testCV1.IsMajorVersion = true;
        testCV1.NetworkId = testCommunityNetwork.Id;
        
        insert testCV1;
        
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
        System.debug('--> documents -->'+documents);
        
        ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
        testContentDoclink1.LinkedEntityId = roRec.Id;
        testContentDoclink1.ContentDocumentId = documents[0].Id;
        testContentDoclink1.ShareType = 'I';
        testContentDoclink1.Visibility = 'AllUsers';
        
        Insert testContentDoclink1;
        
        System.debug('Document access: ' + [Select RecordId, HasReadAccess, HasEditAccess, HasDeleteAccess FROM UserRecordAccess WHERE UserId = :testCommunityUser.Id AND RecordId = :documents[0].Id ]);
        ContentDocument delConentDoc1 = [Select Id,Title FROM ContentDocument LIMIT 1];
        System.debug('--> documents befor -->'+delConentDoc1);
        
        
        System.runAs(testCommunityUser){
            
            try {
                //ContentDocument delConentDoc = [Select Id,Title FROM ContentDocument WHERE Title = 'test content trigger error1' LIMIT 1];
                ContentDocument delConentDoc = [Select Id FROM ContentDocument WHERE ID = :testContentDoclink1.ContentDocumentId LIMIT 1];
                System.debug('--> documents -->'+delConentDoc);
                delete delConentDoc;
            }
            catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }
}