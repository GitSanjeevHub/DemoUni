/**
 * @author Jie Tan
 * @date 12/10/2020
 * 
 * @group IST
 * 
 * @description Test class for all invocable methods used by IST flows
 * Modification Log :
 * 24/02/2022 : By Vanita Walia - Modified existing and created new test methods as part of remediation as part of LTU360-868 & LTU360-1212
 */
@IsTest
private class I_ST_FlowMethods_Test {    

    //Vanita : Modified test setup method to create contact without record type and create related affiliations
    @testSetup static void setup() {

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Status',I_RM_Status__c = 'Inactive');
        insert objAffiliationSettings;
		
        //create test contact records
        List<Contact> lstContacts = I_ST_UnitTestUtilities.createTestContactRecords(10,false);
       	//ContactTriggerHandler.runCTEAlways = true;
       	insert lstContacts;         
		system.debug('contact list' + lstContacts);
        
        // Find Domestic Lead Affiliation record type's Id & create affiliation records
        String affiliationRecordTypeIds = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId();
        List<I_RM_Affiliation__c> affRecordsList = new List<I_RM_Affiliation__c>();
        for(Integer i=0;i<lstContacts.size();i++){
            I_RM_Affiliation__c affRecord = I_ST_UnitTestUtilities.createAffiliationRecords(affiliationRecordTypeIds,lstContacts[i].Id)[0];
            affRecord.I_RM_Email__c = 'test'+i+'@test.com.invalid';
            affRecord.I_RM_Mobile_Phone__c ='041111112'+i;
            system.debug('affRecord'+affRecord);
            affRecordsList.add(affRecord);
        }
        insert affRecordsList;
        system.debug('affRecordsList'+affRecordsList);

    }         
    
    /**
     * @description Test method for Apex class I_ST_FlowEncryptText & I_ST_FlowDecryptText
     */
    @IsTest
    static void testEncryptionDecryption() {
        //Test setup
        I_ST_GenericUtils.setupScheduler();

        Test.startTest();
        //Prepare inputs
        String clearText = 'clear text';
        List<String> inputs = new List<String>();
        inputs.add(clearText);

        //Encrypt
        List<String> outputs = I_ST_FlowEncryptText.getEncryptedStrings(inputs);

        //Decrypt
        String cipherText = I_ST_FlowDecryptText.getDecryptedStrings(outputs).get(0);

        //Assert
        System.assertEquals(clearText, cipherText);
        Test.stopTest();
    }

    /**
     * @description Test method for Apex class I_ST_FlowFlattenFields
     */
    @IsTest
    static void testFlattenFields() {
        Test.startTest();
        //Prepare inputs
        I_ST_FlowFlattenFields.ServiceAppointmentFields saf = new I_ST_FlowFlattenFields.ServiceAppointmentFields();
        saf.Description = 'test description';
        List<I_ST_FlowFlattenFields.ServiceAppointmentFields> inputs = new List<I_ST_FlowFlattenFields.ServiceAppointmentFields>();
        inputs.add(saf);

        //Get output
        String output = I_ST_FlowFlattenFields.getStrings(inputs).get(0);

        //Assert
        System.assertEquals(JSON.serialize(saf, true), output);
        Test.stopTest();
    }
    
    /**
     * @description Test method for Apex class I_ST_FlowFindDuplicates
     * @Modified by Vanita : 24/02/2022 as part of LTU360-868 - Modified the logic as per the new Flow find duplicate class
    */
    @IsTest
    static void testFindDuplicate() {
		
        Test.startTest();
        //Create input contact deatils to find duplicate record
        I_ST_FlowFindDuplicates.ContactFields con = new I_ST_FlowFindDuplicates.ContactFields();
        con.FirstName = 'TestFirst1';
        con.LastName ='TestLast1';
        con.Email ='test2@test.com.invalid';
        con.Mobile ='0411111120';
        con.AllOrFirst = False;

        List<I_ST_FlowFindDuplicates.ContactFields> conList = new List<I_ST_FlowFindDuplicates.ContactFields>();
        conList.add(con);        
        system.debug('conList' + conList);
        // Call the FindDuplicate Apex action
        List<Contact> duplicateCons = I_ST_FlowFindDuplicates.FindDuplicateContacts(conList);
        
        //assertion to check if duplicate record found
        if(!duplicateCons.isEmpty()) {
            System.assert(!String.isBlank(duplicateCons[0].Id)); 
        }
        
        // update the con record's AllOrFirst to true to return single record      
        con.AllOrFirst = True;
        conList = new List<I_ST_FlowFindDuplicates.ContactFields>();
        conList.add(con); 
             system.debug('conList' + conList);
        List<Contact> duplicateContacts = I_ST_FlowFindDuplicates.FindDuplicateContacts(conList);
        //assert if it return records
        if(!duplicateContacts.isEmpty()) {
            System.assert(!String.isBlank(duplicateContacts[0].Id)); 
        }
        Test.stopTest();
    }
    
