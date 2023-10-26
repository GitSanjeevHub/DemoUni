/**
 * Created by burnside on 2019-04-23.
 */

trigger ContractTrigger on Contract__c (after insert, after update, before delete) {

    if (!GlobalUtility.isTriggerDisabled('Contract__c')){
        ContractTriggerHandler.execute();
    }

}