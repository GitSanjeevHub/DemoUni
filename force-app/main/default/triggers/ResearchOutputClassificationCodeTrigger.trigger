trigger ResearchOutputClassificationCodeTrigger on Research_Output_Classification_Code__c (before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
        if(!GlobalUtility.isTriggerDisabled(String.valueOf(Project_Proposal__c.sObjectType))){     

            //Research opportunity Classifcation Code trigger handler dispatches appropriate event
            system.debug('--> Project proposal trigger -->');
            ResearchOutputClassificationCodeHandler.execute();
        }
}