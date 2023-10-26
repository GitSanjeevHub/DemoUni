trigger GraduateResearchExaminationTrigger on Graduate_Research_Examination__c (before insert, before update, before delete, after insert, after update, after delete ) {
	if(!GlobalUtility.isTriggerDisabled('Graduate_Research_Examination__c')){
		GraduateResearchExaminationHandler.execute();
	}
}