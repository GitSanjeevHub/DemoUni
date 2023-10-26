/* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_RM_ApplicantAffStatusUpdateBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
  @JIRA           LTU360-867
  @Description	  This class is used to update status field of Affiliation
   @Params	  	  <sObjectName>: Object API Name, <recordTypeIds>: Set of RecordTypeIds for Score Calculation, lastNumberOfHours: Run batch past N Hours
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-03-16      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class I_RM_ApplicantAffStatusUpdateBatchTest {
    @TestSetup
    static void makeData(){

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Status',
        I_RM_Status__c = 'Inactive');
        insert objAffiliationSettings;
        I_RM_Affiliation_Settings__c objApplicationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Application_Status',
        I_RM_Status__c = 'Alternate Offer Declined;Withdrawn;Unoffered;');                                                                                                       
        insert objApplicationSettings;
        I_RM_Affiliation_Settings__c objApplicantAffiliationBatchSettings = new I_RM_Affiliation_Settings__c( Name= 'I_RM_ApplicantAffiliationStatusBatch',
        Value__c ='oneTime'); 
        insert objApplicantAffiliationBatchSettings;
    }
    
    @isTest
    public static void testAffiliationStatus(){
         
       
        Id affiliationApplicantRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId(); 
        Account tstAccount = TestUtility.newEmptyExternalAccount('testAccount001');
        insert tstAccount;
        
        Contact cont = I_ST_UnitTestUtilities.createContactForScore('test_unique0001',
        'unique_test0001',
        'test_unique0001@unique.com',
        'test_unique0001@unique.com',        
        '3029');
        cont.I_RS_Is_Organisation_Confidential__c = false;
        insert cont;
        
        
        I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = cont.Id,
                                                                  recordTypeId = affiliationApplicantRecordTypeId,
                                                                  I_RM_Enquirer_Type__c ='Year 11',
                                                                  I_RM_Time_Frame_to_Study__c= '3-6 months',
                                                                  I_RM_Incremental_Score__c = 0,
                                                                  I_RM_Mobile_Phone__c = '0415822665',
                                                                  I_RM_Role__c ='Applicant',
                                                                  I_RM_Status__c  ='Not Processed',   
                                                                  I_RM_Score__c = 0   
                                                                 );
        insert newAffiliation;

        CourseParent__c courseParent =  new CourseParent__c(
            I_ST_ExternalId__c = '009833'
        );
        insert courseParent;

        CourseInstance__c courseInstance =  new CourseInstance__c(
            I_ST_ExternalId__c = '009833',
            L_AD_CourseParent__c = courseParent.Id
        );
        insert courseInstance;

        CourseAvailability__c courseAvailability = new CourseAvailability__c(
            I_ST_ExternalId__c = '009833',
            L_AD_CourseInstance__c = courseInstance.Id,
            I_ST_Application_Census_Date__c = system.today() + 1
        );
        insert courseAvailability;
        
          CourseAvailability__c courseAvailability2 = new CourseAvailability__c(
            I_ST_ExternalId__c = '009823',
            L_AD_CourseInstance__c = courseInstance.Id,
            I_ST_Application_Census_Date__c = system.today() - 1
        );
        insert courseAvailability2;

        List<I_ST_Application__c> listApp = New List<I_ST_Application__c>();

        I_ST_Application__c createApplication1 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability2.Id);
        createApplication1.I_RM_Affiliation__c = newAffiliation.Id;
        createApplication1.I_ST_Application_Lapsed__c = false;
        createApplication1.I_ST_Application_Status__c = 'Await required doco';
        listApp.add(createApplication1);

        I_ST_Application__c createApplication2 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication2.I_RM_Affiliation__c = newAffiliation.Id;
        createApplication2.I_ST_Application_Lapsed__c = false;
        createApplication2.I_ST_Application_Status__c = 'Conditional offer';
        listApp.add(createApplication2);
        
		insert listApp;
     
        
        Test.startTest();
        I_RM_ApplicantAffStatusUpdateBatch b = new I_RM_ApplicantAffStatusUpdateBatch();        
        database.executebatch(b,20);
        Test.stopTest();
        
        List<I_RM_Affiliation__c> updatedAffl = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where Id =: newAffiliation.id];
        System.assertEquals('Conditional Offer', updatedAffl[0].I_RM_Status__c);

    }
    
    
    @isTest
    public static void testAffiliationStatusToInactive(){
         
       
        Id affiliationApplicantRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId(); 
        Account tstAccount = TestUtility.newEmptyExternalAccount('testAccount002');
        insert tstAccount;
        
        Contact cont = I_ST_UnitTestUtilities.createContactForScore('test_unique0002',
        'unique_test0002',
        'test_unique0002@unique.com',
        'test_unique0002@unique.com',        
        '3029');
        cont.I_RS_Is_Organisation_Confidential__c = false;
        insert cont;
        
        
        I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = cont.Id,
                                                                  recordTypeId = affiliationApplicantRecordTypeId,
                                                                  I_RM_Enquirer_Type__c ='Year 11',
                                                                  I_RM_Time_Frame_to_Study__c= '3-6 months',
                                                                  I_RM_Incremental_Score__c = 0,
                                                                  I_RM_Mobile_Phone__c = '0415822665',
                                                                  I_RM_Role__c ='Applicant',
                                                                  I_RM_Status__c  ='Not Processed',   
                                                                  I_RM_Score__c = 0   
                                                                 );
        insert newAffiliation;

        CourseParent__c courseParent =  new CourseParent__c(
            I_ST_ExternalId__c = '009823'
        );
        insert courseParent;

        CourseInstance__c courseInstance =  new CourseInstance__c(
            I_ST_ExternalId__c = '009823',
            L_AD_CourseParent__c = courseParent.Id
        );
        insert courseInstance;

        CourseAvailability__c courseAvailability = new CourseAvailability__c(
            I_ST_ExternalId__c = '009823',
            L_AD_CourseInstance__c = courseInstance.Id,
            I_ST_Application_Census_Date__c = system.today() - 1
        );
        insert courseAvailability;
        
        CourseAvailability__c courseAvailability2 = new CourseAvailability__c(
            I_ST_ExternalId__c = '009820',
            L_AD_CourseInstance__c = courseInstance.Id,
            I_ST_Application_Census_Date__c = system.today() + 1
        );
        insert courseAvailability2;

        I_ST_Application__c createApplication1 = new I_ST_Application__c(
            Name = 'TestA4',
            I_ST_ExternalId__c = '009822',
            I_ST_Course_Availability__c = courseAvailability2.Id,
            I_ST_Contact__c = cont.Id,
            I_RM_Affiliation__c = newAffiliation.id,
            I_ST_Application_Status__c ='Withdrawn'
        );
       
        insert createApplication1;
        
        
        I_ST_Application__c createApplication2 = new I_ST_Application__c(
            Name = 'TestA5',
            I_ST_ExternalId__c = '009823',
            I_ST_Course_Availability__c = courseAvailability.Id,
            I_ST_Contact__c = cont.Id,
            I_RM_Affiliation__c = newAffiliation.id
        );
        
        insert createApplication2;  
       
        
        
        Test.startTest();
        I_RM_ApplicantAffStatusUpdateBatch b = new I_RM_ApplicantAffStatusUpdateBatch();        
        database.executebatch(b,20);
        Test.stopTest();
        
        List<I_RM_Affiliation__c> updatedAffl = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where Id =: newAffiliation.id];
        System.assertEquals('Inactive', updatedAffl[0].I_RM_Status__c);

    }
    
    @isTest
    public static void testForSceduler(){
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() ); 
        String ss = String.valueOf(Datetime.now().second());
        
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        test.startTest();
        I_RM_ApplicantAffStatusUpdateScheduler SC = new I_RM_ApplicantAffStatusUpdateScheduler(20); 
        Id jobId  =   system.schedule('TEST I_RM_ApplicantAffStatusUpdateBatch', nextFireTime , SC);
        test.stopTest();
        // Get the information from the CronTrigger API object
     	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(nextFireTime,ct.CronExpression);
    }

}