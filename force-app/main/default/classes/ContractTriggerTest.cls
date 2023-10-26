@IsTest
public class ContractTriggerTest {
     /*  @author 		Vanita Walia
     * @date  			13/10/2022
     * @description 	test data setup method As part of Agreement conversion from Opportunity LTU360-2446
     */    
    public static Id prmAgreementRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('L_PR_Agreement').getRecordTypeId();
    public static Id prmOpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('PRM_Opportunity').getRecordTypeId();
     
    @TestSetup
    static void setup(){
    	//create External organisation
        Account tstAccount = TestUtility.newEmptyExternalAccount('test External Organisation');
        insert tstAccount;
        
        Task_Matrix__c tm = new Task_Matrix__c();
        tm.L_PR_Agreement_Type__c = 'Articulation Agreement';
        tm.I_RS_Object_Name__c = 'Agreement';
        tm.I_RS_Record_Type__c = 'Partnership Agreement';
        tm.L_PR_Agreement_Stage__c = 'Executed';
        tm.I_RS_Subject__c = 'Test Subject1';
        tm.I_RS_Inactive__c = false;
        Insert tm;

        Task_Matrix__c tm2 = new Task_Matrix__c();
        tm2.L_PR_Agreement_Type__c = 'Articulation Agreement';
        tm2.I_RS_Object_Name__c = 'Agreement';
        tm2.I_RS_Record_Type__c = 'Partnership Agreement';
        tm2.L_PR_Agreement_Stage__c = 'Terminated';
        tm2.I_RS_Subject__c = 'Test Subject2';
        tm2.I_RS_Inactive__c = false;
        Insert tm2;
        //create opportunity
        Opportunity testOpp = new Opportunity();
        testOpp.RecordTypeId = prmOpportunityRecordTypeId;
        testOpp.AccountId = tstAccount.Id;
        testOpp.L_PR_Type__c = 'Education and Students';
        testOpp.L_PR_Sub_Type__c = 'Third Party Teaching';
        testOpp.L_PR_Location__c = 'Domestic';
        testOpp.L_PR_Location_Country__c = 'Australia';
        testOpp.CloseDate = System.today() +30;
        testOpp.StageName = 'Prospecting';
        testOpp.Name ='TestOpp1';
        Insert testOpp;

        Account extOrgAcc = TestUtility.newEmptyAccount('test ExtOrg1','I_RS_External_Organisation');
        Insert extOrgAcc;
        Account  laOrg1= TestUtility.newEmptyAccount('test laOrg1','I_RS_La_Trobe_Organisation_Unit');
        Insert laOrg1;

        Contract__c prmAgreement = new Contract__c();
        prmAgreement.Name ='Prm Agreement1';
        prmAgreement.recordTypeId = prmAgreementRecordTypeId;
        prmAgreement.I_RS_Organisation__c = extOrgAcc.Id;
        prmAgreement.L_PR_Category__c = 'New';
        prmAgreement.I_RS_Contract_Start_Date__c = System.today();
        prmAgreement.I_RS_Contract_End_Date__c = System.today() +10;
        prmAgreement.I_RS_Status__c = 'Executed';
        prmAgreement.I_RS_Agreement_Type__c = 'Articulation Agreement';
        Insert prmAgreement;
    }
    
    /*  @author 		Vanita Walia
     * @date  			13/10/2022
     * @description 	test method As part of Agreement conversion from Opportunity LTU360-2446
     */  
    @isTest
    public static void testupdateConvertedOpp(){

        Test.startTest();
		List<Account> acc = [Select Id from Account Limit 1];
        List<Opportunity> opp = [Select Id,AccountId, StageName from Opportunity Limit 1];
		//Create new Agreement from Opportunity
		Contract__c prmAgreement = new Contract__c(RecordTypeId = prmAgreementRecordTypeId,
                                                  Name ='Test Agreement', I_RS_Organisation__c = acc[0].Id,
                                                  L_PR_Category__c ='New', I_RS_Agreement_Type__c='Other',
                                                  I_RS_Contract_Start_Date__c = system.today(), 
                                                  I_RS_Contract_End_Date__c = system.today()+30, 
                                                  L_PR_Opportunity_Name__c = opp[0].Id,
                                                  L_PR_IsConverted__c = True);
        insert prmAgreement;
        
         List<Opportunity> updatedOpp = [Select Id,AccountId, StageName from Opportunity where Id =: opp[0].Id];
        system.assertEquals('Closed Won', updatedOpp[0].StageName);
        Test.stopTest();
    }
    
