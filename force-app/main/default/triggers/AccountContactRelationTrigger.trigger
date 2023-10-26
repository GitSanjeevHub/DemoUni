trigger AccountContactRelationTrigger on AccountContactRelation (before insert,
                                          before update,
                                          before delete,
                                          after insert,
                                          after update,
                                          after delete,
                                          after undelete) {
    if(!GlobalUtility.isTriggerDisabled(String.valueOf(AccountContactRelation.sObjectType))){
        AccountContactRelationHandler.execute();
    }
}