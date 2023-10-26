@isTest
public class I_ST_CaseTriggerHandlerTest {
	 @TestSetup
    static void setup() {
        String affiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
        String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);
        
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypIds,20,caseRecordTypeIds,20,null,null);           
        insert listBatchScoringSetting;
        
        
		Id CaseRecordTypeId =  I_ST_BatchScoring__c.getValues('I_ST_CaseScoring').I_ST_RecordType_SFIDs__c.split(',')[0];
       
        I_ST_CaseTriggerHandler.setNotFired();       
        Account newExternalAccount = TestUtility.newEmptyExternalAccount('Test Account');
        insert newExternalAccount;
        List<Contact>listDomesticLeadContacts = new List<Contact>();
       	I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        for(Integer i =0; i<10; i++){
            Contact newDomesticLead = I_ST_UnitTestUtilities.createContactForScore('test_unique001'+i,
                                                                                   'unique_test001'+i,
                                                                                   'test_unique001'+i+'@unique.com',
                                                                                   'test_unique001'+i+'@unique.com',                                                                                  
                                                                                   '3029');
                                                                                           
            listDomesticLeadContacts.add(newDomesticLead);
        }
        Insert listDomesticLeadContacts;
        //Creating Cases to test incremental score on record creation.
        List<Case> casesforTest = New List<Case>();
        List<Case> enquiryCases = New List<Case>();
        for(Integer j=0; j<listDomesticLeadContacts.size(); j++) {
            case newcase =  I_ST_UnitTestUtilities.newListOfContactRelatedCases(CaseRecordTypeId,listDomesticLeadContacts[j],10,false,'Title First'+j,'Open','test@test.com.invalid',null);
            casesforTest.add(newcase);           
        }        
        Insert casesforTest;
        for(Integer i=0; i<listDomesticLeadContacts.size(); i++){
            case objEnquirycase =  I_ST_UnitTestUtilities.newListOfContactRelatedCases(caseRecordTypeIds,listDomesticLeadContacts[i],10,false,'Title FirstEnquiry'+i,'Open','test@test.com.invalid',null);
            enquiryCases.add(objEnquirycase);
        }
        
    }
    //Testing Incrementascore for update case.
    @isTest
    public static void testCalculateIncrementScore(){
        
        test.startTest();    	
            Contact domesticContact = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE email = 'test_unique0011@unique.com' LIMIT 1];
            List<Case> caseToProcess = [SELECT Id,Subject,Type,RecordTypeId,Origin,Status,ContactId,I_ST_Incremental_Score__c FROM case WHERE ContactId =: domesticContact.Id];             
            
            case caseToUpdate = new case();
            caseToUpdate.id = caseToProcess[0].id;        
            caseToUpdate.Origin = 'Email';
            I_ST_CaseTriggerHandler.setNotFired();      
            update caseToUpdate;
            
            I_ST_CaseTriggerHandler.hasFired();
        test.stopTest();
        
        system.assertEquals(20,caseToProcess[0].I_ST_Incremental_Score__c);
	}
    
    //Testing Case Affiliation update.
    @isTest
    public static void testCreateLeadAffiliation(){
        
        test.startTest();
        	String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);
        	Contact domesticContact = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE email = 'test_unique0011@unique.com' LIMIT 1];
            List<Case> caseToProcess = [SELECT Id,Subject,I_RM_Affiliation__c,I_RM_Affiliation__r.I_RM_Contact__c,I_ST_Campus_Interest__c,RecordTypeId,I_ST_Study_Interest__c,I_ST_Study_Level__c,I_ST_Timeframe_To_Study__c,ContactId,I_ST_Incremental_Score__c FROM case WHERE ContactId =: domesticContact.Id AND RecordTypeId =: caseRecordTypeIds];             
        	Case objUpdatedCase = caseToProcess[0];
        	system.assertEquals(objUpdatedCase.ContactId,objUpdatedCase.I_RM_Affiliation__r.I_RM_Contact__c,'Case contact and affiliation contact is match');
        test.stopTest();
    }
    
    //Testing Case Affiliation update.
    @isTest
    public static void testCreateLeadAffiliationWeb(){
       String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);
       Contact domesticContact = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE email = 'test_unique0011@unique.com' LIMIT 1];
       Case newCase2 = new Case(Subject = 'Title',
                                 Type='Entry Requirements',
                                 Origin = 'Web',
                                 SuppliedEmail = 'test_unique0011@unique.com.invalid',
                                 RecordTypeId = caseRecordTypeIds,                                 
                                 I_ST_Score_Calculated__c = false,                                
                                 ContactId = domesticContact.id);
        insert newCase2;
        
       test.startTest(); 
          
            List<Case> caseToProcess = [SELECT Id,Subject,I_RM_Affiliation__c,I_RM_Affiliation__r.I_RM_Contact__c,I_ST_Campus_Interest__c,RecordTypeId,I_ST_Study_Interest__c,I_ST_Study_Level__c,I_ST_Timeframe_To_Study__c,ContactId,I_ST_Incremental_Score__c FROM case WHERE ContactId =: domesticContact.Id AND RecordTypeId =: caseRecordTypeIds AND Origin = 'Web' ];             
        	Case objUpdatedCase = caseToProcess[0];
        	system.assertEquals(objUpdatedCase.ContactId,objUpdatedCase.I_RM_Affiliation__r.I_RM_Contact__c,'Case contact and affiliation contact is match');
        test.stopTest();
        
    }
        
        
        
        
        //Testing Case Affiliation update.
    @isTest
    public static void testCreateLeadAffiliationOfflineChat(){ 
         String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);
         Contact domesticContact = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE email = 'test_unique0011@unique.com' LIMIT 1];
        Case newCase3 = new Case(Subject = 'Title',
                                 Type='Entry Requirements',
                                 Origin = 'Offline Chat',
                                 SuppliedEmail = 'test_unique0011@unique.com.invalid',      
                                 RecordTypeId = CaseRecordTypeIds,
                                 ContactId = domesticContact.id);
        insert newCase3;
        test.startTest(); 
          
            List<Case> caseToProcess = [SELECT Id,Subject,I_RM_Affiliation__c,I_RM_Affiliation__r.I_RM_Contact__c,I_ST_Campus_Interest__c,RecordTypeId,I_ST_Study_Interest__c,I_ST_Study_Level__c,I_ST_Timeframe_To_Study__c,ContactId,I_ST_Incremental_Score__c FROM case WHERE ContactId =: domesticContact.Id AND RecordTypeId =: caseRecordTypeIds AND Origin = 'Offline Chat' ];             
        	Case objUpdatedCase = caseToProcess[0];
        	system.assertEquals(objUpdatedCase.ContactId,objUpdatedCase.I_RM_Affiliation__r.I_RM_Contact__c,'Case contact and affiliation contact is match');
        test.stopTest();
        
    }
       
    @isTest
    public static void checkForMatchingActivityCaseValue(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeenquiry@ibm.com',AccountId=a.Id);
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Email__c='caseoftypeenquiry@ibm.com',
                                I_RM_Status__c='Active',
                                I_RM_Mobile_Phone__c='+61412345678',I_RM_Other_Phone__c='+61412345678');
            insert aff;
                                                       
   //insert case of type enquiry with available Email and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseOfTypeActivity',
                        Origin='Email',SuppliedEmail='caseoftypeenquiry@ibm.com',
                        SuppliedName='Enquiry Case',
                        SuppliedPhone='+61412345678',
                       I_ST_School_or_Educational_body__c='fromcaseaccounttestclass1');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail from Case where ID =: c.ID];
        system.assertEquals(cs.ContactID,con.ID);        
    test.stopTest();
    }  
    @isTest
    public static void checkForUnmatchedCaseValue(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;       
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeenquiry@ibm.com',AccountId=a.Id);
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Email__c='caseoftypeenquiry@ibm.com',
                                I_RM_Status__c='Active',
                                I_RM_Mobile_Phone__c='0441234563',I_RM_Other_Phone__c='0452648936');
            insert aff;                                                       
   //insert case of type Activity with unmatched Email and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseOfTypeUnmatched',
                        Origin='Email',SuppliedEmail='unmatched@ibm.com',
                        SuppliedName='Unmatched Case',
                        SuppliedPhone='0441234563',
                        I_ST_Proposed_Activity_Start_Datetime__c='2022-07-01 19:30:00',
                        I_ST_Proposed_Activity_End_Datetime__c = '2022-08-01 19:30:00',
                       I_ST_School_or_Educational_body__c='Unmatched Account');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail from Case where ID =: c.ID];
        Contact ct=[Select ID from Contact where ID =: cs.ContactID];
        system.assertEquals(cs.ContactID,ct.ID);        
    test.stopTest();  

    }
   
    @isTest
    public static void createContactAndAffiliation(){
        test.startTest();
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Enquiry').getrecordTypeId(),
                        subject='CaseCreateContact', 
                        SuppliedPhone='0441234563',
                        I_ST_Contact_First_Name__c  ='test1',
                        I_ST_Contact_Last_Name__c  ='last1'
                      );
		insert c;
        test.stopTest();        
    }
    @isTest
    public static void checkForNameandPhCaseValue(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeenquiry@ibm.com',AccountId=a.Id,MobilePhone='6374829760',Phone='6374829771',OtherPhone='6374829782');
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Email__c='caseoftypeenquiry@ibm.com',
                                I_RM_Status__c='Active',
                                I_RM_Mobile_Phone__c='0441234563',I_RM_Other_Phone__c='0845264893');
            insert aff;                 
   //insert case of type Activity with SuppliedName and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseOfTypeUnmatched',
                        Origin='Email',
                        SuppliedName='Matched Phone',
                        SuppliedPhone='0441234563',
                        ContactId = con.Id,
                       I_ST_School_or_Educational_body__c='Unmatched Account');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail,I_RM_Affiliation__c from Case where ID =: c.ID];
        Contact ct=[Select ID,Name from contact where ID =: cs.ContactID];
        I_RM_Affiliation__c caseAff = [Select ID,I_RM_Contact__c from I_RM_Affiliation__c where ID =: cs.I_RM_Affiliation__c];
        
        system.assertEquals(cs.ContactID,ct.ID);       
        system.assertEquals(cs.ContactID,caseAff.I_RM_Contact__c);       
    test.stopTest();
    }
    @isTest
    public static void checkForStudentEmailMatchingAffiliation(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeactivity@ibm.com',AccountId=a.Id,MobilePhone='6374829760',Phone='6374829771',OtherPhone='6374829782');
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Student_Email__c='caseoftypeactivity@ibm.com',
                                I_RM_Status__c='Active',
                                I_RM_Mobile_Phone__c='0441234563',I_RM_Other_Phone__c='0845264893');
            insert aff;                 
   //insert case of type Activity with SuppliedName and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseOfTypeUnmatched',
                        Origin='Email',
                        SuppliedEmail='caseoftypeactivity@ibm.com',
                        SuppliedName='Matched Phone',
                        SuppliedPhone='0441234563',
                       I_ST_School_or_Educational_body__c='Unmatched Account');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail,I_RM_Affiliation__c from Case where ID =: c.ID];
        Contact ct=[Select ID,Name from contact where ID =: cs.ContactID];
        I_RM_Affiliation__c caseAff = [Select ID,I_RM_Contact__c from I_RM_Affiliation__c where ID =: cs.I_RM_Affiliation__c];
        
        system.assertEquals(cs.ContactID,ct.ID);       
        system.assertEquals(cs.ContactID,caseAff.I_RM_Contact__c);       
    test.stopTest();
    }    
 @isTest
    public static void checkForAvailableSchoolRepOnCase(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeactivity@ibm.com',AccountId=a.Id,MobilePhone='6374829760',Phone='6374829771',OtherPhone='6374829782');
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Work_Email__c='caseoftypeactivity@ibm.com',
                                I_RM_Status__c='Active',
                                I_RM_Mobile_Phone__c='0441234563',I_RM_Other_Phone__c='0845264893');
            insert aff;                 
   //insert case of type Activity with SuppliedName and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseForSchoolRep',
                        ContactId=con.ID,
                        Origin='Email',
                        SuppliedEmail='caseoftypeactivity@ibm.com',
                        SuppliedName='Matched Phone',
                        SuppliedPhone='0441234563',
                       I_ST_School_or_Educational_body__c='fromcaseaccounttestclass1');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail,I_RM_Affiliation__c from Case where ID =: c.ID];
        Contact ct=[Select ID,Name from contact where ID =: cs.ContactID];
        I_RM_Affiliation__c caseAff = [Select ID,I_RM_Contact__c from I_RM_Affiliation__c where ID =: cs.I_RM_Affiliation__c];
        
        system.assertEquals(cs.ContactID,ct.ID);       
        system.assertEquals(cs.I_RM_Affiliation__c,caseAff.ID);       
    test.stopTest();
    }
