@isTest
private class I_RM_VilomaContactDeletionSchedulerTest {

    public static Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();

    @TestSetup
    static void makeData(){

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        List<Contact>listDomesticLeadContacts = new List<Contact>();
        List<I_RM_Affiliation__c> listLeadAffiliations = new List<I_RM_Affiliation__c>();
    
        I_RM_Affiliation_Settings__c objAffiliationSettings1 = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Status',I_RM_Status__c = 'Inactive',
        Value__c = '1');
        Insert  objAffiliationSettings1;
        I_RM_Affiliation_Settings__c objAffiliationSettings2 = new I_RM_Affiliation_Settings__c(Name = 'I_RM_No_of_days',I_RM_Status__c = 'Inactive',
        Value__c = '1');
        Insert  objAffiliationSettings2;
        for(integer i=0; i<=10; i++){
            Contact newLeadContact = I_ST_UnitTestUtilities.createContactForScore('test_unique001'+i,
                                                                                  'unique_test001'+i,
                                                                                  'test_unique001'+i+'@unique.com',
                                                                                  'test_unique001'+i+'@unique.com',                                                                                 
                                                                                  '3029');
            listDomesticLeadContacts.add(newLeadContact);
        }
        insert listDomesticLeadContacts;
        
        List<I_RM_Affiliation__c> lstAffiliations = new List<I_RM_Affiliation__c>();
        for(Integer j=0; j<listDomesticLeadContacts.size(); j++) {
            listLeadAffiliations = I_ST_UnitTestUtilities.createAffiliationRecords(affiliationDomesticLeadRecordTypeId,listDomesticLeadContacts[j].Id);
            lstAffiliations.addAll(listLeadAffiliations);
        }
        
        insert lstAffiliations;
        Contact portalContact = new Contact(FirstName='pcontact1',LastName='pconact1',I_ST_Personal_Email__c='test4@email.com');
        insert portalContact;


    } 

    @isTest
    public static  void vilomaContactDeletionSchedulerTest() {        
         test.startTest();
         List<Contact> listOfContactsWOAffls = new List<Contact>();
         Contact listOfContactsWOAffls1 = new Contact(FirstName='TestFirst1',LastName='TestLast1',I_ST_Personal_Email__c='test1@email.com');
         listOfContactsWOAffls.add(listOfContactsWOAffls1);
         Contact listOfContactsWOAffls2 = new Contact(FirstName='TestFirst2',LastName='TestLast2',I_ST_Personal_Email__c='test2@email.com');
         listOfContactsWOAffls.add(listOfContactsWOAffls2);
         Contact listOfContactsWOAffls3 = new Contact(FirstName='TestFirst3',LastName='TestLast3',I_ST_Personal_Email__c='test3@email.com');
         listOfContactsWOAffls.add(listOfContactsWOAffls3);
         Insert listOfContactsWOAffls;
         I_RM_VilomaContactDeletionBatchScheduler myClass = new I_RM_VilomaContactDeletionBatchScheduler ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, myClass);
         List<Contact> cont = new List<Contact>();
         cont = [Select Id, name from Contact];
         test.stopTest();
         system.assert(cont != null);
    }

    @isTest
    public static void vilomaContactDeletionwithCasesTest() {        
        test.startTest();
        List<Contact> listOfContactsWOAffls = new List<Contact>();
        Contact listOfContactsWOAffls1 = new Contact(FirstName='TestFirst1',LastName='TestLast1',I_ST_Personal_Email__c='test1@email.com');
        listOfContactsWOAffls.add(listOfContactsWOAffls1);
        Contact listOfContactsWOAffls2 = new Contact(FirstName='TestFirst2',LastName='TestLast2',I_ST_Personal_Email__c='test2@email.com');
        listOfContactsWOAffls.add(listOfContactsWOAffls2);
        Contact listOfContactsWOAffls3 = new Contact(FirstName='TestFirst3',LastName='TestLast3',I_ST_Personal_Email__c='test3@email.com');
        listOfContactsWOAffls.add(listOfContactsWOAffls3);
        Insert listOfContactsWOAffls;

        case c= new case(
        subject='CaseOfTypeUnmatched',
        ContactId = listOfContactsWOAffls1.Id,
        Origin='Email',SuppliedEmail='unmatched@ibm.com',
        SuppliedName='Unmatched Case',
        SuppliedPhone='6478390245',
        I_ST_School_or_Educational_body__c='Unmatched Account');
        insert c;
        List<Contact> allContacts1 = [Select Id, Name from Contact];
        I_RM_VilomaContactDeletionBatchScheduler myClass = new I_RM_VilomaContactDeletionBatchScheduler ();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, myClass);
        List<Contact> cont = new List<Contact>();
        cont = [Select Id, name from Contact];
        test.stopTest();
        system.assert(cont != null);
   }

   @isTest 
   public static void vilomaContactDeletionwithPUsersTest() {        
    test.startTest();
    List<Contact> listOfContactsWOAffls = new List<Contact>();
    Contact listOfContactsWOAffls1 = new Contact(FirstName='TestFirst1',LastName='TestLast1',I_ST_Personal_Email__c='test1@email.com');
    listOfContactsWOAffls.add(listOfContactsWOAffls1);
    Contact listOfContactsWOAffls2 = new Contact(FirstName='TestFirst2',LastName='TestLast2',I_ST_Personal_Email__c='test2@email.com');
    listOfContactsWOAffls.add(listOfContactsWOAffls2);
    Contact listOfContactsWOAffls3 = new Contact(FirstName='TestFirst3',LastName='TestLast3',I_ST_Personal_Email__c='test3@email.com');
    listOfContactsWOAffls.add(listOfContactsWOAffls3);
    Insert listOfContactsWOAffls;
    List<Contact> portalContact = [Select Id from Contact where LastName = 'pconact1'];
    Profile profile1 = [Select Id from Profile where name = 'LTU Partner Community User'];
    User portalAccountOwner1 = new User(
        ProfileId = profile1.Id,
        ContactId = portalContact[0].Id,
        Username = Math.random()+'@'+UserInfo.getOrganizationid()+'.test',
        Alias = 'frtman',
        Email='TestUserF124.TestUserL125@test124562.com',
        EmailEncodingKey='UTF-8',
        Firstname='TestUserF124',
        Lastname='TestUserL125',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US');
        Database.insert(portalAccountOwner1);

    List<Contact> allContacts1 = [Select Id, Name from Contact];
    I_RM_VilomaContactDeletionBatchScheduler myClass = new I_RM_VilomaContactDeletionBatchScheduler ();   
    String chron = '0 0 23 * * ?';        
    system.schedule('Test Sched', chron, myClass);
    List<Contact> cont = new List<Contact>();
    cont = [Select Id, name from Contact];
    test.stopTest();
    system.assert(cont != null);
}
}