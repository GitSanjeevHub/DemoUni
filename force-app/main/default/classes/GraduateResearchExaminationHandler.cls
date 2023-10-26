public without sharing  class GraduateResearchExaminationHandler {
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
            GraduateResearchExaminationHelper.calculateAccessForAffectedThesis((Map<Id, Graduate_Research_Examination__c>) Trigger.newMap, null);
        }
        if (Trigger.isUpdate){   
            GraduateResearchExaminationHelper.calculateAccessForAffectedThesis((Map<Id, Graduate_Research_Examination__c>) Trigger.newMap, 
                                                                               (Map<Id, Graduate_Research_Examination__c>) Trigger.oldMap);
        }
        if (Trigger.isDelete){   
            Map<Id, Graduate_Research_Examination__c> oldGREMap = (Map<Id, Graduate_Research_Examination__c>) Trigger.oldMap;            
            GraduateResearchExaminationHelper.deleteChildRecordSharesOfThesis(oldGREMap.keySet());
        }
    }
}