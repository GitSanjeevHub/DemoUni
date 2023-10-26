/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Review_TimeTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Review_TimeTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Review_Time__c());
    }
}