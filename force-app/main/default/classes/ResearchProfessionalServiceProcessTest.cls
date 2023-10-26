@isTest
private class ResearchProfessionalServiceProcessTest  {
    @testSetup static void TestData(){
        
        Research_Professional_Settings__c setting = new Research_Professional_Settings__c();
        setting.Name = 'RP_API_details';
        setting.Batch_Delay__c = 100;
        setting.Batch_Delay_Upon_Failure__c = 1;
        setting.Batch_Delay_Upon_Failure_Multiplier__c = 2;
        setting.Maximum_Number_of_Batch_Retries__c = 3;
        setting.Eligibility_Regions__c = 'Australia';
        setting.Api_Key__c = 'abcd';
        setting.API_Password__c = 'test';
        setting.Api_Url__c = 'https://demo-api.researchprofessional.com/funding/v1/fops/search?query=social%20sciences,physical%20sciences%20and%20engineering,bio%2Fmedical,arts%20and%20humanities';
        Insert setting;
    }
    
    static testMethod void testSuccessfulCallout() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('RP_Sample_JSONResponse');
        mock.setStatusCode(200);
        mock.setStatus('OK');
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock); 
        
        Test.startTest();
        //Fire Service manually
        System.enqueueJob(new ResearchProfessionalService(9));
        Test.stopTest();
        
        List<Funding_Opportunity_Staging__c> lstFundOppStg = [SELECT Id FROM Funding_Opportunity_Staging__c LIMIT 1000];
        System.debug('Staging opportunities -' + lstFundOppStg);
        System.assertEquals(36,lstFundOppStg.size());


    }
    
    
    static testMethod void testFailedCallout() {
		RPfailedCalloutMock mock = new RPfailedCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock); 
        
        Test.startTest();
        //Fire Service manually
        System.enqueueJob(new ResearchProfessionalService(9, 1));
        Test.stopTest();
        
		Apex_Debug_Log__c errorLog = 
			[select Apex_Class_Name__c, Apex_Class_Method_Name__c,
             	Callout_Endpoint_URL__c,
             	Response_Status_Code__c,
             	Log_Type__c,
             	Transaction_Type__c,
             	Exception_Message__c
			FROM Apex_Debug_Log__c];
		
        System.assertequals('ResearchProfessionalService', errorLog.Apex_Class_Name__c);
    	System.assertequals('execute', errorLog.Apex_Class_Method_Name__c);
        System.assert(errorLog.Callout_Endpoint_URL__c.contains('research'));
        System.assertequals('Error', errorLog.Log_Type__c);
        System.assertequals('REST Callout', errorLog.Transaction_Type__c);
        System.assertequals('404', errorLog.Response_Status_Code__c);
        System.assertequals('Resource not found', errorLog.Exception_Message__c);
            
        CronTrigger delayedRetryJob =[SELECT Id,
                                      CronJobDetail.Name,
                                      CronJobDetail.Id,
                                      State
                                      FROM CronTrigger 
                                      where CronJobDetail.Name LIKE 'RP-PRD-DAILY-IMPORT-RESUME-FROM-PAGE-9-RETRY-2%'
                                      AND State !='COMPLETE'];
        System.assert(delayedRetryJob != null);
        
    }
    
    
    
    static testMethod void testCalloutException() {
		RPCalloutExceptionMock mock = new RPCalloutExceptionMock();
        Test.setMock(HttpCalloutMock.class, mock); 
        
        Test.startTest();
        //Fire Service manually
        System.enqueueJob(new ResearchProfessionalService(9, 1));
        Test.stopTest();
        
		Apex_Debug_Log__c errorLog = 
			[select Apex_Class_Name__c, Apex_Class_Method_Name__c,
             	Callout_Endpoint_URL__c,
             	Response_Status_Code__c,
             	Log_Type__c,
             	Transaction_Type__c,
             	Exception_Message__c,
	             Exception_stack_trace__c
			FROM Apex_Debug_Log__c];
		
        System.assertequals('ResearchProfessionalService', errorLog.Apex_Class_Name__c);
    	System.assertequals('execute', errorLog.Apex_Class_Method_Name__c);
        System.assert(errorLog.Callout_Endpoint_URL__c.contains('research'));
        System.assertequals('Error', errorLog.Log_Type__c);
        System.assertequals('REST Callout', errorLog.Transaction_Type__c);
        System.assertequals('0', errorLog.Response_Status_Code__c);
        System.assertequals('Callout Exception', errorLog.Exception_Message__c);
        System.assert(errorLog.Exception_stack_trace__c != null);
        
        CronTrigger delayedRetryJob =[SELECT Id,
                                      CronJobDetail.Name,
                                      CronJobDetail.Id,
                                      State
                                      FROM CronTrigger 
                                      where CronJobDetail.Name LIKE 'RP-PRD-DAILY-IMPORT-RESUME-FROM-PAGE-9-RETRY-2%'
                                      AND State !='COMPLETE'];
        System.assert(delayedRetryJob != null);
            
    }
    
    
    
    //Mock classes
    
    public class RPfailedCalloutMock implements HttpCalloutMock {
       
		public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('Resource not found');
            res.setStatusCode(404);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    public class RPCalloutExceptionMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Callout Exception');
            throw e;
        }
        
    }

}