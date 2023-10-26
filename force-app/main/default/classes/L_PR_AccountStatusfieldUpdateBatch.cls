/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* L_PR_AccountStatusfieldUpdateBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Kishore Reddy Basani
* @version        1.0
* @created        05-08-2022
* @Description	  This batch class is to update the status field of the Organisation to active if it is NULL or Proposed
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/

public  without sharing class L_PR_AccountStatusfieldUpdateBatch implements Database.Batchable<sObject>, Database.Stateful{

    Integer numberOfRecordsUpdated = 0;
    public Database.QueryLocator start(Database.BatchableContext bc){

        String strQuery = 'SELECT Id, Name, I_RS_Status__c from account where I_RS_Status__c= \'Proposed\' OR I_RS_Status__c = null';
        return database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<Account> accountList) {

        List<Account> accountListToBeUpdated = New List<Account>();

        for(Account acc : accountList){
            Account acct = New Account();
            if(acc.I_RS_Status__c == 'Proposed' || acc.I_RS_Status__c == null){
                acct.Id = acc.Id;
                acct.I_RS_Status__c = 'Active';
                numberOfRecordsUpdated++;
            }
            accountListToBeUpdated.add(acct);
        }

        if(!accountListToBeUpdated.isEmpty()){
            update accountListToBeUpdated;
        }
    }

    public void finish(Database.BatchableContext bc){
        Apex_Debug_Log__c debugLog = new Apex_Debug_Log__c();
        debugLog.Apex_Class_Name__c = 'L_PR_AccountStatusfieldUpdateBatch';
        debugLog.Transaction_Description__c = 'Number of account status records updated::' +numberOfRecordsUpdated + ' On the Date ::' + System.today();
        debugLog.Log_Type__c = 'Info';
        debugLog.Log_Type__c = 'Batch';
        insert debugLog;
    }

}