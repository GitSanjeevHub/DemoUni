/* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_AffiliationScoring_Batch2Test
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
  @JIRA           LTU360-867
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-02-18      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class I_RM_AffiliationScoring_Batch_Test {
    
    //If test class fails for the SOQL 101 governining limit OR Apex CPU Limit Exceeded, please reduce this contactBatchFrequency and run test again
    //This contactBatchFrequency tells how may contact records can be updated in 1 transaction
    private static Integer contactsToCreateUpdate = 20;
    @TestSetup
    static void setup(){        
        String affiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
        String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);  
        String interactionRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.INTERACTION_OBJECT_API_NAME,GlobalConstants.INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION);
        
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypIds,20,caseRecordTypeIds,20,interactionRecordTypeIds,20);           
        insert listBatchScoringSetting;
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
        List<Contact> contactsToInsert = new List<contact>();
        //Id domesticLeadRecordTypeId =  listBatchScoringSetting[0].I_ST_RecordType_SFIDs__c.split(',')[0];
         //Id contactDomesticLeadRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('I_ST_Domestic_Lead').getRecordTypeId();
         Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        
        for(integer i = 0; i < contactsToCreateUpdate; i++){
            Contact newDomesticLead = I_ST_UnitTestUtilities.createContactForScore('test_unique'+i,
                                                                          'unique_test'+i, 
                                                                          'test_unique'+i+'@unique.com',
                                                                          'test_unique'+i+'@unique.com',                                                                         
                                                                          '3029');
                                                                          
            contactsToInsert.add(newDomesticLead);
        }
        insert contactsToInsert;
        
        List<I_RM_Affiliation__c> testAffiliation = I_ST_UnitTestUtilities.createAffiliationRecords(affiliationDomesticLeadRecordTypeId,contactsToInsert[0].Id);
        insert testAffiliation;
         system.debug('testAffiliation'+testAffiliation);
    }
    
    //IST - Test method to test the execution of batch class - I_ST_AffiliationScoring_Batch - Positive Test
    @isTest
    public static void testCalculateAffiliationScoreBatch(){
        
        List<I_RM_Affiliation__c> contactAfterInsert = new List<I_RM_Affiliation__c>();
        contactAfterInsert = [SELECT Id,I_RM_Score__c 
                              FROM  I_RM_Affiliation__c
                             ];       
        
        System.assertEquals(0,contactAfterInsert[0].I_RM_Score__c);
        
        I_ST_BatchScoring__c batchScoringSettingAffiliation = I_ST_BatchScoring__c.getValues(GlobalConstants.I_RM_AFFILIATIONSCORING);
        Integer lastNHours = (Integer)batchScoringSettingAffiliation.I_ST_Last_N_Hour__c;
        Integer batchSize = (Integer)batchScoringSettingAffiliation.I_ST_BatchSize__c;
        Set<Id> newrecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringSettingAffiliation.I_ST_RecordType_SFIDs__c);
        
        Test.startTest();           
            I_RM_AffiliationScoring_Batch leadScoringBatch = new I_RM_AffiliationScoring_Batch(GlobalConstants.AFFILIATION_OBJECT_API_NAME,newrecordTypeIds,lastNHours);
            Database.executeBatch(leadScoringBatch,batchSize);
        Test.stopTest();
        
        List<I_RM_Affiliation__c> affiliationAfterBatchUpdate = new List<I_RM_Affiliation__c>();
        affiliationAfterBatchUpdate = [SELECT Id,I_RM_Score__c
                                   FROM I_RM_Affiliation__c 
                                   ];
        //Assert on Score calculated based on metadata mapping in Lead Scoring metadata. Hence asserting increment in score NOT actual score calculated as it keeps on changing
        system.assert(Integer.valueOf(affiliationAfterBatchUpdate[0].I_RM_Score__c)>0);  
    }
    
    //IST - Test method to test the scheduler - I_ST_AffiliationScoring_Batch_Scheduler2 
    @isTest
    public static void testCalculateAffiliationScoreScheduler2(){
        
        I_ST_BatchScoring__c batchScoringSettingAffiliation = I_ST_BatchScoring__c.getValues(GlobalConstants.I_RM_AFFILIATIONSCORING);
        Integer lastNHours = (Integer)batchScoringSettingAffiliation.I_ST_Last_N_Hour__c;
        Set<Id> newrecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringSettingAffiliation.I_ST_RecordType_SFIDs__c);
        
        String jobId = '';
        Test.startTest();           
            jobId  = I_RM_AffiliationScoring_Batch_Scheduler.scheduleActivityScoring();
        Test.stopTest();
      
        System.assert(String.isNotBlank(jobId));
    }
    
}