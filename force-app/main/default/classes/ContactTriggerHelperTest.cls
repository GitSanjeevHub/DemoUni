@IsTest
public class ContactTriggerHelperTest {
	
     public static string affiliationRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
     public static string caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);
     public static Id affiliationIntLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();

    @TestSetup
    static void setup() {  

        I_RM_Affiliation_Settings__c objAffiliationSettings = new I_RM_Affiliation_Settings__c(
            Name = 'I_RM_Inactive_Status',
            I_RM_Status__c = 'Inactive'
        );
        insert objAffiliationSettings;
        
        I_RM_Affiliation_Settings__c affSettings = (I_RM_Affiliation_Settings__c) TestUtility.newSObjectInstance(
            new Map<String, String> {
                'Name' => 'I_IL_Sponsored_by_Citizenship',
                'Value__c' => 'Saudi Arabia;Oman;United Arab Emirates;United Arab Emirates (the);Kuwait;Bahrain;Qatar',
                'I_RM_Status__c' => 'Coursework External Sponsorship;Graduate Research Scholarship;Graduate Research External Sponsorship;Other'
            },
            'I_RM_Affiliation_Settings__c'
        );
        insert affSettings;
               
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypeIds,20,caseRecordTypeIds,20,null,null);           
        insert listBatchScoringSetting;        
        
        Account tstAccount = TestUtility.newEmptyExternalAccount('testAccount');
        insert tstAccount;
        tstAccount.isPartner = True;
        update tstAccount;
        
        Contact researcherContact = new Contact(FirstName = 'test', LastName = 'Researcher', email = 'researcher@test.com');
        //researcherContact.AccountId = tstAccount.Id;
        insert researcherContact;

      /*  I_RM_Affiliation__c affliation = new I_RM_Affiliation__c();
        affliation.I_RM_Contact__c = researcherContact.Id;
        affliation.I_RM_Status__c = 'Not Qualified';
        affiliation.I_RM_Mobile_Phone__c ='0411111111';
        insert affliation;*/
        
         

        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community Login User'];

        User researcher;
        researcher = new User(Alias = 'research', Email='researcher@ltu.com.test', 
            EmailEncodingKey='UTF-8', LastName='researcher', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId =  researcherContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName='researcher@ltu.com.test');
        insert researcher;
        
        researcherContact.I_RS_Related_User__c = researcher.Id;
        Update researcherContact;
        
         
        
        //Conor Langan IBM, Bluewolf 11/11/2020/////////////////
        //Id domesticLeadRecordTypeId = I_ST_BatchScoring__c.getValues('I_ST_ContactScoring').I_ST_RecordType_SFIDs__c.split(',')[0];
        Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        Contact newDomesticLead = new Contact(FirstName = 'test_unique1994', LastName = 'unique_test1994', 
                                              Email = 'test_unique1994@unique.com', I_ST_Personal_Email__c = 'test_unique1994@unique.com', MobilePhone = '0447173488');
        //ContactTriggerHandler.runCTEAlways = true;
        insert newDomesticLead;
        
        
        Id educationInstitutionRecordTypeId = [Select Id From RecordType Where DeveloperName = 'I_ST_Educational_Institution'].Id;
        Account fosterOrganisation = new Account(Name = 'fosterParent', RecordTypeId = educationInstitutionRecordTypeId);
        insert fosterOrganisation;
    } 
    
	@IsTest
    public static void testRelatedUserClear(){
        User researcher = [SELECT Id, ContactId, IsActive, IsPortalEnabled FROM User WHERE UserName = 'researcher@ltu.com.test' LIMIT 1];
        Contact researcherContact = [SELECT Id, Name, I_RS_Related_User__c from Contact WHERE Id = :researcher.ContactId LIMIT 1 ];
        System.assert(researcherContact.I_RS_Related_User__c == researcher.Id,  'Contact\'s Related user is not equal to user id');
        
        Test.startTest();
        researcher.IsActive = False;
        researcher.IsPortalEnabled = False;
        update researcher;
        Test.stopTest();
        
        researcherContact = [SELECT Id, Name, I_RS_Related_User__c from Contact WHERE Id = :researcher.ContactId LIMIT 1 ];
        System.assert(researcherContact.I_RS_Related_User__c == null,  'Contact\'s Related user is not cleared');
    }
    
       //Teja Yenduri IBM, Bluewolf 11/09/2021/////////////////
	/*@isTest
    public static void testmarkCalculateContactScoreToTrue(){
       
        List<Contact> domesticLeadContact = [SELECT Id, Name,MobilePhone,I_ST_Calculate_Contact_Score__c from Contact WHERE email = 'test_unique1994@unique.com' LIMIT 1 ];        
        
        try{
			Contact updateContact = new Contact();
            updateContact.id= domesticLeadContact[0].Id;
			updateContact.MobilePhone = '0440901788';
			test.startTest();
            update updateContact;
			test.StopTest();
        }
        catch (Exception e) {
            System.debug('>>> ERROR ='+e);
        }   
       // system.assertEquals(false, domesticLeadContact[0].I_ST_Calculate_Contact_Score__c);
    }*/
    
    @isTest
    public static void testDeleteContact(){
        User researcher = [SELECT Id, ContactId, IsActive, IsPortalEnabled FROM User WHERE UserName = 'researcher@ltu.com.test' LIMIT 1];
        Contact researcherContact = [SELECT Id, Name, I_RS_Related_User__c from Contact WHERE Id = :researcher.ContactId LIMIT 1 ];
        // AccountContactRelation acr = [SELECT Id, AccountId, ContactId, IsDirect, IsActive, I_RS_Manual__c FROM AccountContactRelation WHERE ContactId=:researcherContact.id and AccountID =:researcherContact.accountid];
        
        try{
            delete researcherContact;
        }
        catch (Exception e) {
            System.debug('>>> ERROR ='+e);
        }       
    }
    
    @isTest
    public static void testAccountCleanupDeleteWithCase(){
        
        
        Contact newDomesticLead = [Select Id, AccountId From Contact Where I_ST_Personal_Email__c = 'test_unique1994@unique.com'];
        
        //Lead account should be created via flow automation and associated to domestic lead
        Id paternalParentId = [Select Id FROM Account WHERE Id = :newDomesticLead.AccountId].Id;
        System.assert(paternalParentId != null);
        
        //Associate a case to Lead Account
        Case newCase = new Case(Subject = 'Test', AccountId = paternalParentId);
        insert newCase;
        
        //Delete test
        Test.startTest();
        delete newDomesticLead;
        
        //Lead Account should not delete as it has a case associated
        Account paternalParentDeleted = [Select Id, IsDeleted FROM Account WHERE Id = :paternalParentId ALL ROWS];
        System.assertEquals(paternalParentDeleted.IsDeleted, false);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testAccountCleanupReparent(){
        
        Contact newDomesticLead = [Select Id, AccountId From Contact Where I_ST_Personal_Email__c = 'test_unique1994@unique.com'];
        
        //Lead account should be created via flow automation and associated to domestic lead
        Id paternalParentId = [Select Id FROM Account WHERE Id = :newDomesticLead.AccountId].Id;
        System.assert(paternalParentId != null);
        
        //Reparent Test
        Test.startTest();
        newDomesticLead.AccountId = [Select Id FROM Account WHERE Name = 'fosterParent'].Id;
        
        update newDomesticLead;
        
        Account paternalParentDeleted = [Select Id, IsDeleted FROM Account WHERE Id = :paternalParentId ALL ROWS];
        System.assertEquals(paternalParentDeleted.IsDeleted, true);
        
        Test.stopTest();
    }

    @isTest

    public static void setAffliationsToInactiveTest(){

        Contact researcherContact = [SELECT Id, Name, I_RS_Related_User__c from Contact LIMIT 1 ];

        researcherContact.I_RS_Deceased__c = True;
        update researcherContact;

    }
    
    //Added by Teja IBM on 21 January 2022 for LTU360-995  to cover createLeadOrganization methodin ContactTriggerHelper
    
    @isTest
    public static void testcreateLeadOrganizationWithoutAccount(){
        List<Contact> lstContacts = I_ST_UnitTestUtilities.createTestContactRecords(10,false);
        
        Test.startTest();
        	//ContactTriggerHandler.runCTEAlways = true;
        	insert lstContacts;        
            Contact objContact = [SELECT Id,AccountId,Name from Contact where FirstName = 'TestFirst1' limit 1];
            System.AssertEquals(objContact.AccountId != null,true,'An Account is Inserted for Contact.');
        Test.stopTest();       
        
    }

    @isTest 
    public static void updateConfidentialfieldTest(){
        Test.startTest();
        Account acc = TestUtility.newEmptyLTUAccount('testAcc1');
        acc.I_RS_Confidential__c = True;
        Insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = System.now().millisecond() + 'test@test.com'
        );
        Insert con;
        con.I_RS_Is_Organisation_Confidential__c = False;
        update con;

        Test.stopTest();
    }
    
	//Added by Vanita Walia for LTU360-2031 update contact name on affiliations
    
    @isTest
    public static void updateContactNameonAffiliation(){
        Test.startTest();
        
        List<Contact> con = [Select Id,FirstName, LastName from Contact where FirstName ='test_unique1994'];
        if(!con.isEmpty()){ 
        	// create affiliation record for newDomesticLead contact
			List<I_RM_Affiliation__c> listLeadAffiliations = I_ST_UnitTestUtilities.createAffiliationRecords(affiliationRecordTypeIds,con[0].Id);
        	insert listLeadAffiliations; 
        
        	// update firstname and lastname for contact
        	con[0].FirstName = 'UpdateFirstName';
        	con[0].LastName = 'UpdateLastName';
        	if(!con.isEmpty()){
           		update con[0];
        	}
        }
        
        List<I_RM_Affiliation__c> affList = [Select Id, L_PR_Contact_Name__c from I_RM_Affiliation__c where I_RM_Contact__c =: con[0].Id];
        system.assertEquals(affList[0].L_PR_Contact_Name__c, 'UpdateFirstName UpdateLastName', 'Affiliation are updated');
        
        Test.stopTest();       
        
    }
    
    @isTest
    public static void setSponsoredFieldValue_Test(){
        
        Test.startTest();

        Account acc1 = (Account) TestUtility.newSObjectInstance(
            new Map<String, String> {
                'Name' => 'Test Account',
                'RecordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.ACCOUNT_RECORD_TYPE_NAME_LTU_ORG_UNIT).getRecordTypeId()
            },
            'Account'
        );
        insert acc1;

        Contact cont1 = (Contact) TestUtility.newSObjectInstance(
            new Map<String, String> {
                'FirstName' => 'Test',
                'LastName' => 'Contact',
                'AccountId' => acc1.Id,
                'Email' => System.now().millisecond() + 'test@test.com', 
                'I_RS_Citizenship__c' => 'Saudi Arabia'
            },
            'Contact'
        );
        insert cont1;        
        
        
        I_RM_Affiliation__c aff1 = (I_RM_Affiliation__c) TestUtility.newSObjectInstance(
            new Map<String, String> {
                'RecordTypeId' => affiliationIntLeadRecordTypeId,
                'I_RM_Contact__c' => cont1.Id,
                'I_RM_Role__c' => 'Student Lead (Int)',
                'I_RM_Email__c' => 'caseoftypeenquiry@ibm.com.invalid',
                'I_RM_Status__c' => 'Not Qualified',
                'I_RM_Mobile_Phone__c' => '+61415822666'
            },
            'I_RM_Affiliation__c'
        );        
        insert aff1;

        System.assertEquals(
            'Yes', 
            [SELECT I_IL_Sponsored__c FROM I_RM_Affiliation__c WHERE Id = :aff1.Id].I_IL_Sponsored__c,
            'Expected Yes as the Country of residence matches one of the sponsorship countries'
        );

        cont1.I_RS_Citizenship__c = 'United States of America (the)';
        update cont1;
        System.assertEquals(
            'No', 
            [SELECT I_IL_Sponsored__c FROM I_RM_Affiliation__c WHERE Id = :aff1.Id].I_IL_Sponsored__c,
            'Expected No as the Country of residence doesn\'t match one of the sponsorship countries'
        );

        Test.StopTest();        
    }
}