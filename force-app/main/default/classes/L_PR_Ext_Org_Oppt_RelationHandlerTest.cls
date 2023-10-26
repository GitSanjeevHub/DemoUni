@isTest 
public class L_PR_Ext_Org_Oppt_RelationHandlerTest{

    public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    public static Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('PRM_Opportunity').getRecordTypeId();

    @testSetup static void setup() {
        
        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
    }

    @isTest 
    public static void extOrgOppTest(){
         //affiliation setting required for creating affiliations
         I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
         insert objAffiliationSettings;   
        Account tstAccount = TestUtility.newEmptyExternalAccount('test External Organisation');
        insert tstAccount;

        Account ltuOrg =TestUtility.newEmptyLTUAccount('LTU Test Account');           
        insert ltuOrg;

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

        // Create PRM Lead
        L_PR_Idea__c prmLead = new L_PR_Idea__c(Name='Test PRM Lead', L_PR_Affiliation__c = lstAffiliations[0].Id, L_PR_Type__c ='Research and Innovation',
        L_PR_Sub_Type__c ='Access to equipment', L_PR_Location__c='Domestic', L_PR_Location_Country__c ='Australia',
        L_PR_Organisation__c = tstAccount.Id,L_PR_La_Trobe_Organisation_Unit__c = ltuOrg.Id);

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
        testOpp.RecordTypeId = oppRecordTypeId;
        Insert testOpp;


        L_PR_External_Org_Opportunity_Relation__c extOrOpp = new L_PR_External_Org_Opportunity_Relation__c();
        extOrOpp.L_PR_Organisation_Name__c = tstAccount.Id;
        extOrOpp.L_PR_Opportunity_Name__c = testOpp.id;
        insert extOrOpp;
    }
}