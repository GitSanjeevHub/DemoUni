//Test class for ContentVersion trigger
@IsTest
public class ContentVersionTriggerHelperTest {
    public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    @testSetup static void setup() {
        
        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        Account testAcc = TestUtility.newEmptyExternalAccount('Test LTU Account');
        Insert testAcc;
        testAcc.IsPartner = True;
        update testAcc;
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
        Contact testContact = TestUtility.newContact(testAcc.Id);
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'LTU';
        insert testContact;
        
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
    
    static testMethod void testNewFileVersionUploadErrorWhenParentLocked() {
        
        //UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'Partner' Limit 1];
        //System.debug('--> portalRole -->'+portalRole);
        
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community Login User' Limit 1];
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        Insert testCommunityUser;
        
        queryTestCon.I_RS_Related_User__c = testCommunityUser.Id;
        update queryTestCon;
            
            
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
        projectProposalUnLocked.I_RS_Theme__c = 'No theme alignment ';
        
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
        
        
        
        Project_Team_Member__c ptm = TestUtility.newProjectTeamMember(projectProposalUnLocked.Id, 'Chief Investigator', queryTestCon.Id);
        ptm.I_RS_Team_Member_User__c = testCommunityUser.Id;
        insert ptm;
        
        Classification_Code__c testClassficationCode = TestUtility.newClassificationCode(testClassficationMaster.Id,null,projectProposalUnLocked.Id,null);
        testClassficationCode.RecordTypeId = Schema.SObjectType.Classification_Code__c.getRecordTypeInfosByName().get('Type of Activity (TOA) codes').getRecordTypeId();
        testClassficationCode.I_RS_Percentage__c = 100;
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
        
        // statements to be executed by this test user.
        Blob testBlobFile2 = Blob.valueOf('Testing Content Version2');
        
        ContentVersion testCv2 = new ContentVersion();
        testCV2.title = 'test content trigger error2';
        testCV2.PathOnClient ='test';
        testCV2.VersionData = testBlobFile2;
        testCV2.IsMajorVersion = true;
        testCV2.NetworkId = testCommunityNetwork.Id;
        testCV2.ContentDocumentId = documents1[0].Id;
        
        System.runAs(testCommunityUser){
            try {
                Insert testCV2;
            }
            catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains('Project proposal is currently locked down until Research Office has approved') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }
    
    
    static testMethod void testNewFileVersionUploadErrorFundingOpportunity() {
        
        //UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'Partner' Limit 1];
        //System.debug('--> portalRole -->'+portalRole);
        
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community User' Limit 1];
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        insert testCommunityUser;

        queryTestCon.I_RS_Related_User__c = testCommunityUser.Id;
        update queryTestCon;
        System.debug('-->testCommunityUser--> '+testCommunityUser);  
        
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);  
        
        Research_Opportunity__c roRec = TestUtility.newResearchOpportunity(false);
        insert roRec;
        
        Research_Opportunity_Team_Member__c roTM = TestUtility.newFundingOpportunityTeamMember(roRec.Id, queryTestCon.Id, testCommunityUser.Id );
        insert roTM;
        
        Blob testBlobFile1 = Blob.valueOf('Testing Content Version');
        
        //Insert test content version for the draft proposal
        ContentVersion testCv1 = new ContentVersion();
        testCV1.title = 'test content trigger error1';
        testCV1.PathOnClient ='test';
        testCV1.VersionData = testBlobFile1;
        testCV1.IsMajorVersion = true;
        testCV1.NetworkId = testCommunityNetwork.Id;
        
        Insert testCV1;
        
        List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
        System.debug('--> documents -->'+documents1);
        
        ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
        testContentDoclink1.LinkedEntityId = roRec.Id;
        testContentDoclink1.ContentDocumentId = documents1[0].Id;
        testContentDoclink1.ShareType = 'I';
        
        Insert testContentDoclink1;
        
        // statements to be executed by this test user.
        Blob testBlobFile2 = Blob.valueOf('Testing Content Version2');
        
        ContentVersion testCv2 = new ContentVersion();
        testCV2.title = 'test content trigger error2';
        testCV2.PathOnClient ='test';
        testCV2.VersionData = testBlobFile2;
        testCV2.IsMajorVersion = true;
        testCV2.NetworkId = testCommunityNetwork.Id;
        testCV2.ContentDocumentId = documents1[0].Id;
        Test.startTest();
        System.runAs(testCommunityUser){
            
            
            try {
                Insert testCV2;
            }
            catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    static testMethod void testNewFileVersionUploadEthicsRequestDraft() {
        /*AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ContactTriggerHandler.runHierarchySharing = false;
	    ContactTriggerHandler.runProjectTeamMemberSharing = false;*/
        
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community User' Limit 1];
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Contact queryTestCon = [Select Id FROM Contact Where FirstName = 'Test Contact' AND LastName = 'LTU'];
        
        User testCommunityUser = TestUtility.newUser('test', profile1.Id, null, queryTestCon.Id);
        insert testCommunityUser;

        queryTestCon.I_RS_Related_User__c = testCommunityUser.Id;
        update queryTestCon;
        System.debug('-->testCommunityUser--> '+testCommunityUser);  
        
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);         
       

        Meeting_Date__c md = new Meeting_Date__c(Name = 'test meeting date', Type__c = 'Animal Ethics Application', 
                                                 I_RS_Committee__c = 'HREC A', I_RS_Meeting_Date__c = System.today(), I_RS_Meeting_Closing_Date__c = System.today() + 2);
        insert md;
        
        Ethics_Request__c erRec = new Ethics_Request__c(I_RS_Ethics_Application_Title__c = 'Test Ethics application title',
                                                    Name = 'TestName', I_RS_Ethics_Application_Number__c = '123456' , 
                                                     I_RS_Status__c = 'Draft', I_RS_Meeting_Date__c = md.Id,
                                                    I_RS_Meeting_Comments__c = 'Test', I_RS_Ethics_Application_Review_Outcome__c = 'Deferred');
        insert erRec;
        
        Research_Personnel__c rp1 = new Research_Personnel__c (I_RS_Contact_Researcher__c = queryTestCon.id, I_RS_Role__c = 'Principal Investigator',
                                                              I_RS_Ethics_Request__c = erRec.id, I_RS_Start_Date__c = System.today() - 10);
        insert rp1;

       
        Blob testBlobFile1 = Blob.valueOf('Testing Content Version');
        
        //Insert test content version for the draft proposal
        ContentVersion testCv1 = new ContentVersion();
        testCV1.title = 'test content trigger error1';
        testCV1.PathOnClient ='test';
        testCV1.VersionData = testBlobFile1;
        testCV1.IsMajorVersion = true;
        testCV1.NetworkId = testCommunityNetwork.Id;
        
        Insert testCV1;
        
        List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
        System.debug('--> documents -->'+documents1);
        
        ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
        testContentDoclink1.LinkedEntityId = erRec.Id;
        testContentDoclink1.ContentDocumentId = documents1[0].Id;
        testContentDoclink1.ShareType = 'I';
        
        Insert testContentDoclink1;
        
        // statements to be executed by this test user.
        Blob testBlobFile2 = Blob.valueOf('Testing Content Version2');
        
        ContentVersion testCv2 = new ContentVersion();
        testCV2.title = 'test content trigger error2';
        testCV2.PathOnClient ='test';
        testCV2.VersionData = testBlobFile2;
        testCV2.IsMajorVersion = true;
        testCV2.NetworkId = testCommunityNetwork.Id;
        testCV2.ContentDocumentId = documents1[0].Id;
        Test.startTest();
        System.runAs(testCommunityUser){
            
            
            try {
                Insert testCV2;
                System.assert(true);
            }
            catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains(GlobalConstants.RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    static testMethod void testNewFileVersionUploadEthicsRequestNotDraft() {
        Test.startTest();
        
        AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ContactTriggerHandler.runHierarchySharing = false;
	    ContactTriggerHandler.runProjectTeamMemberSharing = false;

        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community User' Limit 1];
        
        Account queryTestAcc = [Select Id FROM Account Where Name = 'Test LTU Account'];
        
        Network testCommunityNetwork = [Select Id From Network Where Name = 'PRIME Researcher Portal'];
        System.debug('testCommunityNetwork'+testCommunityNetwork);  
        
        List<Contact> conList = new List<Contact>();
        Contact researcher1 = new Contact(FirstName = 'sushant', LastName = 'verma', email = 'sushant@verma.test.com.au', AccountId = queryTestAcc.Id);
        Contact researcher2 = new Contact(FirstName = 'lachlan', LastName = 'burnside', email = 'lachlan@burnside.test.com.au', AccountId = queryTestAcc.Id);
        conList.add(researcher1);
        conList.add(researcher2);
       // insert researcher1 ;
        //insert researcher2 ;
        insert conList;

        List<User> userList = new List<User>();
        User rUser1 = new User(Alias = 'Name1', Email='sushant@verma.test.com.au', 
                                  EmailEncodingKey='UTF-8', LastName='Researcher', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_AU', ProfileId = profile1.Id, ContactId = researcher1.Id,
                                  TimeZoneSidKey='Australia/Sydney', UserName='sushant@verma.test.com.au');
        
        User rUser2 = new User(Alias = 'Name2', Email='lachlan@burnside.test.com.au', 
                                  EmailEncodingKey='UTF-8', LastName='Researcher', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_AU', ProfileId = profile1.Id, ContactId = researcher2.Id,
                                  TimeZoneSidKey='Australia/Sydney', UserName='lachlan@burnside.test.com.au');
        userList.add(rUser1);
        userList.add(rUser2);
        insert userList;
      //  insert rUser1  ;
       // insert  rUser2 ;
        conList.clear();
        
        researcher1.I_RS_Related_User__c = rUser1.Id;
        researcher2.I_RS_Related_User__c = rUser2.Id;
        conList.add(researcher1);
        conList.add(researcher2);
        update conList;
       // update researcher1  ;
       // update  researcher2 ;
       
        

        Meeting_Date__c md = new Meeting_Date__c(Name = 'test meeting date', Type__c = 'Animal Ethics Application', 
                                                 I_RS_Committee__c = 'HREC A', I_RS_Meeting_Date__c = System.today(), I_RS_Meeting_Closing_Date__c = System.today() + 2);
        insert md;
        
        Ethics_Request__c erRec = new Ethics_Request__c(I_RS_Ethics_Application_Title__c = 'Test Ethics application title',
                                                    Name = 'TestName', I_RS_Ethics_Application_Number__c = '123456' , 
                                                     I_RS_Status__c = 'Draft', I_RS_Meeting_Date__c = md.Id,
                                                    I_RS_Meeting_Comments__c = 'Test', I_RS_Ethics_Application_Review_Outcome__c = 'Deferred');
        insert erRec;
        
        List<Research_Personnel__c> rpList = new List<Research_Personnel__c>();
        Research_Personnel__c rp1 = new Research_Personnel__c (I_RS_Contact_Researcher__c = researcher1.id, I_RS_Role__c = 'Principal Investigator',
                                                              I_RS_Ethics_Request__c = erRec.id, I_RS_Start_Date__c = System.today() - 10);
        Research_Personnel__c rp2 = new Research_Personnel__c (I_RS_Contact_Researcher__c = researcher2.id, I_RS_Role__c = 'Co-Investigator',
                                                              I_RS_Ethics_Request__c = erRec.id, I_RS_Start_Date__c = System.today() - 10, I_RS_End_Date__c = System.today());
        rpList.add(rp1);
        rpList.add(rp2);
        insert rpList;
        //insert rp1 ;
        //insert rp2 ;
        
        String rowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;   
        List<Ethics_Request__share> ethicShareList = new List<Ethics_Request__share>();
        Ethics_Request__share erShare1 = new Ethics_Request__share();
        erShare1.ParentId = erRec.Id;
        erShare1.UserOrGroupId = rUser1.Id;
        erShare1.RowCause = rowCause;                        
        erShare1.AccessLevel = GlobalConstants.ETHICS_TEAM_MEMBER_SHARING_ACCESS;
        ethicShareList.add(erShare1);
        //insert erShare1;
        
        Ethics_Request__share erShare2 = new Ethics_Request__share();
        erShare2.ParentId = erRec.Id;
        erShare2.UserOrGroupId = rUser2.Id;
        erShare2.RowCause = rowCause;                        
        erShare2.AccessLevel = GlobalConstants.ETHICS_TEAM_MEMBER_SHARING_ACCESS;
        ethicShareList.add(erShare2);
        insert ethicShareList;
      // insert erShare2;
        
        erRec.I_RS_Status__c = 'Review by Research Office';
        update erRec;        
        
        System.debug('ER Share:' + [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause 
                                     from Ethics_request__share]);
        System.debug('User1: ' + rUser1);
        System.debug('User1: ' + rUser2);
        
        //System.runAs(rUser1){            
            Blob testBlobFile1 = Blob.valueOf('Testing Content Version');
            
            //Insert test content version for the draft proposal
            ContentVersion testCv1 = new ContentVersion();
            testCV1.title = 'test content trigger error1';
            testCV1.PathOnClient ='test';
            testCV1.VersionData = testBlobFile1;
            testCV1.IsMajorVersion = true;
            testCV1.NetworkId = testCommunityNetwork.Id;
            
            Insert testCV1;
        
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
            System.debug('--> documents -->'+documents1);
            
            ContentDocumentLink testContentDoclink1 = new ContentDocumentLink();
            testContentDoclink1.LinkedEntityId = erRec.Id;
            testContentDoclink1.ContentDocumentId = documents1[0].Id;
            testContentDoclink1.ShareType = 'I';
            
            Insert testContentDoclink1;
        //}
        
        

        System.runAs(rUser2){            
            try {
                //List<ContentDocument> documents2 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Where Title = 'test content trigger error1'];
                List<ContentDocument> documents2 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
                System.debug('--> documents -->'+documents2);
                 // statements to be executed by this test user.

                Blob testBlobFile2 = Blob.valueOf('Testing Content Version2');
                
                ContentVersion testCv2 = new ContentVersion();
                testCV2.title = 'test content trigger error2';
                testCV2.PathOnClient ='test';
                testCV2.VersionData = testBlobFile2;
                testCV2.IsMajorVersion = true;
                testCV2.NetworkId = testCommunityNetwork.Id;
                testCV2.ContentDocumentId = documents1[0].Id;
                
                Insert testCV2;
                System.assert(false);
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