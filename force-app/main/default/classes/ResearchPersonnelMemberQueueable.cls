public class ResearchPersonnelMemberQueueable implements Queueable {
    
    set<Id> erIds;
    set<Id> userIds;
    set<String> revokeKeys;
    List<Ethics_Request__Share> revokeList;
    List<Ethics_Request__share> grantList;
    
    public ResearchPersonnelMemberQueueable(Map<Id, Research_Personnel__c> oldRPMap, Map<Id, Research_Personnel__c> newRPMap) {
        String rowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;
        grantList = new List<Ethics_Request__share>();
        revokeList = new List<Ethics_Request__share>();
        erIds = new set<Id>();
        userIds = new set<Id>();
    	revokeKeys = new set<String>();
        
        if (newRPMap == null) { 
            for ( Research_Personnel__c rp: oldRPMap.values()) {
            	erIds.add(rp.I_RS_Ethics_Request__c);
                userIds.add(rp.I_RS_Reseracher_User_Id__c);
                revokeKeys.add(rp.I_RS_Ethics_Request__c + '-' + rp.I_RS_Reseracher_User_Id__c);
            }
        }
        if (oldRPMap == null) {
            for ( Research_Personnel__c rp: newRPMap.values()) {
                system.debug('rp.I_RS_Reseracher_User_Id__c rp1: ' + rp);
                system.debug('rp.I_RS_Reseracher_User_Id__c 1: ' + rp.I_RS_Reseracher_User_Id__c);
                if ((rp.I_RS_End_Date__c == null) && ((rp.I_RS_Reseracher_User_Id__c != '') && (rp.I_RS_Reseracher_User_Id__c != null))) {
                    Ethics_Request__share erShare = new Ethics_Request__share();
                    erShare.ParentId = rp.I_RS_Ethics_Request__c;
                    erShare.UserOrGroupId = rp.I_RS_Reseracher_User_Id__c;
                    erShare.RowCause = rowCause;                        
                    erShare.AccessLevel = GlobalConstants.ETHICS_TEAM_MEMBER_SHARING_ACCESS;
                    grantList.add(erShare);
                }
            }
        }

        if ((oldRPMap != null) && (newRPMap != null)) {
            for ( Research_Personnel__c rp: newRPMap.values()) {
                    if (rp.I_RS_End_Date__c == null) {
                system.debug('rp.I_RS_Reseracher_User_Id__c 2: ' + rp.I_RS_Reseracher_User_Id__c);
                        if ((rp.I_RS_Reseracher_User_Id__c != '') && (rp.I_RS_Reseracher_User_Id__c != null)) {
                            Ethics_Request__share erShare = new Ethics_Request__share();
                            erShare.ParentId = rp.I_RS_Ethics_Request__c;
                            erShare.UserOrGroupId = rp.I_RS_Reseracher_User_Id__c;
                            erShare.RowCause = rowCause;                        
                    		erShare.AccessLevel = GlobalConstants.ETHICS_TEAM_MEMBER_SHARING_ACCESS;
                            grantList.add(erShare);
                        }
                    } else {
                        erIds.add(rp.I_RS_Ethics_Request__c);
                        userIds.add(rp.I_RS_Reseracher_User_Id__c);
                		revokeKeys.add(rp.I_RS_Ethics_Request__c + '-' + rp.I_RS_Reseracher_User_Id__c);
                    }
            }
        }
        
        populateRevokeList();
    }
    
    private void populateRevokeList() {
                        System.debug('revokeKeys add: ' + revokeKeys);
        if ((erIds.size() > 0) || (userIds.size() > 0)) {
            for (Ethics_Request__Share erShare: [Select Id, ParentId, UserOrGroupId FROM Ethics_Request__Share WHERE ParentId IN :erIds AND UserOrGroupId IN :userIds]) {
                        System.debug('revokeKeys check: ' + erShare.ParentId + '-' + erShare.UserOrGroupId);
                if (revokeKeys.contains(erShare.ParentId + '-' + String.valueOf(erShare.UserOrGroupId).substring(0, 15))){
                    Ethics_Request__Share ers = new Ethics_Request__Share(Id = erShare.Id);
                	revokeList.add(erShare);    
                }
            }
        }
    }
    
    public void execute(QueueableContext queCont){
        System.debug('RP-grantList: ' + grantList);
        System.debug('RP-revokeList: ' + revokeList);
        if(grantList.size() > 0) {
        	Database.insert(grantList, false);
        }
        
        if(revokeList.size() > 0) {
        	Database.DeleteResult[] deleRes = Database.delete(revokeList, false);
            for (Database.DeleteResult dr: deleRes) {
            	System.debug('database.delete result: ' + dr);
            }
        }
        
    }

}