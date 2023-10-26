/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Budget_Line_ItemTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Budget_Line_ItemTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Budget_Line_Item__c());
    }
}