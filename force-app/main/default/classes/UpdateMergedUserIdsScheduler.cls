public class UpdateMergedUserIdsScheduler implements Schedulable{

    Integer batchSize;

    public UpdateMergedUserIdsScheduler(Integer batchSize) {
        this.batchSize = batchSize;
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new batchUpdateMergedUserIds(), batchSize);
    }
}