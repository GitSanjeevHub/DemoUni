/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_IncrementalScoreContactRelObjTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-02-18     Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class I_ST_IncrementalScoreContactRelObjTest {
    @TestSetup
    static void setup() {
        Profile saceUserProfile = [SELECT Id FROM Profile WHERE Name='SACE User'];
        Id CaseRecordTypeId = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where sobjectType = 'Case' and Name = 'Enquiry'].Id;
        User saceuser;
        saceuser = new User(Alias = 'saceuser', Email='saceuser@test.com.test', 
            EmailEncodingKey='UTF-8', LastName='saceuserTest', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = saceUserProfile.Id,
            TimeZoneSidKey='Australia/Sydney', UserName='saceuser@test.com.test');
        insert saceuser;
        
        String affiliationRecordTypIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);        
       string caseRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.CASE_OBJECT_API_NAME,GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY);

        List<I_ST_BatchScoring__c> batchScoringSettings = new List<I_ST_BatchScoring__c>();
        List<I_ST_BatchScoring__c> listContactBatchScoringSetting =  I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypIds,20,null,null,null,null);
        List<I_ST_BatchScoring__c> listCaseBatchScoringSetting =  I_ST_UnitTestUtilities.createBatchScoringCustomSetting(null,null,caseRecordTypeIds,20,null,null);
        
        
        batchScoringSettings.addAll(listContactBatchScoringSetting);
        batchScoringSettings.addAll(listCaseBatchScoringSetting);
        insert batchScoringSettings;
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
       
        
        I_ST_CaseTriggerHandler.setNotFired();
      
       
         Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        
        List<Contact> listDomesticLeadContacts = new List<Contact>();
        for(Integer i =0; i<10; i++){
            Contact newDomesticLead = I_ST_UnitTestUtilities.createContactForScore('test_unique001'+i,
                                                                                   'unique_test001'+i,
                                                                                   'test_unique001'+i+'@unique.com',
                                                                                   'test_unique001'+i+'@unique.com',                                                                                  
                                                                                   '3029');
                                                                                           
            listDomesticLeadContacts.add(newDomesticLead);
        }
        Insert listDomesticLeadContacts;
        /*I_RM_Affiliation__c testAffiliation= I_ST_UnitTestUtilities.createAffiliationRecords(affiliationDomesticLeadRecordTypeId,listDomesticLeadContacts[0].Id)[0];
        insert testAffiliation;*/
            
        //Insert first batch of 10 cases - 1 for each Contact
        List<Case> casesListForScoreTestBatch1 = New List<Case>();
        for(Integer j=0; j<listDomesticLeadContacts.size(); j++) {
            case newcase =  I_ST_UnitTestUtilities.newListOfContactRelatedCases(CaseRecordTypeId,listDomesticLeadContacts[j],10,false,'Title First'+j,'Open','test_uniquee001'+j+'@unique.com',null);          
            casesListForScoreTestBatch1.add(newcase);
        }
        Insert casesListForScoreTestBatch1;
        
        //Insert second batch of 10 cases - 1 for each Contact
        List<Case> casesListForScoreTestBatch2 = New List<Case>();
        for(Integer k=0; k<listDomesticLeadContacts.size(); k++) {
            case newcase =  I_ST_UnitTestUtilities.newListOfContactRelatedCases(CaseRecordTypeId,listDomesticLeadContacts[k],20,false,'Title Second'+k,'Open','test_uniquee001'+k+'@uniquee.com',null);            
            casesListForScoreTestBatch2.add(newcase);
        }
        Insert casesListForScoreTestBatch2;     
    }
    
    @isTest
    public static void testCalculateIncrementScore(){
        
        Test.startTest();        
        
           Contact domesticContact = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE email = 'test_unique0011@unique.com' LIMIT 1];
           List<Case> caseToProcess = [SELECT Id,Subject,Type,RecordTypeId,Origin,Status,ContactId,I_ST_Incremental_Score__c FROM case WHERE ContactId =: domesticContact.Id];             
        
           case caseToUpdate = new case();
           caseToUpdate.id = caseToProcess[0].id;        
           caseToUpdate.Origin = 'Evolve';
           I_ST_CaseTriggerHandler.setNotFired();      
           update caseToUpdate;
        
           I_ST_CaseTriggerHandler.hasFired();
        Test.stopTest();
          system.assertEquals(20,caseToProcess[0].I_ST_Incremental_Score__c);
    }
     
}