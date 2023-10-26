public class StagingFundingOppDupeDetectorController {

    @AuraEnabled
    public static List<Account> getPotentialDuplicateFunders(String searchTerm){
        
        System.debug('searchTerm '+searchTerm);
        
        List<Account> potentialDuplicates = [
            FIND :searchTerm
            RETURNING Account(Id, Name, I_RS_ABN__c, Website, Parent.Name WHERE I_RS_Funder_Id__c = NULL LIMIT 20)
        ][0];
        
       	System.debug('potentialDuplicates '+potentialDuplicates);
        
        return potentialDuplicates;
    }
    
    
    @InvocableMethod
    public static void markMatchingStagingOppsAsPRIMEReady(List<String> funderIdList){
        
        System.debug('markMatchingStagingOppsAsPRIMEReady');
        System.debug(funderIdList);
        
        Set<String> funderIdSet = new Set<String>(funderIdList);
        
        List<Funding_Opportunity_Staging__c> fundingOppsWithMatchingFunderId = [
            SELECT Id, Name, I_RS_Primary_Funder_Id__c from Funding_Opportunity_Staging__c WHERE 
            	I_RS_Primary_Funder_Id__c IN :funderIdSet AND
            	I_RS_Funding_Opportunity_Sync_Status__c = 'No Matching Funder in PRIME' AND 
            	I_RS_PRIME_Ready__c = false
        ];
        
        for (Funding_Opportunity_Staging__c fundingOpp : fundingOppsWithMatchingFunderId){
            fundingOpp.I_RS_PRIME_Ready__c = true;
            System.debug(fundingOpp);
        }
        
		update fundingOppsWithMatchingFunderId;
    }
    
}