    /**
     * @description Test method for Apex class I_ST_FlowInsertContact
     * @Modified by Vanita : 24/02/2022 as part of LTU360-868 & LTU360-1212 - Update test method and removed reference to flow update contact as that class is obselete
    */
    @IsTest
    static void testContactDuplicateSupport() {
		
        // Insert new contact record
        Test.startTest();
        Contact newContact = new Contact();
        newContact.FirstName = 'TestContact';
        newContact.LastName = 'TestLastName';
        newContact.Email = 'testingcontact@invalid.com';
        
        List<Contact> conList = new List<Contact>();
        conList.add(newContact);

        //Pass Input to Flow Insert Duplicate Apex action which will return contact Id
        String output = I_RM_FlowInsertContact.SaveContact(conList).get(0);

        Contact con =[Select Id from Contact where Email ='testingcontact@invalid.com' ];

        //Assertion output should not be blank and match the contact Id
        System.assert(!String.isBlank(output));
        System.assertEquals(con.Id, output);
        
        Test.stopTest();
    }
    
    /**
     * 
     * @description Test method for Apex class I_ST_FlowInsertAffiliations 
     * Vanita : 28/02/2022 as part of LTU360-1212 - Create test method for creating affiliation
    */
    @IsTest
    static void testInsertAffiliation() {

        Test.startTest();
		// Find contact with which affiliation will be linked
        List<Contact> conList = [Select Id from Contact];
		
        // Prepare Affiliation data which will then be passed to Flow Insert Affiliation class
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('I_RM_Affiliation__c').getDescribe().getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
		List<I_RM_Affiliation__c> affList = new List<I_RM_Affiliation__c>();
		I_RM_Affiliation__c aff = new I_RM_Affiliation__c(I_RM_Campus_Interest__c = 'City Campus', I_RM_Study_Interest__c ='Health',
                                                          I_RM_Enquirer_Type__c ='International (inside Australia)',I_RM_Career_Area__c ='Disability',
                                                          I_RM_Email__c ='test23@test.com.invalid',I_RM_Mobile_Phone__c = '0411111120',I_RM_Contact__c = conList[0].Id,
                                                          I_RM_Role__c = 'Domestic Lead',I_RM_Lead_Source_Category__c = 'Consultation',RecordTypeId = accountRecordTypeId);
		affList.add(aff);
		system.debug('affList'+affList);

		// Call InsertAffiliation apex action to insert affiliation records
        List<String> AffRecords = new List<String>();
		AffRecords=I_RM_FlowInsertAffiliations.InsertAffiliation(affList);
		system.debug('AffRecords'+AffRecords);
        //query the affiliation record from the system which match the input data
        List<I_RM_Affiliation__c> insertedAff = [Select Id from I_RM_Affiliation__c where I_RM_Contact__c =: conList[0].Id and I_RM_Email__c ='test23@test.com.invalid'];
        
        // Assertion to check output from apex action call and system data
        System.assertEquals(insertedAff[0].Id, AffRecords[0]);
        Test.stopTest();
    }
    
