/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_InteractionTriggerHandlerTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2021-09-07
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2021-09-07      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class I_ST_InteractionTriggerHandlerTest {
    @TestSetup
    static void setup() {
        
         string affiliationRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.AFFILIATION_OBJECT_API_NAME,GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD);
        String interactionRecordTypeIds = I_ST_UnitTestUtilities.recordTypeIds(GlobalConstants.INTERACTION_OBJECT_API_NAME,GlobalConstants.INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION);
        Integer NumberOfInteractions = 50;
        
        List<I_ST_BatchScoring__c> listBatchScoringSetting = I_ST_UnitTestUtilities.createBatchScoringCustomSetting(affiliationRecordTypeIds,20,null,null,interactionRecordTypeIds,20);           
        insert listBatchScoringSetting;
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
        
        Id interactionRecordTypeId =  I_ST_BatchScoring__c.getValues('I_ST_InteractionScoring').I_ST_RecordType_SFIDs__c.split(',')[0];
        
        I_ST_InteractionTriggerHandler.setNotFired();
        //Id contactDomesticLeadRecordTypeId =  I_ST_BatchScoring__c.getValues('I_ST_ContactScoring').I_ST_RecordType_SFIDs__c.split(',')[0];
        Id affiliationDomesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        List<Contact> contactsforTest = new List<Contact>();
        
        for(Integer i =0; i<10; i++){
            Contact newDomesticLead = I_ST_UnitTestUtilities.createContactForScore(
                                                                                   'test_unique001'+i,
                                                                                   'unique_test001'+i,
                                                                                   'test_unique001'+i+'@unique.com',
                                                                                   'test_unique001'+i+'@unique.com',                                                                                  
                                                                                   '3029');
                                                                                          
            contactsforTest.add(newDomesticLead);
        }
        Insert contactsforTest;
        
         I_RM_Affiliation__c testAffiliation= I_ST_UnitTestUtilities.createAffiliationRecords(affiliationDomesticLeadRecordTypeId,contactsforTest[0].Id)[0];
        insert testAffiliation;
        
        //Insert batch of Interactions
        List<I_ST_Interaction__c> interactionsforTest = new List<I_ST_Interaction__c>();
        for(Integer j=0; j<contactsforTest.size(); j++) {
            I_ST_Interaction__c newinteraction =  I_ST_UnitTestUtilities.newListOfContactRelatedInteractions(interactionRecordTypeId,contactsforTest[j],'FirstTest'+j,'LastTest'+j,'039948757',
                                                                                                             'testInteractionEmail'+j+'@test.com','Web','Keep in touch form',testAffiliation);
             newinteraction.I_RM_Affiliation__c= testAffiliation.Id;
            interactionsforTest.add(newinteraction);
        }
        Insert interactionsforTest;
        
    }
    
    //Test incremental score on update interaction
    @isTest
    public static void testUpdateInteraction(){
        
        Test.startTest();    	
           Contact domesticContact = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE email = 'test_unique0011@unique.com' LIMIT 1];
           List<I_ST_Interaction__c> interactionToProcess = [SELECT id,I_ST_FirstName__c,I_ST_Last_Name__c,I_ST_Mobile__c,
                                                          I_ST_Email__c, I_ST_Source_Category__c,I_ST_Source_Sub_Category__c,
                                                          I_ST_Contact__c,I_ST_Incremental_Score__c FROM I_ST_Interaction__c WHERE I_ST_Contact__c =: domesticContact.Id];             
        
          I_ST_Interaction__c interactionToUpdate = new I_ST_Interaction__c();
          interactionToUpdate.id = interactionToProcess[0].id;        
          interactionToUpdate.I_ST_Mobile__c = '0390480757';
          I_ST_InteractionTriggerHandler.setNotFired();
          update interactionToUpdate;
          I_ST_InteractionTriggerHandler.hasFired();
        Test.stopTest();
        
        system.assertEquals(5,interactionToProcess[0].I_ST_Incremental_Score__c);
    }
    
}