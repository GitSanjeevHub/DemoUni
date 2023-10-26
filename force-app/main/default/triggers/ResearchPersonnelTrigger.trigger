trigger ResearchPersonnelTrigger on Research_Personnel__c (before insert, before update, before delete, after insert, after update, after delete ) {
	if(!GlobalUtility.isTriggerDisabled('Research_Personnel__c')){
		ResearchPersonnelTriggerHandler.execute();
	}
}