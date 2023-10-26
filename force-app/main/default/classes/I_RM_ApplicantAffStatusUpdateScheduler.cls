public with sharing class I_RM_ApplicantAffStatusUpdateScheduler implements Schedulable{
    public Integer batchSize = 0;
    public I_RM_ApplicantAffStatusUpdateScheduler(Integer batchSize){
        this.batchSize = batchSize;
        /*Do it from annonamous window.
        I_RM_ApplicantAffStatusUpdateScheduler SC = new I_RM_ApplicantAffStatusUpdateScheduler(20); 
        return system.schedule('Activity Scoring Job', cronExpression, SC);*/
    }
    public void execute(SchedulableContext sc) {
		I_RM_ApplicantAffStatusUpdateBatch b = new I_RM_ApplicantAffStatusUpdateBatch();        
      	database.executebatch(b,batchSize);
   	}
}