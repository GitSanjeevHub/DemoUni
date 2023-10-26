/**
* @author  Vanita Walia
* @date    15/09/2022
* @description : This is a test class to cover OpportunityTriggerHandler & OpportunityTriggerHelper methods
*/
@isTest
public class L_PR_OpportunityTriggerHandlerTest {
    public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    
     @TestSetup
    static void setup(){

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
         //affiliation setting required for creating affiliations
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;        
		
        //create External organisation
        Account tstAccount = TestUtility.newEmptyExternalAccount('test External Organisation');
        insert tstAccount;
        
        Profile PrmProfile = [SELECT Id FROM Profile WHERE Name='PRM User'];
       
        //Create PRM User
        User prmUser;
        prmUser = new User(Alias = 'prmUser', Email='prmusertest@ltu.com.test', 
            		EmailEncodingKey='UTF-8', FirstName='Test PRM', LastName='user', LanguageLocaleKey='en_US', 
            		LocaleSidKey='en_AU', ProfileId = PrmProfile.Id, TimeZoneSidKey='Australia/Sydney', UserName='prmusertest@ltu.com.test');
        insert prmUser;
		
        //Create Contacts and populate related User
        List<Contact> conList = new List<Contact>();
        for(integer i=0; i<=10; i++){
            Contact newContact = I_ST_UnitTestUtilities.createContactForScore('test_PRMFirstName'+i,
                                                                                  'test_PRMLastName'+i,
                                                                                  'test_PRM'+i+'@invalid.com',
                                                                                  'test_PRM'+i+'@invalid.com',                                                                                 
                                                                                  '3000');
            newContact.AccountId = tstAccount.Id;
            newContact.I_RS_Related_User__c = prmUser.Id;
            conList.add(newContact);
        }
        insert conList;
        
        //Create staff affiliations
        List<I_RM_Affiliation__c> lstAffiliations = new List<I_RM_Affiliation__c>();
        for(Integer j=0; j<conList.size(); j++) {
            for(I_RM_Affiliation__c aff : I_ST_UnitTestUtilities.createAffiliationRecords(affiliationStaffRecordTypeId,conList[j].Id)){
                aff.I_RM_Role__c = 'La Trobe Staff';
                aff.I_RM_Status__c ='';
                lstAffiliations.add(aff);
            }            
        }        
        insert lstAffiliations;     
        
        //Create La Trobe Organisation Unit       
        Account ltuOrg =TestUtility.newEmptyLTUAccount('LTU Test Account');           
        insert ltuOrg;
        
    	// Create PRM Lead
        L_PR_Idea__c prmLead = new L_PR_Idea__c(Name='Test PRM Lead', L_PR_Affiliation__c = lstAffiliations[0].Id, L_PR_Type__c ='Research and Innovation',
                                               L_PR_Sub_Type__c ='Access to equipment', L_PR_Location__c='Domestic', L_PR_Location_Country__c ='Australia',
                                               L_PR_Organisation__c = tstAccount.Id,L_PR_La_Trobe_Organisation_Unit__c = ltuOrg.Id);
        insert prmLead;
        
		//create opportunity
        Opportunity testOpp = new Opportunity();
        testOpp.AccountId = tstAccount.Id;
        testOpp.L_PR_La_Trobe_Org_Unit__c = ltuOrg.Id;
        testOpp.L_PR_Idea__c = prmLead.Id;
        testOpp.L_PR_Type__c = 'Education and Students';
        testOpp.L_PR_Sub_Type__c = 'Third Party Teaching';
        testOpp.L_PR_Location__c = 'Domestic';
        testOpp.L_PR_Location_Country__c = 'Australia';
        testOpp.CloseDate = System.today() +30;
        testOpp.StageName = 'Prospecting';
        testOpp.Name ='TestOpp1';
        Insert testOpp;
        
      /* L_PR_External_Org_Opportunity_Relation__c extOrg = new L_PR_External_Org_Opportunity_Relation__c();
        extOrg.L_PR_Opportunity_Name__c = testOpp.Id;
        extOrg.L_PR_Organisation_Name__c = tstAccount.Id;
        insert extOrg;*/
        
    }

    @isTest
    public static void testupdateExtOrgOpptStageField(){

        Test.startTest();

        List<Opportunity> oppList = [Select Id,AccountId, StageName from Opportunity Limit 1];

        oppList[0].StageName = 'Development';
        update oppList[0];

        List<Opportunity> updatedOppList = [Select Id,AccountId, StageName from Opportunity Limit 1];

        system.assertEquals('Development', updatedOppList[0].StageName);
    }

