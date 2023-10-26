global class TaskToOutlookCalendarBatchHandler implements Database.Batchable<SObject>, Database.allowsCallouts{
    
	String operationType;  
    
    private Map<String, String> statusToOperationTypeMap = new Map<String, String>{
        'insert'=>'Insert Pending',
        'update'=>'Update Pending',
        'delete'=>'Delete Pending'
    };
    
    public TaskToOutlookCalendarBatchHandler(String operationType){
        
        System.debug('TaskToOutlookCalendarBatchHandler constructor');
        
        this.operationType = operationType;
        
        System.debug('operationType '+this.operationType);

    }
    
  	global Database.QueryLocator start(Database.BatchableContext BC){
	
        System.debug('Batch start');
        
      String statusToCheckFor = statusToOperationTypeMap.get(operationType);
        System.debug(statusToCheckFor);
        
      String query = 'SELECT Id, Subject, ActivityDate, '+
            'I_RS_Pre_Conditions_and_Instructions__c, '+
            'I_RS_Outlook_Id__c, I_RS_Task_to_Outlook_Sync_Event_Subject__c, I_RS_Task_to_Outlook_Sync_Event_Body__c, '+
            'Owner.Name, Owner.Email, '+
            'I_ST_SACE_Record_Type__c, I_ST_Task_to_Outlook_Sync_Event_Body__c '+
            'FROM Task WHERE I_RS_Task_to_Outlook_Sync_Status__c = \''+statusToCheckFor+'\'';
        System.debug('query '+query);
        
      return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<SObject> taskInputList){

        System.debug('Batch execute');
        System.debug('Task input list '+taskInputList);
        
        List<Task> taskUpdateList = new List<Task>();
        
        for (Task taskToProcess : (List<Task>) taskInputList){
            
            System.debug('Preparing to process Task '+taskToProcess);
            system.debug('Executing callout from batch handler');
            
            Task processedTask = new TaskToOutlookCalendarCallout(taskToProcess, operationType).execute();
            taskUpdateList.add(processedTask);                
            
        }
        
        //if (!taskUpdateList.isEmpty())
            upsert taskUpdateList;
        
        
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Batch job completed');
    }
}