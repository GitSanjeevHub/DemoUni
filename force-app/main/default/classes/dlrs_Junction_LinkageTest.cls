/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Junction_LinkageTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Junction_LinkageTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Junction_Linkage__c());
    }
}