     /*  @author 		Vanita Walia
     * @date  			15/09/2022
     * @description 	this method will test updating organisation details on opportunity & opportunity closed Notification 
     */
	@isTest
    public static void testOppClosedNotification(){

        Test.startTest();

        Opportunity testOpp = [Select Id,AccountId, StageName from Opportunity where Name='TestOpp1'];

        testOpp.StageName = 'Closed Lost';
        testOpp.L_PR_Closed_Reason__c = 'Closed Opportunity';
        update testOpp;
        
        Opportunity updatedOpp = [Select Id,AccountId, StageName from Opportunity where Name='TestOpp1'];
        system.assertEquals('Closed Lost', updatedOpp.StageName);        
        Test.stopTest();

    }
    /*  @author 		Vanita Walia
     * @date  			15/09/2022
     * @description 	this method will test updating organisation details on opportunity 
     */
	@isTest
    public static void testOppupdateExternalOrgs(){

        Test.startTest();
        //create External organisation
        Account tstAccount = TestUtility.newEmptyExternalAccount('test org');
        insert tstAccount;
        
        //Create La Trobe Organisation Unit       
        Account ltuOrg =TestUtility.newEmptyLTUAccount('LaTrobeOrg');           
        insert ltuOrg;
        
	// update opportunity with new organisations
        Opportunity testOpp = [Select Id,AccountId, StageName from Opportunity where Name='TestOpp1'];
        testOpp.AccountId = tstAccount.Id;
        testOpp.L_PR_La_Trobe_Org_Unit__c = ltuOrg.Id;
        update testOpp;
        List<L_PR_External_Org_Opportunity_Relation__c> extOrg = new List<L_PR_External_Org_Opportunity_Relation__c>();
        extOrg =[Select Id,L_PR_Opportunity_Name__c,L_PR_Organisation_Name__c, L_PR_IsPrimary__c
                                                           from L_PR_External_Org_Opportunity_Relation__c where L_PR_Opportunity_Name__c =: testOpp.Id and 
                                                          L_PR_Organisation_Name__c =:tstAccount.Id limit 1];
        
           //system.assertEquals(extOrg[0].L_PR_IsPrimary__c, True);       
        //Remove account details from opportunity
        testOpp.L_PR_La_Trobe_Org_Unit__c = Null;
        update testOpp;
        List<L_PR_External_Org_Opportunity_Relation__c> internalOrg =[Select Id,L_PR_Opportunity_Name__c,L_PR_Organisation_Name__c, L_PR_IsPrimary__c
                                                           from L_PR_External_Org_Opportunity_Relation__c where L_PR_Opportunity_Name__c =: testOpp.Id and 
                                                          L_PR_Organisation_Name__c =:ltuOrg.Id];
        
           //system.assertEquals(internalOrg.size(), 1);       
        
        Test.stopTest();

    }
    
     /*  @author 		Vanita Walia
     * @date  			29/09/2022
     * @description 	this method will test exception handling
     */
	@isTest
    public static void testupdateLeadStatusClosedConverted_Exception(){

        Test.startTest();
       Map<Id,Id> testMap = new Map<Id,Id>();
        testMap.put('a3T5P0000008qzFUAQ','a3T5P0000008qzFUAQ');
        try{
        	L_PR_OpportunityTriggerHelper.updateLeadStatusClosedConverted(testMap);            
        }catch(exception e){
             System.debug ('Exception'+e);
        }
        
        Test.stopTest();
    }  
    
    /*  @author 		Vanita Walia
     * @date  			29/09/2022
     * @description 	this method will test exception handling
     */
	@isTest
    public static void testcreateCustomSFNotification_Exception(){

        Test.startTest();
        Opportunity testOpp = [Select Id,AccountId, StageName from Opportunity where Name='TestOpp1'];
       Map<Id, Set<String>> oppStaffMap = new Map<Id, Set<String>>();
        Set<String> staffIds = new  Set<String>();
        staffIds.add('test');
        oppStaffMap.put(testOpp.Id,staffIds);
        try{
        	L_PR_OpportunityTriggerHelper.createCustomSFNotification(oppStaffMap);            
        }catch(exception e){
             System.debug ('Exception'+e);
        }
        
        Test.stopTest();
    }  
}