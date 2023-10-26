/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Related_Ethics_AgreementTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Related_Ethics_AgreementTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Related_Ethics_Agreement__c());
    }
}