public without sharing class I_ST_RemoveAccountSharingBatch implements Database.Batchable<SObject>, Schedulable {
    public I_ST_RemoveAccountSharingBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Account WHERE I_ST_share_with_guest__c = TRUE';        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        for (Account acc : accounts) {
            acc.I_ST_share_with_guest__c = false;
        }
        update accounts;
    }

    public void finish(Database.BatchableContext BC) {
    }

    public void execute(SchedulableContext sc) {
        I_ST_RemoveAccountSharingBatch b = new I_ST_RemoveAccountSharingBatch(); 
        database.executebatch(b);
     }
}