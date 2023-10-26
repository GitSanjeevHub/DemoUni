/* created by : IST Team On 05-11-2020*/

global with sharing class I_ST_AccountDeleteBatchSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new I_ST_AccountDeleteBatch(), 200);
    }

    /*
    Run below schedular through Dev Console and change timings or schedule through UI--------

    I_ST_AccountDeleteBatchSchedule IADS = new I_ST_AccountDeleteBatchSchedule();
    String sch = '0 0 23 31 12 ?'; // 11 pm on 31 dec
    system.schedule('Execute Account Delete Scheduler', sch, IADS);
    */

}