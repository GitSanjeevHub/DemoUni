trigger AppointmentOfExaminerTrigger on Appointment_of_Examiner__c (before insert, before update, before delete, after insert, after update, after delete ) {
	if(!GlobalUtility.isTriggerDisabled('Appointment_of_Examiner__c')){
		AppointmentOfExaminerHandler.execute();
	}
}