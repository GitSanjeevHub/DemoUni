@isTest
public class I_ST_Student_CourseTriggerHelperTest {

    @testSetup static void setup() {
        
        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
    }
    
    @isTest
    public static void testAluminiAffiliation1(){
        Test.startTest();
      
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
         I_RM_Affiliation_Settings__c objAffiliationSettings1 = I_ST_UnitTestUtilities.createEarlyEntryCourses();
        insert objAffiliationSettings1;
        
            Contact con=new Contact(FirstName='Contact',LastName='ForAlumini',I_ST_Personal_Email__c='contactforalumini@invalid.com');
        	insert con;
        	        I_RM_Affiliation__c student=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Student').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Phone__c='0412345678',
                                I_RM_Role__c='Student',I_RM_Email__c='alumini@invalid.com',
                                I_RM_Status__c='Admitted And Enrolled',I_RM_Street__c='invalid',I_RM_Suburb__c='invalid',I_RM_Mailing_Suburb__c='invalid',I_RM_Mailing_Postcode__c='3000',I_RM_Mailing_Country__c='Australia',
                                I_RM_Mailing_State__c='Melbourne',I_RM_State__c='Melbourne',I_RM_Postcode__c='3000',I_RM_Country__c='Australia',I_RM_Mailing_Street__c='invalid',I_RM_Mobile_Phone__c='0412345670',I_RM_Other_Phone__c='0412345672');
            insert student;
        CourseParent__c parentInstance = new CourseParent__c(I_ST_ExternalId__c='123456',L_AD_Course_Type_Name__c ='Test'); 
        	insert parentInstance;
        CourseInstance__c addInstance = new CourseInstance__c(L_AD_CourseParent__c=parentInstance.ID,I_ST_ExternalId__c='123458');
        	insert addInstance;
        CourseAvailability__c availableCourse = new CourseAvailability__c(L_AD_CourseInstance__c=addInstance.ID,I_ST_ExternalId__c='123876');
        	insert availableCourse;
        I_ST_Student_Course__c studentCourse = new I_ST_Student_Course__c(I_ST_Student__c=con.ID,I_RM_Affiliation__c=student.Id,I_ST_ExternalId__c='123872',I_ST_CourseAvailability__c=availableCourse.ID,I_ST_Course_Admission_Stage_Code__c='COMP',I_ST_Course_Admission_Status_Code__c='PASS');
    		insert studentCourse;
     
        List<contact> verifyContact=[select ID,I_RM_Alumni__c from contact where I_ST_Personal_Email__c='contactforalumini@invalid.com'];
       contact objUpdatedContact = verifyContact[0];
        system.assertEquals(1,objUpdatedContact.I_RM_Alumni__c,'Alumini Affiliation Created for inserted Student Course');
     Test.stopTest();
    }
    
    @isTest
    public static void testAluminiAffiliation2(){
        Test.startTest();
     
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
         I_RM_Affiliation_Settings__c objAffiliationSettings1 = I_ST_UnitTestUtilities.createEarlyEntryCourses();
        insert objAffiliationSettings1;
            Contact con=new Contact(FirstName='Contact',LastName='ForAlumini',I_ST_Personal_Email__c='contactforalumini@invalid.com');
        	insert con;
        	        I_RM_Affiliation__c student=new I_RM_Affiliation__c(RecordTypeID=Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Student').getrecordTypeId(),
            					I_RM_Contact__c=con.Id,I_RM_Phone__c='0412345678',
                                I_RM_Role__c='Student',I_RM_Email__c='alumini@invalid.com',
                                I_RM_Status__c='Admitted And Enrolled',I_RM_Street__c='invalid',I_RM_Suburb__c='invalid',I_RM_Mailing_Suburb__c='invalid',I_RM_Mailing_Postcode__c='3000',I_RM_Mailing_Country__c='Australia',
                                I_RM_Mailing_State__c='Melbourne',I_RM_State__c='Melbourne',I_RM_Postcode__c='3000',I_RM_Country__c='Australia',I_RM_Mailing_Street__c='invalid',I_RM_Mobile_Phone__c='0412345670',I_RM_Other_Phone__c='0412345672');
            insert student;
        CourseParent__c parentInstance = new CourseParent__c(I_ST_ExternalId__c='123456',L_AD_Course_Type_Name__c ='Test'); 
        	insert parentInstance;
        CourseInstance__c addInstance = new CourseInstance__c(L_AD_CourseParent__c=parentInstance.ID,I_ST_ExternalId__c='123458');
        	insert addInstance;
        CourseAvailability__c availableCourse = new CourseAvailability__c(L_AD_CourseInstance__c=addInstance.ID,I_ST_ExternalId__c='123876');
        	insert availableCourse;
        I_ST_Student_Course__c studentCourse = new I_ST_Student_Course__c(I_ST_Student__c=con.ID,I_RM_Affiliation__c=student.Id,I_ST_ExternalId__c='123872',I_ST_CourseAvailability__c=availableCourse.ID,I_ST_Course_Admission_Stage_Code__c='abc',I_ST_Course_Admission_Status_Code__c='xyz');
    		insert studentCourse;
        studentCourse.I_ST_Course_Admission_Stage_Code__c='COMP';
            studentCourse.I_ST_Course_Admission_Status_Code__c='PASS';
        update studentCourse;
   
        List<contact> verifyContact=[select ID,I_RM_Alumni__c from contact where I_ST_Personal_Email__c='contactforalumini@invalid.com'];
       contact objUpdatedContact = verifyContact[0];
        system.assertEquals(1,objUpdatedContact.I_RM_Alumni__c,'Alumini Affiliation Created for inserted Student Course');
     Test.stopTest();
    }

}