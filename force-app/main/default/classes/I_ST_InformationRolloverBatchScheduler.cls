global with sharing class I_ST_InformationRolloverBatchScheduler implements Schedulable{
	Integer BatchSize;
 global I_ST_InformationRolloverBatchScheduler(Integer BatchSize){
	 this.BatchSize = BatchSize;
 }
 global void execute(SchedulableContext sc) {
	 I_ST_InformationRolloverBatch b = new I_ST_InformationRolloverBatch(); 
	   database.executebatch(b, BatchSize);
	}
}