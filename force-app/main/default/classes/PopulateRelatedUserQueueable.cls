public class PopulateRelatedUserQueueable implements Queueable {

    private Map<Id, Id> contactUserMap;
    public PopulateRelatedUserQueueable(List<User> users) {
        contactUserMap = new Map<Id, Id>();
        for (User u: users) {
			contactUserMap.put(u.ContactId, u.Id);
        }
    }    
    
    public void execute(QueueableContext queCont) {
        PopulateContactRelatedUser();
        PopulateContactUserInPTM();
    }

    private void PopulateContactUserInPTM() {
		Id userId;
        List<Project_Team_Member__c> PTMs = new List<Project_Team_Member__c>();
        for (Project_Team_Member__c ptm: [SELECT Id, I_RS_Project_Team_Member__c, I_RS_Team_Member_User__c FROM Project_Team_Member__c WHERE I_RS_Project_Team_Member__c IN :contactUserMap.keySet()]) {
            userId = contactUserMap.get(ptm.I_RS_Project_Team_Member__c);
            if (ptm.I_RS_Team_Member_User__c != userId) {
                ptm.I_RS_Team_Member_User__c = userId;
            	PTMs.add(ptm);
            }
        }
        
        try {
            Database.SaveResult[] srList = Database.update(PTMs, false);
            Integer recIndex=0;
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) { 
                        System.debug('Error updating PTM PopulateRelatedUserQueueable: ' +PTMs.get(recIndex).Id + ': ' + err.getMessage());
                    }
                }
                recIndex++;
            }  

        } catch(DmlException e){
			System.debug('PopulateRelatedUserQueueable: Error in upserting Project Team Member records - ' + e.getMessage());
		}
    }
    
    private void PopulateContactRelatedUser() {
        List<Contact> Contacts = new List<Contact>();
        for (Id cId: contactUserMap.keySet()) {
        	Contact c = new Contact(Id = cId, I_RS_Related_User__c = contactUserMap.get(cId));
            Contacts.add(c);
        }
        
        try {
            Database.SaveResult[] srList = Database.update(Contacts, false);
            Integer recIndex=0;
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) { 
                        System.debug('Error updating Contacts PopulateRelatedUserQueueable: ' +Contacts.get(recIndex).Id + ': ' + err.getMessage());
                    }
                }
                recIndex++;
            }  
        } catch(DmlException e){
			System.debug('PopulateRelatedUserQueueable: Error in upserting Related Users in Contact records - ' + e.getMessage());
		}
    }
}