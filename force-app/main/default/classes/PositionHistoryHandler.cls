public class PositionHistoryHandler {
    private static boolean noPositionHistoryRealtedFieldChanged(AccountContactRelation oldACR, AccountContactRelation newACR) {
        return 
            (oldACR.AccountId ==  newACR.AccountId) && 
            (oldACR.I_RS_Position_Description__c ==  newACR.I_RS_Position_Description__c) && 
            (oldACR.I_RS_Campus__c==  newACR.I_RS_Campus__c) && 
            (oldACR.I_RS_Campus_Code__c==  newACR.I_RS_Campus_Code__c) && 
            //Leaving out Start date and end date as it is calculate in this class not fed from Middleware
            /*(oldACR.StartDate == newACR.StartDate) &&  
            (oldACR.EndDate == newACR.EndDate) &&*/
            (oldACR.I_RS_Employment_Grade_Level__c ==  newACR.I_RS_Employment_Grade_Level__c) && 
            (oldACR.I_RS_Employment_Status__c ==  newACR.I_RS_Employment_Status__c) && 
            (oldACR.I_RS_FTE_Ratio__c ==  newACR.I_RS_FTE_Ratio__c) && 
            (oldACR.I_RS_Staff_Group_Code__c ==  newACR.I_RS_Staff_Group_Code__c) && 
            (oldACR.I_RS_Staff_Group_Desc__c ==  newACR.I_RS_Staff_Group_Desc__c) && 
            (oldACR.I_RS_Staff_Sub_Group_Code__c ==  newACR.I_RS_Staff_Sub_Group_Code__c) && 
            (oldACR.I_RS_Staff_Sub_Group_Desc__c ==  newACR.I_RS_Staff_Sub_Group_Desc__c) && 
            (oldACR.I_RS_Organisation_Code__c ==  newACR.I_RS_Organisation_Code__c)&&
            (oldACR.I_RS_Organisation_Name__c ==  newACR.I_RS_Organisation_Name__c)&&
            (oldACR.I_RS_Department_Code__c ==  newACR.I_RS_Department_Code__c)&&
            (oldACR.I_RS_Department_Name__c ==  newACR.I_RS_Department_Name__c)&&
            (oldACR.I_RS_School_Code__c ==  newACR.I_RS_School_Code__c)&&
            (oldACR.I_RS_School_Name__c ==  newACR.I_RS_School_Name__c)&&
            (oldACR.I_RS_College_Code__c ==  newACR.I_RS_College_Code__c)&&
            (oldACR.I_RS_College_Name__c ==  newACR.I_RS_College_Name__c);            
    }
    
    private static boolean blankPositionHistoryRealtedFields(AccountContactRelation newACR) {
        return            
            (newACR.I_RS_Position_Description__c ==  null) && 
            (newACR.I_RS_Campus__c ==  null) && 
            (newACR.I_RS_Campus_Code__c ==  null) && 
            //Leaving out Start date and end date as it is calculate in this class not fed from Middleware
            /*(newACR.StartDate == null) &&
            (newACR.EndDate == null) &&*/
            (newACR.I_RS_Employment_Grade_Level__c == null) && 
            (newACR.I_RS_Employment_Status__c ==  null) && 
            (newACR.I_RS_FTE_Ratio__c ==  null) && 
            (newACR.I_RS_Staff_Group_Code__c == null) && 
            (newACR.I_RS_Staff_Group_Desc__c ==  null) && 
            (newACR.I_RS_Staff_Sub_Group_Code__c == null) && 
            (newACR.I_RS_Staff_Sub_Group_Desc__c ==  null) && 
            (newACR.I_RS_Organisation_Code__c ==  null)&&
            (newACR.I_RS_Organisation_Name__c ==  null)&&
            (newACR.I_RS_Department_Code__c ==  null)&&
            (newACR.I_RS_Department_Name__c == null)&&
            (newACR.I_RS_School_Code__c ==  null)&&
            (newACR.I_RS_School_Name__c ==  null)&&
            (newACR.I_RS_College_Code__c == null)&&
            (newACR.I_RS_College_Name__c == null);            
    }
    
    private static Position_History__c formPositionHistoryRec(AccountContactRelation acr){
        return new Position_History__c(
            I_RS_Contact__c = acr.ContactId,
            I_RS_Organisation__c = acr.AccountId,
            I_RS_Position_Description__c = acr.I_RS_Position_Description__c,
            I_RS_Campus__c = acr.I_RS_Campus__c,
            I_RS_Campus_Code__c = acr.I_RS_Campus_Code__c,
            I_RS_Start_Date__c = Date.today(),
            I_RS_End_Date__c = acr.EndDate,
            I_RS_Salary_Grade_level__c = acr.I_RS_Employment_Grade_Level__c,
            I_RS_Employment_Type__c = acr.I_RS_Employment_Status__c,
            I_RS_FTE__c = acr.I_RS_FTE_Ratio__c,
            I_RS_Staff_Group_Code__c = acr.I_RS_Staff_Group_Code__c,
            I_RS_Staff_Group_Desc__c = acr.I_RS_Staff_Group_Desc__c,
            Staff_Sub_Group_Code__c = acr.I_RS_Staff_Sub_Group_Code__c,
            I_RS_Staff_SubGroup_Desc__c = acr.I_RS_Staff_Sub_Group_Desc__c,
            I_RS_Organisation_Code__c = acr.I_RS_Organisation_Code__c,
            I_RS_Organisation_Name__c = acr.I_RS_Organisation_Name__c,
            I_RS_Department_Code__c = acr.I_RS_Department_Code__c,
            I_RS_Department_Name__c = acr.I_RS_Department_Name__c,
            I_RS_School_Code__c = acr.I_RS_School_Code__c,
            I_RS_School_Name__c = acr.I_RS_School_Name__c,
            I_RS_College_Code__c = acr.I_RS_College_Code__c,
            I_RS_College_Name__c = acr.I_RS_College_Name__c,
            I_RS_IsDirect__c = acr.IsDirect,
            I_RS_Data_Source__c = acr.I_RS_Data_Source__c
        );
    }
    
    public static void handlePositionHistory(Map<Id, AccountContactRelation> oldACRs, Map<Id, AccountContactRelation> newACRs) {
        //handling only "new" and "update" scenarios only, not required for "delete"
        List<Position_History__c> poList = new List<Position_History__c>();
        set<Id> contactIds = new set<Id>();
        if (oldACRs == null) {
            for (AccountContactRelation acr: newACRs.values()) {
                if (!(blankPositionHistoryRealtedFields(acr))) {
                    if ((acr.IsDirect) && (acr.I_RS_Part_Of_LaTrobe__c)){
                        poList.add(formPositionHistoryRec(acr)); 
                        contactIds.add(acr.ContactId);
                    }
                }    
            } 
        } else {
            for (AccountContactRelation acr: newACRs.values()) {               

                if (!(noPositionHistoryRealtedFieldChanged(oldACRs.get(acr.Id), acr))) {
                    if ((acr.IsDirect) && (acr.I_RS_Part_Of_LaTrobe__c)){
                        poList.add(formPositionHistoryRec(acr)); 
                        contactIds.add(acr.ContactId);
                    }
                }    
            } 
        } 
        
        if (contactIds.size() > 0) {
        	enddateLastPostionHistoryRecForContact(contactIds);            
        }
               
        if (poList.size() > 0){
            Database.SaveResult[] srList = Database.insert(poList, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('PH create error code & message : ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('PH record that failed to create : ' + err.getFields());
                    }
                }
            }
        }
    }
    
    public static void enddateLastPostionHistoryRecForContact(set<Id> contactIds){
        List<Position_History__c> phRecs2Update = [SELECT Id,I_RS_End_Date__c FROM Position_History__c WHERE Id != null and I_RS_End_Date__c = null and I_RS_Contact__c IN :contactIds];
        If (phRecs2Update.size() > 0){
        Position_History__c phRec = [SELECT id,I_RS_End_Date__c From Position_History__c WHERE Id != null and I_RS_End_Date__c = null and Id = :phRecs2Update[0].Id];  //contactRec.Position_Histories__r;
        system.debug('phRecs2Updatestart>>>' + phRecs2Update);
        for (contact contactRec: [SELECT Id, Name,I_RS_Employment_End_Date__c, (SELECT Id, I_RS_End_Date__c, createddate FROM Position_Histories__r  
                                                    WHERE I_RS_IsDirect__c = true AND I_RS_End_Date__c = NULL and Id != null ORDER By createddate desc LIMIT 1) From Contact WHERE Id in :contactIds]){
                                                        if (phRec.Id != null) {              
                                                            system.debug('phRec>>>>>'+phRec.id);
                                                            if (phRec.I_RS_End_Date__c == null){
                                                                phRec.I_RS_End_Date__c = contactRec.I_RS_Employment_End_Date__c;
                                                                phRecs2Update.add(phRec);    
                                                            }
                                                           system.debug('phRec.I_RS_End_Date__c/////' + contactRec.I_RS_Employment_End_Date__c);
                                                        }
                                                        system.debug('contactRec>>>>>'+contactRec);
                                                    }
        }
        
        MAP<Id,Position_History__c> phMap = new MAP<Id,Position_History__c>();
 		phMap.putall(phRecs2Update);
	 	if(phMap.size()>0){
    	update phMap.values();
        }
        /*system.debug('phRecs2Updateend>>>'+ phRecs2Update);
     if (phRecs2Update.size() > 0) {
            Database.update(phRecs2Update, false);
            
            system.debug('phRecs2Updatecomplete>>>>>>>>'+ phRecs2Update);
       } */
    }
}