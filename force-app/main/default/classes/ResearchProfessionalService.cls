/**
* @author: Sush
* @date : 20/06/2019
*
*/

public with sharing class ResearchProfessionalService implements Queueable, Database.AllowsCallouts{
    
    public Integer pageIndex{get; private set;}
    public Integer pageRetryCount{get; private set;}
    
    public  List<Research_Professional_Settings__c> RPSettings {
        get {	
            if (RPSettings == null)
                RPSettings = [Select Name, 
                              Api_Key__c, 
                              API_Password__c, 
                              Api_Url__c,
                              Eligibility_Regions__c,
                              Batch_Delay__c,
                              Batch_Delay_Upon_Failure__c,
                              Batch_Delay_Upon_Failure_Multiplier__c,
                              Maximum_Number_of_Batch_Retries__c 
                              FROM Research_Professional_Settings__c
                              WHERE Name = 'RP_API_details'];
            return RPSettings;
        }
        set;
    }
    
    public ResearchProfessionalService(Integer pageIndex){
        this.pageIndex = pageIndex;
        this.pageRetryCount = 0;
        system.debug(' page index is ' + this.pageIndex );
    }

    public ResearchProfessionalService(Integer pageIndex, Integer pageRetryCount){
        this.pageIndex = pageIndex;
        this.pageRetryCount = pageRetryCount;
        system.debug(' page index is ' + this.pageIndex );
    }
    
    public void execute(QueueableContext context){
        
        system.debug('get into service class');
        Http objhttp;
        HttpRequest req ;
        HttpResponse res ;
        ResearchProfessionalWrapper objRPWrapper;
        
        //Integer pageIndex = 0;
        String pageSize = Label.RP_PageSize;
        String endPointUrl ; //= 'https://demo-api.researchprofessional.com/funding/v1/fops/search' + '?page=' + String.valueOf(pageIndex) + '&size=' + pageSize;
        String username ; //= '!RuH3R4RAdu-';
        String password ; //= '';
        String eligibilityRegions ;
        Integer delay = 0;
        System.debug(' RP custom setting - ' + RPSettings);
        if(!RPSettings.isEmpty() && RPSettings.size() >0){
            endPointUrl = RPSettings[0].Api_Url__c;
            username = RPSettings[0].Api_Key__c;
            password = RPSettings[0].API_Password__c;
            eligibilityRegions = RPSettings[0].Eligibility_Regions__c;
            delay = Integer.valueOf(RPSettings[0].Batch_Delay__c);
            endPointUrl = endPointUrl + '&page=' + String.valueOf(pageIndex) + '&size=' + pageSize; 
            
            system.debug('endpoint is - ' + endPointUrl);
            objhttp = new Http();
            req = new HttpRequest();
            res = new HttpResponse();
            req.setMethod('GET'); // req.setMethod('GET');
            Blob headerValue = Blob.valueOf(UserName + ':' + Password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            // Set the necessary Headers
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type','application/json');
            req.setHeader('Connection','keep-alive');
            req.setHeader('Content-Length','0');
            req.setTimeout(60000);
            req.setEndpoint(endPointUrl);
            
            try {
                res = objhttp.send(req);
            
                system.debug('response is - ' + res);
                system.debug('response status is - ' + res.getStatus());
            
                Boolean calloutSucceeded = 
                    res != null && 
                    res.getStatus()?.toLowerCase() == 'ok' && 
                    res.getStatusCode() == 200 &&
                    res.getBody() != null;
                
                if(calloutSucceeded){
                    // Logic here to parse the response in wrapper
                    //system.debug('response JSON - '+ res.getBody());
                    objRPWrapper = ResearchProfessionalWrapper.parse(res.getBody());
                    system.debug(' response is -' + objRPWrapper);
                    system.debug(' response Record size is -' + objRPWrapper.records.size());
                    Boolean isSuccess = ResearchProfessionalServiceProcess.opportunityStagingRecordProcess(objRPWrapper,eligibilityRegions);

                    logSuccess(endpointURL, res?.getStatusCode());

                    if(pageIndex < objRPWrapper.Metadata.pageCount){
                        if(delay > 0) { //Check for delay in job run
                            DateTime start = System.Now();
                            while(System.Now().getTime() < start.getTime()+ delay)
                            {} 
                        }
                        String jobId = System.enqueueJob(new ResearchProfessionalService(this.pageIndex + 1));
                    } 
                }
                else {
                    logCalloutError(res.getBody(), endpointURL, res.getStatusCode());

                    attemptRetryOfBatch();
                }
            }
            catch (System.CalloutException ce){
                logException(ce, endpointURL, res?.getStatusCode());

                attemptRetryOfBatch();
            }
            catch (Exception e){
                logException(e, endpointURL, res?.getStatusCode());
            }
        }
    }
    

    void attemptRetryOfBatch(){

        System.debug('Replay RP');
                        
        Boolean tryPageAgain = this.pageRetryCount < RPSettings[0].Maximum_Number_of_Batch_Retries__c;
        System.debug(this.pageRetryCount);
        System.debug(tryPageAgain);

        if (tryPageAgain){

            Integer baselineBatchDelay = (Integer) RPSettings[0].Batch_Delay_Upon_Failure__c;
            Double batchDelayMultipler = RPSettings[0].Batch_Delay_Upon_Failure_Multiplier__c;

            Integer delayTimeSecondIncrement; 

            if (batchDelayMultipler >= 1) {
                delayTimeSecondIncrement = 
                    (Integer) (baselineBatchDelay * 
                    Math.pow(batchDelayMultipler, this.pageRetryCount));
            }
            else return;

            DateTime timeToRetry = DateTime.now().addSeconds(delayTimeSecondIncrement);

            String timeToRetryCronJobExpression = 
                timeToRetry.second() + ' ' + 
                timeToRetry.minute() + ' ' + 
                timeToRetry.hour() + ' ' + 
                timeToRetry.day() + ' ' + 
                timeToRetry.format('MMM').toUpperCase() + ' ? ' + 
                timeToRetry.year();
            System.debug(timeToRetryCronJobExpression);

            System.schedule(
                'RP-PRD-DAILY-IMPORT-RESUME-FROM-PAGE-'+this.pageIndex+'-RETRY-'+(this.pageRetryCount+1)+' '+DateTime.now(),
                timeToRetryCronJobExpression, 
                new ResearchProfessionalREST(this.pageIndex, this.pageRetryCount+1));
        }
    }


    void logSuccess(String endpointURL, Integer responseStatusCode){
        Apex_Debug_Log__c errorLog = initialiseApexDebugLog(endpointURL, responseStatusCode);
        errorLog.Log_Type__c = 'Info';
        insert errorLog;
    }

    void logException(Exception e, String endpointURL, Integer responseStatusCode){

        Apex_Debug_Log__c errorLog = initialiseApexDebugLog(endpointURL, responseStatusCode);
        errorLog.Log_Type__c = 'Error';
        errorLog.Exception_Message__c = e.getMessage();
        errorLog.Exception_stack_trace__c = e.getStackTraceString();
        
        insert errorLog;

    }

    void logCalloutError(String errorMessage, String endpointURL, Integer responseStatusCode){
        Apex_Debug_Log__c errorLog = initialiseApexDebugLog(endpointURL, responseStatusCode);
        errorLog.Log_Type__c = 'Error';
        errorLog.Exception_Message__c = errorMessage;
        insert errorLog;
    }

    Apex_Debug_Log__c initialiseApexDebugLog(String endpointURL, Integer responseStatusCode){
        Apex_Debug_Log__c errorLog = new Apex_Debug_Log__c(
            Apex_Class_Name__c = 'ResearchProfessionalService',
            Apex_Class_Method_Name__c = 'execute',
            Callout_Endpoint_URL__c = endpointURL,
            Transaction_Type__c = 'REST Callout'
        );
        if (responseStatusCode != null){
            errorLog.Response_Status_Code__c = ''+responseStatusCode;
        }
        return errorLog;
    }

}