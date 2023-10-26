/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_ActivityScoring_Batch_Scheduler
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* @Description	  This class is used to schedule the batch job to calaculate Activity Score on Affiliation
* @Params	  	  
*/
global class I_ST_ActivityScoring_Batch_Scheduler implements Schedulable {
    private Set<Id> recordTypeIds;
    private Integer lastNHours = 24;
    private Decimal batchSize = 30;
    
    //Call this method from developer console directly to schedule the batch
    //Use command I_ST_ActivityScoring_Batch_Scheduler2.scheduleActivityScoring() from developer console
    global static String scheduleActivityScoring() {
       
            String cronExpression = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_CASESCORING).I_ST_CronExpression__c ;
            I_ST_ActivityScoring_Batch_Scheduler SC = new I_ST_ActivityScoring_Batch_Scheduler(); 
            return system.schedule('Activity Scoring Job', cronExpression, SC);
       
    }
    
    global void execute(SchedulableContext sc) { 
        
        //GET the Batch Scoring custom setting for required parameters      
        I_ST_BatchScoring__c batchScoringCustomSetting = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_CASESCORING);
        
        lastNHours = (Integer)batchScoringCustomSetting.I_ST_Last_N_Hour__c;
        Set<Id> recordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringCustomSetting.I_ST_RecordType_SFIDs__c);
        batchSize = batchScoringCustomSetting.I_ST_BatchSize__c;
        
        I_ST_ActivityScoring_Batch leadScoringBatch = new I_ST_ActivityScoring_Batch(GlobalConstants.CASE_OBJECT_API_NAME,recordTypeIds,lastNHours);
        Database.executeBatch(leadScoringBatch,Integer.valueOf(batchSize));
        }
    }