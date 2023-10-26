trigger AccountTrigger on Account (after update, after delete, before update, before insert) {
    if(!GlobalUtility.isTriggerDisabled(String.valueOf(Account.sObjectType))){
        AccountTriggerHandler.execute();
    }
}