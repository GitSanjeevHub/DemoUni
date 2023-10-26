public class AppointmentOfExaminerHandler {
    public static void execute() {       
        // Check for event type of trigger
        if(Trigger.isBefore ){
            beforeHandler();
        }
        else if(Trigger.isAfter){
            afterHandler();
        }
    }
    
    private static void beforeHandler(){
    }
    
    private static void afterHandler(){
        if(Trigger.isInsert){ 
            AppointmentOfExaminerHelper.calculateSharingForAOE((Map<Id, Appointment_of_Examiner__c>) Trigger.newMap, null);
        }
        if (Trigger.isUpdate){   
            AppointmentOfExaminerHelper.calculateSharingForAOE((Map<Id, Appointment_of_Examiner__c>) Trigger.newMap, (Map<Id, Appointment_of_Examiner__c>) Trigger.oldMap);
        }
    }
}