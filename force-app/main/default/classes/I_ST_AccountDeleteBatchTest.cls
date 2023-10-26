/* created by : IST Team On 05-11-2020*/

@isTest
private class I_ST_AccountDeleteBatchTest{
    
    static testmethod void accountRecordForBatch() {
        
        // Create test accounts to be deleted
        // by the batch job.
        RecordType objrt = [select id from RecordType where sObjectType='Account' and DeveloperName='I_ST_Lead_Account'];
        List<Account> accList = new List<Account>();
        for (Integer i=0; i<200; i++) {
            Account m = new Account(Name = 'Account ' + i, RecordTypeId=objrt.Id);
            accList.add(m);
        }
        insert accList;
        Test.startTest();
        I_ST_AccountDeleteBatch objIstAcc = new I_ST_AccountDeleteBatch();
        Database.executeBatch(objIstAcc );
        Test.stopTest();
        
    }
    static testmethod void checkAccountCase() {
        
        I_RM_Affiliation_Settings__c objAffiliationSettings = I_ST_UnitTestUtilities.createAffiliationSettings();
        insert objAffiliationSettings;
        
        RecordType objrt = [select id from RecordType where sObjectType='Account' and DeveloperName='I_ST_Lead_Account'];
        
        List<Account> accList = new List<Account>();
        for (Integer i=0; i<200; i++) {
            Account m = new Account(Name = 'Account ' + i, RecordTypeId=objrt.Id);
            accList.add(m);
        }
        
        insert accList;
        
        Case cs = new Case(status='Open', Priority='Normal', accountid=accList[0].id);
        Insert cs;
        
        Test.startTest();
        //I_ST_AccountDeleteBatch objIstAcc = new I_ST_AccountDeleteBatch();
        //Database.executeBatch(objIstAcc );
        
        //SchedulableContext sc = null;
        //I_ST_AccountDeleteBatchSchedule objAsc = new I_ST_AccountDeleteBatchSchedule();
        // objAsc.execute(sc);
        
        I_ST_AccountDeleteBatchSchedule BWE = new I_ST_AccountDeleteBatchSchedule ();
        String sch = '0 15 17 ? * SUN';
        system.schedule('Execute Schedular', sch, BWE);
        
        Test.stopTest();
    }
}