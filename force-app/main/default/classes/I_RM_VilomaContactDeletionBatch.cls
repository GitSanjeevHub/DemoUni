/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_RM_VilomaContactDeletionBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Kishore Reddy Basani
* @version        1.0
* @created        2022-04-28
* @Description	  This class is for to delete the contacts which does not have any related affliations
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/

global with sharing class  I_RM_VilomaContactDeletionBatch implements Database.Batchable<sObject>,Database.Stateful {
    Integer numberOfRecordsDeleted = 0;
    global Database.QueryLocator start(Database.BatchableContext bc){
        String numberOfDays = [SELECT Value__c FROM I_RM_Affiliation_Settings__c WHERE Name ='I_RM_No_of_days' limit 1].Value__c;
        Date daysToDelete = System.today() - Integer.valueOf(numberOfDays);
        String strQuery = 'SELECT Id, Name, I_RM_No_Of_Affiliation__c FROM Contact WHERE I_RM_No_Of_Affiliation__c = 0 AND CreatedDate <: daysToDelete';
        return database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<Contact> contactList) {

        List<Contact> contactsWOAffliations = new List<Contact>();
        List<Contact> contactsWOAffliationsAndPusers = new List<Contact>();
        List<User> lUsers = new List<User>();
        List<Contact> listOfContacts = [select id, (select id, I_RM_Contact__c from Affiliations__r) from Contact where id IN : contactList AND Id NOT IN (SELECT ContactId FROM Case WHERE ContactId IN : contactList)];
        for(Contact c: [select id, (select id, I_RM_Contact__c from Affiliations__r) from Contact where id IN : contactList AND Id NOT IN (SELECT ContactId FROM Case WHERE ContactId IN : contactList)]){
            if( c.Affiliations__r.size() == 0){
                contactsWOAffliations.add(c);
            }
        }
        if(contactsWOAffliations.size() > 0){
            contactsWOAffliationsAndPusers = [Select Id from Contact Where Id IN : contactsWOAffliations AND Id NOT IN (SELECT ContactId FROM User WHERE Profile.Name = 'LTU Partner Community User' AND ContactId IN :contactsWOAffliations)];
                    if(!contactsWOAffliationsAndPusers.isEmpty()){
                        try{
                            delete contactsWOAffliationsAndPusers;
                            numberOfRecordsDeleted = contactsWOAffliationsAndPusers.size();
                        }catch(Exception e){
                            Apex_Debug_Log__c debugLog = new Apex_Debug_Log__c();
                            debugLog.Apex_Class_Name__c = 'I_RM_VilomaContactDeletionBatch';
                            debugLog.Exception_Message__c = e.getMessage();
                            debugLog.Log_Type__c = 'Error';
                            debugLog.Transaction_Type__c = 'Scheduled';
                            insert debugLog;
                        }
                    }
        }
    }

    
    global void finish(Database.BatchableContext BC) {
        Apex_Debug_Log__c debugLog = new Apex_Debug_Log__c();
        debugLog.Apex_Class_Name__c = 'I_RM_VilomaContactDeletionBatch';
        debugLog.Transaction_Description__c = 'Number of contact records deleted ::' +numberOfRecordsDeleted + ' On the Date ::' + System.today();
        debugLog.Log_Type__c = 'Info';
        debugLog.Log_Type__c = 'Scheduled';
        insert debugLog;
    }
}