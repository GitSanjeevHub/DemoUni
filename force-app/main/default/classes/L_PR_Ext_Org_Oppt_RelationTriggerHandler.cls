public without sharing class L_PR_Ext_Org_Oppt_RelationTriggerHandler{

    public static void execute(){
        List<L_PR_External_Org_Opportunity_Relation__c> listOfExtOrgToUpdate = New List<L_PR_External_Org_Opportunity_Relation__c>();                       
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
        if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                try{
                    List<L_PR_External_Org_Opportunity_Relation__c> listOfExtOrgs = [Select Id, L_PR_IsPrimary__c, L_PR_Opportunity_Name__r.StageName, L_PR_OpportunityStage__c, L_PR_Organisation_Name__c
                    From L_PR_External_Org_Opportunity_Relation__c Where Id IN : Trigger.New];
                    map<Id,L_PR_External_Org_Opportunity_Relation__c> mapOldExtOrgs = (map<Id,L_PR_External_Org_Opportunity_Relation__c>)Trigger.oldMap;
                    for(L_PR_External_Org_Opportunity_Relation__c eorg : listOfExtOrgs){
                        L_PR_External_Org_Opportunity_Relation__c extOrg = New L_PR_External_Org_Opportunity_Relation__c();
                        if(eorg.L_PR_Opportunity_Name__r.StageName != null && (Trigger.isInsert || (Trigger.isUpdate && eorg.L_PR_Opportunity_Name__r.StageName != mapOldExtOrgs.get(eorg.id).L_PR_OpportunityStage__c))) {
                            extOrg.L_PR_OpportunityStage__c = eorg.L_PR_Opportunity_Name__r.StageName;
                            extOrg.Id = eorg.Id;
                            listOfExtOrgToUpdate.add(extOrg);
                        }
                    }
                    if(!listOfExtOrgToUpdate.isEmpty()){
                        update listOfExtOrgToUpdate;
                    }
                }catch(Exception e){
                    errorLogs.add(new Apex_Debug_Log__c(
                        Apex_Class_Name__c = 'L_PR_Ext_Org_Oppt_RelationTriggerHandler',
                        Apex_Class_Method_Name__c = 'L_PR_Ext_Org_Oppt_RelationTriggerHandler',
                        Exception_message__c = 'Exception while updating the L_PR_OpportunityStage__c field in L_PR_External_Org_Opportunity_Relation__c',
                        Exception_Stack_Trace__c = e.getStackTraceString()));
                }
            }
        }

    }
}