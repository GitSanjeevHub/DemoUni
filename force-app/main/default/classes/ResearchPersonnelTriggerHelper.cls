public class ResearchPersonnelTriggerHelper {
    public static void updateRPSharesWithNewUserId(Map<Id, Contact> oldMap, Map<Id, Contact> newMap){
        List<Id> newCs= new List<Id>();
        List<Id> delCs= new List<Id>();
        for (Contact c: newMap.values()) {
            if ((c.I_RS_Related_User__c != null) && (c.I_RS_Related_User__c != oldMap.get(c.Id).I_Rs_Related_User__c)) {
                newCs.add(c.Id);
            }
            if ((c.I_RS_Related_User__c == null) && (c.I_RS_Related_User__c != oldMap.get(c.Id).I_Rs_Related_User__c)) {
                delCs.add(oldMap.get(c.Id).I_Rs_Related_User__c);
            }
        }
        
        if (newCs.size() > 0){
        	List<Ethics_Request__share> grantList = new List<Ethics_Request__share>();
            for (Research_Personnel__c rp: [SELECT Id, I_RS_Ethics_Request__c, I_RS_End_Date__c, I_RS_Contact_Researcher__c FROM Research_Personnel__c WHERE I_RS_Contact_Researcher__c in :newCs]) {
                System.debug('Research_Personnel__c rp: '+ rp);
                if (rp.I_RS_End_Date__c == null)  {
                    Ethics_Request__share erShare = new Ethics_Request__share();
                    erShare.ParentId = rp.I_RS_Ethics_Request__c;
                    erShare.UserOrGroupId = newMap.get(rp.I_RS_Contact_Researcher__c).I_Rs_Related_User__c;
                    erShare.RowCause = Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c;                        
                    erShare.AccessLevel = GlobalConstants.ETHICS_TEAM_MEMBER_SHARING_ACCESS;
                    grantList.add(erShare);
                }
            }
            if (grantList.size() > 0) {
                insert grantList;
            }
        }
        
        if (delCs.size() > 0) {
        	List<Ethics_Request__share> revokeList = [SELECT Id FROM Ethics_Request__share WHERE UserOrGroupId in :delCs AND RowCause = :Schema.Ethics_Request__Share.rowCause.Ethics_Team_Member__c];
            if (revokeList.size() > 0 ){
                delete revokeList;
            }
            
        } 

    }

}