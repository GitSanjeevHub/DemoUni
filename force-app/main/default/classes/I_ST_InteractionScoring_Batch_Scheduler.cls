/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_InteractionScoring_Batch_Scheduler
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2022-02-18
* @Description	  This class is used to calculate Activity Score on Affiliation
* @Params	  	  <sObjectName>: Object API Name, <recordTypeIds>: Set of RecordTypeIds for Score Calculation, lastNumberOfHours: Run batch past N Hours
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/
global  without sharing class I_ST_InteractionScoring_Batch_Scheduler implements Schedulable {
    private Set<Id> recordTypeIds;
    private Integer lastNHours = 24;
    private Decimal batchSize = 30;
    
    //Call this method from developer console directly to schedule the batch
    //Use command I_ST_InteractionScoring_Batch_Scheduler.scheduleActivityScoring() from developer console after setting up the custom setting - Batch Scoring
    global static String scheduleActivityScoring() {        
        String cronExpression = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_INTERACTIONSCORING).I_ST_CronExpression__c ;
        I_ST_InteractionScoring_Batch_Scheduler SC = new I_ST_InteractionScoring_Batch_Scheduler(); 
        return system.schedule('Interaction Activity Scoring Job', cronExpression, SC);        
    }
    
    global void execute(SchedulableContext sc) {
        
        //GET the Batch Scoring custom setting for required parameters      
        
        I_ST_BatchScoring__c batchScoringCustomSetting = I_ST_BatchScoring__c.getValues(GlobalConstants.I_ST_INTERACTIONSCORING);
        
        lastNHours = (Integer)batchScoringCustomSetting.I_ST_Last_N_Hour__c;
        Set<Id> recordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringCustomSetting.I_ST_RecordType_SFIDs__c);
        batchSize = batchScoringCustomSetting.I_ST_BatchSize__c;
        
        I_ST_InteractionScoring_Batch leadScoringBatch = new I_ST_InteractionScoring_Batch(GlobalConstants.INTERACTION_OBJECT_API_NAME,recordTypeIds,lastNHours);
        Database.executeBatch(leadScoringBatch,Integer.valueOf(batchSize));
        }
    }