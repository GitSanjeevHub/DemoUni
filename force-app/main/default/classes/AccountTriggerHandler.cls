public with sharing class AccountTriggerHandler {

    public static void execute() {

        System.debug('AccountTriggerHandler.execute');
        System.debug(Trigger.operationType);
        System.debug(Trigger.New);
        System.debug(Trigger.OldMap);
        
        if (Trigger.isAfter){
            if (Trigger.isUpdate){
                AccountTriggerHelper.handleBudgetRelatedFieldChanges(
                    Trigger.New, (Map<Id, Account>) Trigger.OldMap);
            }
            if (Trigger.isDelete){
                Set<Id> masterAccountIds = GlobalUtility.getParentIds(Trigger.Old, 'MasterRecordId');
                System.debug('masterAccountIds '+masterAccountIds);
                if (masterAccountIds != null){
                    System.enqueueJob(new RecordMergeBudgetHandler(masterAccountIds, 'Account'));
                }
            }
        }


        if(Trigger.isBefore){
            if(Trigger.isUpdate || Trigger.isInsert){
                //LTU360-1640
                AccountTriggerHelper.updateEndDate(Trigger.New, (Map<Id, Account>) Trigger.OldMap);
                
                // LTU360-2508
                List<Account> listOfUpdatedAccountCountries = New List<Account>();
                listOfUpdatedAccountCountries = getShippingCountryList(Trigger.New, (Map<Id, Account>) Trigger.OldMap);
                if(listOfUpdatedAccountCountries != null && listOfUpdatedAccountCountries.size() > 0){
                    AccountTriggerHelper.updatePortfolio(listOfUpdatedAccountCountries);
                }
            }
        }
    }

    public static List<Account> getShippingCountryList(List<Account> accList, Map<Id, Account> oldAccMap){

        List<Account> listOfAccounts = New List<Account>();

        for(Account acc : accList){
            if((acc.ShippingCountry != null || acc.ShippingCountry != '') && (Trigger.isInsert || (oldAccMap != null && acc.ShippingCountry != oldAccMap.get(acc.Id).ShippingCountry))) {
                listOfAccounts.add(acc);
            }
        }
        return listOfAccounts;
    }
}