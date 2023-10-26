@isTest

public class I_ST_InformationRolloverTest {

    @testSetup static void setup() {

        String recTypeIdsForAffScoring = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getRecordTypeId();
        recTypeIdsForAffScoring += ',' + Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_IL_Student_Lead_Int').getRecordTypeId();
        TestUtility.createBatchScoringCustomSettings(recTypeIdsForAffScoring);
        

        Integer remainder;

        List<I_RM_Affiliation__c> lstAffiliation= new List<I_RM_Affiliation__c>();

        List<Contact> cnt=new List<Contact>();

        ID conid;

        Id recTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Applicant').getrecordTypeId();

    	Id recTypeIdLead = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId();

        contact c=new contact();

        for(Integer i=0;i<1;i++){

                    c.FirstName = 'Test';
                    c.LastName = 'Tset';
                    c.Email = c.FirstName + '@' + c.LastName + '.com';
                    c.I_ST_Personal_Email__c = c.Email;
                    c.MobilePhone = '04473' + String.valueOf(i).leftPad(5, '0');
                   // c.RecordTypeId = '0124a0000004NL9AAM';
                    cnt.add(c);
        }
        insert cnt;

      //  list<string> parentaccount=new list<string>([select id from contact where name='Test Tset']);

        for(contact ct :([select id from contact where name='Test tset'])){
            conid=ct.id;
        }

        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;


        for(Integer i=0 ;i <1;i++){
            

            I_RM_Affiliation__c con = new I_RM_Affiliation__c();
            remainder = math.mod(i,3);           

            con.I_RM_Contact__c = conid;

            con.RecordTypeId = recTypeId;           

            if(remainder == 0){

                //Values should be rolled over

                con.I_RM_Enquirer_Type__c = 'Year 10';

                con.I_RM_Time_Frame_to_Study__c = '3+ years';

            } else if(remainder == 1){

                //Only Enquirer Type should be rolled over

                con.I_RM_Enquirer_Type__c = 'Year 10';

                con.I_RM_Time_Frame_to_Study__c = null;

            } else{

                //Values should be not considered

                con.I_RM_Enquirer_Type__c = 'Other';

                con.I_RM_Time_Frame_to_Study__c = 'Unsure';

            }

            lstAffiliation.add(con);

        }

        insert lstAffiliation;        

    }

    static testMethod void testInformationRolloverBatch() {

        Integer batchSize = 10;

        List<I_RM_Affiliation__c> preRollover10s = [Select Id From I_RM_Affiliation__c Where I_RM_Enquirer_Type__c = 'Year 10'];

        List<I_RM_Affiliation__c> preRolloverNulls = [Select Id From I_RM_Affiliation__c Where I_RM_Time_Frame_to_Study__c = null];

        List<I_RM_Affiliation__c> preRolloverUnqualifieds = [Select Id From I_RM_Affiliation__c Where I_RM_Time_Frame_to_Study__c = 'Unsure' AND I_RM_Enquirer_Type__c = 'Other'];

        

        Test.startTest();

        

        String hour = String.valueOf(Datetime.now().hour());

        String min = String.valueOf(Datetime.now().minute() ); 

        String ss = String.valueOf(Datetime.now().second() + 2);

        

        //parse to cron expression

        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

        

        System.schedule('Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, new I_ST_InformationRolloverBatchScheduler(batchSize));

        

        I_ST_InformationRolloverBatch obj = new I_ST_InformationRolloverBatch();

        DataBase.executeBatch(obj); 

        Test.stopTest();

        

        List<I_RM_Affiliation__c> postRollover10s = [Select Id From I_RM_Affiliation__c Where I_RM_Enquirer_Type__c = 'Year 11'];

        List<I_RM_Affiliation__c> postRolloverNulls = [Select Id From I_RM_Affiliation__c Where I_RM_Time_Frame_to_Study__c = null];

        List<I_RM_Affiliation__c> postRolloverUnqualifieds = [Select Id From I_RM_Affiliation__c Where I_RM_Time_Frame_to_Study__c = 'Unsure' AND I_RM_Enquirer_Type__c = 'Other'];

        

        System.assertEquals(preRollover10s.size(), postRollover10s.size());

        System.assertEquals(preRolloverNulls.size(), postRolloverNulls.size());

        System.assertEquals(preRolloverUnqualifieds.size(), postRolloverUnqualifieds.size());

    }

}