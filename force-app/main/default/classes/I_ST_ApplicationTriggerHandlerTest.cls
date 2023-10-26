@isTest
public class I_ST_ApplicationTriggerHandlerTest{

    @TestSetup
    static void makeData(){

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        
       // create inactive affiliation status custom setting record
        I_RM_Affiliation_Settings__c objAffiliationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Status',I_RM_Status__c = 'Inactive');
        insert objAffiliationSettings;
        // create inactive application status custom setting record
        I_RM_Affiliation_Settings__c objApplicationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Application_Status',I_RM_Status__c = 'Alternate Offer Declined;Withdrawn;Unoffered;');
        insert objApplicationSettings;  
        //create courseParent record, courseInstance record and courseAvailability record which is mandatory for creating application
        CourseParent__c courseParent =  I_ST_UnitTestUtilities.createCourseParent();
        insert courseParent;
        CourseInstance__c courseInstance = I_ST_UnitTestUtilities.createCourseInstance(courseParent.Id);
        insert courseInstance;
        CourseAvailability__c courseAvailability = I_ST_UnitTestUtilities.createCourseAvailability(courseInstance.Id);
        insert courseAvailability;
        // Fetch the applicant affiliation recordtype Id
        Id affiliationApplicantRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId(); 
       
        //create test contact
        Contact con = I_ST_UnitTestUtilities.createContactForScore('testuser1','lastname1','testuser1@test.com','testuser1@test.com','3000');
        con.I_RS_Is_Organisation_Confidential__c = false;
        insert con;
        //create applicant affiliation
        List<I_RM_Affiliation__c> applicantAff = I_ST_UnitTestUtilities.createApplicantAffiliationRecords(affiliationApplicantRecordTypeId,con.Id);
        insert applicantAff;
    }


    @isTest
    public static void updateAffiliationStatusTest(){

        Test.startTest();
        Contact cont =[Select Id from Contact];
        List<I_RM_Affiliation__c> lstAffiliation = [Select Id from I_RM_Affiliation__c];
        CourseAvailability__c courseAvailability = [Select Id from CourseAvailability__c];
        I_ST_Application__c createApplication1 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication1.I_RM_Affiliation__c = lstAffiliation[0].Id;
        createApplication1.I_ST_Application_Status__c = 'Await required doco';
        insert createApplication1;
        I_ST_Application__c createApplication2 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication2.I_RM_Affiliation__c = lstAffiliation[0].Id;
        createApplication2.I_ST_Application_Status__c = 'Conditional offer';
        insert createApplication2;
        I_ST_Application__c createApplication3 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication3.I_RM_Affiliation__c = lstAffiliation[0].Id;
        createApplication3.I_ST_Application_Status__c = 'Offered';
        insert createApplication3;
        List<I_RM_Affiliation__c> updatedAffl = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where Id =: lstAffiliation[0].Id];
        System.assertEquals('Offer', updatedAffl[0].I_RM_Status__c);
        
