public class HierarchySharesForContactsQueueable implements Queueable {
    @testVisible private static boolean isTest = Test.isRunningTest();
    set<Id> contactIds;
    Map<Id, set<Id>> proposalTMContactsMap;
    Map<Id, set<Id>> ppHierarchyUsers;
    boolean ppComplete, agComplete; 
    public HierarchySharesForContactsQueueable(set<Id> contacts, Map<Id, set<Id>> ppHU,
                                               boolean ppDone, boolean agDone) {
        ppComplete = ppDone; 
        agComplete = agDone;
        contactIds = contacts;
		ppHierarchyUsers = ppHU;
                                                   
        if (!ppComplete && !agComplete) {
            ProjectTeamMemberHierarchyAccess.initialiseStaticMapsVariables();
            proposalTMContactsMap = ProjectTeamMemberHierarchyAccess.calculateHierarchySharesForContacts(contactIds);
            ppHierarchyUsers = ProjectTeamMemberHierarchyAccess.getProposalHierarchyUserMap(proposalTMContactsMap);
        }        
        
    }
    public void execute(QueueableContext queCont) {
        if ((!ppComplete && !agComplete) || (isTest)) {
        	ProjectTeamMemberHierarchyAccess.recalculateProjectProposalHierarchyShares(ppHierarchyUsers.keySet(), ppHierarchyUsers);
            ppComplete = true;
            if (!isTest) {
        		System.enqueueJob(new HierarchySharesForContactsQueueable(contactIds, ppHierarchyUsers, ppComplete, agComplete));
            }
        } else if ((ppComplete && !agComplete) || (isTest)) {
        	ProjectTeamMemberHierarchyAccess.recalculateContractsHierarchyShares(ppHierarchyUsers.keySet(), ppHierarchyUsers);
            agComplete = True;
        }
    }

}