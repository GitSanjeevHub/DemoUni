/**
* @author  Vanita Walia
* @date    15/0/2022
* @description : This is a test class to cover leadTriggerHandler & LeadTriggerHelper methods
*/
@isTest
public class L_PR_LeadTriggerHelperTest {
	public static Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    
    @TestSetup
    static void setup() {

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
    }
    
    /*  @author 		Vanita Walia
     * @date  			15/08/2022
     * @description 	this method will test PRM Lead creation with affiliation
     */
	@isTest
    public static void createPRMLeadwithAffiliation(){
        Test.startTest();
        //Search for staff affiliation
        List<I_RM_Affiliation__c> aff = [Select Id from I_RM_Affiliation__c where I_RM_Role__c = 'La Trobe Staff'];
        
        // Create PRM Lead
        L_PR_Idea__c prmLead = new L_PR_Idea__c(Name='Test PRM Lead', L_PR_Affiliation__c = aff[0].Id, L_PR_Type__c ='Research and Innovation',
                                               L_PR_Sub_Type__c ='Access to equipment', L_PR_Location__c='Domestic', L_PR_Location_Country__c ='Australia');
        insert prmLead;
        
        List<L_PR_Idea_Affiliation__c> leadAffList =[Select Id, L_PR_Idea__c,L_PR_Affiliation__c, L_PR_IsPrimary__c from L_PR_Idea_Affiliation__c where L_PR_Idea__c=:prmLead.Id AND L_PR_Affiliation__c =:aff[0].Id];
        
        system.assertEquals(leadAffList[0].L_PR_IsPrimary__c,True );
        
        // Updating the affiliation record on PRM Lead
        prmLead.L_PR_Affiliation__c = aff[1].Id;
        update prmLead;
        // again update the affiliation record to 1st one
        prmLead.L_PR_Affiliation__c = aff[0].Id;
        update prmLead;
        Test.stopTest();
    }
    
    /*  @author 		Vanita Walia
     * @date  			15/08/2022
     * @description 	this method will test PRM Lead creation with organisation 
     */
	@isTest
    public static void createPRMLeadwithOrganisation(){
        Test.startTest();
        // Search for External Org
        Account extOrg =[Select Id from Account where Name='test External Organisation'];
        
        //Search for staff affiliation
        List<I_RM_Affiliation__c> aff = [Select Id from I_RM_Affiliation__c where I_RM_Role__c = 'La Trobe Staff'];
        
        //Create La Trobe Organisation Units
        List<Account> ltuOrgs = new List<Account>();
        for(Integer i=0;i<5;i++){
            Account acc =TestUtility.newEmptyLTUAccount('LTU Test Account'+i);
            ltuOrgs.add(acc);
        }
        insert ltuOrgs;
        
        // Create PRM Lead
        L_PR_Idea__c prmLead = new L_PR_Idea__c(Name='Test PRM Lead', L_PR_Organisation__c = extOrg.Id, L_PR_Type__c ='Research and Innovation',
                                               L_PR_Sub_Type__c ='Access to equipment', L_PR_Location__c='Domestic', L_PR_Location_Country__c ='Australia',
                                               L_PR_La_Trobe_Organisation_Unit__c = ltuOrgs[0].Id, L_PR_Affiliation__c = aff[0].Id);
        insert prmLead;
        
        List<L_PR_Idea_Organisation__c> leadOrgList =[Select Id, L_PR_Idea__c,L_PR_Organisation__c, L_PR_IsPrimary__c from L_PR_Idea_Organisation__c
                                                                  where L_PR_Idea__c =: prmLead.Id AND L_PR_organisation__c =: extOrg.Id];
        system.Assert(leadOrgList.size()>0,'True');
            
        // Updating the affiliation record on PRM Lead
        prmLead.L_PR_La_Trobe_Organisation_Unit__c = ltuOrgs[1].Id;        
        update prmLead;
        // again update the affiliation record to 1st one
        prmLead.L_PR_La_Trobe_Organisation_Unit__c = ltuOrgs[0].Id;
        prmLead.L_PR_Lead_Status__c ='Closed';
        prmLead.L_PR_Closed_Reason__c ='test closed';
        update prmLead;
        Test.stopTest();
    }
}