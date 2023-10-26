/**
 * Created by burnside on 2019-04-23.
 */

public with sharing class ContractTriggerHandler {

    public static void execute(){

        System.debug('ContractTriggerHandler');

        System.debug(Trigger.operationType);


        if (Trigger.isBefore) {
            
	        if (Trigger.isDelete){
                
                List<Contract__c> agreementsThatFailedToDelete = DeletionBlocker.blockDelete('Contract__c', Trigger.Old);
                if (agreementsThatFailedToDelete != NULL && agreementsThatFailedToDelete.isEmpty()){
            		delete [SELECT Id FROM Related_Contract__c WHERE I_RS_Contract__c IN :Trigger.oldMap.keySet()];
                }
        	}
        }

        if (Trigger.isAfter) {

            if (Trigger.isInsert) {
                new ProjectTeamMemberRecordAccess3().runViaChildRecord('Contract__c');
                ProjectTeamMemberHierarchyAccess.handleContractRecordVisibility(null, (Map<Id, Contract__c>)Trigger.newMap);
            }

            if (Trigger.isUpdate) {
                new ProjectTeamMemberRecordAccess3().runViaChildRecord('Contract__c');

                //Invokes sharing code
                update [SELECT Id FROM Related_Contract__c
                    WHERE I_RS_Contract__c IN :Trigger.newMap.keySet() OR I_RS_Contract__c IN :Trigger.oldMap.keySet()
                ];

                ProjectTeamMemberHierarchyAccess.handleContractRecordVisibility((Map<Id, Contract__c>)Trigger.oldMap, (Map<Id, Contract__c>)Trigger.newMap);


            }

            //LTU360-2354

            if(Trigger.isUpdate || Trigger.isInsert){

                //LTU360-2384

                Map<Id,String> agreementStatusMap = new Map<Id,String>();
                Map<Id,Contract__c> mapOldAgreemets = (Map<Id,Contract__c>)Trigger.oldMap;
                Map<Id,Contract__c> mapOfAgreements = (Map<Id,Contract__c>)Trigger.newMap;
                Map<Id, Id> agrEOrgMap = new Map<Id,Id>(); 
                Map<Id, Id> agrIOrgMap = new Map<Id,Id>(); 
                Map<Id, Id> removeAgrEOrgMap = new Map<Id,Id>(); 
                Map<Id, Id> removeAgrIOrgMap = new Map<Id,Id>();
                Map<Id,Id> oppAggMap = new Map<Id,Id>();
                Map<Id, Contract__c> agreementMap = new Map<Id, Contract__c>();
                Id prmAgreementRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('L_PR_Agreement').getRecordTypeId();
                Id agentAgreementRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('L_PR_Agent_Agreement').getRecordTypeId();
                for(Contract__c agr : (List<Contract__c>)Trigger.new){  
                    // check if I_RS_Status__c is updated (to update on Related_Contract__c L_PR_Agreement_Status__c field)
                    if(agr.I_RS_Status__c != Null && Trigger.isUpdate && agr.I_RS_Status__c != mapOldAgreemets.get(agr.Id).I_RS_Status__c){
                        agreementStatusMap.put(agr.Id,agr.I_RS_Status__c);
                    }

                    // check if organisation is not blank or value is updated
                    if(agr.I_RS_Organisation__c != Null  && (Trigger.isInsert || (Trigger.isUpdate && agr.I_RS_Organisation__c != mapOldAgreemets.get(agr.Id).I_RS_Organisation__c))){                           
                        agrEOrgMap.put(agr.Id,agr.I_RS_Organisation__c);                               
                    }
                    else if(Trigger.isUpdate && agr.I_RS_Organisation__c == Null && agr.I_RS_Organisation__c != mapOldAgreemets.get(agr.Id).I_RS_Organisation__c){ 
                        //remove the record from list
                        removeAgrEOrgMap.put(agr.Id,mapOldAgreemets.get(agr.Id).I_RS_Organisation__c);
                    }

                    // check if LaTrobe organisation is not blank or value is updated
                    if(agr.L_PR_La_Trobe_Organisation_Unit__c != Null  && (Trigger.isInsert || (Trigger.isUpdate && agr.L_PR_La_Trobe_Organisation_Unit__c != mapOldAgreemets.get(agr.Id).L_PR_La_Trobe_Organisation_Unit__c))){                           
                        agrIOrgMap.put(agr.Id,agr.L_PR_La_Trobe_Organisation_Unit__c);                               
                    }
                    else if(Trigger.isUpdate && agr.L_PR_La_Trobe_Organisation_Unit__c == Null && agr.L_PR_La_Trobe_Organisation_Unit__c != mapOldAgreemets.get(agr.Id).L_PR_La_Trobe_Organisation_Unit__c){ 
                        //remove the record from list
                        removeAgrIOrgMap.put(agr.Id,mapOldAgreemets.get(agr.Id).L_PR_La_Trobe_Organisation_Unit__c);
                    }
                    
                    //check if agreement is converted from opportunity
                    if(Trigger.isInsert && agr.L_PR_Opportunity_Name__c != Null && agr.L_PR_IsConverted__c == True){
                        oppAggMap.put(agr.L_PR_Opportunity_Name__c,agr.Id);                                     
                    }

                    //LTU360-2659 Create agreement tasks from the Task Matrix
                    if(agr.recordTypeId == prmAgreementRecordTypeId || agr.recordTypeId == agentAgreementRecordTypeId){
                        if((agr.I_RS_Agreement_Type__c != Null  && (Trigger.isInsert || (Trigger.isUpdate && agr.I_RS_Agreement_Type__c != mapOldAgreemets.get(agr.Id).I_RS_Agreement_Type__c)))
                        || (agr.I_RS_Status__c != Null  && (Trigger.isInsert || (Trigger.isUpdate && agr.I_RS_Status__c != mapOldAgreemets.get(agr.Id).I_RS_Status__c)))){                           
                                agreementMap.put(agr.Id,agr);                               
                        }
                    }
                    if(!agreementMap.isEmpty()){
                        ContractTriggerHelper.createTasksFromTaskMatrix(agreementMap);
                    }
                }
                    if(agreementStatusMap != null){
                        ContractTriggerHelper.updateRelatedOrgStatus(agreementStatusMap);
                    }  
                    if(!agrEOrgMap.isEmpty() || !removeAgrEOrgMap.isEmpty()){
                       ContractTriggerHelper.createUpdateRelatedOrgs(agrEOrgMap, removeAgrEOrgMap, 'External', mapOfAgreements);
                    }

                    if(!agrIOrgMap.isEmpty() || !removeAgrIOrgMap.isEmpty()){
                       ContractTriggerHelper.createUpdateRelatedOrgs(agrIOrgMap, removeAgrIOrgMap, 'Internal', mapOfAgreements);
                    }

					//call helper method to mark opportunity as Closed Won
                    if(!oppAggMap.isEmpty()){
                        ContractTriggerHelper.updateOppStatusClosedWon(oppAggMap);
                    }


            }

            if (Trigger.isDelete) {

                ProjectTeamMemberHierarchyAccess.handleContractRecordVisibility((Map<Id, Contract__c>)Trigger.oldMap, null);
            }

        }

    }

}