public with sharing class ContractTriggerHelper{


    //LTU360-2384 update the L_PR_Agreement_Status__c fild in Related_Contract__c when there is an update in Agreement I_RS_Status__c field
    public static void updateRelatedOrgStatus(Map<Id,String> agreementStatusMap){

        List<Related_Contract__c> agreementStatusToUpdate = new List<Related_Contract__c>();
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
        try{
            if(agreementStatusMap != null){
                for(Related_Contract__c relOrgAgr : [Select Id, I_RS_Contract__c, L_PR_Agreement_Status__c, I_RS_Organisation__c
                                                                           From Related_Contract__c Where I_RS_Contract__c IN : agreementStatusMap.keySet()]){
                                                                            
                    Related_Contract__c relOrg = new Related_Contract__c();
                    relOrg.Id = relOrgAgr.Id;
                    relOrg.L_PR_Agreement_Status__c = agreementStatusMap.get(relOrgAgr.I_RS_Contract__c);                                             
                    agreementStatusToUpdate.add(relOrg);
                }
            }

 
            if(!agreementStatusToUpdate.isEmpty()){
                update agreementStatusToUpdate;
            }

        }catch(Exception e){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'ContractTriggerHelper', Apex_Class_Method_Name__c = 'updateRelatedOrgStatus',
                Exception_message__c = 'exception while updating the L_PR_Agreement_Status__c in ContractTriggerHelper', Exception_Stack_Trace__c = e.getStackTraceString()));
                if (errorLogs != null && !errorLogs.isEmpty()){
                    insert errorLogs;
                 errorLogs.clear();
                }
        }

    }


    public static void createUpdateRelatedOrgs(Map<Id,Id> agrOrgMap, Map<Id,Id> removeAgrOrgMap, String orgType, Map<Id,Contract__c> mapOfAgreements){

        List<Related_Contract__c> relatedOrgs = new List<Related_Contract__c>();
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
        try{
            if(agrOrgMap != Null){
                  //check if the current Agreement organisation pair exist in Related organisation relationship records                      
                  List<Related_Contract__c> existingRelatedOrgs = [SELECT Id, I_RS_Contract__c,L_PR_isPrimary__c, I_RS_Organisation__c, L_PR_Agreement_Recordtype__c FROM Related_Contract__c
                                                                  where I_RS_Contract__c IN: agrOrgMap.keySet() AND I_RS_Organisation__c IN: agrOrgMap.values()];
                      if(!existingRelatedOrgs.isEmpty()){ 
                       // if Found, mark IsPrimary True for that record
                      		for(Related_Contract__c exLOrg : existingRelatedOrgs){
                                //  update existing opportunity organisation relationship
                                Related_Contract__c agrOrg = new Related_Contract__c();
                                agrOrg.Id = exLOrg.Id;
                            	agrOrg.L_PR_isPrimary__c = True; 
                            	relatedOrgs.add(agrOrg);
                            }
                        }
                        else{
                            // if no existing record found, create new record with agreement & organisation relationship and isPrimary true
                            for(Id agr : agrOrgMap.keySet()){
                             	//create agreement organisation relationship record
                                Related_Contract__c agrOrg = new Related_Contract__c();
                            	agrOrg.I_RS_Organisation__c = agrOrgMap.get(agr);
                            	agrOrg.I_RS_Contract__c = agr;
                            	agrOrg.L_PR_isPrimary__c = True;
                                agrOrg.L_PR_Agreement_Recordtype__c = getAgreementRecordTypeName(mapOfAgreements.get(agr).RecordTypeId);
                            	relatedOrgs.add(agrOrg);
                            }
                        }

                        // find all agreement organisation relationships where agreement is present and isPrimary ticked
                        // or any other agreement organisation relationship is present with isprimary true
                        for(Related_Contract__c ActivelOrgList : [SELECT Id, I_RS_Contract__c,I_RS_Organisation__c,I_RS_Organisation__r.recordType.Name, L_PR_isPrimary__c,L_PR_Agreement_Recordtype__c FROM Related_Contract__c
                                                                    WHERE (I_RS_Contract__c in: agrOrgMap.keySet() AND I_RS_Organisation__c NOT IN: agrOrgMap.values() AND L_PR_isPrimary__c = TRUE)
                                                                    OR (I_RS_Contract__c in: removeAgrOrgMap.keySet() AND I_RS_Organisation__c in: removeAgrOrgMap.values())]){
                        //  update existing lead organisation relationship
                            if(orgType =='External' && (ActivelOrgList.I_RS_Organisation__r.recordType.Name == 'External Organisation' || ActivelOrgList.I_RS_Organisation__r.recordType.Name == 'Educational Institution')){
                                Related_Contract__c agrOrg = new Related_Contract__c();
                                agrOrg.Id = ActivelOrgList.Id;
                                agrOrg.L_PR_IsPrimary__c = False; 
                                relatedOrgs.add(agrOrg);   
                            }
                            else if(orgType =='Internal' && ActivelOrgList.I_RS_Organisation__r.recordType.Name == 'La Trobe Organisation Unit'){
                                Related_Contract__c agrOrg = new Related_Contract__c();
                                agrOrg.Id = ActivelOrgList.Id;
                                agrOrg.L_PR_IsPrimary__c = False; 
                                relatedOrgs.add(agrOrg);   
                                }
                        }  
                    }
                    if(relatedOrgs != null){
                        upsert relatedOrgs;
                    }
        		}catch(exception e){
                    errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'ContractTriggerHelper', Apex_Class_Method_Name__c = 'createUpdateRelatedOrgs',
                        Exception_message__c = 'exception while updating the isPrimary in ContractTriggerHelper', Exception_Stack_Trace__c = e.getStackTraceString()));
                        if (errorLogs != null && !errorLogs.isEmpty()){
                            insert errorLogs;
                         errorLogs.clear();
                        } 
                }                    
    }

    public static String getAgreementRecordTypeName(Id agreementId){

        return Schema.getGlobalDescribe().get('Contract__c').getDescribe().getRecordTypeInfosById().get(agreementId).getName();
    }
    
    // Method to update prm opportunity status to closed won
    public static void updateOppStatusClosedWon(Map<Id,Id> oppAggMap){
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
        try{
            List<Opportunity> oppList = new List<Opportunity>();
            for(Id oppId : oppAggMap.keyset()){
                Opportunity opp = new Opportunity(Id=oppId);
                opp.StageName ='Closed Won';
                opp.CloseDate = system.today();
                oppList.add(opp);
            }
            if(!oppList.isEmpty())
                update oppList;
			
        }catch(Exception ex){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'ContractTriggerHelper',Apex_Class_Method_Name__c = 'updateOppStatusClosedWonId',Exception_message__c = ex.getMessage(),Exception_Stack_Trace__c = ex.getStackTraceString()));
            		if (errorLogs != null && !errorLogs.isEmpty()){
               			insert errorLogs;
            			errorLogs.clear();
            		} 
        }
    }


    //LTU360-2659 Create agreement tasks from the Task Matrix

    public static void createTasksFromTaskMatrix(Map<Id,Contract__c> triggerMap){

        Map<Id, Task_Matrix__c> mapOfAllTaskMatrix = new Map<Id, Task_Matrix__c>();
        List<Task> taskListToCreate = new List<Task>();
        List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
        Map<Id,List<String>> agrTaskMap = new Map<Id,List<String>>();
        for(Task tsk : [SELECT Id, Subject, WhatId FROM Task WHERE WhatId IN : triggerMap.keySet()]){
            if(agrTaskMap.containsKey(tsk.WhatId)){
                agrTaskMap.get(tsk.WhatId).add(tsk.Subject);
            } else {
                agrTaskMap.put(tsk.WhatId, new List<String>{tsk.Subject});
            }
        }

        try{
            for(Task_Matrix__c taskMatrix: [SELECT Id, Name, L_PR_Agreement_Type__c, I_RS_Object_Name__c, I_RS_Record_Type__c, L_PR_Agreement_Stage__c, I_RS_Subject__c
            FROM Task_Matrix__c WHERE  I_RS_Object_Name__c ='Agreement' AND I_RS_Inactive__c= FALSE]){
                for(Id aggr: triggerMap.keySet()){
                    if(triggerMap.get(aggr).I_RS_Closure_Reason__c == null && taskMatrix.L_PR_Agreement_Stage__c == 'Terminated'){
                        Task newTask = new Task();
                    }
                    else if(( taskMatrix.L_PR_Agreement_Stage__c == 'Executed' && triggerMap.get(aggr).I_RS_Agreement_Type__c == taskMatrix.L_PR_Agreement_Type__c 
                    && triggerMap.get(aggr).I_RS_Closure_Reason__c == null)){
                        if(agrTaskMap.isEmpty() || (!agrTaskMap.isEmpty() && !agrTaskMap.get(aggr).contains(taskMatrix.I_RS_Subject__c))){
                            taskListToCreate.add(ContractTriggerHelper.createTask(taskMatrix.I_RS_Subject__c, aggr, triggerMap.get(aggr).OwnerId, taskMatrix.L_PR_Agreement_Stage__c));
                        }
                    }else if (triggerMap.get(aggr).I_RS_Closure_Reason__c != null && triggerMap.get(aggr).I_RS_Agreement_Type__c == taskMatrix.L_PR_Agreement_Type__c 
                    && triggerMap.get(aggr).I_RS_Closure_Reason__c == taskMatrix.L_PR_Agreement_Stage__c){
                        if(agrTaskMap.isEmpty() || (!agrTaskMap.isEmpty() && !agrTaskMap.get(aggr).contains(taskMatrix.I_RS_Subject__c))){
                            taskListToCreate.add(ContractTriggerHelper.createTask(taskMatrix.I_RS_Subject__c, aggr, triggerMap.get(aggr).OwnerId, taskMatrix.L_PR_Agreement_Stage__c));
                        }
                    }
                
                }
            }

            if(!taskListToCreate.isEmpty()){
                insert taskListToCreate;
            }
        }catch(Exception e){
            errorLogs.add(new Apex_Debug_Log__c(Apex_Class_Name__c = 'ContractTriggerHelper', Apex_Class_Method_Name__c = 'createTasksFromTaskMatrix',
                Exception_message__c = 'exception while creating the tasks for the agreement in ContractTriggerHelper', Exception_Stack_Trace__c = e.getStackTraceString()));
                if (errorLogs != null && !errorLogs.isEmpty()){
                    insert errorLogs;
                 errorLogs.clear();
                } 
        }

    }


    public static Task createTask(String taskSubject, Id agrId, String ownerId, String agrStage){
        Id taskAgreementRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('L_PR_Agreement_Task').getRecordTypeId();
        Task newTask = new Task();
        newTask.Subject = taskSubject;
        newTask.WhatId = agrId;
        newTask.Status = 'Not Started';
        newTask.RecordTypeId = taskAgreementRecordTypeId;
        newTask.OwnerId =  ownerId;
        newTask.L_PR_Stage__c = agrStage;
        return newTask;
    }

}