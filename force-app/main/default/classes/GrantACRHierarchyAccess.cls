public class GrantACRHierarchyAccess implements Queueable {
	@testvisible
    private static boolean isTest = Test.isRunningTest();

    private static final integer chunkSize = 9999;

    private boolean firstTime = false;
    private boolean sharingComplete = false;
    private boolean deleteComplete = false;
    private integer listIndex = 0;
    private SObject[] sharelist;
    private SObject[] deletelist;
    Map<Id, AccountContactRelation> oldACRs;
    Map<Id, AccountContactRelation> newACRs;
    Map<string, boolean> statusMap;
    Map<Id, set<Id>> projectHierarchyMap;
    set<Id> deleteuserIds;

    public GrantACRHierarchyAccess (Map<Id, AccountContactRelation> oACRs, Map<Id, AccountContactRelation> nACRs,
                                    List<SObject> sList, List<SObject> dList,
                                    Integer lIndex, Map<string, boolean> sMap, 
                                    Map<Id, set<Id>> phUMap, set<Id> dUserIds) {
		oldACRs = oACRs;
        newACRs = nACRs;
        statusMap = sMap;
        projectHierarchyMap = phUMap;
        deleteuserIds = dUserIds;
		firstTime = (sMap == null);
        listIndex = lIndex;

		if (firstTime) {
        	Map<string, Map<Id, set<Id>>> shareDeleteMap = ProjectTeamMemberHierarchyAccess.recalculateGrantHierarchyshares(oldACRs, newACRs);
			projectHierarchyMap = shareDeleteMap.get(ProjectTeamMemberHierarchyAccess.SHARE_PROJECT_HIERARCHY_MAP);
			System.debug('hierarchyUserMap.size() 37: ' + projectHierarchyMap.size());            
            
            Map<Id, set<Id>> tempDelMap = shareDeleteMap.get(ProjectTeamMemberHierarchyAccess.DELETE_USER_ID_LIST);
        	deleteuserIds = tempDelMap.get(UserInfo.getUserId());
			System.debug('deleteuserIds.size() 37: ' + deleteuserIds.size());            
            statusMap = new Map<string, boolean>();
            statusMap.put('sharingComplete', false);
            statusMap.put('deleteComplete', false);
            statusMap.put('ppShareCalculated', false);
            statusMap.put('cShareCalculated', false);
            statusMap.put('ppDeleteCalculated', false);
            statusMap.put('cDeleteCalculated', false);
		} else {
        	sharelist = sList;
        	deletelist = dList;
            sharingComplete = statusMap.get('sharingComplete');
            deleteComplete = statusMap.get('deleteComplete');
        }

        System.debug('GrantACRHierarchyAccess');
    }

    private void sortListByObjectType(List<SObject> objList){
        System.debug('sortListByObjectType');
    	SObject[] projectProposals = new List<SObject>();
    	SObject[] contracts = new List<SObject>();

        for (SObject o: objList) {
            if (o.getSObjectType() == Project_Proposal__share.getSObjectType()) {
            	projectProposals.add(o);
            } else if (o.getSObjectType() == Contract__share.getSObjectType()){
            	contracts.add(o);
            }
        }
        objList.clear();
        objList.addAll(projectProposals);
        objList.addAll(contracts);
        System.debug('objList.size(): ' + objList.size());

    }

    private void insertShareRecords(){
        System.debug('insertShareRecord : begin');
        List<List<SObject>> subsetObjList = new List<List<SObject>>();
        integer listBlockSize = ((listIndex + chunkSize) >= sharelist.size()-1) ? sharelist.size()-1: (listIndex + chunkSize);
        System.debug('insertShareRecord listBlockSize : ' + listBlockSize);
        integer counter = 0;
        List<SObject> tenChunkList;
        for (integer i = listIndex; i <= listBlockSize; i++) {
            if (counter == 0) {tenChunkList = new List<sObject>();}
            counter++;
        	tenChunkList.add(sharelist.get(i));
            if ((counter == 200) || (i == listBlockSize)) {
            	counter = 0;
        		subsetObjList.add(tenChunkList);
            }
        }

        for (List<SObject> objList: subsetObjList) {
            if ((objList != null) && (objList.size() > 0)) {
                database.insert(objList, false);
            }
        }

        if ((!sharingComplete) && (listBlockSize >= sharelist.size()-1)) {
            sharingComplete = true;
            listIndex = 0;
        } else {
        	listIndex = listIndex + chunkSize + 1;
        }
        System.debug('insertShareRecord listIndex 88: ' + listIndex);
        System.debug('insertShareRecord : end');
    }

    private void deleteShareRecords(){
        System.debug('deleteShareRecord : begin');
        List<List<SObject>> subsetObjList = new List<List<SObject>>();
        integer listBlockSize = ((listIndex + chunkSize) >= deletelist.size()-1) ? deletelist.size()-1: (listIndex + chunkSize);

        System.debug('deleteShareRecord listIndex : ' + listIndex);
        System.debug('deleteShareRecord listBlockSize : ' + listBlockSize);
        System.debug('deleteShareRecord  deletelist.size() : ' +  deletelist.size());

        integer counter = 0;
        List<SObject> tenChunkList;
        for (integer i = listIndex; i <= listBlockSize; i++) {
            if (counter == 0) {tenChunkList = new List<sObject>();}
            counter++;
        	tenChunkList.add(deletelist.get(i));
            if ((counter == 200) || (i == listBlockSize)) {
            	counter = 0;
        		subsetObjList.add(tenChunkList);
            }
        }

        for (List<SObject> objList: subsetObjList) {
            if ((objList != null) && (objList.size() > 0)) {
        		//delete objList;
        		Database.delete(objList, false);
            }
        }

        if ((sharingComplete) && (!deleteComplete) && (listBlockSize >= deletelist.size()-1)) {
            deleteComplete = true;
        } else {
            listIndex = listIndex + chunkSize + 1;
        }
        System.debug('deleteShareRecord listIndex 126: ' + listIndex);
        System.debug('deleteShareRecord : end');
    }

    
    public void execute(QueueableContext context) {
        System.debug('execute');
        system.debug('sharingComplete: ' + sharingComplete);
        system.debug('deleteComplete: ' + deleteComplete);

        if (!sharingComplete) {
            boolean ppShareCalculated = statusMap.get('ppShareCalculated');
            boolean cShareCalculated = statusMap.get('cShareCalculated');
            boolean ppDeleteCalculated = statusMap.get('ppDeleteCalculated');
            boolean cDeleteCalculated = statusMap.get('cDeleteCalculated');
            
            if ((!firstTime) || (isTest)){
                if ((!ppShareCalculated) || (isTest)) {
                    shareList = new List<SObject>();
                    shareList.addAll(ProjectTeamMemberHierarchyAccess.queueableCalculatePPShare(projectHierarchyMap));
                	statusMap.put('ppShareCalculated', true);
                }
                if (((ppShareCalculated) && (!cShareCalculated)) || (isTest)) {
                    shareList.addAll(ProjectTeamMemberHierarchyAccess.queueableCalculateCShare(projectHierarchyMap));
                	statusMap.put('cShareCalculated', true);
                }
                if (((cShareCalculated) && (!ppDeleteCalculated)) || (isTest)) {
                    deleteList = new List<SObject>();
                        System.debug('deleteuserIds 181: ' + deleteuserIds);
                    deleteList.addAll(ProjectTeamMemberHierarchyAccess.queueableCalculatePPDelete(deleteuserIds));
                        System.debug('deletelist.size() 181: ' + deletelist.size());
                	statusMap.put('ppDeleteCalculated', true);
                }
                if (((ppDeleteCalculated) && (!cDeleteCalculated)) || (isTest)) {
                        System.debug('deleteuserIds 181: ' + deleteuserIds);
                    deleteList.addAll(ProjectTeamMemberHierarchyAccess.queueableCalculateCDelete(deleteuserIds));
                        System.debug('deletelist.size() 186: ' + deletelist.size());
                	statusMap.put('cDeleteCalculated', true);
                }
                if (((ppShareCalculated) && (cShareCalculated) && 
                    (ppDeleteCalculated) && (cDeleteCalculated)) || (isTest)){
                        System.debug('ShareList.size() 197: ' + shareList.size());
                        System.debug('deletelist.size() 198: ' + deletelist.size());
                        sortListByObjectType(sharelist);
                        sortListByObjectType(deletelist);
        				insertShareRecords();
                    }
            }
        } else {
        	System.debug('inside else !sharingComplete 134 after insert is complete');
        	deleteShareRecords();
        }

        if ((!deleteComplete) && (isTest)) {
        	deleteShareRecords();
            deleteComplete = True;
        }

        if ((!deleteComplete)) {
            statusMap.put('sharingComplete', sharingComplete);
            statusMap.put('deleteComplete', deleteComplete);
            
    		System.enqueueJob(new GrantACRHierarchyAccess (oldACRs, newACRs, sharelist, deletelist, listIndex, statusMap, projectHierarchyMap, deleteuserIds));
        }
    }
}