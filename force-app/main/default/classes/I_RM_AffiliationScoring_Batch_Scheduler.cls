/* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_AffiliationScoring_Batch2Test
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
  @JIRA           LTU360-867 
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2022-02-18      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global with sharing class I_RM_AffiliationScoring_Batch_Scheduler  implements Schedulable  {
    private Set<Id> recordTypeIds;
    private Integer lastNHours = 24;
    private Decimal batchSize = 30;
    
    //Call this method from developer console directly to schedule the batch
    //Use command I_ST_AffiliationScoring_Batch_Scheduler.scheduleActivityScoring() from developer console
    global static String scheduleActivityScoring() {
        
        String cronExpression = I_ST_BatchScoring__c.getValues(GlobalConstants.I_RM_AFFILIATIONSCORING).I_ST_CronExpression__c ;
        I_RM_AffiliationScoring_Batch_Scheduler SC = new I_RM_AffiliationScoring_Batch_Scheduler(); 
        String schName = Test.isRunningTest() ? 'Test Affiliation/Lead Scoring Job'
            								  : 'Affiliation/Lead Scoring Job';
        return system.schedule(schName, cronExpression, SC);
        
    }
    
    global void execute(SchedulableContext SC) {

        I_ST_BatchScoring__c batchScoringCustomSetting = I_ST_BatchScoring__c.getValues(GlobalConstants.I_RM_AFFILIATIONSCORING);
        
        lastNHours = (Integer)batchScoringCustomSetting.I_ST_Last_N_Hour__c;
        Set<Id> recordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringCustomSetting.I_ST_RecordType_SFIDs__c);
        batchSize = batchScoringCustomSetting.I_ST_BatchSize__c;
        
        I_RM_AffiliationScoring_Batch leadScoringBatch = new I_RM_AffiliationScoring_Batch(GlobalConstants.AFFILIATION_OBJECT_API_NAME,recordTypeIds,lastNHours);
        Database.executeBatch(leadScoringBatch,Integer.valueOf(batchSize));
    }


}