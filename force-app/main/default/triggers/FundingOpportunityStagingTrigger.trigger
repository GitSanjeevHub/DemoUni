trigger FundingOpportunityStagingTrigger on Funding_Opportunity_Staging__c (before insert, before update) {

    if (!GlobalUtility.isTriggerDisabled('Funding_Opportunity_Staging__c')){
        FundingOpportunityStagingTriggerHandler.execute();
    }
    
}