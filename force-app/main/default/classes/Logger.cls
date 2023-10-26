global class Logger {

    
    global static final String

        TRANSACTION_TYPE = 'Transaction_Type__c',
        
        TRANSACTION_TYPE_VALUE_SERVICE_REST = 'Apex REST Service',
        TRANSACTION_TYPE_VALUE_SERVICE_SOAP = 'Apex SOAP Service',
        TRANSACTION_TYPE_VALUE_CALLOUT_REST = 'Apex REST Callout',
        TRANSACTION_TYPE_VALUE_CALLOUT_SOAP = 'Apex SOAP Callout',
        TRANSACTION_TYPE_VALUE_BATCH = 'Batch',
        TRANSACTION_TYPE_VALUE_SCHEDULED = 'Scheduled',
        TRANSACTION_TYPE_VALUE_QUEUEABLE = 'Queueuable',
        
        RELATED_TO_ID = 'Related_To_Id__c',
        
        CLASS_NAME = 'Apex_Class_Name__c',
        CLASS_METHOD_NAME = 'Apex_Class_Method_Name__c',
        TRANSACTION_DESCRIPTION = 'Transaction_Description__c',
        
        EXCEPTION_MESSAGE = 'Exception_Message__c',
        EXCEPTION_STACK_TRACE = 'Exception_Stack_Trace__c',
        
        REQUEST_DATA = 'Request_Data__c',
        REQUEST_PARAMETERS = 'Request_Parameters__c',
        
        RESPONSE_BODY = 'Response_Body__c',
        RESPONSE_STATUS_CODE = 'Response_Status_Code__c',
        
        LOG_TYPE = 'Type__c',
        
        LOG_TYPE_VALUE_INFO = 'Info',
        LOG_TYPE_VALUE_WARNING = 'Warning',
        LOG_TYPE_VALUE_ERROR = 'Error'
        ;


    //LOG HERE, WHETHER SYNCHRONOUSLY OR ASYNCHRONOUSLY
    global static void log(Map<String, Object> data){

        System.debug('ApexDebugLogger.log');
        System.debug('data '+data);
        
        try {
            Apex_Debug_Log__c a = new Apex_Debug_Log__c();
    
            //Prepare to create an attachment is any piece of data is too big
            Boolean attachmentRequired = false;
            
            //CATEGORISATION AND APEX METADATA FIELDS
            
            String transactionType = (String) data.get(TRANSACTION_TYPE);
            if (transactionType != null)
                a.Transaction_Type__c = transactionType;
            
            String logType = (String) data.get(LOG_TYPE);
            if (logType != null)
                a.Log_Type__c = logType;
            
            String className = (String) data.get(CLASS_NAME);
            if (className != null)
                a.Apex_Class_Name__c = className;
            
            String classMethodName = (String) data.get(CLASS_METHOD_NAME);
            if (classMethodName != null)
                a.Apex_Class_Method_Name__c = classMethodName;
            
            String transactionDescription = (String) data.get(TRANSACTION_DESCRIPTION);
            if (transactionDescription != null)
                a.Transaction_Description__c = transactionDescription;
            
            
            //RELATED RECORD
            
            Id relatedToId = (Id) data.get(RELATED_TO_ID);
            if (relatedToId != null)
                a.Related_To_Id__c = relatedToId;
            
            
            //EXCEPTION FIELDS
            
            String exceptionMessage = (String) data.get(EXCEPTION_MESSAGE);
            if (exceptionMessage != null)
                a.Exception_Message__c = exceptionMessage;
            
            String exceptionStackTrace = (String) data.get(EXCEPTION_STACK_TRACE);
            if (exceptionStackTrace != null)
                a.Exception_Stack_Trace__c = exceptionStackTrace;
            
            //REQUEST FIELDS
            
            String requestData = '';
            if (data.get(REQUEST_DATA) != null){
                
                //Input may can be one of multiple types
                try {
                    requestData = ((Blob) data.get(REQUEST_DATA)).toString();}
                catch(Exception e) {
                    requestData = (String) data.get(REQUEST_DATA);}
                
                //If data is too long, truncate and standby for creating attachment with full data
                Integer fieldLength = Schema.SObjectType.Apex_Debug_Log__c.fields.Request_Data__c.getLength();
                if (requestData.length() > fieldLength){
                    a.Request_Data__c = requestData.substring(0, fieldLength);
                    attachmentRequired = true;
                }
                else
                    a.Request_Data__c = requestData;
            }
            
            /*System.debug('data.get(REQUEST_PARAMETERS) '+data.get(REQUEST_PARAMETERS));
            Map<String, String> requestParameters = (Map<String, String>) data.get(REQUEST_PARAMETERS);
            System.debug('requestParameters '+requestParameters);
            
            a.Request_Parameters__c = '';
            if (requestParameters != null) {
            for (String key : new List<String>(requestParameters.keySet())) {
            a.Request_Parameters__c += key;
            a.Request_Parameters__c += ' : ';
            a.Request_Parameters__c += requestParameters.get(key);
            a.Request_Parameters__c += '\n';
            }
            }*/
            
            //RESPONSE FIELDS
            //
            
            //If data is too long, truncate and standby for creating attachment with full data
            String responseBody = '' + (String) data.get(RESPONSE_BODY);
            if (responseBody != null){
                Integer fieldLength = Schema.SObjectType.Apex_Debug_Log__c.fields.Response_Body__c.getLength();
                if (responseBody.length() > fieldLength){
                    a.Response_Body__c = responseBody.substring(0, fieldLength);
                    attachmentRequired = true;
                }
                else a.Response_Body__c = responseBody;
            }
            
            String responseStatusCode = String.valueOf((Integer) data.get(RESPONSE_STATUS_CODE));
            if (responseStatusCode != null)
                a.Response_Status_Code__c = responseStatusCode;
            
            /*String[] responseMessageArray = (String[]) data.get(RESPONSE_STATUS_MESSAGES);
            if (responseMessageArray != null)
            a.Response_Messages__c = String.join(responseMessageArray,'; ');*/
            
            
            //SYSTEM-DEFINED FIELDS
            //
            a.Logged_In_Salesforce_User__c = UserInfo.getUserId();
            
            
            //Insert log
            insert a;
            
            //If applicable, create attachment with full data
            if (attachmentRequired){
                createAttachment(a, requestData, responseBody);
            }
    	
        }
        catch (Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    
    static void createAttachment(Apex_Debug_Log__c a, String fullRequestBody, String fullResponseBody){
    	
        //Get fields we will be exporting
        List<Schema.FieldSetMember> fs = 
            Schema.SObjectType.Apex_Debug_Log__c.fieldSets.getMap().get(
                'Attachment_File_Output_Fields').getFields();

        //Create content
        ContentVersion cont = new ContentVersion();
    
        //Get record name, as we'll be using this
        String recordName = [select Name from Apex_Debug_Log__c where Id = :a.Id].Name;
        
        cont.Title = 'Apex Debug Log ' + recordName;
        cont.PathOnClient = '.txt'; 
        cont.Origin = 'H';
        
        //Create content
        String content = '';
        content += 'APEX DEBUG LOG '+recordName;
        content += '\n\n';
        
        for (Schema.FieldSetMember f : fs){
            content += f.getLabel().toUpperCase();
        	content += '\n\n';
            
            //Append either a field or one of the method input parameters
            String fieldName = f.getFieldPath();
            if (fieldName == REQUEST_DATA)
            	content += fullRequestBody;
            else if (fieldName == RESPONSE_BODY)
                content += fullResponseBody;
            else 
            	content += a.get(f.getFieldPath());
            
            content += '\n\n\n';
        }
        
        cont.VersionData = Blob.valueOf(content);
        
        //Save and stuff
        insert cont;
        
        insert new FeedItem(
            ParentId = a.Id, 
            RelatedRecordId = cont.Id, 
            Type = 'ContentPost');
    }

}