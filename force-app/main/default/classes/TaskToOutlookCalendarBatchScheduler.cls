global class TaskToOutlookCalendarBatchScheduler implements Schedulable{
    
    String operationType;
   	Integer batchSize;
    
    global TaskToOutlookCalendarBatchScheduler(String operationType, Integer batchSize){
        this.operationType = operationType;
        this.batchSize = batchSize;
    }
    
	global void execute(SchedulableContext sc) {
		TaskToOutlookCalendarBatchHandler b = new TaskToOutlookCalendarBatchHandler(operationType); 
      	database.executebatch(b, batchSize);
   	}

}