     /*  @author 		Vanita Walia
     * @date  			13/10/2022
     * @description 	this method will test exception handling
     */
	@isTest
    public static void testupdateConvertedOpp_Exception(){

        Test.startTest();
       Map<Id,Id> testMap = new Map<Id,Id>();
        testMap.put('a3T5P0000008qzFUAQ','a3T5P0000008qzFUAQ');
        try{
        	ContractTriggerHelper.updateOppStatusClosedWon(testMap);            
        }catch(exception e){
             System.debug ('Exception'+e);
        }
        
        Test.stopTest();
    }  
    

    @IsTest
    public static void deleteAsNonSysAdmin() {
        
        //Create deletion-blocker custom setting
        insert new Object_Metadata__c(
            Name = 'Contract__c',
            I_RS_Enable_Deletion_Blocker__c = true,
            I_RS_Deletion_Blocker_Check_Formula__c = 'I_RS_Valid_for_Deletion__c',
            I_RS_Deletion_Blocker_Error_Message__c = 'You cant delete record'
        );

        // create a management user 
        Profile gProfile = [SELECT Id FROM Profile WHERE Name='LTU PRIME'];
        User gUser;
        gUser = new User(Alias = 'gUser', Email='guser@ltu.com.test', 
            EmailEncodingKey='UTF-8', LastName='researcher', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = gProfile.Id, 
            TimeZoneSidKey='Australia/Sydney', UserName='guser@ltu.com.test');
        insert gUser;
        
        Account acc = TestUtility.newEmptyExternalAccount('test Acc');
        Insert acc;
        
        //Create an agreement and related agreement;
        //Id RecTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('I_RS_New_La_Trobe_contract').getRecordTypeId();
        Contract__c pAgreement = new Contract__c(Name='Parent Agreement', I_RS_Organisation__c = acc.Id );
        Insert pAgreement;
        
        Contract__c cAgreement = new Contract__c(Name='Child Agreement', I_RS_Contract__c = pAgreement.Id, I_RS_Organisation__c = acc.Id);
        Insert cAgreement;
        
        List<Contract__c> agreements = [SELECT ID, Name FROM Contract__c];
        
        System.assertEquals(agreements.size(), 3, 'There should be three records');
        
        Test.startTest();
        System.runAs ( gUser ) {
            try{
            	delete pAgreement;
            }  catch (Exception e){
                system.debug('Exception Message: ' + e.getMessage());
            }
        }

        Test.stopTest();
            agreements.clear();
            agreements = [SELECT ID, Name FROM Contract__c];            
            System.assertEquals(agreements.size(), 3, 'There should be three records');
    }

    public static void deleteAsSysAdmin() {
        
        //Create deletion-blocker custom setting
        insert new Object_Metadata__c(
            Name = 'Contract__c',
            I_RS_Enable_Deletion_Blocker__c = true,
            I_RS_Deletion_Blocker_Check_Formula__c = 'I_RS_Valid_for_Deletion__c',
            I_RS_Deletion_Blocker_Error_Message__c = 'You cant delete record'
        );

        // create a management user 
        Profile gProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User gUser;
        gUser = new User(Alias = 'gUser', Email='guser@ltu.com.test', 
            EmailEncodingKey='UTF-8', LastName='researcher', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = gProfile.Id, 
            TimeZoneSidKey='Australia/Sydney', UserName='guser@ltu.com.test');
        insert gUser;
        
        Account acc = TestUtility.newEmptyExternalAccount('test Acc');
        Insert acc;
        
        //Create an agreement and related agreement;
        //Id RecTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('I_RS_New_La_Trobe_contract').getRecordTypeId();
        Contract__c pAgreement = new Contract__c(Name='Parent Agreement', I_RS_Organisation__c = acc.Id );
        Insert pAgreement;
        
        Contract__c cAgreement = new Contract__c(Name='Child Agreement', I_RS_Contract__c = pAgreement.Id, I_RS_Organisation__c = acc.Id);
        Insert cAgreement;
        
        List<Contract__c> agreements = [SELECT ID, Name FROM Contract__c];
        
        System.assertEquals(agreements.size(), 2, 'There should be two records');
        
        Test.startTest();
        System.runAs ( gUser ) {
            try{
            	delete pAgreement;
            }  catch (Exception e){
                system.debug('Exception Message: ' + e.getMessage());
            }
        }

        Test.stopTest();
            agreements.clear();
            agreements = [SELECT ID, Name FROM Contract__c];            
            System.assertEquals(agreements.size(), 0, 'There should be two records');
    }

