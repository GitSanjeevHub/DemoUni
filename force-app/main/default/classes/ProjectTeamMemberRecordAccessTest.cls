/**
 * Created by burnside on 2019-04-16.
 */

@IsTest
public with sharing class ProjectTeamMemberRecordAccessTest {

    static TestSetupWrapper data;
    static Database.DMLOptions allowDuplicates = TestUtility.getAllowDuplicatesDMLOption();
    

    static void disableHierarchySharingForTest() {
        ContactTriggerHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ProjectTeamMemberTriggerHandler.runHierarchySharing = false;
    }


    public static testMethod void projectTeamMemberRecordAccessTest(){
		disableHierarchySharingForTest();
        
        //Added by JTan IBM on 18 Feb 2021 for Apex test class fix
        I_ST_UnitTestUtilities.skipLeadAccountCleanup();

        TestSetupWrapper data = new TestSetupWrapper();


        List<Contract__c> contracts = new List<Contract__c>{
            TestUtility.newContract(data.projectProposal0.Id, null),
            TestUtility.newContract(data.projectProposal1.Id, null)
        };
        insert contracts;
        Contract__c contract0 = contracts[0];
        Contract__c contract1 = contracts[1];


        List<Related_Contract__c> relatedContracts = new List<Related_Contract__c>{
            TestUtility.newRelatedContract(contract0.Id),
            TestUtility.newRelatedContract(contract0.Id),
            TestUtility.newRelatedContract(contract1.Id),
            TestUtility.newRelatedContract(contract1.Id)
        };
        insert relatedContracts;

        

        List<Junction_Linkage__c> junctionLinkages = new List<Junction_Linkage__c>{
            TestUtility.newJunctionLinkage(null, data.projectProposal0.Id, null),
            TestUtility.newJunctionLinkage(null, data.projectProposal1.Id, null)
        };
        insert junctionLinkages;

		List<Project_Team_Member__c> teamMembers = new List<Project_Team_Member__c>();
        
        Project_Team_Member__c teamMember0 = 
            TestUtility.newProjectTeamMember(data.projectProposal0.Id, 'Lead Chief Investigator', data.contact0.Id);
        teamMembers.add(teamMember0);
        
        
        Project_Team_Member__c teamMember1 = 
            TestUtility.newProjectTeamMember(data.projectProposal1.Id, 'Student', data.contact0.Id);
		teamMembers.add(teamMember1);
        
        
        Project_Team_Member__c teamMember2 = 
            TestUtility.newProjectTeamMember(data.projectProposal1.Id, 'Administrator', data.contact1.Id);
        teamMembers.add(teamMember2);
        

        
        Test.startTest();
        
		insert teamMembers;        
        
        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 2);
        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c',  data.contact0.I_RS_Manager__c, 2);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 2);

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 1);
        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 1);


        

        teamMember0.I_RS_Active__c = false;
        update teamMember0;


        
        delete teamMember2;

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 1);
        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c', data.contact0.I_RS_Manager__c, 1);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 1);

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 0);
        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 0);

        

        Test.stopTest();
        

    }




    public static testMethod void testObjectDrivenSharing_Contract(){

		disableHierarchySharingForTest();
        
        //Added by JTan IBM on 18 Feb 2021 for Apex test class fix
        I_ST_UnitTestUtilities.skipLeadAccountCleanup();
        
        TestSetupWrapper data = new TestSetupWrapper();

        List<Project_Team_Member__c> teamMembers = new List<Project_Team_Member__c>{
            
		    TestUtility.newProjectTeamMember(data.projectProposal0.Id, 'Administrator', data.contact0.Id),
                
            TestUtility.newProjectTeamMember(data.projectProposal1.Id, 'Administrator', data.contact1.Id)
        };
        insert teamMembers;

        List<Contract__c> contracts = new List<Contract__c>{
                TestUtility.newContract(data.projectProposal0.Id, null),
                TestUtility.newContract(data.projectProposal1.Id, null)
        };
        insert contracts;
        Contract__c contract0 = contracts[0];
        Contract__c contract1 = contracts[1];

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 1);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 1);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 1);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 1);


        Test.startTest();

        contract0.I_RS_Project_Proposal__c = data.projectProposal1.Id;
        update contract0;

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 0);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 2);


        contract0.I_RS_Project_Proposal__c = null;
        update contract0;

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 0);

        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 1);


        delete contract1;
        verifyShareCount('Contract__Share', 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 0);

        Test.stopTest();

    }





    static void testObjectDrivenSharing(
            String objectName, String objectShareName,
            String lookupField, TestSetupWrapper data
    ){

        

        List<Project_Team_Member__c> teamMembers = new List<Project_Team_Member__c>{
            
            TestUtility.newProjectTeamMember(data.projectProposal0.Id, 'Administrator', data.contact0.Id),
                
            TestUtility.newProjectTeamMember(data.projectProposal1.Id, 'Administrator', data.contact1.Id)
        };
        insert teamMembers;


        SObjectType objectType = Schema.getGlobalDescribe().get(objectName);

        SObject record0 = objectType.newSObject();
        record0.put(lookupField, data.projectProposal0.Id);

        SObject record1 = objectType.newSObject();
        record1.put(lookupField, data.projectProposal0.Id);


        List<SObject> records = new List<SObject>{record0, record1};
        
        insert records;

        verifyShareCount(objectShareName, 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 2);


        for (SObject record : records){
            record.put(lookupField, null);
        }
        update records;


        verifyShareCount(objectShareName, 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 0);
        verifyShareCount(objectShareName, 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 0);


        for (SObject record : records){
            record.put(lookupField, data.projectProposal1.Id);
        }
        update records;


        verifyShareCount(objectShareName, 'Project_Proposal_Team_Member__c', data.portalUser0.Id, 0);
        verifyShareCount(objectShareName, 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 2);


        delete records;

        verifyShareCount(objectShareName, 'Project_Proposal_Team_Member__c', data.portalUser1.Id, 0);


    }


    public static testmethod void testManager(){

		disableHierarchySharingForTest();
        
        //Added by JTan IBM on 18 Feb 2021 for Apex test class fix
        I_ST_UnitTestUtilities.skipLeadAccountCleanup();
        
        TestSetupWrapper data = new TestSetupWrapper();

        List<Project_Team_Member__c> teamMembers = new List<Project_Team_Member__c>{
            TestUtility.newProjectTeamMember(data.projectProposal0.Id, 'Administrator', data.contact0.Id),
                
            TestUtility.newProjectTeamMember(data.projectProposal1.Id, 'Administrator', data.contact0.Id)
        };
        insert teamMembers;

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c', data.managerUser.Id, 2);
        
        Test.startTest();

        data.contact0.I_RS_Manager__c = data.portalUser1.Id;
        data.contact0.I_RS_Manager_staff_Id__c = 'GOOD EVENING';
        update data.contact0;

        Test.stopTest();

      
        System.assertequals(0, [SELECT COUNT() FROM Apex_Debug_Log__c]);

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c', data.managerUser.Id, 0); 

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c', data.portalUser1.Id, 2); 

        teamMembers[0].I_RS_Active__c = false;
        teamMembers[1].I_RS_Active__c = false;
        
		update teamMembers;
        
        for (Apex_Debug_Log__c al: [SELECT Id, Name, Apex_Class_Name__c, Apex_Class_Method_Name__c, Log_Type__c, Request_Data__c, Exception_Message__c FROM Apex_Debug_Log__c]){
        	
        }
        System.assertequals(0, [SELECT COUNT() FROM Apex_Debug_Log__c]);

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c', data.managerUser.Id, 0); 

        verifyShareCount('Project_Proposal__Share', 'Project_Proposal_Team_Member_Manager__c', data.portalUser1.Id, 0); 
        
    }



    public static testmethod void stressTest(){

        Profile portalProfile = [SELECT Id FROM Profile WHERE 
            Name = 'LTU Partner Community User' Limit 1];

        Account portalAccount = TestUtility.newEmptyExternalAccount('TestAccount');
        insert portalAccount;
        portalAccount.isPartner =  True;
        update portalAccount;
	
        List<Contact> contacts = new List<Contact>();
        for (Integer i=0; i<10; i++){
            //contacts.add(TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, portalAccount.Id));
            contacts.add(TestUtility.createContact(portalAccount.Id));
        }
        insert contacts;

        List<User> users = new List<User>();
        for (Integer i=0; i<10; i++){
            users.add(TestUtility.newUser(i+'', portalProfile.Id, null, contacts[i].Id));
        }
        insert users;

        for (Integer i=0; i<10; i++){
            contacts[i].I_RS_Related_User__c = users[i].Id;
        }
        update contacts;

        List<Project_Proposal__c> projectProposals = new List<Project_Proposal__c>();
        for (Integer i=0; i<10; i++){
            projectProposals.add(TestUtility.newProjectProposal());
        }
        insert projectProposals;

        Test.startTest();

        List<Project_Team_Member__c> ptms = new List<Project_Team_Member__c>();
        for (Contact contact : contacts){
            for (Project_Proposal__c projectProposal : projectProposals){
                ptms.add(
                    TestUtility.newProjectTeamMember(
                        projectProposal.Id,
                        'Administrator',
                        contact.Id
                    )
                );
            }
        }
        insert ptms;

        Test.stopTest();

        List<Apex_Debug_Log__c> errors = [select Exception_Message__c from Apex_Debug_Log__c];
       

        System.assertequals(0, errors.size());

        System.assertequals(100, [SELECT COUNT() FROM Project_Proposal__share WHERE RowCause = 'Project_Proposal_Team_Member__c']);

    }


    static void verifyShareCount(String objectShareName, String shareReason, Id userId, Integer count){

        String query = 'SELECT Id from '+objectShareName+' WHERE UserOrGroupId = \''+userId+'\'' +
            ' AND RowCause = \''+shareReason+'\'';
        
        List<SObject> data = Database.query(query);

        System.assertEquals(count, data.size());

    }





    class TestSetupWrapper {

        Account portalAccount = TestUtility.newEmptyExternalAccount('TestAccount');

        Contact managerContact;
        Contact contact0;
        Contact contact1;

        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'LTU Partner Community User' Limit 1];

        User managerUser;
        User portalUser0;
        User portalUser1;
        
        Project_Proposal__c projectProposal0;
        Project_Proposal__c projectProposal1;


        TestSetupWrapper(){

            
            insert portalAccount;
            portalAccount.isPartner =  True;
            update portalAccount;

            //managerContact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, portalAccount.Id);
            managerContact = TestUtility.createContact(portalAccount.Id);
            managerContact.I_RS_Staff_Id__c = 'HELLO :)';
            insert managerContact;

            managerUser = TestUtility.newUser('manager', portalProfile.Id, null, managerContact.Id);
            insert managerUser; 
            
            managerContact.I_RS_Related_User__c = managerUser.Id; 
            update managerContact;


            //contact0 = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, portalAccount.Id);
            contact0 = TestUtility.createContact(portalAccount.Id);
            contact0.I_RS_Manager_Staff_Id__c = 'HELLO :)';
            contact0.I_RS_Manager__c = managerUser.Id;
            Database.insert(contact0, allowDuplicates);

            //contact1 = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, portalAccount.Id);
            contact1 = TestUtility.createContact(portalAccount.Id);
            contact1.I_RS_Manager_Staff_Id__c = 'HELLO :)';
            contact1.I_RS_Staff_Id__c = 'GOOD EVENING';
            contact1.I_RS_Manager__c = managerUser.Id;
            Database.insert(contact1, allowDuplicates);

            portalUser0 = TestUtility.newUser('portalUser0', portalProfile.Id, null, contact0.Id);
            insert(portalUser0);
			Integer start = System.Now().millisecond();
            while(System.Now().millisecond()< start+5){ 
			}
            portalUser1 = TestUtility.newUser('portalUser1', portalProfile.Id, null, contact1.Id);
            insert(portalUser1);

            contact0.I_RS_Related_User__c = portalUser0.Id;
            update contact0;
            
            contact1.I_RS_Related_User__c = portalUser1.Id; 
            update contact1;
            
            List<Project_Proposal__c> projectProposals = new List<Project_Proposal__c>{
                TestUtility.newProjectProposal(),
                TestUtility.newProjectProposal()
            };
            insert projectProposals;
            projectProposal0 = projectProposals[0];
            projectProposal1 = projectProposals[1];


        }

    }

}