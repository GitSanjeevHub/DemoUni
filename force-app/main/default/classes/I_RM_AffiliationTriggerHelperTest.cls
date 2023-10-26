/**
─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_RM_AffiliationTriggerHelperTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author Teja Yenduri
* @date 2022-02-18
* 
* * @description : markCalculateAffiliationScoreToTrue method is used to set I_RM_Calculate_Affiliation_Score__c to true
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class I_RM_AffiliationTriggerHelperTest {
    public static Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
    public static Id affiliationIntLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
    public static Id affiliationApplicantRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId(); 
    public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    public static Id affiliationStudentRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Student').getRecordTypeId();
    public static Id affiliationECRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getRecordTypeId();  
    public static Id affiliationHDRStudentRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_HDR_Student').getRecordTypeId();
    
    
    @TestSetup
    static void setup() {

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        string affiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
        string caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);
        string applicantaffiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_APPLICANT);
        
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypIds,20,caseRecordTypeIds,20,null,null);           
        insert listBatchScoringSetting; 
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Enquiry').getRecordTypeId();        
        Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        Id affiliationApplicantRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        
        List<I_RM_Affiliation__c> listLeadAffiliations = new List<I_RM_Affiliation__c>();
        List<I_RM_Affiliation__c> listAppAffiliations  = new List<I_RM_Affiliation__c>();
        List<Contact>listDomesticLeadContacts = new List<Contact>();
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
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
        
        List<I_RM_Affiliation__c> lstApplicantAffiliations = new List<I_RM_Affiliation__c>();
        for(Integer j=0; j<listDomesticLeadContacts.size(); j++) {
            listAppAffiliations = I_ST_UnitTestUtilities.createApplicantAffiliationRecords(affiliationApplicantRecordTypeId,listDomesticLeadContacts[j].Id);
            lstApplicantAffiliations.addAll(listAppAffiliations);
        }
        
      //  insert lstApplicantAffiliations;
        
        
    } 
    
    //Teja Yenduri IBM, Bluewolf 18/02/2022/////////
    @isTest
    public static void testmarkCalculateAffiliationScoreToTrue(){
        
        List<I_RM_Affiliation__c> domesticLeadAffiliation = [SELECT Id, Name,I_RM_Calculate_Affiliation_Score__c FROM I_RM_Affiliation__c];        
        
        try{
            I_RM_Affiliation__c updateAffiliation = new I_RM_Affiliation__c();
            updateAffiliation.id= domesticLeadAffiliation[0].Id;
            updateAffiliation.I_RM_Enquirer_Type__c = 'Year 11';            
            test.startTest();
            update updateAffiliation;
            test.StopTest();
        }
        catch (Exception e) {
            System.debug('>>> ERROR ='+e);
        }   
        system.assertEquals(true, domesticLeadAffiliation[0].I_RM_Calculate_Affiliation_Score__c);
    }
    
    
    //Teja Yenduri IBM, Bluewolf 02/03/2022//
    @isTest
    public static void testActiveLeadAffiliation(){
        
        test.startTest();
        //List<I_RM_Affiliation__c> beforeUpadateAff = [SELECT Id, Name,I_RM_Status__c,I_RM_Contact__c FROM I_RM_Affiliation__c where I_RM_Status__c  ='Not Processed' AND  I_RM_Role__c ='Applicant' AND I_RM_EndDate__c = null ];
        Contact cont1 = new Contact(FirstName='TestFirst2',LastName='TestLast2',I_ST_Personal_Email__c='test2@email.com');
        Insert cont1;        
        
        
        I_RM_Affiliation__c aff1 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= cont1.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='caseoftypeenquiry@ibm.com.invalid',
                                                          I_RM_Status__c='Not Qualified',
                                                          I_RM_Mobile_Phone__c='0415822666');
        
        insert aff1;
        
        I_RM_Affiliation__c aff2 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= cont1.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='caseoftypeenquiry1@ibm.com.invalid',
                                                          I_RM_Status__c='Not Qualified',
                                                          I_RM_Mobile_Phone__c='0415822667');
        
        insert aff2;
        
        I_RM_Affiliation__c aff3 = new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getrecordTypeId(),
                                                           I_RM_Contact__c = cont1.Id,
                                                           I_RM_Role__c = 'Applicant',
                                                           I_RM_Status__c = 'Inactive');
        
        insert aff3;  
        test.StopTest();
        
        
        List<I_RM_Affiliation__c> affToBeUpdated = [SELECT Id, Name,I_RM_Status__c,I_RM_Contact__c FROM I_RM_Affiliation__c where I_RM_Role__c ='Domestic Lead' AND I_RM_Contact__c =: cont1.Id];
        system.assertEquals('Qualified', affToBeUpdated[0].I_RM_Status__c);
        
    }        
    
    
    //Teja Yenduri IBM, Bluewolf 02/03/2022//
    @isTest
    public static void testInactiveLeadAffiliation(){
    
        Contact cont = new Contact(FirstName='TestFirst2',LastName='TestLast2',I_ST_Personal_Email__c='test2@email.com');
        Insert cont;
        
        
        I_RM_Affiliation__c aff1 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= cont.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='caseoftypeenquiry@ibm.com.invalid',
                                                          I_RM_Status__c='Inactive',
                                                          I_RM_Mobile_Phone__c='0415822666');
        
        insert aff1;
        
        I_RM_Affiliation__c aff2 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= cont.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='caseoftypeenquiry1@ibm.com.invalid',
                                                          I_RM_Status__c='Inactive',
                                                          I_RM_Mobile_Phone__c='0415822667');
        
        insert aff2;
        
        I_RM_Affiliation__c aff3 = new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getrecordTypeId(),
                                                           I_RM_Contact__c = cont.Id,
                                                           I_RM_Role__c = 'Applicant',
                                                           I_RM_Status__c = 'Not Processed');
        
        insert aff3;       
        
      
        try{
            
            test.startTest();
            aff3.I_RM_Status__c = 'Inactive';
            update aff3;
            test.StopTest();
        }
        catch (Exception e) {
            System.debug('>>> ERROR ='+e);
        }  
        List<I_RM_Affiliation__c> affToBeUpdated = [SELECT Id, Name,I_RM_Status__c,I_RM_Contact__c FROM I_RM_Affiliation__c where I_RM_Role__c ='Domestic Lead' AND I_RM_Contact__c =: cont.Id ORDER BY createdDate DESC ];        
        system.assertEquals('Qualified', affToBeUpdated[0].I_RM_Status__c);
    }  
    @isTest
    public static void checkActiveDomAffiliationUpdate(){
        Test.startTest();
        Contact con = [SELECT Id FROM Contact WHERE I_ST_Personal_Email__c='test_unique0012@unique.com'];
        I_RM_Affiliation__c af=new I_RM_Affiliation__c(RecordTypeID = affiliationDomesticLeadRecordTypeId,
                                                       I_RM_Contact__c=con.Id,
                                                       I_RM_Role__c='Domestic Lead',
                                                       I_RM_Status__c='Qualified',I_RM_Mobile_Phone__c='0415822666');
        insert af;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=affiliationApplicantRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Applicant',
                                                        I_RM_Status__c='Make An Offer',I_RM_Mobile_Phone__c='0415822667');
        insert aff;
         List<I_RM_Affiliation__c> beforeUpadateAff = [select ID,I_RM_EndDate__c,I_RM_Email__c from I_RM_Affiliation__c where ID =: aff.ID];
        List<I_RM_Affiliation__c> UpdateAff=new List<I_RM_Affiliation__c>();
        for(I_RM_Affiliation__c old:beforeUpadateAff){
            old.I_RM_Email__c = 'newemail@ibm.com';
            UpdateAff.add(old);
        }
         Contact c = [select ID,I_ST_Student_Email__c from contact where ID =: con.ID];
         I_RM_Affiliation__c postUpdate = [select ID,I_RM_Email__c from I_RM_Affiliation__c where ID IN: beforeUpadateAff];
         system.assertEquals(c.I_ST_Student_Email__c,postUpdate.I_RM_Email__c,'Email on Contact and Affiliation are synced');
        Test.stopTest();
    }    
    
    //create lead affliation record if applicant affliation record is inactive test.
    @isTest
    public static void createLeadAffliationsNegativeTest(){       
    
        Contact cont22 = new Contact(FirstName='TestFirst1',LastName='TestLast1',I_ST_Personal_Email__c='test1@email.com');
        insert cont22;
        
        I_RM_Affiliation__c affl = new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getrecordTypeId(),
                                                           I_RM_Contact__c = cont22.Id,
                                                           I_RM_Role__c = 'Applicant',                                               
                                                           I_RM_Status__c = 'Not Processed');    
        insert affl;
        test.startTest();
        affl.I_RM_Status__c = 'Inactive';
        update affl;
        List<I_RM_Affiliation__c> leadAffls = new List<I_RM_Affiliation__c>();
        leadAffls = [Select Id,I_RM_Contact__c, I_RM_Role__c from  I_RM_Affiliation__c where I_RM_Role__c = 'Domestic Lead' AND I_RM_Contact__c =: cont22.id];
        test.stopTest();
        
        System.assertEquals(0, leadAffls.size());
    }

        //create lead affliation record if applicant affliation record is inactive test.
        @isTest
        public static void createLeadAffliationsPositiveTest(){       
        
            Contact cont22 = new Contact(FirstName='TestFirst1',LastName='TestLast1',I_ST_Personal_Email__c='test1@email.com');
            insert cont22;
            
            I_RM_Affiliation__c affl = new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getrecordTypeId(),
                                                               I_RM_Contact__c = cont22.Id,
                                                               I_RM_Role__c = 'Applicant',
                                                               I_RM_Email__c = 'test12@email.com', 
                                                               I_RM_Mobile_Phone__c='0415822666',                                                
                                                               I_RM_Status__c = 'Not Processed');    
            insert affl;
            test.startTest();
            affl.I_RM_Status__c = 'Inactive';
            update affl;
            List<I_RM_Affiliation__c> leadAffls = new List<I_RM_Affiliation__c>();
            leadAffls = [Select Id,I_RM_Contact__c, I_RM_Role__c from  I_RM_Affiliation__c where I_RM_Role__c = 'Domestic Lead' AND I_RM_Contact__c =: cont22.id];
            test.stopTest();
            
            System.assertEquals('Domestic Lead', leadAffls[0].I_RM_Role__c);
        }
    
    //Teja Yenduri IBM, Bluewolf 07/03/2022//
    @isTest
    public static void testInactiveStudentAffiliation(){ 
        test.startTest();
        Contact newDomesticLead = new Contact(FirstName = 'Test1', 
                                              LastName = 'last1',
                                              Email = 'abc@ibm.com.invalid', 
                                              I_ST_Personal_Email__c = 'abc@ibm.com.invalid',                                              
                                              OtherPostalCode = '3029',
                                              I_RS_Deceased__c = FALSE);
        
        
        insert newDomesticLead; 
        
        
        
        I_RM_Affiliation__c aff1 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= newDomesticLead.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='abc@ibm.com.invalid',                                                         
                                                          I_RM_Status__c='Inactive',
                                                          I_RM_Mobile_Phone__c='0415822666');
        
        insert aff1;        
        
        I_RM_Affiliation__c aff2 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= newDomesticLead.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='abc1@ibm.com.invalid',                                                            
                                                          I_RM_Status__c='Not Qualified',
                                                          I_RM_Mobile_Phone__c='0415822667');
        
        insert aff2;
        
        I_RM_Affiliation__c aff3 =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= newDomesticLead.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='abc2@ibm.com.invalid',                                                            
                                                          I_RM_Status__c='Not Qualified',
                                                          I_RM_Mobile_Phone__c='0415822668');
        
        insert aff3;
        
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID = affiliationStudentRecordTypeId,
                                                        I_RM_Contact__c=newDomesticLead.Id,
                                                        I_RM_Role__c='Student',I_RM_Email__c='caseoftypeenquiry@ibm.com',
                                                        I_RM_Status__c='Inactive',
                                                        I_RM_Mobile_Phone__c='0415822669');
        
        insert aff;        
        
        
        test.StopTest();
        List<I_RM_Affiliation__c> affToBeUpdated = [SELECT Id, Name,I_RM_Status__c,I_RM_Contact__c FROM I_RM_Affiliation__c where I_RM_Role__c ='Domestic Lead' AND I_RM_Contact__c =: newDomesticLead.Id];       
        system.assertEquals('Qualified', affToBeUpdated[2].I_RM_Status__c);
    }  
    
    @isTest 
    public static void updateContactEmailfieldsApplicantTest(){
        Test.startTest();
        Contact cont22 = new Contact(FirstName='TestFirst1',LastName='TestLast1',I_ST_Personal_Email__c='test1@email.com');
        insert cont22;
        I_RM_Affiliation__c aff=new I_RM_Affiliation__c(RecordTypeID=affiliationApplicantRecordTypeId,
                                                        I_RM_Contact__c=cont22.Id,
                                                        I_RM_Role__c='Applicant',
                                                        I_RM_Status__c='Make An Offer',
                                                        I_RM_Mobile_Phone__c='0415822666');
        insert aff;
        aff.I_RM_Email__c = 'teste1@gmail1.com';
        update aff;
        Contact cont = New Contact();
        cont = [Select Id, I_RM_Applicant_Email__c from Contact Where Id = :  aff.I_RM_Contact__c];
        system.assertEquals('teste1@gmail1.com', cont.I_RM_Applicant_Email__c );
        Test.stopTest();
    } 

    @isTest 
    public static void updateContactEmailfieldsDomesticLeadTest(){
        Test.startTest();
        /*List<I_RM_Affiliation__c> domesticLeadAffiliation = [SELECT Id, Name,I_RM_Work_Email__c,I_RM_Student_Email__c, I_RM_Email__c, 
        I_RM_Contact__c, I_RM_Contact__r.I_RM_Applicant_Email__c FROM I_RM_Affiliation__c WHERE I_RM_Role__c ='Domestic Lead'];
        domesticLeadAffiliation[0].I_RM_Email__c = 'teste1@gmail1.com';*/
        Contact newDomesticLead = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test12@test.com.invalid');       
       	insert newDomesticLead;  
        I_RM_Affiliation__c domesticLeadAffiliation =new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                          I_RM_Contact__c= newDomesticLead.Id,
                                                          I_RM_Role__c='Domestic Lead',I_RM_Email__c='abc2@ibm.com.invalid',                                                            
                                                          I_RM_Status__c='Not Qualified',
                                                          I_RM_Mobile_Phone__c='0415822668');
        
        insert domesticLeadAffiliation;
        domesticLeadAffiliation.I_RM_Email__c = 'teste1@gmail1.com';
        update domesticLeadAffiliation;
        List<Contact> cont = New List<Contact>();
        cont = [Select Id, I_ST_Personal_Email__c from Contact Where Id = :  domesticLeadAffiliation.I_RM_Contact__c];
        system.assertEquals('teste1@gmail1.com', cont[0].I_ST_Personal_Email__c );
        Test.stopTest();
    }

    @isTest 
    public static void updateContactEmailfieldsLaTrobeStaffTest(){
        Test.startTest();
        List<Contact> contactList  = [SELECT Id,FirstName, Name FROM Contact];
    	I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = contactList[0].Id,
                                                                     recordTypeId = affiliationStaffRecordTypeId,
                                                                  I_RM_Enquirer_Type__c ='Year 11',
                                                                  I_RM_Time_Frame_to_Study__c= '3-6 months',
                                                                  I_RM_Incremental_Score__c = 0,
                                                                  I_RM_Mobile_Phone__c = '0415822665',
                                                                  I_RM_Role__c ='La Trobe Staff', 
                                                                  I_RM_Score__c = 0,
                                                                  I_RM_Work_Email__c =  'teste2@gmail1.com'
                                                                 );

        Insert newAffiliation;
        newAffiliation.I_RM_Work_Email__c = 'teste1@gmail1.com';
        update newAffiliation;
        Contact cont = New Contact();
        cont = [Select Id, Email from Contact Where Id = :  newAffiliation.I_RM_Contact__c];
        system.assertEquals('teste1@gmail1.com', cont.Email );
        Test.stopTest();
    }

    @isTest 
    public static void updateContactEmailfieldsStudentTest(){
        Test.startTest();
        List<Contact> contactList  = [SELECT Id,FirstName, Name FROM Contact];
    	I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = contactList[0].Id,
                                                                     recordTypeId = affiliationStudentRecordTypeId,                                                                  
                                                                     I_RM_Mobile_Phone__c = '0415822665',
                                                                     I_RM_Role__c ='Student',                                                                 
                                                                     I_RM_Student_Email__c =  'teste2@gmail1.com'
                                                                 );

        Insert newAffiliation;
        newAffiliation.I_RM_Student_Email__c = 'teste1@gmail1.com';
        update newAffiliation;
        Contact cont = New Contact();
        cont = [Select Id, I_ST_Student_Email__c from Contact Where Id = :  newAffiliation.I_RM_Contact__c];
        system.assertEquals('teste1@gmail1.com', cont.I_ST_Student_Email__c );
        Test.stopTest();
    }
    
    @isTest 
    public static void updateContactEmailfieldsStudentInsertTest(){
        Test.startTest();
        List<Contact> contactList  = [SELECT Id,FirstName, Name FROM Contact];
    	I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = contactList[0].Id,
                                                                     recordTypeId = affiliationStudentRecordTypeId,                                                                  
                                                                     I_RM_Mobile_Phone__c = '0415822665',
                                                                     I_RM_Role__c ='Student',                                                                  
                                                                     I_RM_Student_Email__c =  'teste2@gmail1.com'
                                                                 );

        Insert newAffiliation;
        Contact cont = New Contact();
        cont = [Select Id, I_ST_Student_Email__c from Contact Where Id = :  newAffiliation.I_RM_Contact__c];
        system.assertEquals('teste2@gmail1.com', cont.I_ST_Student_Email__c );
        Test.stopTest();
    }        
      

    /* @author Vanita Walia
     * @date  08/03/2022
     * @description - LTU360-1248 : test method for testing creation of new domestic lead when an inactive student affiliation is created
     */
    
    @IsTest
	private static void testcreateLeadAff_InactiveStudent_Insert() {
        Test.startTest();
        
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test12@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            //Create Inactive student affiliation record which should create a qualified lead affiliation record
            I_RM_Affiliation__c stuAff1=new I_RM_Affiliation__c(RecordTypeID = affiliationStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Student',I_RM_Email__c='testemail@test.com.invalid',
                                                        I_RM_Status__c='Inactive',
                                                        I_RM_Mobile_Phone__c='0412345678');
            I_RM_Affiliation__c stuAff2=new I_RM_Affiliation__c(RecordTypeID = affiliationStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Student',I_RM_Email__c='testemail@test.com.invalid',
                                                        I_RM_Status__c='Inactive',
                                                        I_RM_Mobile_Phone__c='0412345679');
            
            List<I_RM_Affiliation__c> stuAff = new List<I_RM_Affiliation__c>{stuAff1,stuAff2};
            insert stuAff;            
        }
        List<I_RM_Affiliation__c> leadAff = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where I_RM_Role__c = 'Domestic Lead' 
                                      		and I_RM_Contact__c=:con.Id ];
       // match the status of new created domestic lead affiliation record to Qualified
        system.assertEquals('Qualified', leadAff[0].I_RM_Status__c);
        Test.stopTest();
    }

    /* @author Vanita Walia
     * @date  28/03/2022
     * @description - LTU360-1248 : test method for test negative scenario when email and mobile is blank
     */
    @IsTest
	private static void testcreateLeadAff_InactiveStudent_NegativeTest() {
        Test.startTest();
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test123@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            //Create student affiliation record
            I_RM_Affiliation__c stuAff=new I_RM_Affiliation__c(RecordTypeID = affiliationStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Student',
                                                        I_RM_Status__c='Inactive');
            insert stuAff;        
        }
        List<I_RM_Affiliation__c> leadAff = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where I_RM_Role__c = 'Domestic Lead' 
                                      		and I_RM_Contact__c=:con.Id ];        
       
        System.assertEquals(0, leadAff.size());
        Test.stopTest();
    }
    
    
     /* @author Vanita Walia
     * @date  08/03/2022
     * @description - LTU360-1248 : test method for testing creation of new domestic lead when a student affiliation is updated to Inactive status
     */
    @IsTest
	private static void testcreateLeadAff_InactiveStudent_Update() {
        Test.startTest();
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test123@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            //Create student affiliation record
            I_RM_Affiliation__c stuAff=new I_RM_Affiliation__c(RecordTypeID = affiliationStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Student',I_RM_Email__c='testemail2@test.com.invalid',
                                                        I_RM_Status__c='Nearing Completion',
                                                        I_RM_Mobile_Phone__c='0412345678');
            insert stuAff;            
        
        	//update the status of affiliation to inactive, it should create a qualified domestic lead affiliation record
        	stuAff.I_RM_Status__c ='Inactive';
        	update stuAff;
        }
        List<I_RM_Affiliation__c> leadAff = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where I_RM_Role__c = 'Domestic Lead' 
                                      		and I_RM_Contact__c=:con.Id ];        
       
        system.assertEquals('Qualified', leadAff[0].I_RM_Status__c);
        Test.stopTest();
    }
    /* @author Rahul Kumar
     * @date  23/03/2022
     * @description - LTU360-1251 : test method for testing Update Active Applicant record when Student becomes Admitted And Enrolled
     */
    @isTest
    public static void updateActiveApplicant(){
        Test.startTest();
        Contact con = [SELECT Id FROM Contact WHERE I_ST_Personal_Email__c='test_unique0012@unique.com'];
        I_RM_Affiliation__c applicant=new I_RM_Affiliation__c(RecordTypeID = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getrecordTypeId(),
                                                       I_RM_Contact__c=con.Id,
                                                       I_RM_Role__c='Applicant',
                                                       I_RM_Status__c='Make An Offer',I_RM_Email__c='applicant@invalid.com');
        insert applicant;
        I_RM_Affiliation__c student=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Student').getRecordTypeId(),
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Student',
                                                        I_RM_Status__c='Admitted And Enrolled',I_RM_Email__c='student@invalid.com');
        insert student;
        I_RM_Affiliation__c postUpdate = [select ID,I_RM_Status__c from I_RM_Affiliation__c where I_RM_Contact__c =: con.ID and I_RM_Email__c='applicant@invalid.com'];
        //system.assertEquals('Inactive',postUpdate.I_RM_Status__c, 'Applicant status changes to inactive');
        Test.stopTest();
    }

    @IsTest
	private static void updateContactExternalEmalInsertTest() {
        Test.startTest();
        
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test777@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            I_RM_Affiliation__c ecff1=new I_RM_Affiliation__c(RecordTypeID = affiliationECRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='External Contact',I_RM_Email__c='testemail77@test.com.invalid',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Work_Email__c = 'k1@g.com',
                                                        I_RM_Mobile_Phone__c='0412345678');
            I_RM_Affiliation__c ecff2=new I_RM_Affiliation__c(RecordTypeID = affiliationECRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='External Contact',I_RM_Email__c='testemail88@test.com.invalid',
                                                        I_RM_Status__c='Inactive',
                                                        I_RM_Mobile_Phone__c='0412345679');
            
            List<I_RM_Affiliation__c> ecAff = new List<I_RM_Affiliation__c>{ecff1,ecff2};
            insert ecAff;            
        }
        List<Contact> contactList = [Select Id, I_RM_Examiner_Email__c from Contact where Id =: con.Id ];
       // match the status of new created domestic lead affiliation record to Qualified
        system.assertEquals('k1@g.com', contactList[0].I_RM_Examiner_Email__c);
        Test.stopTest();
    }

    @IsTest
	private static void updateContactExternalEmalUpdateTest() {
        Test.startTest();
        
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test778@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            I_RM_Affiliation__c ecff1=new I_RM_Affiliation__c(RecordTypeID = affiliationECRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='External Contact',I_RM_Email__c='testemail778@test.com.invalid',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Work_Email__c = 'k1@g.com',
                                                        I_RM_Mobile_Phone__c='0412345678');
            I_RM_Affiliation__c ecff2=new I_RM_Affiliation__c(RecordTypeID = affiliationECRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='External Contact',I_RM_Email__c='testemail779@test.com.invalid',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Work_Email__c = 'k2@g.com',
                                                        I_RM_Mobile_Phone__c='0412345679');
            
            List<I_RM_Affiliation__c> ecAff = new List<I_RM_Affiliation__c>{ecff1,ecff2};
            insert ecAff;
            ecff1.I_RM_Work_Email__c = 'k3@g.com';
            update ecff1;
        }
        List<Contact> contactList = [Select Id, I_RM_Examiner_Email__c from Contact where Id =: con.Id ];
       // match the status of new created domestic lead affiliation record to Qualified
        system.assertEquals('k3@g.com;k2@g.com', contactList[0].I_RM_Examiner_Email__c);
        Test.stopTest();
    }

    @IsTest
	private static void updateContactExternalEmalDeleteTest() {
        Test.startTest();
        
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test778@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            I_RM_Affiliation__c ecff1=new I_RM_Affiliation__c(RecordTypeID = affiliationECRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='External Contact',I_RM_Email__c='testemail778@test.com.invalid',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Work_Email__c = 'k1@g.com',
                                                        I_RM_Mobile_Phone__c='0412345678');
            I_RM_Affiliation__c ecff2=new I_RM_Affiliation__c(RecordTypeID = affiliationECRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='External Contact',I_RM_Email__c='testemail778@test.com.invalid',
                                                        I_RM_Status__c='Active',
                                                        I_RM_Work_Email__c = 'k2@g.com',
                                                        I_RM_Mobile_Phone__c='0412345679');
            
            List<I_RM_Affiliation__c> ecAff = new List<I_RM_Affiliation__c>{ecff1,ecff2};
            insert ecAff;

            delete ecff1;
        }
        List<Contact> contactList = [Select Id, I_RM_Examiner_Email__c from Contact where Id =: con.Id ];
       // match the status of new created domestic lead affiliation record to Qualified
        system.assertEquals('k2@g.com', contactList[0].I_RM_Examiner_Email__c);
        Test.stopTest();
    }
    
    /* @author Vanita Walia
     * @date  22/04/2022
     * @description - LTU360-1492 : test method for testing creation of new domestic lead when an inactive graduate researcher affiliation is created
     */
    
    @IsTest
	private static void testcreateLeadAff_InactiveHDRStudent_Insert() {
        Test.startTest();
        
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='testhdr@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            //Create Inactive student affiliation record which should create a qualified lead affiliation record
            I_RM_Affiliation__c hdrStuAff1=new I_RM_Affiliation__c(RecordTypeID = affiliationHDRStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='HDR Student',I_RM_Email__c='testHDRemail1@test.com.invalid',
                                                        I_RM_Status__c='Inactive',
                                                        I_RM_Mobile_Phone__c='0442345678');
            I_RM_Affiliation__c hdrStuAff2=new I_RM_Affiliation__c(RecordTypeID = affiliationHDRStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='HDR Student',I_RM_Email__c='testHDRemail2@test.com.invalid',
                                                        I_RM_Status__c='Inactive',
                                                        I_RM_Mobile_Phone__c='0412345679');
            
            List<I_RM_Affiliation__c> hdrStuAff = new List<I_RM_Affiliation__c>{hdrStuAff1,hdrStuAff2};
            insert hdrStuAff;            
        }
        List<I_RM_Affiliation__c> leadAff = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where I_RM_Role__c = 'Domestic Lead' 
                                      		and I_RM_Contact__c=:con.Id ];
       // match the status of new created domestic lead affiliation record to Qualified
        system.assertEquals('Qualified', leadAff[0].I_RM_Status__c);
        Test.stopTest();
    }
    @isTest
    public static void updateActiveLead(){
        Test.startTest();
        Contact con = [SELECT Id FROM Contact WHERE I_ST_Personal_Email__c='test_unique0012@unique.com'];
        I_RM_Affiliation__c lead=new I_RM_Affiliation__c(RecordTypeID = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId(),
                                                       I_RM_Contact__c=con.Id,
                                                       I_RM_Role__c='Domestic Lead',
                                                       I_RM_Status__c='Not Qualified',I_RM_Email__c='lead@invalid.com');
        insert lead;
        I_RM_Affiliation__c applicant=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId(),
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Applicant',I_RM_Email__c='applicant@invalid.com');
        insert applicant;
        I_RM_Affiliation__c updateApplicant=new I_RM_Affiliation__c(ID=applicant.ID,I_RM_Status__c='Admitted And Not Enrolled');
        update updateApplicant;
        
        I_RM_Affiliation__c postUpdate = [select ID,I_RM_Status__c from I_RM_Affiliation__c where I_RM_Contact__c =: con.ID and I_RM_Email__c='lead@invalid.com'];
        system.assertEquals('Inactive',postUpdate.I_RM_Status__c, 'Lead status changes to inactive');
        Test.stopTest();
    }
	
    /* @author Vanita Walia
     * @date  08/08/2022
     * @description - LTU360-2031 : test method for updating contact name on affiliation
     */
    @IsTest
	private static void testUpdateContactNameonAffiliation() {
        Test.startTest();
        Contact con = new Contact(FirstName='TestFirstName', LastName='TestLastName', Email='test123@test.com.invalid');       
       	insert con;         
		
        if(con != Null){
            //Create student affiliation record
            I_RM_Affiliation__c stuAff=new I_RM_Affiliation__c(RecordTypeID = affiliationStudentRecordTypeId,
                                                        I_RM_Contact__c=con.Id,
                                                        I_RM_Role__c='Student',
                                                        I_RM_Status__c='Inactive');
            insert stuAff;        
        }
        List<I_RM_Affiliation__c> aff = [Select Id, L_PR_Contact_Name__c from I_RM_Affiliation__c where I_RM_Contact__c =:con.Id ];        
        System.assertEquals(aff[0].L_PR_Contact_Name__c, 'TestFirstName TestLastName');
        
        Test.stopTest();
    }
    
    @isTest
    public static void setSponsoredFieldValue_Test(){
        
        Test.startTest();

        I_RM_Affiliation_Settings__c affSettings = (I_RM_Affiliation_Settings__c) TestUtility.newSObjectInstance(
            new Map<String, String> {
                'Name' => 'I_IL_Sponsored_by_Citizenship',
                'Value__c' => 'Saudi Arabia;Oman;United Arab Emirates;United Arab Emirates (the);Kuwait;Bahrain;Qatar',
                'I_RM_Status__c' => 'Coursework External Sponsorship;Graduate Research Scholarship;Graduate Research External Sponsorship;Other'
            },
            'I_RM_Affiliation_Settings__c'
        );
        insert affSettings;

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
        
        aff1.I_IL_Intended_Funding_Source__c = 'Coursework External Sponsorship';
        update aff1;
        System.assertEquals(
            'Yes', 
            [SELECT I_IL_Sponsored__c FROM I_RM_Affiliation__c WHERE Id = :aff1.Id].I_IL_Sponsored__c,
            'Expected Yes as the Country of residence matches one of the sponsorship countries and intended funding source matches one of the list of acceptable values'
        );

        aff1.I_IL_Intended_Funding_Source__c = 'Self-funded';
        update aff1;
        System.assertEquals(
            'No', 
            [SELECT I_IL_Sponsored__c FROM I_RM_Affiliation__c WHERE Id = :aff1.Id].I_IL_Sponsored__c,
            'Expected No since the intended funding source doesn\'t match one of the list of acceptable values'
        );

        aff1.I_IL_Sponsored__c = 'Yes';
        update aff1;
        System.assertEquals(
            'Yes', 
            [SELECT I_IL_Sponsored__c FROM I_RM_Affiliation__c WHERE Id = :aff1.Id].I_IL_Sponsored__c,
            'Expected Yes as user enforced update bypasses the rules in the trigger'
        );

        Test.StopTest();        
    } 

    @isTest 
    public static void updateContactEmailfieldsInternationalLeadTest(){
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
                'I_RM_Email__c' => 'iltest@gmail.com.invalid',
                'I_RM_Status__c' => 'Not Qualified',
                'I_RM_Mobile_Phone__c' => '+61415822666'
            },
            'I_RM_Affiliation__c'
        );        
        insert aff1;
        System.assertEquals(
            aff1.I_RM_EMail__c,
            [SELECT I_ST_Personal_Email__c FROM Contact WHERE Id = :cont1.Id].I_ST_Personal_Email__c,
            'Personal email on contact should match RM_EMail__c on Affiliation for Intenational Leads');
        Test.stopTest();
    } 
}