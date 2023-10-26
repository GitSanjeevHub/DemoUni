public class L_PR_Idea_OrganisationTriggerHandler{
    public static void execute() {

        List<L_PR_Idea_Organisation__c> listOfIdeaOrgToUpdate = New List<L_PR_Idea_Organisation__c>();
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                List<L_PR_Idea_Organisation__c> listOfIdeaOrg = [Select Id, L_PR_Idea__r.L_PR_Lead_Status__c from L_PR_Idea_Organisation__c where Id In : Trigger.New];
                for(L_PR_Idea_Organisation__c ideaOrg :listOfIdeaOrg){
                    L_PR_Idea_Organisation__c idea = New L_PR_Idea_Organisation__c();
                    idea.L_PR_LeadStatus__c = ideaOrg.L_PR_Idea__r.L_PR_Lead_Status__c;
                    idea.Id = ideaOrg.Id;
                    listOfIdeaOrgToUpdate.add(idea);
                }
                system.debug('###listOfIdeaOrgToUpdate'+ listOfIdeaOrgToUpdate);
                if(!listOfIdeaOrgToUpdate.isEmpty()){
                    update listOfIdeaOrgToUpdate;
                }

            }
        }
    }
}