        Test.stopTest();

    }
    
    @isTest
    public static void updateAffiliationStatusUnknownStatusTest(){
        
        Test.startTest();
        Contact cont =[Select Id from Contact];
        List<I_RM_Affiliation__c> lstAffiliation = [Select Id from I_RM_Affiliation__c];
        CourseAvailability__c courseAvailability = [Select Id from CourseAvailability__c];
        I_ST_Application__c createApplication1 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication1.I_RM_Affiliation__c = lstAffiliation[0].Id;
        insert createApplication1;
        I_ST_Application__c createApplication2 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication2.I_RM_Affiliation__c = lstAffiliation[0].Id;
        insert createApplication2;
        I_ST_Application__c createApplication3 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication3.I_RM_Affiliation__c = lstAffiliation[0].Id;
        insert createApplication3;
        List<I_RM_Affiliation__c> updatedAffl = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where Id =: lstAffiliation[0].Id];
        System.assertEquals('Unknown status', updatedAffl[0].I_RM_Status__c);
        Test.stopTest();

    }
    
    @isTest
    public static void updateAffiliationStatusCatchTest(){
        
        Test.startTest();
        Map<Id, List<I_ST_Application__c>> affAppListMap = new Map<Id, List<I_ST_Application__c>>();
        List<I_ST_Application__c> listApp = New List<I_ST_Application__c>();
        Contact cont =[Select Id from Contact];
        List<I_RM_Affiliation__c> lstAffiliation = [Select Id from I_RM_Affiliation__c];
        CourseAvailability__c courseAvailability = [Select Id from CourseAvailability__c];
        I_ST_Application__c createApplication1 = I_ST_UnitTestUtilities.createApplication(cont.Id, courseAvailability.Id);
        createApplication1.I_RM_Affiliation__c = lstAffiliation[0].Id;
        listApp.add(createApplication1);
        
        affAppListMap.put(cont.id, listApp);
        try{
        	I_ST_ApplicationTriggerHelper.updateAffiliationStatus(affAppListMap);
        }catch(Exception e){
             System.debug ('Exception'+e);
        }
        
                Test.stopTest();
    }
    
    /*  @author 		Vanita Walia
     * @date  			23/03/2022
     * @description 	LTU360-1324 : Method to test updateaffiliationtoInactive method
     */
	@isTest
    public static void updateAffiliationtoInactiveTest(){
        Test.startTest();
        
        Contact con =[Select Id from Contact];
        List<I_RM_Affiliation__c> applicantAff = [Select Id from I_RM_Affiliation__c];
        
	CourseAvailability__c courseAvailability = [Select Id from CourseAvailability__c];

        I_ST_Application__c app1 = I_ST_UnitTestUtilities.createApplication(con.Id, courseAvailability.Id);
        app1.I_RM_Affiliation__c = applicantAff[0].Id;
        app1.I_ST_Application_Status__c = 'Withdrawn';
        insert app1;
        
        I_ST_Application__c app2 = I_ST_UnitTestUtilities.createApplication(con.Id, courseAvailability.Id);
        app2.I_RM_Affiliation__c = applicantAff[0].Id;
        app2.I_ST_Application_Lapsed__c = false;
        insert app2;
        
        app2.I_ST_Application_Lapsed__c = true;
        I_ST_ApplicationTriggerHandler.FirstRun = false;
        update app2;
        
        List<I_RM_Affiliation__c> updatedAffl = [Select Id, I_RM_Status__c from I_RM_Affiliation__c where Id =: applicantAff[0].Id];
        System.assertEquals('Inactive', updatedAffl[0].I_RM_Status__c);

    }
    
    /*  @author 		Vanita Walia
     * @date  			30/03/2022
     * @description 	LTU360-1324 : Method to cover catch block of applicationtrigger handler class
     */
	@isTest
    public static void updateAffiliationtoInactive_CatchTest1(){
		Test.startTest();
        
        Contact con =[Select Id from Contact];
        List<I_RM_Affiliation__c> applicantAff = [Select Id from I_RM_Affiliation__c];
       
        CourseAvailability__c courseAvailability = [Select Id from CourseAvailability__c];
        
		//delete the custom setting record so that it cause exception in handler class
        I_RM_Affiliation_Settings__c af = [Select Id from I_RM_Affiliation_Settings__c where Name='I_RM_Inactive_Application_Status'];
        delete af;
        try{
        	I_ST_Application__c app1 = I_ST_UnitTestUtilities.createApplication(con.Id,courseAvailability.Id);
        	app1.I_RM_Affiliation__c = applicantAff[0].Id;
        	app1.I_ST_Application_Status__c = 'Withdrawn';
        	insert app1;
        }
        Catch(exception e){
            System.debug ('Exception'+e);
        }
       test.stopTest();
       
        Apex_Debug_Log__c err = [SELECT Id,Apex_Class_Method_Name__c FROM Apex_Debug_Log__c WHERE Apex_Class_Name__c = 'I_ST_ApplicationTriggerHandler' AND Apex_Class_Method_Name__c = 'execute Method' Limit 1];       
        system.assertNotEquals('', err.Apex_Class_Method_Name__c);
        
    }
    /*  @author 		Vanita Walia
     * @date  			30/03/2022
     * @description 	LTU360-1324 : Method to do code coverage for catch block in application trigger helper class
     */
	@isTest
    public static void updateAffiliationtoInactive_CatchTest2(){
		test.startTest();
        try{
           I_ST_ApplicationTriggerHelper.updateAffiliationToInactive(Null);
        }
        Catch(Exception e){
            System.debug ('Exception'+e);
        }
        test.stopTest();
        Apex_Debug_Log__c err = [SELECT Id,Apex_Class_Method_Name__c FROM Apex_Debug_Log__c WHERE Apex_Class_Name__c = 'I_ST_ApplicationTriggerHelper' AND Apex_Class_Method_Name__c = 'updateAffiliationToInactive' Limit 1];       
        system.assertNotEquals('', err.Apex_Class_Method_Name__c);
    }
    
}