    /**c
     * @description Test method for Apex class I_ST_FlowInsertAccount
    */
    @IsTest
    static void testAccountDuplicateSupport() {
        Id leadAcctRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('I_ST_Lead_Account').getRecordTypeId();
        
        //Insert an account
        Account acct1 = new Account(
            Name = 'Test Dup Account',
            RecordTypeId = leadAcctRTId
        );
        insert acct1;

        Test.startTest();

        //Create another account with the same name that will trigger dup rule and need to be overridden
        Account acct2 = new Account(
            Name = 'Test Dup Account',
            RecordTypeId = leadAcctRTId
        );
        //Prepare inputs
        List<Account> inputs = new List<Account>();
        inputs.add(acct2);

        //Get output
        String output = I_RM_FlowInsertAccount.SaveAccount(inputs).get(0);

        //Assert
        System.assertNotEquals(acct1.Id, output);
        
        Test.stopTest();
    }
    
    /**
     * @description Test method for Apex class I_ST_FlowLaunchScoring
    */
  /*  @IsTest
    static void testLaunchScoring() {
		
        Test.startTest();
        //Launch Contact Scoring
		Contact conToBeScored = [SELECT Id, FirstName FROM Contact WHERE FirstName = 'TestFirst2' LIMIT 1];
        
        List<I_ST_FlowLaunchScoring.Request> reqs = new List<I_ST_FlowLaunchScoring.Request>();
        I_ST_FlowLaunchScoring.Request req = new I_ST_FlowLaunchScoring.Request();
        req.flowType = 'Contact';
        req.objectID = conToBeScored.Id;
        reqs.add(req);
        I_ST_FlowLaunchScoring.ParseObjectValue(reqs);
        

        //Launch Case Scoring
        Case casToBeScored = new Case();
        casToBeScored.Subject = 'Test';
        casToBeScored.ContactId = conToBeScored.Id;
        casToBeScored.recordTypeId = [Select Id From RecordType Where DeveloperName = 'I_ST_Enquiry'].Id;
        system.debug('case inserted' + casToBeScored);
        insert casToBeScored; 
        
        List<I_ST_FlowLaunchScoring.Request> reqs2 = new List<I_ST_FlowLaunchScoring.Request>();
        I_ST_FlowLaunchScoring.Request req2 = new I_ST_FlowLaunchScoring.Request();
        req2.flowType = 'Case';
        req2.objectID = casToBeScored.Id;
        reqs2.add(req2);
        I_ST_FlowLaunchScoring.ParseObjectValue(reqs2);
        
        //assert
        //System.assert(!String.isBlank(duplicateCon.Id)); //fields returned by dup don't coincide with fields set
        Test.stopTest();
    }*/

    /**
     * @description Test method for Apex class OrgWideEmailAddressUtil
    */
    @IsTest
    static void testRetrieveOrgWideEmailAddressPositiveTest() {
        Test.startTest();
        List<String> displayNames = new List<String>();
        displayNames.add('Future Students');        
        List<String> orgWideEmailAddressIds = I_ST_OrgWideEmailAddressUtil.getOrgWideEmailAddressId(displayNames);
        Test.stopTest();
        System.assertEquals(1, orgWideEmailAddressIds.size());
    }


    /**
     * @description Test method for Apex class OrgWideEmailAddressUtil
    */
    @IsTest
    static void testRetrieveOrgWideEmailAddressNegativeTest() {
        String displayName = 'unknown';

        Test.startTest();
        List<String> displayNames = new List<String>();
        displayNames.add(displayName);

        try {
            List<String> orgWideEmailAddressIds = I_ST_OrgWideEmailAddressUtil.getOrgWideEmailAddressId(displayNames);
        } catch(Exception e) {
            System.assertEquals('There is no org wide email address for ' + displayName, e.getMessage());
        }
        Test.stopTest();
        // System.assertEquals(1, orgWideEmailAddressIds.size());
    }

    /**
     * @description Test method for Apex class I_ST_FlowUpdateServiceAppointment
    */
    @IsTest
    static void testUpdateServiceAppointment() {

        
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('I_ST_Lead_Account').getRecordTypeId();

        Account leadAcct = new Account();
        leadAcct.recordTypeId = accountRecordTypeId;
        leadAcct.Name = 'testAccount';
        insert leadAcct;

        List<ServiceAppointment> sas = new List<ServiceAppointment>();

        sas.add(new ServiceAppointment(ParentRecordId = leadAcct.Id));
        insert sas;
        
        Test.startTest();
        I_ST_FlowUpdateServiceAppointment.updateServiceAppointments(sas);
        Test.stopTest();
    }
}