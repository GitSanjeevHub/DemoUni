@isTest
public class TaskDeletionBlockerTest {

    public static testmethod void taskDeletionBlockerTest() {

        String blockedProfilesConcat = System.label.Task_Deletion_Blocker_blocked_Profiles;
        String blockedRecordTypesContat = System.label.Task_Deletion_Blocker_Blocked_Record_Types;

        List<String> blockedProfiles = blockedProfilesConcat.split(',');
        List<String> blockedRecordTypes = blockedRecordTypesContat.split(',');

        String blockedProfileName = blockedProfiles[0];
        String blockedRecordTypeName = blockedRecordTypes[0];

        Id blockedProfileId = [select Id from Profile where Name = :blockedProfileName].Id;

        Id blockedRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
        .get(blockedRecordTypeName).getRecordTypeId();


        User runningUser = TestUtility.newUser('user', blockedProfileId, null, null);
        insert runningUser;

        Task taskToTest = TestUtility.newTask(null);
        taskToTest.recordTypeId = blockedRecordTypeId;
        taskToTest.ownerId = runningUser.Id;
        insert taskToTest;


        System.runAs(runningUser){

            try {
                delete taskToTest;

                System.assert(false, 'Delete succeeded by '+blockedProfileName +' on '+
                blockedRecordTypeName + ' when it should have failed');
            }
            catch (Exception e){
                System.debug('Delete succeeded. Is it because of this trigger or something else though?');
            }

        }


    }

}