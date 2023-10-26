trigger I_ST_Student_CourseTrigger on I_ST_Student_Course__c (after insert, after update) {
    if(!GlobalUtility.isTriggerDisabled('I_ST_Student_Course__c')) {
        I_ST_Student_CourseTriggerHandler.execute();
    }
}