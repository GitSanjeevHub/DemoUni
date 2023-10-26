public without sharing class ContactManagerPTMAccess implements System.Queueable {
    
    public static Boolean recalculationEnabled = true;

    Set<Id> contactIdsToRecalculateSharingFor;
    

    public static void checkThenExecute(List<Contact> contactsAfterDML, Map<Id, Contact> contactsBeforeDML){

        Set<Id> teamMemberContactIds = new Set<Id>();
        for (Contact contactAfterDML : contactsAfterDML){
            Contact contactBeforeDML = contactsBeforeDML.get(contactAfterDML.Id);

            String previousManagerId = contactBeforeDML.I_RS_Manager__c;
            String currentManagerId = contactAfterDML.I_RS_Manager__c;

            if (previousManagerId != currentManagerId){
                teamMemberContactIds.add(contactAfterDML.Id);
            }
        }

        if (!teamMemberContactIds.isEmpty()){
            ContactManagerPTMAccess access = 
                new ContactManagerPTMAccess(teamMemberContactIds);

            if (!GlobalUtility.currentContextIsAsync()){
                System.enqueueJob(access);
            }
            else {
                access.run();
            }
        }

    }


    public ContactManagerPTMAccess(Set<Id> contactIdsToRecalculateSharingFor){
        this.contactIdsToRecalculateSharingFor = contactIdsToRecalculateSharingFor;
    }


    public void execute(System.QueueableContext qc){
        run();
    }

    void run(){

        List<Project_Team_Member__c> reducedPTMList = [
            SELECT Id, I_RS_Project_Team_Member__c, I_RS_Project_Proposal__c FROM Project_Team_Member__c
        	WHERE I_RS_Project_Team_Member__c IN :contactIdsToRecalculateSharingFor
            AND I_RS_Active__c = TRUE
            AND (I_RS_Role__c != 'Approver' AND I_RS_Role__c != 'Research Centre Member')
        ];
        
        ProjectTeamMemberAccess4.runForTeamMembers(reducedPTMList, 'All', false, false);

    }
}