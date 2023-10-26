public class ProjectProposalLockUnlockQueueable implements Queueable {
    private static final String APPROVALS = 'Approvals';
    private static final String REVIEW_BY_RESEARCH_OFFICE = 'Review by Research Office';
    private static final set<String> projectProposalLockedStatuses = ProjectProposalHelper.getLockedProposalStatuses();
    
    private List<Id> ppIds;
    private Map<Id, Project_Proposal__c> oldPPMap;
    
    public ProjectProposalLockUnlockQueueable(Set<Id> Ids){
        ppIds = new List<Id>();
        ppIds.addAll(Ids);
    }
    
    public void execute(QueueableContext queCont) {
        List<Id> lockList = new List<Id>();
        List<Id> unlockList = new List<Id>();
        
        Map<Id, boolean> ppLockSuggestedMap = new Map<Id, boolean>();
        
        //Making an assumption any record (which is not Recommendation and Placeholder) that whos status is "approval" should be either locked or unlocked based on I_RS_Allow_Updates_on_Approval__c
        for (Project_Proposal__c pp: [SELECT Id, I_RS_Status__c, I_RS_Allow_Updates_on_Approval__c FROM Project_Proposal__c WHERE Id in : ppIds ]){
            system.debug('ProjectProposalLockUnlockQueueable 1 status: ' + pp.I_RS_Status__c);
            if ((pp != null) && (pp.I_RS_Status__c != null) && (projectProposalLockedStatuses.contains(pp.I_RS_Status__c.toLowerCase()))) {
                system.debug('ProjectProposalLockUnlockQueueable 7');
                if (pp.I_RS_Allow_Updates_on_Approval__c){
                    system.debug('ProjectProposalLockUnlockQueueable 8');
                    unlockList.add(pp.Id);    
                } else {
                    system.debug('ProjectProposalLockUnlockQueueable 9');
                    lockList.add(pp.Id);    
                }                 
            }else {
                system.debug('ProjectProposalLockUnlockQueueable 10');
                unlockList.add(pp.Id);    
            }            
        }
        
        System.debug('lockList: ' +lockList);
        System.debug('unlockList: ' +unlockList);
        if (lockList.size() > 0) {
            Approval.lock(lockList);
        }
        if (unlockList.size() > 0) {
            Approval.unlock(unlockList);
        }
        
    }
}