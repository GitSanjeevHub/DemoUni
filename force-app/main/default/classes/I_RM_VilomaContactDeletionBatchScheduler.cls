global with sharing class I_RM_VilomaContactDeletionBatchScheduler implements Schedulable {

    global void execute(SchedulableContext ctx) {
        I_RM_VilomaContactDeletionBatch contactDeletionBatch = new I_RM_VilomaContactDeletionBatch();
         database.executeBatch(contactDeletionBatch);
    }   
 }