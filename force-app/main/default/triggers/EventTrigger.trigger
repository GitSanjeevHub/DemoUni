/**
 * Created by burnside on 2019-04-24.
 */

trigger EventTrigger on Event (before insert, before update) {

    if (!GlobalUtility.isTriggerDisabled('Event')){

        if (Trigger.isBefore){

            if (Trigger.isInsert || Trigger.isUpdate){

                Set<Id> whatIds = new Set<Id>();
                for (Event event : Trigger.new){
                    if (event.whatId != null)
                        whatIds.add(event.whatId);
                }

                Map<Id, Project_Proposal__c> projectProposals = new Map<Id, Project_Proposal__c>(
                    [select Id from Project_Proposal__c where Id in :whatIds]
                );

                for (Event event : trigger.new){
                    if (projectProposals.get(event.whatId) != null)
                        event.IsVisibleInSelfService = true;
                }
            }

        }

    }

}