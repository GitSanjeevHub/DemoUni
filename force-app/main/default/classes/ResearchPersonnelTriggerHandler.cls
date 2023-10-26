public without sharing class ResearchPersonnelTriggerHandler {
    public static Boolean runHierarchySharing = true;
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
        	System.enqueueJob(new ResearchPersonnelMemberQueueable(null, (Map<ID, Research_Personnel__c>)Trigger.newMap));  
        }
        if (Trigger.isUpdate){   
        	System.enqueueJob(new ResearchPersonnelMemberQueueable((Map<ID, Research_Personnel__c>)Trigger.oldMap, (Map<ID, Research_Personnel__c>)Trigger.newMap));  
        }
        if (Trigger.isDelete){   
        	System.enqueueJob(new ResearchPersonnelMemberQueueable((Map<ID, Research_Personnel__c>)Trigger.oldMap, null));  
        }
    }
}