/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_ActivityScoring_BatchTest
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
public class I_ST_ActivityScoring_BatchTest{ 
    @TestSetup
    static void setup() {
        String affiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
        String caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);  
        String interactionRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.INTERACTION_OBJECT_API_NAME,GlobalConstants.INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION);
        
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypIds,20,caseRecordTypeIds,20,interactionRecordTypeIds,20);           
        insert listBatchScoringSetting;  
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Enquiry').getRecordTypeId();        
        Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        
        List<I_RM_Affiliation__c> listLeadAffiliations = new List<I_RM_Affiliation__c>();
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
        
       /* List<I_RM_Affiliation__c> lstAffiliations = new List<I_RM_Affiliation__c>();
         for(Integer j=0; j<listDomesticLeadContacts.size(); j++) {
        	listLeadAffiliations = I_ST_UnitTestUtilities.createAffiliationRecords(affiliationDomesticLeadRecordTypeId,listDomesticLeadContacts[j].Id);
         	lstAffiliations.addAll(listLeadAffiliations);
         }
        insert lstAffiliations;*/
        
        //Insert first batch of 10 cases - 1 for each Contact 
        List<Case> casesListForScoreTestBatch1 = New List<Case>();
        for(Integer j=0; j<listDomesticLeadContacts.size(); j++) {
            case newcase =  I_ST_UnitTestUtilities.newListOfContactRelatedCases(caseRecordTypeId,listDomesticLeadContacts[j],10,false,'Title First'+j,'Open','test_uniquee001'+j+'@unique.com', null);           
            casesListForScoreTestBatch1.add(newcase);
        } 
        insert casesListForScoreTestBatch1;
        
        //Insert second batch of 10 cases - 1 for each Contact
        /*List<Case> casesListForScoreTestBatch2 = New List<Case>();
        for(Integer k=0; k<listDomesticLeadContacts.size(); k++) {
            case newcase =  I_ST_UnitTestUtilities.newListOfContactRelatedCases(caseRecordTypeId,listDomesticLeadContacts[k],20,false,'Title Second'+k,'Open', listLeadAffiliations[0]);         
            casesListForScoreTestBatch2.add(newcase);
        }
        Insert casesListForScoreTestBatch2;*/
    }
    
    
    //IST - Test method to test the scheduler - I_ST_ActivityScoring_Batch_Scheduler2 
    @isTest
    public static void testActivityScoreScheduler2(){
        
        I_ST_BatchScoring__c batchScoringSettingCase = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_CASESCORING);
        Integer lastNHours = (Integer)batchScoringSettingCase.I_ST_Last_N_Hour__c;
        Set<Id> newrecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringSettingCase.I_ST_RecordType_SFIDs__c);
        
        String jobId = '';
        Test.startTest();           
        jobId  = I_ST_ActivityScoring_Batch_Scheduler.scheduleActivityScoring();
        Test.stopTest();     
        System.assert(String.isNotBlank(jobId));
    }
    
    //IST - Test method to test the execution of batch class - I_ST_ActivityScoring_Batch2 - Positive Test
    @isTest
    public static void testCalculateActivityScoreBatch2(){
        
        List<String> contactIdsForCases = new List<String>();
        for(Case cs: [Select Subject,I_ST_Study_Interest__c,I_ST_Score_Calculated__c,I_ST_Incremental_Score__c,
                     I_RM_Affiliation__c,I_RM_Affiliation__r.I_RM_Incremental_Score__c,
                      ContactId 
                      FROM Case 
                      WHERE I_RM_Affiliation__c != null 
                      AND I_ST_Score_Calculated__c = false
                      AND (Subject LIKE 'Title First%'
                      OR Subject LIKE 'Title Second%')
                      ]) {
                          System.debug('** cs.I_RM_Affiliation__c >> '+cs.I_RM_Affiliation__c);                         
                          contactIdsForCases.add(cs.ContactId);
                      }
        List<I_RM_Affiliation__c> affiliationAfterBatchUpdate = new List<I_RM_Affiliation__c>();
      
        I_ST_BatchScoring__c batchScoringSettingCase = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_CASESCORING);
        Integer lastNHours = (Integer)batchScoringSettingCase.I_ST_Last_N_Hour__c;
        Integer batchSize = (Integer)batchScoringSettingCase.I_ST_BatchSize__c;
        Set<Id> newrecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringSettingCase.I_ST_RecordType_SFIDs__c);
        
        Test.startTest();            
            I_ST_ActivityScoring_Batch leadScoringBatch = new I_ST_ActivityScoring_Batch(GlobalConstants.CASE_OBJECT_API_NAME,newrecordTypeIds,lastNHours);
            Database.executeBatch(leadScoringBatch,batchSize);        
        Test.stopTest();
        
        affiliationAfterBatchUpdate = [SELECT Id,I_RM_Contact__c,I_RM_Incremental_Score__c FROM I_RM_Affiliation__c WHERE I_RM_Contact__c =:contactIdsForCases];
        system.debug('outsideaffiliationAfterBatchUpdate:'+affiliationAfterBatchUpdate);
        //Assert on Score calculated based on metadata mapping in Lead Scoring metadata. Hence asserting increment in score NOT actual score calculated as it keeps on changing
        system.assert(Integer.valueOf(affiliationAfterBatchUpdate[1].I_RM_Incremental_Score__c)>0);  
       
    }
}