/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_OpportunityTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_OpportunityTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        Account acc = new Account();
        acc.Name = 'Test Acc2';
        acc.I_RS_Status__c ='Active';
        Insert acc;
        dlrs.RollupService.testHandler(new Opportunity(Name ='Test Opp', StageName ='Development', CloseDate = System.today()+30, AccountId = acc.Id));
    }
}