@isTest
    public static void checkForNoAvailableSchoolRepOnCase(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeactivity@ibm.com',AccountId=a.Id,MobilePhone='6374829760',Phone='6374829771',OtherPhone='6374829782');
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Work_Email__c='caseoftypeactivity@ibm.com',
                                I_RM_Status__c='Inactive',
                                I_RM_Mobile_Phone__c='0441234563',I_RM_Other_Phone__c='0845264893');
            insert aff;                 
   //insert case of type Activity with SuppliedName and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseForSchoolRep',
                        ContactId=con.ID,
                        Origin='Email',
                        SuppliedEmail='caseoftypeactivity@ibm.com',
                        SuppliedName='Matched Phone',
                        SuppliedPhone='0441234563',
                       I_ST_School_or_Educational_body__c='fromcaseaccounttestclass1');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail,I_RM_Affiliation__c from Case where ID =: c.ID];
        Contact ct=[Select ID,Name from contact where ID =: cs.ContactID];
        I_RM_Affiliation__c caseAff = [Select ID,I_RM_Contact__c from I_RM_Affiliation__c where ID =: cs.I_RM_Affiliation__c];
        
        system.assertEquals(cs.ContactID,ct.ID);       
        system.assertEquals(cs.ContactID,caseAff.I_RM_Contact__c);       
    test.stopTest();
    } 
    @isTest
    public static void checkForNoNameOnCase(){
      test.startTest();
        Account a=new Account(Name='fromcaseaccounttestclass1');
        insert a;
        Contact con=new Contact(FirstName='Activity',LastName='Case',I_ST_Personal_Email__c='caseoftypeactivity@ibm.com',AccountId=a.Id,MobilePhone='6374829760',Phone='6374829771',OtherPhone='6374829782');
        	insert con;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Account__c=a.Id,I_RM_Phone__c='+61412345678',
                                I_RM_Role__c='School Representative',I_RM_Work_Email__c='caseoftypeactivity@ibm.com',
                                I_RM_Status__c='Inactive',
                                I_RM_Mobile_Phone__c='0441234563',I_RM_Other_Phone__c='0845264893');
            insert aff;                 
   //insert case of type Activity with SuppliedName and Phone
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseWithNoName',
                        Origin='Email',
                        SuppliedEmail='caseoftypeactivity1@ibm.com',
                        SuppliedPhone='0441234563',
                       I_ST_School_or_Educational_body__c='fromcaseaccounttestclass1');
		insert c;
        Case cs=[Select ID,ContactID,SuppliedEmail,I_RM_Affiliation__c from Case where ID =: c.ID];
        
        system.assertEquals(cs.ContactID,NULL);      
    test.stopTest();
            }
    @isTest
    public static void errorlogs(){
        test.startTest();
        case c=new case(RecordTypeID=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId(),
                        subject='CaseOfErrorlogs',
                        Origin='Phone',                        
                        SuppliedEmail = 'doesnot@exist.com.invalid',
                        I_ST_Proposed_Activity_Start_Datetime__c='2022-07-01 19:30:00',
                        I_ST_Proposed_Activity_End_Datetime__c = '2022-08-01 19:30:00'
                       );
		insert c;
        test.stopTest();
    }
    @isTest
    public static void createInternationalContact_Test(){
        Test.startTest();

        Case caseRecNew = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORD_TYPE_NAME_INT_ENQUIRY).getRecordTypeId(),
            subject = 'CaseCreateContactAndAffiliation', 
            SuppliedPhone = '+61433776665',
            SuppliedEmail = 'test@test.com.invalid',
            Origin =  'Phone',
            I_ST_Contact_First_Name__c  = 'testIntLead1',
            I_ST_Contact_Last_Name__c  = 'last1'
        );
		insert caseRecNew;

        caseRecNew = [ SELECT contactId, I_RM_Affiliation__c 
                    FROM Case 
                    WHERE Id = :caseRecNew.Id];

        system.assertEquals(
            1,
            [SELECT Id 
             FROM Contact 
             WHERE Id = :caseRecNew.contactId].size(),
            'Expect new contact to be created and linked to case for International Enquiry'
        );
        system.assertEquals(
            1,
            [SELECT Id 
             FROM I_RM_Affiliation__c 
             WHERE Id = :caseRecNew.I_RM_Affiliation__c].size(),
            'Expect new affiliation to be created and linked to case for International Enquiry'
        );

        Case caseRecUpdate = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORD_TYPE_NAME_INT_ENQUIRY).getRecordTypeId(),
            subject = 'UpdateContactAndAffiliation', 
            SuppliedPhone = '+61433776665',            
            SuppliedEmail = 'test@test.com.invalid',
            Origin =  'Phone',
            I_ST_Contact_First_Name__c  = 'testIntLead1',
            I_ST_Contact_Last_Name__c  = 'last1'
        );
		insert caseRecUpdate;
        caseRecUpdate = [ SELECT contactId, I_RM_Affiliation__c 
                          FROM Case 
                          WHERE Id = :caseRecUpdate.Id];
        system.assertEquals(
            [SELECT Id 
             FROM Contact 
             WHERE Id = :caseRecNew.contactId].Id,
             caseRecUpdate.contactId,
            'Expect the previously created contact to be updated and linked to current case'
        );
        system.assertEquals(
            [SELECT Id 
             FROM I_RM_Affiliation__c 
             WHERE Id = :caseRecNew.I_RM_Affiliation__c].Id,
             caseRecUpdate.I_RM_Affiliation__c,
            'Expect the previously created affiliation to be updated and linked to current case'
        );
        Test.stopTest();        
    }
}