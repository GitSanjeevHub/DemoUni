@isTest
public class ProjectProposalHelperTest {
    
    private static final String ApprovalName = 'Test project Porposal for Approval';
    private static final String ApprovalNoLockName = 'Test project Porposal for Approval no Lock';
    private static final String RROLockName = 'Test project Porposal RRO Lock';
    private static final String RROUnLockName = 'Test project Porposal RRO Unlock';
    private static final String DarftLockName = 'Test project Porposal Draft Lock';
    private static final String DarftNoLockName = 'Test project Porposal Draft No Lock';
    
    
    @TestSetup
    static void setup() {
        AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ContactTriggerHandler.runHierarchySharing = false;
	    ContactTriggerHandler.runProjectTeamMemberSharing = false;
    	ContactTriggerHandler.runResearchPersonnelSharing = false;
        
        //SV
        List<sObject> sObjList = new List<sObject>();
        Account testAcc = TestUtility.newEmptyExternalAccount('Test LTU Account');
        sObjList.add(testAcc);

        //Create Account
        Account tstAccount = TestUtility.newEmptyExternalAccount('testAccount');
        tstAccount.I_RS_SAP_Customer_Number__c = '1234567890';
        sObjList.add(tstAccount);
        insert sObjList;
        sObjList.clear();
        
        tstAccount.IsPartner = True;
        sObjList.add(tstAccount);
        
        testAcc.IsPartner = True;
        sObjList.add(testAcc);
        update sObjList;
        
        sObjList.clear();
        Contact researcherContact = new Contact(FirstName = 'test', LastName = 'Researcher', email = 'researcher@test.com');
        researcherContact.AccountId = tstAccount.Id;
        Contact approverContact = new Contact(FirstName = 'test', LastName = 'Approver', email = 'approver@test.com');
        approverContact.AccountId = tstAccount.Id;
    
        Contact FirstApproverContact = new Contact(FirstName = 'One', LastName = 'Approver', email = 'bruce.wayne2342332@wayneenterprises.com');
        FirstApproverContact.AccountId = tstAccount.Id;
        Contact SecondApproverContact = new Contact(FirstName = 'One', LastName = 'Approver', email = 'bruce.wayne2342335@wayneenterprises.com');
        SecondApproverContact.AccountId = tstAccount.Id;

        Contact TeamMember1Contact = new Contact(FirstName = 'One', LastName = 'TeamMember', email = 'bruce.wayne2342336@wayneenterprises.com');
        TeamMember1Contact.AccountId = tstAccount.Id;
        Contact TeamMember2Contact = new Contact(FirstName = 'two', LastName = 'TeamMember', email = 'bruce.wayne2342337@wayneenterprises.com');
        TeamMember2Contact.AccountId = tstAccount.Id;

        approverContact.AccountId = tstAccount.Id;
    
        sObjList.add(researcherContact);
        sObjList.add(approverContact);
        sObjList.add(FirstApproverContact);
        sObjList.add(SecondApproverContact);
        sObjList.add(TeamMember1Contact);
        sObjList.add(TeamMember2Contact);

        Contact testContact = TestUtility.newContact(testAcc.Id);
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'LTU';

        sObjList.add(testContact);

        insert sObjList;
        sObjList.clear();
        
        
        Profile roSysAdm = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        Profile roProfile = [SELECT Id FROM Profile WHERE Name='LTU PRIME' LIMIT 1];
        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community Login User'  LIMIT 1];
        UserRole grantsRole = [SELECT Id FROM UserRole WHERE Name = 'Grants' Limit 1];
        

        User roUser;
        User researcher;
        User approver;
        User testCommunityUser;
		User testFirstApproverUser;
		User testSecondApproverUser;
		User testLatrobeTeamMeberUser1;
		User testLatrobeTeamMeberUser2;
        
        System.runAs(new User(ID = UserInfo.getUserID())) {
        
        // Create Research Office user
        roUser = new User(Alias = 'rouser', Email='rouser@ltu.com.test', 
            EmailEncodingKey='UTF-8', LastName='ROuser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = roProfile.Id, UserRoleId = grantsRole.Id,
            TimeZoneSidKey='Australia/Sydney', UserName='rouser@ltu.com.test');
        sObjList.add(roUser);

        // create Researcher - Project Proposal Owner
        researcher = new User(Alias = 'research', Email='researcher@ltu.com.test', 
            EmailEncodingKey='UTF-8', LastName='researcher', LanguageLocaleKey='en_US', 
            //LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = approverContact.Id,
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId =  researcherContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName='researcher@ltu.com.test');
        sObjList.add(researcher);

        // create Researcher - Project Proposal approver
        approver = new User(Alias = 'approver', Email='approver@ltu.com.test', 
            EmailEncodingKey='UTF-8', LastName='approver', LanguageLocaleKey='en_US', 
            //LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = researcherContact.Id,
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = approverContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName='approver@ltu.com.test');
        sObjList.add(approver);
        
        Map<String,Id> profileNameVsId = new Map<String,Id>();
        for(Profile p: [SELECT Id,Name FROM Profile WHERE Name LIKE '%LTU%']) {
            profileNameVsId.put(p.Name, p.Id);
        }
        
        testCommunityUser = TestUtility.newUser('zero', profileNameVsId.get('LTU Partner Community Login User'), null, testContact.Id);
        System.debug('-->testCommunityUser--> '+testCommunityUser);  
        
        testFirstApproverUser = TestUtility.newUser('one', profileNameVsId.get('LTU Partner Community Login User'),null,FirstApproverContact.Id);
        testFirstApproverUser.Email = 'bruce.wayne2342332@wayneenterprises.com';
        testfirstApproverUser.Username = System.now().millisecond() + 'bruce.wayne2342332@wayneenterprises.com';
            
        testSecondApproverUser = TestUtility.newUser('two', profileNameVsId.get('LTU Partner Community Login User'),null,SecondApproverContact.Id);
        testSecondApproverUser.Email = 'bruce.wayne2342335@wayneenterprises.com';
        testSecondApproverUser.Username = System.now().millisecond() + 'bruce.wayne2342335@wayneenterprises.com';
        
        testLatrobeTeamMeberUser1 = TestUtility.newUser('three', profileNameVsId.get('LTU Partner Community Login User'),null,TeamMember1Contact.Id);
        testLatrobeTeamMeberUser1.Email = 'bruce.wayne2342336@wayneenterprises.com';
        testLatrobeTeamMeberUser1.Username = System.now().millisecond() + 'bruce.wayne2342336@wayneenterprises.com';
        
        testLatrobeTeamMeberUser2 = TestUtility.newUser('four', profileNameVsId.get('LTU Partner Community Login User'),null,TeamMember2Contact.Id);
        testLatrobeTeamMeberUser2.Email = 'bruce.wayne2342337@wayneenterprises.com';
        testLatrobeTeamMeberUser2.Username = System.now().millisecond() + 'bruce.wayne2342337@wayneenterprises.com';
        
        sObjList.add((sObject)testCommunityUser);
        sObjList.add((sObject)testFirstApproverUser);
        sObjList.add((sObject)testSecondApproverUser);
        sObjList.add((sObject)testLatrobeTeamMeberUser1);
        sObjList.add((sObject)testLatrobeTeamMeberUser2);
        
        Insert sObjList;
        sObjList.clear();
		
        testContact.I_RS_Related_User__c = testCommunityUser.Id;
        researcherContact.I_RS_Related_User__c = researcher.Id;
        approverContact.I_RS_Related_User__c = approver.Id;
        FirstApproverContact.I_RS_Related_User__c = testFirstApproverUser.Id;
        SecondApproverContact.I_RS_Related_User__c = testSecondApproverUser.Id;
        TeamMember1Contact.I_RS_Related_User__c = testLatrobeTeamMeberUser1.Id;
        TeamMember2Contact.I_RS_Related_User__c = testLatrobeTeamMeberUser2.Id;

        System.debug('testContact: ' + testContact);
        System.debug('researcherContact: ' + researcherContact);
        System.debug('approverContact: ' + approverContact);
        System.debug('FirstApproverContact: ' + FirstApproverContact);
        System.debug('SecondApproverContact: ' + SecondApproverContact);
        System.debug('TeamMember1Contact: ' + TeamMember1Contact);
        System.debug('TeamMember2Contact: ' + TeamMember2Contact);
            
        /*for (User u: [SELECT Id, Name, ContactId FROM User WHERE IsActive = TRUE AND ISPortalEnabled = TRUE]) {
        	System.debug('User u:: ' + u);
			if (researcherContact.Id == u.ContactId) {
                researcherContact.I_RS_Related_User__c = u.Id;
            } else if (approverContact.Id == u.ContactId) {
                approverContact.I_RS_Related_User__c = u.Id;
            } else if (FirstApproverContact.Id == u.ContactId) {
                FirstApproverContact.I_RS_Related_User__c = u.Id;
            } else if (SecondApproverContact.Id == u.ContactId) {
                SecondApproverContact.I_RS_Related_User__c = u.Id;
            } else if (TeamMember1Contact.Id == u.ContactId) {
                TeamMember1Contact.I_RS_Related_User__c = u.Id;
            } else if (TeamMember2Contact.Id == u.ContactId) {
                TeamMember2Contact.I_RS_Related_User__c = u.Id;
            } else if (testContact.Id == u.ContactId) {
                testContact.I_RS_Related_User__c = u.Id;
            }
        }*/


        System.debug('testContact: ' + testContact.I_RS_Related_User__c);
        System.debug('researcherContact: ' + researcherContact.I_RS_Related_User__c);
        System.debug('approverContact: ' + approverContact.I_RS_Related_User__c);
        System.debug('FirstApproverContact: ' + FirstApproverContact.I_RS_Related_User__c);
        System.debug('SecondApproverContact: ' + SecondApproverContact.I_RS_Related_User__c);
        System.debug('TeamMember1Contact: ' + TeamMember1Contact.I_RS_Related_User__c);
        System.debug('TeamMember2Contact: ' + TeamMember2Contact.I_RS_Related_User__c);


        sObjList.add(testContact);
        sObjList.add(researcherContact);
        sObjList.add(approverContact);
        sObjList.add(FirstApproverContact);
        sObjList.add(SecondApproverContact);
        sObjList.add(TeamMember1Contact);
        sObjList.add(TeamMember2Contact);
        update sObjList;
        sObjList.clear();
    }
        
        
        List<Project_Proposal__c> listProjectPropForEmails = new List<Project_Proposal__c>();
        Integer i;
        for(i=0 ; i<10 ; i++) {
            Project_Proposal__c projectProposalUnLocked = TestUtility.newProjectProposal();
            projectProposalUnLocked.Name = 'Test Proposal Success Email Test'+i;
            projectProposalUnlocked.I_RS_First_Approver__c = testFirstApproverUser.Id;
            projectProposalUnlocked.I_RS_Second_Approver__c = testSecondApproverUser.Id;
            projectProposalUnLocked.RecordTypeId = getProjectPropsalRecTypeIdByDevName('I_RS_Proposal');
            projectProposalUnlocked.I_RS_LeadChiefInvestigator__c = testLatrobeTeamMeberUser1.Id;
            projectProposalUnlocked.I_RS_Lead_Chief_Investigator__c = TeamMember1Contact.Id;
            projectProposalUnLocked.I_RS_Status__c = 'Negotiating';
            projectProposalUnLocked.I_RS_Theme__c = 'No theme alignment';
            projectProposalUnLocked.I_RS_Submission_Date__c = System.today();
            listProjectPropForEmails.add(projectProposalUnLocked);
        }

        
        //create project proposal for approval        
        Project_Proposal__c pp1 = new Project_Proposal__c();
        pp1.Name = ApprovalName;
        pp1.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        pp1.I_RS_Peer_Review_Status__c = 'Exempt';
        pp1.I_RS_Theme__c = 'No theme alignment';
        pp1.I_RS_Status__c = 'Review by Research Office';
        pp1.I_RS_Allow_Updates_on_Approval__c = False;
        pp1.I_RS_First_Approver__c = approver.Id;
        pp1.I_RS_LeadChiefInvestigator__c = researcher.Id;
        pp1.I_RS_Lead_Chief_Investigator__c = researcherContact.Id;
        pp1.OwnerId = researcher.Id;
        listProjectPropForEmails.add(pp1);

        Project_Proposal__c pp2 = new Project_Proposal__c();
        pp2.Name = ApprovalNoLockName;
        pp2.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        pp2.I_RS_Peer_Review_Status__c = 'Exempt';
        pp2.I_RS_Theme__c = 'No theme alignment';
        pp2.I_RS_Status__c = 'Review by Research Office';
        pp2.I_RS_Allow_Updates_on_Approval__c = True;
        pp2.I_RS_First_Approver__c = approver.Id;
        pp2.I_RS_LeadChiefInvestigator__c = researcher.Id;
        pp2.I_RS_Lead_Chief_Investigator__c = researcherContact.Id;
        pp2.OwnerId = researcher.Id;
        listProjectPropForEmails.add(pp2);

        Project_Proposal__c pp3 = new Project_Proposal__c();
        pp3.Name = RROLockName;
        pp3.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        pp3.I_RS_Peer_Review_Status__c = 'Exempt';
        pp3.I_RS_Theme__c = 'No theme alignment';
        pp3.I_RS_Status__c = 'Review by Research Office';
        pp3.I_RS_Allow_Updates_on_Approval__c = False;
        pp3.I_RS_First_Approver__c = approver.Id;
        pp3.I_RS_LeadChiefInvestigator__c = researcher.Id;
        pp3.I_RS_Lead_Chief_Investigator__c = researcherContact.Id;
        pp3.OwnerId = researcher.Id;
        listProjectPropForEmails.add(pp3);
        
        Project_Proposal__c pp4 = new Project_Proposal__c();
        pp4.Name = RROUnLockName;
        pp4.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        pp4.I_RS_Peer_Review_Status__c = 'Exempt';
        pp4.I_RS_Theme__c = 'No theme alignment';
        pp4.I_RS_Status__c = 'Review by Research Office';
        pp4.I_RS_Allow_Updates_on_Approval__c = True;
        pp4.I_RS_First_Approver__c = approver.Id;
        pp4.I_RS_LeadChiefInvestigator__c = researcher.Id;
        pp4.I_RS_Lead_Chief_Investigator__c = researcherContact.Id;
        pp4.OwnerId = researcher.Id;
        listProjectPropForEmails.add(pp4);
        
        Project_Proposal__c pp5 = new Project_Proposal__c();
        pp5.Name = DarftLockName;
        pp5.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        pp5.I_RS_Peer_Review_Status__c = 'Exempt';
        pp5.I_RS_Status__c = 'Draft Proposal';
        pp5.I_RS_Theme__c = 'No theme alignment';
        pp5.I_RS_Allow_Updates_on_Approval__c = False;
        pp5.I_RS_First_Approver__c = approver.Id;
        pp5.I_RS_LeadChiefInvestigator__c = researcher.Id;
        pp5.I_RS_Lead_Chief_Investigator__c = researcherContact.Id;
        pp5.OwnerId = researcher.Id;
        listProjectPropForEmails.add(pp5);
        
        Project_Proposal__c pp6 = new Project_Proposal__c();
        pp6.Name = DarftNoLockName;
        pp6.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        pp6.I_RS_Peer_Review_Status__c = 'Exempt';
        pp6.I_RS_Status__c = 'Draft Proposal';
        pp6.I_RS_Theme__c = 'No theme alignment';
        pp6.I_RS_Allow_Updates_on_Approval__c = True;
        pp6.I_RS_First_Approver__c = approver.Id;
        pp6.I_RS_LeadChiefInvestigator__c = researcher.Id;
        pp6.I_RS_Lead_Chief_Investigator__c = researcherContact.Id;
        pp6.OwnerId = researcher.Id;
        listProjectPropForEmails.add(pp6);
        

        Insert listProjectPropForEmails;
        System.debug('--> PP after insert -->'+pp1);//false - Review by Research Office - Locked 
        System.debug('--> PP after insert -->'+pp2);//true - Review by Research Office
        System.debug('--> PP after insert -->'+pp3);//false - Review by Research Office - Locked
        System.debug('--> PP after insert -->'+pp4);//true - Review by Research Office
        System.debug('--> PP after insert -->'+pp5);//false - Draft Proposal
        System.debug('--> PP after insert -->'+pp6);//true - Draft Proposal
        
        List<Project_Team_Member__c> listPTM = new List<Project_Team_Member__c>();
        
        Integer k;
        Integer j;
        /*for(k=0 ; k<10 ;k++) {
            Project_Team_Member__c ptm1LeadCI = TestUtility.newProjectTeamMember(listProjectPropForEmails[k].Id,
                                                                                 'Lead Chief Investigator',
                                                                                 testCommunityUser.ContactId);
            Project_Team_Member__c ptm2ChiefInvestigator = TestUtility.newProjectTeamMember(listProjectPropForEmails[k].Id,
                                                                                            'Chief Investigator',
                                                                                            testLatrobeTeamMeberUser1.ContactId);
            Project_Team_Member__c ptm3StudentSupervisor = TestUtility.newProjectTeamMember(listProjectPropForEmails[k].Id,
                                                                                            'Student or Graduate Researcher Supervisor',
                                                                                            testLatrobeTeamMeberUser2.ContactId);
            listPTM.add(ptm1LeadCI);
            listPTM.add(ptm2ChiefInvestigator); 
            listPTM.add(ptm3StudentSupervisor); 
        }
        
        Insert listPTM;*/
        //SV
        for(k=0 ; k<1 ;k++) {
            Project_Team_Member__c ptm1LeadCI = TestUtility.newProjectTeamMember(listProjectPropForEmails[k].Id,
                                                                                 'Lead Chief Investigator',
                                                                                 testCommunityUser.ContactId);
            Project_Team_Member__c ptm2ChiefInvestigator = TestUtility.newProjectTeamMember(listProjectPropForEmails[k].Id,
                                                                                            'Chief Investigator',
                                                                                            testLatrobeTeamMeberUser1.ContactId);
            Project_Team_Member__c ptm3StudentSupervisor = TestUtility.newProjectTeamMember(listProjectPropForEmails[k].Id,
                                                                                            'Student or Graduate Researcher Supervisor',
                                                                                            testLatrobeTeamMeberUser2.ContactId);
            listPTM.add(ptm1LeadCI);
            listPTM.add(ptm2ChiefInvestigator); 
            listPTM.add(ptm3StudentSupervisor); 
        }
        Insert listPTM;
        
    }
    
