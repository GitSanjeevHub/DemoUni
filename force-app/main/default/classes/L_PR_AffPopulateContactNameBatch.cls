/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* L_PR_AffPopulateContactNameBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vanita Walia
* @version        1.0
* @created        08-09-2022
* @Description	  This batch class is to populate the contact name on affiliations
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/

public  without sharing class L_PR_AffPopulateContactNameBatch implements Database.Batchable<sObject>, Database.Stateful{

    Integer numberOfRecordsUpdated = 0;
    public Database.QueryLocator start(Database.BatchableContext bc){

        String strQuery = 'SELECT Id, I_RM_Contact__c, I_RM_Affiliation_Contact_Name__c, L_PR_Contact_Name__c from I_RM_Affiliation__c where L_PR_Contact_Name__c = null';
        return database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<I_RM_Affiliation__c> affList) {

        List<I_RM_Affiliation__c> affListToBeUpdated = New List<I_RM_Affiliation__c>();

        for(I_RM_Affiliation__c aff : affList){
            I_RM_Affiliation__c newAff = New I_RM_Affiliation__c();
            if(aff.I_RM_Contact__c != Null && aff.I_RM_Affiliation_Contact_Name__c !='' && aff.L_PR_Contact_Name__c == null){
                newAff.Id = aff.Id;
                newAff.L_PR_Contact_Name__c = aff.I_RM_Affiliation_Contact_Name__c;
                numberOfRecordsUpdated++;
            }
            affListToBeUpdated.add(newAff);
        }

        if(!affListToBeUpdated.isEmpty()){
            update affListToBeUpdated;
        }
    }

    public void finish(Database.BatchableContext bc){
        Apex_Debug_Log__c debugLog = new Apex_Debug_Log__c();
        debugLog.Apex_Class_Name__c = 'L_PR_AffPopulateContactNameBatch';
        debugLog.Transaction_Description__c = 'Number of affiliation records updated::' +numberOfRecordsUpdated + ' On the Date ::' + System.today();
        debugLog.Log_Type__c = 'Info';
        debugLog.Log_Type__c = 'Batch';
        insert debugLog;
    }

}