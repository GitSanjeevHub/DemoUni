/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_InteractionScoringBatchTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-02-18      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class I_ST_InteractionScoringBatchTest{
    @TestSetup
    static void setup() {
        
        String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);  
        String interactionRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.INTERACTION_OBJECT_API_NAME,GlobalConstants.INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION);
        String affiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
        
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypIds,20,caseRecordTypeIds,20,interactionRecordTypeIds,20);           
        insert listBatchScoringSetting;
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
        Profile integrationUserRec = [SELECT Id FROM Profile WHERE Name='LTU Integration']; 
        User integrationUser = I_ST_UnitTestUtilities.newUser('interactionUser',integrationUserRec.Id);
        
        Id interactionRecordTypeId = Schema.SObjectType.I_ST_Interaction__c.getRecordTypeInfosByDeveloperName().get('I_ST_Lead_Interaction').getRecordTypeId();        
        Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        
        List<Contact> contactsforTest = new List<Contact>();
        
        for(Integer i =0; i<10; i++){
            Contact newDomesticLead = I_ST_UnitTestUtilities.createContactForScore('test_unique001'+i,
                                                                                   'unique_test001'+i,
                                                                                   'test_unique001'+i+'@unique.com',
                                                                                   'test_unique001'+i+'@unique.com',                                                                                   
                                                                                   '3029'); 
                                                                                         
            contactsforTest.add(newDomesticLead);
        }
        Insert contactsforTest;
        
        List<I_RM_Affiliation__c> testAffiliation = I_ST_UnitTestUtilities.createAffiliationRecords(affiliationDomesticLeadRecordTypeId,contactsforTest[0].Id);
        insert testAffiliation;
         system.debug('testAffiliation'+testAffiliation);
              
        
        //system.runAs(integrationUser){
            //Insert batch of Interactions
            List<I_ST_Interaction__c> interactionsforTest = new List<I_ST_Interaction__c>();
            for(Integer j=0; j<contactsforTest.size(); j++) {
                I_ST_Interaction__c newinteraction =  I_ST_UnitTestUtilities.newListOfContactRelatedInteractions(interactionRecordTypeId,contactsforTest[j],'FirstTest'+j,'LastTest'+j,'039948757',
                                                                                                                                                              'testInteractionEmail'+j+'@test.com','Web','Keep in touch form', testAffiliation[0]);
                //newinteraction.I_RM_Affiliation__c= testAffiliation.Id;
                interactionsforTest.add(newinteraction);
            }
            Insert interactionsforTest;     
       // }   
        
    }
    
    //IST - Test method to test the scheduler - I_ST_Interaction_Scoring_Batch_Scheduler 
    @isTest
    public static void testInteractionScoringScheduler(){
        
        I_ST_BatchScoring__c batchScoringSettingInteraction = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_INTERACTIONSCORING);
        Integer lastNHours = (Integer)batchScoringSettingInteraction.I_ST_Last_N_Hour__c;
        Set<Id> newrecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringSettingInteraction.I_ST_RecordType_SFIDs__c);
        
        String jobId = '';
        Test.startTest();           
          jobId  = I_ST_InteractionScoring_Batch_Scheduler.scheduleActivityScoring();
        Test.stopTest();       
        System.assert(String.isNotBlank(jobId));
    }
    
    //IST - Test method to test the execution of batch class - I_ST_InteractionScoring_Batch - Positive Test
    @isTest
    public static void testInteractionScoringBatch(){
        
        List<String> contactIdsForInteractions = new List<String>();
        for(I_ST_Interaction__c interaction: [SELECT id,
                                              I_ST_Contact__c,
                                              I_RM_Affiliation__c,
                                              I_ST_Interaction__c.I_RM_Affiliation__r.I_RM_Incremental_Score__c,
                                              I_ST_Incremental_Score__c 
                                              FROM I_ST_Interaction__c
                                              WHERE I_ST_Email__c = 'testInteractionEmail1@test.com' 
                                              LIMIT 1]) {     
                                                  System.assertEquals(0,interaction.I_RM_Affiliation__r.I_RM_Incremental_Score__c);
                                                  contactIdsForInteractions.add(interaction.I_RM_Affiliation__c);
                                              }
        
        
        I_ST_BatchScoring__c batchScoringSettingInteraction = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_INTERACTIONSCORING);
        Integer lastNHours = (Integer)batchScoringSettingInteraction.I_ST_Last_N_Hour__c;
        Integer batchSize = (Integer)batchScoringSettingInteraction.I_ST_BatchSize__c;
        Set<Id> newrecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringSettingInteraction.I_ST_RecordType_SFIDs__c);
        
        Test.startTest();           
            I_ST_InteractionScoring_Batch leadScoringBatch = new I_ST_InteractionScoring_Batch(GlobalConstants.INTERACTION_OBJECT_API_NAME,newrecordTypeIds,lastNHours);
            Database.executeBatch(leadScoringBatch,batchSize);
        Test.stopTest();
        
        List<I_RM_Affiliation__c> affAfterBatchUpdate = new List<I_RM_Affiliation__c>();
        affAfterBatchUpdate = [SELECT Id,I_RM_Incremental_Score__c FROM I_RM_Affiliation__c WHERE id =: contactIdsForInteractions[0] LIMIT 1];
        //Assert on Score calculated based on metadata mapping in Lead Scoring metadata. Hence asserting increment in score NOT actual score calculated as it keeps on changing
        system.assert(Integer.valueOf(affAfterBatchUpdate[0].I_RM_Incremental_Score__c)>0);  
    } 
}