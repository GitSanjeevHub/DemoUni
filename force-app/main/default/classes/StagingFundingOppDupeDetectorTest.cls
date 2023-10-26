@isTest
public class StagingFundingOppDupeDetectorTest {

    public static testmethod void getPotentialDuplicateFunders(){
        
        Account funderOrg = TestUtility.newEmptyExternalAccount('funderOrg');
        insert funderOrg;
        
        Test.setFixedSearchResults(new List<String>{(String) funderOrg.Id});
		
        System.assert(StagingFundingOppDupeDetectorController.getPotentialDuplicateFunders('funderOrg').size() > 0);
        
    }
    
    
    public static testmethod void markMatchingStagingOppsAsPRIMEReady(){
        
        List<Account> funderOrgs = new List<Account>{
            TestUtility.newEmptyExternalAccount('funderOrg1'),
            TestUtility.newEmptyExternalAccount('funderOrg2')
		};
        insert funderOrgs;
        
        List<Funding_Opportunity_Staging__c> stagingOpps = new List<Funding_Opportunity_Staging__c>();
        for (Integer i=0; i<100; i++){
            
            stagingOpps.addAll(new List<Funding_Opportunity_Staging__c>{
                new Funding_Opportunity_Staging__c(
                    I_RS_PRIME_Ready__c = true,
                    I_RS_RP_Id__c = 'RPID1'+i,
                    I_RS_Primary_Funder_Id__c = 'FUNDER1',
                    I_RS_Primary_Funder_Name__c = 'FUNDER1'
                ),
                new Funding_Opportunity_Staging__c(
                    I_RS_PRIME_Ready__c = true,
                    I_RS_RP_Id__c = 'RPID1'+i,
                    I_RS_Primary_Funder_Id__c = 'FUNDER2',
                    I_RS_Primary_Funder_Name__c = 'FUNDER2'
                )
            });
        }
        insert stagingOpps;
        
        System.assertequals(0, [SELECT COUNT() FROM Research_Opportunity__c]);
        
        funderOrgs[0].I_RS_Funder_Id__c = 'FUNDER1';
        funderOrgs[1].I_RS_Funder_Id__c = 'FUNDER2';
        update funderOrgs;
        
        StagingFundingOppDupeDetectorController.markMatchingStagingOppsAsPRIMEReady(new List<String>{'FUNDER1','FUNDER2'});
        
        System.assertequals(100, [SELECT COUNT() FROM Research_Opportunity__c WHERE I_RS_Organisation__c = :funderORgs[0].Id]);
        System.assertequals(100, [SELECT COUNT() FROM Research_Opportunity__c WHERE I_RS_Organisation__c = :funderORgs[1].Id]);
    }
    
}