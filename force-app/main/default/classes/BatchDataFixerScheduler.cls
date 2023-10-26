public without sharing class BatchDataFixerScheduler implements System.Schedulable{

    String dataFixerJobName;
    Integer batchSize;

    public BatchDataFixerScheduler(String dataFixerJobName, Integer batchSize) {
        this.dataFixerJobName = dataFixerJobName;
        this.batchSize = batchSize;
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new BatchDataFixer(dataFixerJobName), batchSize);
    }

}