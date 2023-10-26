public class ResearchOutputClassificationCodeHelper {
    public void validateUserIsPartOfAuthorship(List<Research_Output_Classification_Code__c> roccList){
        User currentUser = [SELECT ID, ContactId, I_RS_Is_Researcher_User__c FROM User WHERE Id = :UserInfo.getUserId()];
        if ((currentUser.I_RS_Is_Researcher_User__c == '1')&& (currentUser.ContactId <> null) ){
            Map<Id, set<Id>> roAuthorMap = new Map<Id, set<Id>>();
            // get the map of Research Output and Authors Ids
            for (Research_Output_Classification_Code__c rocc: roccList) {
                if (!roAuthorMap.containsKey(rocc.I_RS_Research_Output__c)) {
                    roAuthorMap.put(rocc.I_RS_Research_Output__c, new set<Id>());
                }
            }
            
            //get Authors associated to Research Output
            if (!roAuthorMap.isEmpty()){
                set<Id> tempAuths;
                for (Authorship_Research_Output_Team_Member__c auth: 
                [Select Id,I_RS_Contact__c,I_RS_Research_Output__c 
                 FROM Authorship_Research_Output_Team_Member__c
                 WHERE I_RS_Research_Output__c IN :roAuthorMap.keySet()]){
                    tempAuths = roAuthorMap.get(auth.I_RS_Research_Output__c);
                     if (!tempAuths.contains(auth.I_RS_Contact__c)) {
                         tempAuths.add(auth.I_RS_Contact__c);
                     }
                     roAuthorMap.put(auth.I_RS_Research_Output__c, tempAuths);
                 }
            }
            
            //now parse through and validate if the user is part of authorship table for the Researchoutput
            for (Research_Output_Classification_Code__c rocc: roccList){
            	if ((!roAuthorMap.containsKey(rocc.I_RS_Research_Output__c)) ||
                    (!roAuthorMap.get(rocc.I_RS_Research_Output__c).contains(currentUser.ContactId))) {
                        //rocc.addError(GlobalConstants.RESTRICT_CREATE_MODIFY_CODE_TO_RESEARCHOUTPUT);
                        rocc.addError('You do not have permission to create/modify codes for this research Output');                        
                }
            }
        }        
    }
}