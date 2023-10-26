public class TaskTriggerHandler {

    public static void execute(){
        
        
    	if (Trigger.isBefore){

            if (Trigger.isInsert || Trigger.isUpdate){
                PortalObjectVisibility.enableVisibleInSelfService(Trigger.new);

                ParentToChildRecordNameCopy.copyRelatedToDataToChildActivities(Trigger.new);
            }
            
            if (Trigger.isDelete){

                preventDeletionByNonAdmins();

            }
        }
        
        if (Trigger.isAfter){
            
            if (Trigger.isInsert){
            }
            
            if (Trigger.isUpdate){
            }
            
        }
        
    }


    static void preventDeletionByNonAdmins(){

        String blockedProfilesConcat = System.label.Task_Deletion_Blocker_blocked_Profiles.toLowerCase();
        String blockedRecordTypesContat = System.label.Task_Deletion_Blocker_Blocked_Record_Types.toLowerCase();

        Set<String> blockedProfiles = new Set<String>(blockedProfilesConcat.split(','));
        Set<String> blockedRecordTypes = new Set<String>(blockedRecordTypesContat.split(','));

        System.debug('blockedProfiles '+blockedProfiles);
        System.debug('blockedRecordTypes '+blockedRecordTypes);

        String userProfileName = [select Profile.Name from User where Id = :UserInfo.getUserId()].Profile.Name;
        Boolean userhasBlockedProfile = blockedProfiles.contains(userProfileName.toLowerCase());

        Map<Id,Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.Task.getRecordTypeInfosById();

        for (Task task : (Task[]) Trigger.Old){

            Boolean isRecurringTaskInstance = !task.isRecurrence && task.recurrenceActivityId != null;
            if (!isRecurringTaskInstance){

                if (userhasBlockedProfile ){

                    System.debug('Profile is blocked. Checking record type');
                    RecordTypeInfo rtInfo = recordTypeInfos.get(task.recordTypeId);
                    String taskRecordTypeName = rtInfo.getDeveloperName();
                    String taskRecordTypeLabel = rtInfo.getName();
                    
                    System.debug('taskRecordTypeName '+taskRecordTypeName);
                    Boolean taskisBlockedRecordType = blockedRecordTypes.contains(taskRecordTypeName.toLowerCase());
                    if(taskIsBlockedRecordType){
                        System.debug('Record type is blocked');
                        task.addError('You do not have permission to delete records of this type. '+
                            'Please update the Status field instead.');
                    }

                }

            }

        }

    }

    
    
}