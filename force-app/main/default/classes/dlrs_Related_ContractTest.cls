/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Related_ContractTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Related_ContractTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Related_Contract__c());
    }
}