    @isTest 
    public static void updateRelatedOrgStatusTest(){

        Test.startTest();
        List<Contract__c> agreements = new List<Contract__c>();
        agreements = [Select Name, I_RS_Organisation__c, I_RS_Status__c From Contract__c Where Name ='Prm Agreement1'];
        agreements[0].I_RS_Status__c = 'Closed';
        agreements[0].I_RS_Closure_Reason__c ='Expired';
        update agreements[0];
        Test.stopTest();
        system.assertEquals( agreements[0].I_RS_Status__c, 'Closed');
    }

    @isTest 
    public static void createUpdateRelatedExternalOrgsTest(){

        Test.startTest();
        List<Contract__c> agreements = new List<Contract__c>();
        agreements = [Select Name, I_RS_Organisation__c, I_RS_Status__c From Contract__c Where Name ='Prm Agreement1'];
        Account extOrgAcc1 = TestUtility.newEmptyAccount('test ExtOrg1','I_RS_External_Organisation');
        Insert extOrgAcc1;
        Account extOrgAcc2 = TestUtility.newEmptyAccount('test ExtOrg2','I_RS_External_Organisation');
        Insert extOrgAcc2;

        agreements[0].I_RS_Organisation__c = extOrgAcc1.Id;
        update agreements[0];
        agreements[0].I_RS_Organisation__c = extOrgAcc2.Id;
        update agreements[0];
        agreements[0].I_RS_Organisation__c = extOrgAcc1.Id;
        update agreements[0];
        List<Related_Contract__c> ro = new List<Related_Contract__c>();
        ro = [Select Id, L_PR_isPrimary__c from Related_Contract__c Where I_RS_Organisation__c =: extOrgAcc1.Id];
        system.assertEquals( ro[0].L_PR_isPrimary__c, true);
        Test.stopTest();
    }


    @isTest 
    public static void updateOppStatusClosedWonTest(){

        Test.startTest();
        Account extOrgAcc1 = TestUtility.newEmptyAccount('test ExtOrg1','I_RS_External_Organisation');
        Insert extOrgAcc1;
        Id oppRecordTypeId = 
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('PRM_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.recordTypeId = oppRecordTypeId;
        opp.Name = 'PRM Opportunity1';
        opp.AccountId = extOrgAcc1.Id;
        opp.L_PR_Type__c = 'Research and Innovation';
        opp.L_PR_Sub_Type__c = 'Access to equipment';
        opp.L_PR_Location__c = 'Domestic';
        opp.L_PR_StartDate__c = System.today();
        opp.L_PR_Opportunity_Close_Date__c = System.today()+20;
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today()+20;
        Insert opp;
        Contract__c prmAgreement = new Contract__c();
        prmAgreement.Name ='Prm Agreement1';
        prmAgreement.L_PR_Opportunity_Name__c = opp.Id;
        prmAgreement.L_PR_IsConverted__c = true;
        prmAgreement.I_RS_Organisation__c = extOrgAcc1.Id;
        prmAgreement.L_PR_Category__c = 'New';
        prmAgreement.I_RS_Contract_Start_Date__c = System.today();
        prmAgreement.I_RS_Contract_End_Date__c = System.today() +10;
        prmAgreement.I_RS_Status__c = 'Executed';
        Insert prmAgreement;
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = [Select Id, Name, StageName from Opportunity Where Id =: opp.Id];
        system.assertEquals( oppList[0].StageName, 'Closed Won');
        Test.stopTest();
    }

    @isTest 
    public static void createTasksFromTaskMatrixTest(){
        Id taskAgreementRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('L_PR_Agreement_Task').getRecordTypeId();
        Test.startTest();
        List<Contract__c> agreements = new List<Contract__c>();
        agreements = [Select Name, I_RS_Organisation__c, I_RS_Status__c, OwnerId From Contract__c Where Name ='Prm Agreement1'];
        agreements[0].I_RS_Closure_Reason__c = null;
        update agreements[0];
        Task tk = new Task();
        tk.Subject = 'prm agreement task test1';
        tk.WhatId = agreements[0].Id;
        tk.Status = 'Not Started';
        tk.RecordTypeId = taskAgreementRecordTypeId;
        tk.OwnerId =  agreements[0].OwnerId;
        tk.L_PR_Stage__c = 'Terminated';
        Insert tk;
        agreements[0].I_RS_Status__c ='Closed';
        agreements[0].I_RS_Closure_Reason__c = 'Terminated';
        agreements[0].L_PR_Reason_for_termination__c = 'Test1';
        agreements[0].L_PR_Termination_Date__c = System.today();
        update agreements[0];
        List<Task> tk2 = new List<Task>();
        tk2 = [Select Id,Subject from Task where whatId =: agreements[0].Id];
        system.assertEquals( tk2.size(), 3);
        Test.stopTest();
    }

}