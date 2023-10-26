trigger ContactTrigger on Contact (before insert,after insert, after update, after delete, before delete, before update) {

    if (!GlobalUtility.isTriggerDisabled('Contact')){
        ContactTriggerHandler.execute();
    }

}