@isTest
public with sharing class ResearchPersonnelTest {
    @TestSetup
    static void setup() {
        AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ContactTriggerHandler.runHierarchySharing = false;
	    ContactTriggerHandler.runProjectTeamMemberSharing = false;

        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community User'];

        //Create Account
        Map<integer, Account> accounts = new Map<integer, Account>();
        Account a = TestUtility.newEmptyLTUAccount(System.Label.Top_Org_Name_LaTrobe);
        a.I_RS_SAP_Customer_Number__c = '0000000000';
        insert a;
        a.IsPartner = True;
        update a;

        List<Contact> contactList = new List<Contact>();
        Contact researcher1 = new Contact(FirstName = 'sushant', LastName = 'verma', email = 'sushant@verma.test.com.au', AccountId = a.Id);
        Contact researcher2 = new Contact(FirstName = 'lachlan', LastName = 'burnside', email = 'lachlan@burnside.test.com.au', AccountId = a.Id);
        Contact researcher3 = new Contact(FirstName = 'anusha', LastName = 'cataram', email = 'anusha@cataram.test.com.au', AccountId = a.Id);
       /* insert researcher1;
        insert researcher2;
        insert researcher3;*/
        contactList.add(researcher1);
        contactList.add(researcher2);
        contactList.add(researcher3);
        insert contactList;

        User rUser1 = new User(Alias = 'Name1', Email='sushant@verma.test.com.au', 
                                  EmailEncodingKey='UTF-8', LastName='Researcher', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = researcher1.Id,
                                  TimeZoneSidKey='Australia/Sydney', UserName='sushant@verma.test.com.au');
        insert rUser1;
        system.debug('User1 : ' + rUser1);
        
        User rUser2 = new User(Alias = 'Name2', Email='lachlan@burnside.test.com.au', 
                                  EmailEncodingKey='UTF-8', LastName='Researcher', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = researcher2.Id,
                                  TimeZoneSidKey='Australia/Sydney', UserName='lachlan@burnside.test.com.au');
        insert rUser2;
        system.debug('User2 : ' + rUser2);
        
        researcher1.I_RS_Related_User__c = rUser1.Id;
        update researcher1;
        system.debug('researcher1 1: ' + researcher1);

        researcher2.I_RS_Related_User__c = rUser2.Id;
        update researcher2;
        system.debug('researcher1 2: ' + researcher1);

        Meeting_Date__c md = new Meeting_Date__c(Name = 'test meeting date', Type__c = 'Animal Ethics Application', 
                                                 I_RS_Committee__c = 'HREC A', I_RS_Meeting_Date__c = System.today(), I_RS_Meeting_Closing_Date__c = System.today() + 2);
        insert md;
        
        Ethics_Request__c er = new Ethics_Request__c(I_RS_Ethics_Application_Title__c = 'Test Ethics application title',
                                                    Name = 'TestName', I_RS_Ethics_Application_Number__c = '123456' , 
                                                     I_RS_Status__c = 'Draft', I_RS_Meeting_Date__c = md.Id,
                                                    I_RS_Meeting_Comments__c = 'Test', I_RS_Ethics_Application_Review_Outcome__c = 'Deferred');
        insert er;
        system.debug('Ethics Request: ' + er);
        
        System.debug('one!!!');
        
        Research_Personnel__c rp1 = new Research_Personnel__c (I_RS_Contact_Researcher__c = researcher1.id, I_RS_Role__c = 'Principal Investigator',
                                                              I_RS_Ethics_Request__c = er.id, I_RS_Start_Date__c = System.today() - 10);
        
        Research_Personnel__c rp2 = new Research_Personnel__c (I_RS_Contact_Researcher__c = researcher2.id, I_RS_Role__c = 'Co-Investigator',
                                                              I_RS_Ethics_Request__c = er.id, I_RS_Start_Date__c = System.today() - 10, I_RS_End_Date__c = System.today());
        Research_Personnel__c rp3 = new Research_Personnel__c (I_RS_Contact_Researcher__c = researcher3.id, I_RS_Role__c = 'Co-Investigator',
                                                              I_RS_Ethics_Request__c = er.id, I_RS_Start_Date__c = System.today() - 10);
        System.debug('two!!!');
        insert rp1;
        System.debug('three!!!');
        insert rp2;
        insert rp3;
    }
    
    @isTest
    public static void validateRP_Active_Inactive() {

        System.debug('four!!!');

        String rowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;
        
        Research_Personnel__c rp1 = [SELECT Id, Name, I_RS_Start_Date__c, I_RS_End_Date__c FROM Research_Personnel__c WHERE I_RS_Role__c = 'Principal Investigator' LIMIT 1];
        Research_Personnel__c rp2 = [SELECT Id, Name, I_RS_Start_Date__c, I_RS_End_Date__c FROM Research_Personnel__c WHERE I_RS_End_Date__c != null LIMIT 1];
    	List<Ethics_Request__share> erShares = [SELECT Id FROM Ethics_Request__share WHERE RowCause = :rowCause];
        System.assertEquals(1, erShares.size(), 'There should be one RP which is principle investigator');
        
        Test.startTest();

        rp1.I_RS_End_Date__c = System.today();
        rp2.I_RS_End_Date__c = null;
        System.debug('five!!!');
        update rp1;
        update rp2;
        System.debug('six!!!');
        
        Test.stopTest();
        
    	erShares = [SELECT Id FROM Ethics_Request__share WHERE RowCause = :rowCause];
        System.assertEquals(1, erShares.size(), 'There should be one RP which is Co-Investigator');
    }

    @isTest
    public static void validate_user_Inactive() {
        String rowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;
        Test.startTest();
        Contact c1 = [SELECT Id, I_RS_Related_User__c FROM Contact WHERE FirstName = 'sushant' LIMIT 1];
        c1.I_RS_Related_User__c = null;
        
        update c1;
        Test.stopTest();
    	List<Ethics_Request__share> erShares  = [SELECT Id FROM Ethics_Request__share WHERE RowCause = :rowCause];
        System.assertEquals(0, erShares.size(), 'There should be no RP which is principle investigator');
        
    }
    
    @isTest
    public static void validate_user_Active() {
        String rowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;
        
    	List<Ethics_Request__share> erShares  = [SELECT Id FROM Ethics_Request__share WHERE RowCause = :rowCause];
        System.assertEquals(1, erShares.size(), 'There should be no RP which is principle investigator');

        Test.startTest();
        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community User'];
        Contact researcher3 = [SELECT Id, I_RS_Related_User__c FROM Contact WHERE FirstName = 'anusha' LIMIT 1];
        User rUser3 = new User(Alias = 'Name3', Email='anusha@cataram.test.com.au', 
                                  EmailEncodingKey='UTF-8', LastName='Researcher', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = researcher3.Id,
                                  TimeZoneSidKey='Australia/Sydney', UserName='anusha@cataram.test.com.au');
        insert rUser3;
        system.debug('User3 : ' + rUser3);
        
        Test.stopTest();
        
    	erShares  = [SELECT Id FROM Ethics_Request__share WHERE RowCause = :rowCause];
        system.debug('erShares : ' + erShares);
        System.assertEquals(2, erShares.size(), 'There should be no RP which is principle investigator');
        
    }

    @isTest
    public static void validate_Research_Personnel_Delete() {
        String rowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;
        Test.startTest();
        Research_Personnel__c rp1 = [SELECT Id, Name, I_RS_Start_Date__c, I_RS_End_Date__c FROM Research_Personnel__c WHERE I_RS_Role__c = 'Principal Investigator' LIMIT 1];
		delete rp1;
        Test.stopTest();
        
    	List<Ethics_Request__share> erShares  = [SELECT Id FROM Ethics_Request__share WHERE RowCause = :rowCause];
        system.debug('erShares : ' + erShares);
        System.assertEquals(0, erShares.size(), 'There should be no RP which is principle investigator');
    }
    
}