/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* L_PR_AffPopulateContactNameBatchTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vanita Walia
* @version        1.0
* @created        08-09-2022
* @Description	  This is test class for L_PR_AffPopulateContactNameBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public class L_PR_AffPopulateContactNameBatchTest{

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
        
        //Create Contacts and populate related User
        List<Contact> conList = new List<Contact>();
        for(integer i=0; i<=10; i++){
            Contact newContact = I_ST_UnitTestUtilities.createContactForScore('test_PRMFirstName'+i,
                                                                                  'test_PRMLastName'+i,
                                                                                  'test_PRM'+i+'@invalid.com',
                                                                                  'test_PRM'+i+'@invalid.com',                                                                                 
                                                                                  '3000');
            newContact.AccountId = tstAccount.Id;
            conList.add(newContact);
        }
        insert conList;
        
        Id affiliationStaffRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_La_Trobe_Staff').getRecordTypeId();
    
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

    @isTest 
    public static void AffiliationContactNameUpdatedPositive(){

        Test.startTest();
    /*  System_Switch__c ss = new System_Switch__c(I_RS_DisableTriggers__c=True,
                                                  I_RS_ObjectTriggersToBeDisabled__c='I_RM_Affiliation__c');
        insert ss;*/
        List<I_RM_Affiliation__c> affList = new List<I_RM_Affiliation__c>();
         for(I_RM_Affiliation__c aff : [Select Id from I_RM_Affiliation__c]){
            aff.L_PR_Contact_Name__c = Null;
             affList.add(aff);
        }
        update affList;
        Database.executeBatch(new L_PR_AffPopulateContactNameBatch(), 200);
        Test.stopTest();
    }
    
    @isTest 
    public static void AffiliationContactNameUpdatedNegative(){

        Test.startTest();
        List<I_RM_Affiliation__c> affList = [Select Id from I_RM_Affiliation__c];
        delete affList;
        Database.executeBatch(new L_PR_AffPopulateContactNameBatch(), 200);
        Test.stopTest();
    }
}