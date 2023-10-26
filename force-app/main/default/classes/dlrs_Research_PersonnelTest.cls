/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Research_PersonnelTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Research_PersonnelTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Research_Personnel__c());
    }
}