trigger ClassificationCodeTrigger on Classification_Code__c (after insert, after update) {

    if (!GlobalUtility.isTriggerDisabled('Classification_Code__c')){
        //ClassificationCodeTriggerHandler.execute();
    }

}