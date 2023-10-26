public class AccountContactRelationHandler {
    public static Boolean runHierarchySharing = true;
    public static Boolean runPositionHistory = true;

    public static void execute() {
        // Check for event type of trigger.
        if(Trigger.isBefore ){
            beforeHandler();
        }
        else if(Trigger.isAfter){
            afterHandler();
        }
    }
    
    private static void beforeHandler(){
        if(Trigger.isInsert){ 
            AccountContactRelationHelper.updateStartAndEndDates(null, (List<AccountContactRelation>)Trigger.new);
        }
        if (Trigger.isUpdate){  
            AccountContactRelationHelper.updateStartAndEndDates((Map<ID, AccountContactRelation>)Trigger.oldMap, (List<AccountContactRelation>)Trigger.new);
        }
        if (Trigger.isDelete){
            DeletionBlocker.blockDelete('AccountContactRelation', Trigger.Old);
        }
    }
    
    private static void afterHandler(){
        if(Trigger.isInsert){ 
	        if (runHierarchySharing) {
        		System.enqueueJob(new GrantACRHierarchyAccess(null, (Map<ID, AccountContactRelation>)Trigger.newMap, null, null, 0, null, null, null));  
            	ProjectTeamMemberHierarchyAccess.calculateHierarchySharesForACR(Trigger.new, null);
            }
            if (runPositionHistory) {
            	PositionHistoryHandler.handlePositionHistory(null, (Map<ID, AccountContactRelation>)Trigger.newMap);
            }
        }
        if(Trigger.isDelete){
        	if (runHierarchySharing) {
        		System.enqueueJob(new GrantACRHierarchyAccess((Map<ID, AccountContactRelation>)Trigger.oldMap, null, null, null, 0, null, null, null));  
                ProjectTeamMemberHierarchyAccess.calculateHierarchySharesForACR(Trigger.old, null);
            }
        }
        if (Trigger.isUpdate){
        	if (runHierarchySharing) {
                //ProjectTeamMemberHierarchyAccess.recalculateGrantHierarchyshares((Map<ID, AccountContactRelation>)Trigger.oldMap, (Map<ID, AccountContactRelation>)Trigger.newMap);
        		System.enqueueJob(new GrantACRHierarchyAccess((Map<ID, AccountContactRelation>)Trigger.oldMap, (Map<ID, AccountContactRelation>)Trigger.newMap, null, null, 0, null, null, null));  
                ProjectTeamMemberHierarchyAccess.calculateHierarchySharesForACR(Trigger.new, (Map<ID, AccountContactRelation>)Trigger.oldMap);
            }
            if (runPositionHistory) {
            	PositionHistoryHandler.handlePositionHistory((Map<ID, AccountContactRelation>)Trigger.oldMap, (Map<ID, AccountContactRelation>)Trigger.newMap);
            }
        }
    }
    
}