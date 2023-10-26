/**
 * Created by Kishore Reddy Basani on 2022-10-03.
 */

trigger Related_ContractTrigger on Related_Contract__c (before insert, before update, before delete, after insert, after update, after delete ) {
    if(!GlobalUtility.isTriggerDisabled('Related_Contract__c')){
        RelatedContractTriggerHandler.execute();
    }
}