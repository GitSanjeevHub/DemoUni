//Testing Commit 07-Sep
trigger ProjectProposalTrigger on Project_Proposal__c (before insert,
                                          before update,
                                          before delete,
                                          after insert,
                                          after update,
                                          after delete,
                                          after undelete) {
                                          if(!GlobalUtility.isTriggerDisabled(String.valueOf(Project_Proposal__c.sObjectType))){     
        
        //Project Proposal trigger handler dispatches appropriate event
        system.debug('--> Project proposal trigger -->');
        ProjectProposalHandler.execute();
    }
}