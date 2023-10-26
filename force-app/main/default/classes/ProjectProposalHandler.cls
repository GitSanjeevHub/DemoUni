public without sharing class ProjectProposalHandler {
    private static ProjectProposalHelper projectProposalUtil;
    
    @testVisible 
    private static boolean executeInTest = true;
    
    public static void execute() {
        projectProposalUtil = new ProjectProposalHelper();
        
        // Check for event type of trigger
        if(Trigger.isBefore ){
            beforeHandler();
        }
        else if(Trigger.isAfter){
            afterHandler();
        }
    }
    
    private static void beforeHandler(){
        if (executeInTest) {
            if(Trigger.isInsert){            
            }
            if (Trigger.isUpdate){   
                System.debug('--> Project Propoal Trigger.isUpdate -->');
                ProjectProposalHelper.sendEmailToTheTeamMembers((Map<Id,Project_Proposal__c>) Trigger.oldMap, (Map<Id,Project_Proposal__c>) Trigger.newMap);         
            }
        }
    }
    
    private static void afterHandler(){
        system.debug('in project proposal after Handler');
        if (executeInTest) {
            if(Trigger.isInsert  && ProjectProposalHelper.isFirstRunAfter()){   
                System.enqueueJob(new ProjectProposalLockUnlockQueueable(Trigger.NewMap.keySet()));
            }
            if(Trigger.isDelete){   
                projectProposalUtil.deleteRelatedProjectProposalTeamMembers(Trigger.OldMap.keySet());
            }
            if (Trigger.isUpdate  && ProjectProposalHelper.isFirstRunAfter()){
                system.debug('in project proposal after Handler - after run');
                System.enqueueJob(new ProjectProposalLockUnlockQueueable(Trigger.NewMap.keySet()));
            }
        }
    }
    
}