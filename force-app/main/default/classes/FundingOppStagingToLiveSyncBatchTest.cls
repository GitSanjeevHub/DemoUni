@isTest
public class FundingOppStagingToLiveSyncBatchTest {
    
    static Integer recordCount = 200;
    
    public static testmethod void oneMatchingNewAccount(){
        
        Account funderOrg = TestUtility.newEmptyExternalAccount('Funder Org');
        funderOrg.I_RS_Funder_Id__c = 'TEST';
        insert funderOrg;

        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Test Funding Opportunity',
                    I_RS_Primary_Funder_Id__c = 'TEST',
                    I_RS_Primary_Funder_Name__c = 'Test Org',
                    I_RS_Prime_Ready__c = true,
                    I_RS_Submission_Date__c = Date.today()
                )
            );
        }

        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        stagingFundingOpportunities = [select Id, I_RS_Funding_Opportunity_Sync_Status__c , I_RS_Funding_Opp_Sync_Error_Message__c  FROM Funding_Opportunity_Staging__c];
        system.assertequals(recordCount, stagingFundingOpportunities.size());
        for (Funding_Opportunity_Staging__c fos : stagingFundingOpportunities){
            system.debug(fos);
            system.assertequals(null, fos.I_RS_Funding_Opp_Sync_Error_Message__c );
            System.assertequals('Successful', fos.I_RS_Funding_Opportunity_Sync_Status__c );
        }
        
        List<Research_Opportunity__c> fundingOpportunities = [select id, I_RS_Submission_Date__c from Research_Opportunity__c];
        System.assertequals(recordCount, fundingOpportunities.size());
        for (Research_Opportunity__c fo : fundingOpportunities){
            System.assertequals(Date.today(), fo.I_RS_Submission_Date__c );
        }
        
        System.assertequals(1, [select COUNT() FROM Account]);
    }
    
    
    
    public static testmethod void differentNewFunders(){
        
        List<Account> funderOrgs = new List<Account>();
        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();

        for (Integer index=0; index<recordCount; index++){

            Account funderOrg = TestUtility.newEmptyExternalAccount('Funder Org'+index);
            funderOrg.I_RS_Funder_Id__c = 'TEST'+index;
            funderOrgs.add(funderOrg);

            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Test Funding Opportunity',
                    I_RS_Primary_Funder_Id__c = 'TEST'+index,
                    I_RS_Primary_Funder_Name__c = 'Test Org'+index,
                    I_RS_Prime_Ready__c = true,
                    I_RS_Submission_Date__c = Date.today()
                )
            );
        }

        insert funderOrgs;

        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        stagingFundingOpportunities = [select Id, I_RS_Funding_Opportunity_Sync_Status__c , I_RS_Funding_Opp_Sync_Error_Message__c  FROM Funding_Opportunity_Staging__c];
        system.assertequals(recordCount, stagingFundingOpportunities.size());
        for (Funding_Opportunity_Staging__c fos : stagingFundingOpportunities){
            system.debug(fos);
            system.assertequals(null, fos.I_RS_Funding_Opp_Sync_Error_Message__c );
            System.assertequals('Successful', fos.I_RS_Funding_Opportunity_Sync_Status__c );
        }
        
        List<Research_Opportunity__c> fundingOpportunities = [select id, I_RS_Submission_Date__c  from Research_Opportunity__c];
        System.assertequals(recordCount, fundingOpportunities.size());
        for (Research_Opportunity__c fo : fundingOpportunities){
            System.assertequals(Date.today(), fo.I_RS_Submission_Date__c );
        }
        
        System.assertequals(recordCount, [select COUNT() FROM Account]);
    }
    
    
    public static testmethod void oneMatchingExistingFunder(){
        
        Account funderOrg = TestUtility.newEmptyExternalAccount('Test Org');
        funderOrg.I_RS_Funder_Id__c = 'TEST';
        insert funderOrg;
        
        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Test Funding Opportunity',
                    I_RS_Primary_Funder_Id__c = 'TEST',
                    I_RS_Primary_Funder_Name__c = 'Test Org',
                    I_RS_Submission_Date__c = Date.today(),
                    I_RS_Prime_Ready__c = true
                )
            );
        }
        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        stagingFundingOpportunities = [select Id, I_RS_Funding_Opportunity_Sync_Status__c , I_RS_Funding_Opp_Sync_Error_Message__c  FROM Funding_Opportunity_Staging__c];
        for (Funding_Opportunity_Staging__c fos : stagingFundingOpportunities){
            system.debug(fos);
            system.assertequals(null, fos.I_RS_Funding_Opp_Sync_Error_Message__c );
            System.assertequals('Successful', fos.I_RS_Funding_Opportunity_Sync_Status__c );
        }
        
        List<Research_Opportunity__c> fundingOpportunities = [select id, I_RS_Submission_Date__c from Research_Opportunity__c];
        System.assertequals(recordCount, fundingOpportunities.size());
        for (Research_Opportunity__c fo : fundingOpportunities){
            System.assertequals(Date.today(), fo.I_RS_Submission_Date__c );
        }
        
        System.assertequals(1, [select COUNT() FROM Account]);
    }

    
    public static testmethod void differentExistingFunders(){
        
        List<Account> orgs = new List<Account>(); 
        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            
            Account funderOrg = TestUtility.newEmptyExternalAccount('Test Org'+index);
            funderOrg.I_RS_Funder_Id__c = 'TEST'+index;
            orgs.add(funderOrg);
            
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Test Funding Opportunity',
                    I_RS_Primary_Funder_Id__c = 'TEST'+index,
                    I_RS_Primary_Funder_Name__c = 'Test Org'+index,
                    I_RS_Prime_Ready__c = true,
                    I_RS_Submission_Date__c = Date.today()
                )
            );
        }
        insert orgs;

        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        stagingFundingOpportunities = [select Id, I_RS_Funding_Opportunity_Sync_Status__c , I_RS_Funding_Opp_Sync_Error_Message__c  FROM Funding_Opportunity_Staging__c];
        system.assertequals(recordCount, stagingFundingOpportunities.size());
        for (Funding_Opportunity_Staging__c fos : stagingFundingOpportunities){
            system.debug(fos);
            system.assertequals(null, fos.I_RS_Funding_Opp_Sync_Error_Message__c );
            System.assertequals('Successful', fos.I_RS_Funding_Opportunity_Sync_Status__c );
        }
        
        List<Research_Opportunity__c> fundingOpportunities = [select id, I_RS_Submission_Date__c  from Research_Opportunity__c];
        System.assertequals(recordCount, fundingOpportunities.size());
        for (Research_Opportunity__c fo : fundingOpportunities){
            System.assertequals(Date.today(), fo.I_RS_Submission_Date__c );
        }
        
        System.assertequals(recordCount, [select COUNT() FROM Account]);
    }
    
    
    
    public static testmethod void propagateEditOnStagingToActual(){
        
        Account funderOrg = TestUtility.newEmptyExternalAccount('Funder Org');
        funderOrg.I_RS_Funder_Id__c = 'TEST';
        insert funderOrg;

        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Test Funding Opportunity',
                    I_RS_Primary_Funder_Id__c = 'TEST',
                    I_RS_Primary_Funder_Name__c = 'Test Org',
                    I_RS_Prime_Ready__c = true,
                    I_RS_Submission_Date__c = Date.today()
                )
            );
        }
        insert stagingFundingOpportunities;
        
        Test.startTest();
        update stagingFundingOpportunities;
        Test.stopTest();
        
        System.assertEquals(recordCount, [SELECT COUNT() FROM Research_Opportunity__c]);
        
        for (Funding_Opportunity_Staging__c fos : stagingFundingOpportunities){
            fos.I_RS_Submission_Date__c = Date.today() + 1;
        }
        update stagingFundingOpportunities;
        
        
        List<Research_Opportunity__c> fundingOpportunities = [select id, I_RS_Submission_Date__c  from Research_Opportunity__c];
        System.assertequals(recordCount, fundingOpportunities.size());
        for (Research_Opportunity__c fo : fundingOpportunities){
            System.assertequals(Date.today() + 1, fo.I_RS_Submission_Date__c );
        }
        
    }
    

    public static testmethod void noMatchingFunder(){

        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Test No Funder',
                    I_RS_Prime_Ready__c = true,
                    I_RS_Primary_Funder_Id__c = 'TEST'
                )
            );
        }
        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Research_Opportunity__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Apex_Debug_Log__c]);
        
        List<Funding_Opportunity_Staging__c> foss = 
            [select id, I_RS_Funding_Opportunity_Sync_Status__c, I_RS_Funding_Opp_Sync_Error_Message__c 
             from Funding_Opportunity_Staging__c];
        for (Funding_Opportunity_Staging__c fos : foss){
            System.assertEquals('No Matching Funder in PRIME', fos.I_RS_Funding_Opportunity_Sync_Status__c);
            System.assertEquals(null, fos.I_RS_Funding_Opp_Sync_Error_Message__c);
        }

    }
    
    
    public static testmethod void singleRowError(){
        
        //Error happens with a validation rule on Actual Funding Opporunity when Name = 'Error'

        Account funderOrg = TestUtility.newEmptyExternalAccount('Funder Org');
        funderOrg.I_RS_Funder_Id__c = 'TEST';
        insert funderOrg;

        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Error',
                    I_RS_Primary_Funder_Id__c = 'TEST',
                    I_RS_Primary_Funder_Name__c = 'Test Org',
                    I_RS_Prime_Ready__c = true
                )
            );
        }
        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Research_Opportunity__c]);
        System.assertequals(recordCount, [select COUNT() from Apex_Debug_Log__c]);

        List<Funding_Opportunity_Staging__c> foss = 
            [select id, I_RS_Funding_Opportunity_Sync_Status__c, I_RS_Funding_Opp_Sync_Error_Message__c 
             from Funding_Opportunity_Staging__c];
        for (Funding_Opportunity_Staging__c fos : foss){
            System.assertEquals('Failed', fos.I_RS_Funding_Opportunity_Sync_Status__c);
            System.assert(fos.I_RS_Funding_Opp_Sync_Error_Message__c != null);
        }
        
    }



    public static testmethod void totalBatchError(){

        //Assumption is a Funder Id or Name will be provided, so not having it is how we
        //test a total batch failure

        FundingOppStagingToLiveSync.throwError = true;

        Account funderOrg = TestUtility.newEmptyExternalAccount('Funder Org');
        funderOrg.I_RS_Funder_Id__c = 'TEST';
        insert funderOrg;
    
        List<Funding_Opportunity_Staging__c> stagingFundingOpportunities = new List<Funding_Opportunity_Staging__c>();
        for (Integer index=0; index<recordCount; index++){
            
            stagingFundingOpportunities.add(
                new Funding_Opportunity_Staging__c(
                    Name='Error',
                    I_RS_Prime_Ready__c = true,
                    I_RS_Primary_Funder_Id__c = 'TEST'
                )
            );
        }
        Test.startTest();
        insert stagingFundingOpportunities;
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Research_Opportunity__c]);
        System.assertEquals(1, [SELECT COUNT() FROM Apex_Debug_Log__c]);
        
        List<Funding_Opportunity_Staging__c> foss = 
            [select id, I_RS_Funding_Opportunity_Sync_Status__c, I_RS_Funding_Opp_Sync_Error_Message__c 
             from Funding_Opportunity_Staging__c];
        for (Funding_Opportunity_Staging__c fos : foss){
            System.assertEquals('Failed', fos.I_RS_Funding_Opportunity_Sync_Status__c);
            System.assert(fos.I_RS_Funding_Opp_Sync_Error_Message__c != null);
        }


    }
    
    
}