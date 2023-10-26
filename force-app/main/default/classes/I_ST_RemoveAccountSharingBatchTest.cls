@isTest
public without sharing class I_ST_RemoveAccountSharingBatchTest {
    public static testMethod void RemoveAccountSharingBatchTest() {
        List<Account> accounts = new List<Account>();
        Account a1 = new Account();
        a1.name = 'a1';
        a1.I_ST_share_with_guest__c = true;
        accounts.add(a1);

        Account a2 = new Account();
        a2.name = 'a2';
        a2.I_ST_share_with_guest__c = true;
        accounts.add(a2);

        Account a3 = new Account();
        a3.name = 'a3';
        a3.I_ST_share_with_guest__c = false;
        accounts.add(a3);

        Account a4 = new Account();
        a4.name = 'a4';
        accounts.add(a4);

        insert accounts;
        
        Test.startTest();
            I_ST_RemoveAccountSharingBatch rasb = new I_ST_RemoveAccountSharingBatch();
            System.schedule('test', '20 30 8 10 2 ?', rasb);
            Id jobId = Database.executeBatch(rasb, 10);
        Test.stopTest();

        accounts = [SELECT I_ST_Share_With_Guest__c FROM Account];
        for (Account a : accounts) {
            System.Assert(!a.I_ST_share_with_guest__c);
        }
    }
}