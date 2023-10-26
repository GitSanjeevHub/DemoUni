/**
 * Handler class for the Related_ContractTrigger trigger
 */

public without sharing class RelatedContractTriggerHandler{

    public static void execute(){

        //LTU360-2384
        List<Related_Contract__c> listOfRelOrgToUpdate = new List<Related_Contract__c>();        
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
        
        if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                try{
                    List<Related_Contract__c> listOfRelOrgs = [SELECT Id, L_PR_Agreement_Status__c, I_RS_Contract__r.I_RS_Status__c, I_RS_Contract__c, I_RS_Organisation__c,
                    L_PR_Agreement_Recordtype__c FROM Related_Contract__c Where Id IN : Trigger.New];
                    map<Id,Related_Contract__c> mapOldRelOrgs = (map<Id,Related_Contract__c>)Trigger.oldMap;
                    for(Related_Contract__c eorg : listOfRelOrgs){
                        Related_Contract__c relOrg = new Related_Contract__c();
                        if(eorg.I_RS_Contract__r.I_RS_Status__c != null && (Trigger.isInsert || (Trigger.isUpdate && eorg.I_RS_Contract__r.I_RS_Status__c != mapOldRelOrgs.get(eorg.id).L_PR_Agreement_Status__c))) {
                            relOrg.L_PR_Agreement_Status__c = eorg.I_RS_Contract__r.I_RS_Status__c;
                            relOrg.Id = eorg.Id;
                            listOfRelOrgToUpdate.add(relOrg);
                        }
                    }
                    if(!listOfRelOrgToUpdate.isEmpty()){
                        update listOfRelOrgToUpdate;
                    }
                }catch(Exception e){
                    errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'RelatedContractTriggerHandler', Apex_Class_Method_Name__c = 'RelatedContractTriggerHandler',
                        Exception_message__c = 'Exception while updating the L_PR_Agreement_Status__c field in Related_Contract__c', Exception_Stack_Trace__c = e.getStackTraceString()));
                }
            }
        }

    }
}