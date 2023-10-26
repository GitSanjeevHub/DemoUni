@istest
public class batchUpdateMergedUserIdsTest {
    @testSetup
    static void setup(){
        Test.startTest();

        AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ContactTriggerHandler.runHierarchySharing = false;
	    //ContactTriggerHandler.runProjectTeamMemberSharing = false;
    	//ContactTriggerHandler.runResearchPersonnelSharing = false;
        
        Project_Proposal__c projProposalRec;
        Project_Team_Member__c projTeamMember1;
        Project_Team_Member__c projTeamMember2;
        Classification_Code__c classificationCodeRec;
        Contract__c contractRec;
        Id accountEORecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('I_RS_External_Organisation').getRecordTypeId();
        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community Login User'  LIMIT 1];
        //Create Account
        Account tstAccount = new Account(Name = 'La Trobe University',
        I_RS_Part_of_La_Trobe__c = true,
        recordTypeId = accountEORecordtypeId,
        I_RS_SAP_Customer_Number__c = '1234567890');
        insert tstAccount;
        tstAccount.isPartner = True;
        update tstAccount;
        
        Contact Contact1 = new Contact(FirstName = 'One', LastName = 'Reseracher', email = 'one@test.edu.com');
        Contact1.AccountId = tstAccount.Id;
        insert Contact1;
        User Contact1User = new User(Alias = 'one', Email=Contact1.Email, 
            EmailEncodingKey='UTF-8', LastName=Contact1.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = Contact1.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=Contact1.Email);
        Insert Contact1User;
        Contact1.I_RS_Related_User__c = Contact1User.Id;
        update Contact1;

        Contact Contact2 = new Contact(FirstName = 'two', LastName = 'Reseracher', email = 'two@test.edu.com');
        Contact2.AccountId = tstAccount.Id;
        insert Contact2;
        User Contact2User = new User(Alias = 'one', Email=Contact2.Email, 
            EmailEncodingKey='UTF-8', LastName=Contact2.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = Contact2.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=Contact2.Email);
        Insert Contact2User;
        Contact2.I_RS_Related_User__c = Contact2User.Id;
        update Contact2;
        
        projProposalRec = new Project_Proposal__c();
        projProposalRec.Name = 'Sample Project Proposal';
        projProposalRec.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        projProposalRec.I_RS_Peer_Review_Status__c = 'Exempt';
        projProposalRec.I_RS_Status__c = 'Successful';
        projProposalRec.I_RS_Theme__c = 'No theme alignment	';
        projProposalRec.I_RS_Submission_Date__c = System.today();
        projProposalRec.I_RS_Project_Type__c = 'Grant';
        projProposalRec.I_RS_Project_Start_Date__c = System.today() - 10;
        projProposalRec.I_RS_Project_End_Date__c = System.today() + 10;
        projProposalRec.I_RS_IP_Position__c = 'Owned by La Trobe';
        projProposalRec.I_RS_Administring_Organisation__c=tstAccount.Id;
        projProposalRec.I_RS_Proposal_Submission_Date__c = System.today();
		insert projProposalRec;
        
        contractRec = new Contract__c();
        contractRec.Name = 'Sample Contract';
        contractRec.I_RS_Organisation__c = tstAccount.Id;
        contractRec.I_RS_Project_Proposal__c = projProposalRec.Id;
        insert contractRec;

        projTeamMember1 = new Project_Team_Member__c();
        projTeamMember1.I_RS_Project_Proposal__c = projProposalRec.Id;
        projTeamMember1.I_RS_Role__c = 'Lead Chief Investigator';
        projTeamMember1.I_RS_Project_Team_Member__c = Contact1.Id;        
        projTeamMember1.I_RS_Team_Member_User__c = Contact1.I_RS_Related_User__c;
        projTeamMember1.I_RS_Active__c = True;
        projTeamMember1.I_RS_Status__c = 'Accepted';
        projTeamMember1.I_RS_Invitation_Status__c = 'Accepted';
        insert projTeamMember1;

        Meeting_Date__c md = new Meeting_Date__c(Name = 'test meeting date', Type__c = 'Animal Ethics Application', 
                                                 I_RS_Committee__c = 'HREC A', I_RS_Meeting_Date__c = System.today(), I_RS_Meeting_Closing_Date__c = System.today() + 2);
        insert md;
        Ethics_Request__c er = new Ethics_Request__c(I_RS_Ethics_Application_Title__c = 'Test Ethics application title',
                                                    Name = 'TestName', I_RS_Ethics_Application_Number__c = '123456' , 
                                                     I_RS_Status__c = 'Draft', I_RS_Meeting_Date__c = md.Id,
                                                    I_RS_Meeting_Comments__c = 'Test', I_RS_Ethics_Application_Review_Outcome__c = 'Deferred');
        insert er;
        
        Research_Personnel__c rp1 = new Research_Personnel__c (I_RS_Contact_Researcher__c = Contact1.id, I_RS_Role__c = 'Principal Investigator',
                                                              I_RS_Ethics_Request__c = er.id, I_RS_Start_Date__c = System.today() - 10);
        insert rp1;
        
        try {
        	merge Contact2 Contact1;
        } catch (DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage()); 
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void validateStatusAfterMerge(){
        Test.startTest();
    	Contact masterContact = [SELECT Id, Name FROM Contact WHERE EMail = 'two@test.edu.com' LIMIT 1];	    
    	User masterUser = [SELECT Id, Name FROM User WHERE EMail = 'two@test.edu.com' LIMIT 1];	  
        
        Project_Proposal__c ppRec = [SELECT ID, I_RS_LeadChiefInvestigator__c, I_RS_Lead_Chief_Investigator__c FROM Project_Proposal__c LIMIT 1 ];
        Project_Team_Member__c ptmRec = [SELECT ID, I_RS_Project_Team_Member__c, I_RS_Team_Member_User__c FROM Project_Team_Member__c LIMIT 1 ];
        Ethics_Request__c erRec = [SELECT ID, I_RS_Principal_Investigator_Contact__c, I_RS_Principal_Investigator__c FROM Ethics_Request__c LIMIT 1 ];
        Research_Personnel__c rpRec = [SELECT ID, I_RS_Contact_Researcher__c FROM Research_Personnel__c LIMIT 1 ];
        Test.stopTest();
        
        System.assertEquals(ppRec.I_RS_Lead_Chief_Investigator__c, masterContact.Id, 'Mismatch of LCI Contact');
        System.assertNotEquals(ppRec.I_RS_LeadChiefInvestigator__c, masterUser.Id, 'Mismatch of LCI User');
        //System.assertEquals(ptmRec.I_RS_Project_Team_Member__c, masterContact.Id, 'Mismatch of PTM Contact');
        //System.assertNotEquals(ptmRec.I_RS_Team_Member_User__c, masterUser.Id, 'Mismatch of PTM User');
        System.assertEquals(erRec.I_RS_Principal_Investigator_Contact__c, masterContact.Id, 'Mismatch of PI Contact');
        System.assertNotEquals(erRec.I_RS_Principal_Investigator__c, masterUser.Id, 'Mismatch of PI User');
        System.assertEquals(rpRec.I_RS_Contact_Researcher__c, masterContact.Id, 'Mismatch of Research Personnel Contact');
    }
    
    @isTest
    public static void validateBatchMerge(){
        Test.startTest();
        Database.executeBatch(new batchUpdateMergedUserIds(), 200);
        Test.stopTest();
        
    	Contact masterContact = [SELECT Id, Name FROM Contact WHERE EMail = 'two@test.edu.com' LIMIT 1];	    
    	User masterUser = [SELECT Id, Name FROM User WHERE EMail = 'two@test.edu.com' LIMIT 1];	  
        
        Project_Proposal__c ppRec = [SELECT ID, I_RS_LeadChiefInvestigator__c, I_RS_Lead_Chief_Investigator__c, OwnerId FROM Project_Proposal__c LIMIT 1 ];
        Project_Team_Member__c ptmRec = [SELECT ID, I_RS_Project_Team_Member__c, I_RS_Team_Member_User__c FROM Project_Team_Member__c LIMIT 1 ];
        Ethics_Request__c erRec = [SELECT ID, I_RS_Principal_Investigator_Contact__c, I_RS_Principal_Investigator__c, OwnerId FROM Ethics_Request__c LIMIT 1 ];
        Research_Personnel__c rpRec = [SELECT ID, I_RS_Contact_Researcher__c FROM Research_Personnel__c LIMIT 1 ];
        
        System.assertEquals(ppRec.I_RS_Lead_Chief_Investigator__c, masterContact.Id, 'Mismatch of LCI Contact');
        System.assertEquals(ppRec.I_RS_LeadChiefInvestigator__c, masterUser.Id, 'Mismatch of LCI User');
        System.assertEquals(ppRec.OwnerId, masterUser.Id, 'Mismatch of PPS Owner');
        //System.assertEquals(ptmRec.I_RS_Project_Team_Member__c, masterContact.Id, 'Mismatch of PTM Contact');
        //System.assertEquals(ptmRec.I_RS_Team_Member_User__c, masterUser.Id, 'Mismatch of PTM User');
        System.assertEquals(erRec.I_RS_Principal_Investigator_Contact__c, masterContact.Id, 'Mismatch of PI Contact');
        System.assertEquals(erRec.I_RS_Principal_Investigator__c, masterUser.Id, 'Mismatch of PI User');
        System.assertEquals(erRec.OwnerId, masterUser.Id, 'Mismatch of Ethics Owner Contact');
        System.assertEquals(rpRec.I_RS_Contact_Researcher__c, masterContact.Id, 'Mismatch of RPContact');
        
        try{
        	List<Project_Proposal__share> ppsList = [SELECT Id FROM Project_Proposal__share WHERE UserOrGroupId = :masterUser.Id];
            System.assert(ppsList.size()>0, 'Project Proposal share not updated');
        } catch (DmlException e) {
            System.assert(false, 'Project Proposal share not updated-exception'); 
        }
        
        try{
        	List<Ethics_Request__share> erList = [SELECT Id FROM Ethics_Request__share WHERE UserOrGroupId = :masterUser.Id];
            System.debug('erList.size(): ' + erList.size());
            System.assert(erList.size()>0, 'Project Proposal share not updated');
        } catch (DmlException e) {
            System.assert(false, 'Project Proposal share not updated-exception'); 
        }
    }

}