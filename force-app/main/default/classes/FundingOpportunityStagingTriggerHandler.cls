public class FundingOpportunityStagingTriggerHandler {

    public static void execute(){
    
        System.debug('FundingOpportunityStagingTriggerHandler');
        System.debug(Trigger.operationType);
		System.debug(Trigger.New);
        System.debug(Trigger.oldMap);
        
    	if (Trigger.isBefore){
        
            if (Trigger.isInsert){
                
            	new FundingOppStagingToLiveSync().run(Trigger.new, 
                                                      (Map<Id, Funding_Opportunity_Staging__c>) Trigger.OldMap);
            }
            
        	if (Trigger.isUpdate){
            	new FundingOppStagingToLiveSync().run(Trigger.new, 
                                                      (Map<Id, Funding_Opportunity_Staging__c>) Trigger.OldMap);            
        	}
        
    	}
        
    }
    
}