    @isTest
    public static void testApprovalLockUnlock() {
        User roUser = [SELECT Id, Alias, Email, LastName, UserName from User WHERE UserName = 'rouser@ltu.com.test' LIMIT 1];
        //UserRole grantsRole = [SELECT Id FROM UserRole WHERE Name = 'Grants' Limit 1];
		//User roUser = [SELECT Id, Name, Alias, UserName FROM User WHERE UserRoleId = :grantsRole.Id AND IsActive = TRUE LIMIT 1  ];

        Group pg = [SELECT Id, Name FROM Group WHERE Name='Grants' LIMIT 1];
        GroupMember GM = new GroupMember();
        GM.GroupId = pg.Id;
        GM.UserOrGroupId = roUser.Id;
        
        Insert GM;
        System.debug('Group: ' + pg);
        System.debug('GroupMember: ' + GM);
        

        Project_Proposal__c pp1, pp2, pp3, pp4, pp5, pp6;
        
        for (Project_Proposal__c pp: [SELECT Id, Name, I_RS_Status__c, I_RS_Allow_Updates_on_Approval__c  
                                      FROM Project_Proposal__c 
                                      WHERE Name LIKE 'Test project Porposal%']) {
            System.debug('PP: ' + pp);
            if (ApprovalName.equals(pp.Name)) {
                pp1 = pp;    
            }
            if (ApprovalNoLockName.equals(pp.Name)) {
                pp2 = pp;    
            }
            if (RROLockName.equals(pp.Name)) {
                pp3 = pp;
            }
            if (RROUnLockName.equals(pp.Name)) {
                pp4 = pp;
            }
            if (DarftLockName.equals(pp.Name)) {
                pp5 = pp;
            }
            if (DarftNoLockName.equals(pp.Name)) {
                pp6 = pp;
            }
        }
        
        System.debug('PP1: ' + pp1);//false - Review by Research Office - Locked
        System.debug('PP2: ' + pp2);//true - Review by Research Office
        System.debug('PP3: ' + pp3);//false - Review by Research Office - Locked
        System.debug('PP4: ' + pp4);//true - Review by Research Office
        System.debug('PP5: ' + pp5);//false - Draft Proposal
        System.debug('PP6: ' + pp6);//true - Draft Proposal
        
        System.assertNotEquals(null, pp1, 'pp1 is null');
        System.assertNotEquals(null, pp2, 'pp2 is null');
        System.assertNotEquals(null, pp3, 'pp3 is null');
        System.assertNotEquals(null, pp4, 'pp4 is null');
        System.assertNotEquals(null, pp5, 'pp5 is null');
        System.assertNotEquals(null, pp6, 'pp6 is null');

        //Before any approval process there should be no record in locked state
        List<ProcessInstance> piList = [SELECT ID, TargetObjectId, Status  FROM ProcessInstance WHERE Status in ('Started', 'Pending') ];    
        System.assertEquals(0, piList.size(), 'Mismatch in unlocked record count on proposal');
        
        List<Id> ppIds = new List<Id>();
        ppIds.add(pp1.Id);
        ppIds.add(pp2.Id);
        ppIds.add(pp3.Id);
        ppIds.add(pp4.Id);
        ppIds.add(pp5.Id);
        ppIds.add(pp6.Id);
        Map<Id, boolean> ppLockStatusMap;

        Test.startTest();
        System.runAs(roUser) {
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(pp1.id);
            req1.setSubmitterId(roUser.Id); 
            req1.setProcessDefinitionNameOrId('Approval_Process_for_PP_Only_First_Aprov');
            req1.setSkipEntryCriteria(true);
            requests.add(req1);
            
            Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();
            req2.setComments('Submitting request for approval.');
            req2.setObjectId(pp2.id);
            req2.setSubmitterId(roUser.Id); 
            req2.setProcessDefinitionNameOrId('Approval_Process_for_PP_Only_First_Aprov');
            req2.setSkipEntryCriteria(true);
            requests.add(req2);
            
            System.debug('before Initiating Approval: ');
            Approval.ProcessResult[] results = Approval.process(requests);
            System.debug('After Initiating Approval: ');
            
            for (Approval.ProcessResult result: results){
                System.debug('result.getInstanceStatus(): ' +result.getInstanceStatus());
                System.assert(result.isSuccess());
                System.assertEquals(
                    'Pending', result.getInstanceStatus(),
                    'Instance Status'+result.getInstanceStatus());
            }
            
        }

        Test.stopTest();
        ppLockStatusMap = Approval.isLocked(ppIds);
        System.debug('StatusMap1: ' + ppLockStatusMap);

        System.assertEquals(True, ppLockStatusMap.get(pp1.Id), 'PP1 is unlocked');
        System.assertEquals(False, ppLockStatusMap.get(pp2.Id), 'PP2 is locked');

    }
    
    static testMethod void testEmailToResearchersForGrantSuccess() {
        List<Project_Proposal__c> listProjectProp = new List<Project_Proposal__c>();
        Test.startTest();
        for(Project_Proposal__c pp: [Select Id, I_RS_Status__c FROM Project_Proposal__c
                                     WHERE NAME LIKE 'Test Proposal Success Email Test%']) {
                                       pp.I_RS_Status__c = 'Successful';  
                                       listProjectProp.add(pp);
                                     }
        update listProjectProp;
        Test.stopTest();
        
         //This covers deleteRelatedProjectProposalTeamMembers
        delete listProjectProp[0];
    }
    
    private static Id getProjectPropsalRecTypeIdByDevName (String recordTypeAPIName) {
        return Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByDeveloperName().get(recordTypeAPIName).getRecordTypeId();
    }
}