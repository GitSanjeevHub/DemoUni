public class TaskToOutlookCalendarCallout implements Database.AllowsCallouts {

	public Task taskToSync;
    public String operationType;
    
    private final String outlookEventStartTime = 'T08:00:00';
    private final String dateFormatString = 'YYYY-MM-dd';
    private final String timeZone = 'Australia/Sydney';
        
    public TaskToOutlookCalendarCallout(Task task, String operationType){
        this.taskToSync = task;
        this.operationType = operationType;
    }
    
    public Task execute(){

        System.debug('Processing callout');
        System.debug(taskToSync);
        System.debug(operationType);
        
        Task taskOutput = new Task(Id = taskToSync.Id);
		
        Http http = new Http();
        HttpRequest request;
        HttpResponse calloutResponse;
        
        try {

            request = buildRequest();
        
            calloutResponse = http.send(request);
            
            System.debug(calloutResponse);
            System.debug(calloutResponse.getStatusCode());
            System.debug(calloutResponse.getBody());

            Integer responseCode = calloutResponse.getStatusCode();
            Boolean responseCodeIsSuccess = (responseCode == 201 || responseCode == 204);
            
            if (responseCodeIsSuccess){
                
                taskOutput = processSuccessfulCallout(taskOutput, calloutResponse);
            }
            else {
				String calloutErrorMessage = (calloutResponse.getStatusCode() + ': ' + 
                                              calloutResponse.getStatus() + ' - ' +
                    							calloutResponse.getBody()).abbreviate(255);
                    
                
                System.debug('Callout error: '+calloutErrorMessage);
                
                taskOutput = processFailedCallout(taskOutput, calloutErrorMessage);
            }
            
            
        }
        catch (Exception e){
            
           	System.debug(calloutResponse);
            //System.debug(calloutResponse.getHeaderKeys());
            
            String salesforceErrorMessage = ('Salesforce exception '+e.getMessage()+'. '+e.getStackTraceString()).abbreviate(252);
            
            System.debug(salesforceErrorMessage);
            
            taskOutput = processFailedCallout(taskOutput, salesforceErrorMessage);
            
            
        }
        
        return taskOutput;
        
    }

    
    private HttpRequest buildRequest() {
		System.debug('buildRequest');

		//HTTP Request information        
        HttpRequest req = new HttpRequest();

        String endpointBasedOnOperationType;
        String reqMethod;
        
        switch on operationType {
            when 'insert' {
            	reqMethod = 'POST';
                endpointBasedOnOperationType = '/me/events';
                req.setBody(populateCalloutPayloadWrapper());
            }
            when 'update', 'delete' {
            	reqMethod = 'DELETE'; //Will invoke an insert later on to re-create event with changes
                endpointBasedOnOperationType = '/me/calendar/events/'+taskToSync.I_RS_Outlook_Id__c;
                req.setBody('Body');
            }
        }
        
        req.setMethod(reqMethod);
        //Conor Langan IBM, Bluewolf 04/11/2020
        if(taskToSync != null && taskToSync.I_ST_SACE_Record_Type__c){
            req.setEndpoint('callout:SFDC_Task'+endpointBasedOnOperationType);
        } else{
        	req.setEndpoint('callout:outlook'+endpointBasedOnOperationType);
        }
        
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Length', '4096');
        req.setTimeout(5000);

        return req;
    }
    
    
    Task processSuccessfulCallout(Task taskOutput, HttpResponse calloutResponse){
        
        switch on operationType {
            when 'insert'{
                
                Object result = JSON.deserializeUntyped(calloutResponse.getBody());
                Map<String, Object> resultMap = (Map<String, Object>) result;
                
                taskOutput.I_RS_Outlook_Id__c = (String) resultMap.get('id');
                taskOutput.I_RS_Task_to_Outlook_Sync_Status__c = 'Insert Successful';
            }
            when 'update'{
                //Earlier in the code (when building callout) we do a delete of outlook
                //
                
                taskOutput = new TaskToOutlookCalendarCallout(taskToSync, 'insert').execute();
                taskOutput.I_RS_Task_to_Outlook_Sync_Status__c = 'Update Successful';
            }
            when 'delete' {
                taskOutput.I_RS_Outlook_Id__c = null;
                taskOutput.I_RS_Task_to_Outlook_Sync_Status__c = 'Delete Successful';
            }
        }
        
        taskOutput.I_RS_Task_to_Outlook_Sync_Error_Message__c = null;
        
        return Taskoutput;
        
    }
    
    
    Task processFailedCallout(Task taskOutput, String errorMessage){
        
       	switch on operationType {
            when 'insert'{
                taskOutput.I_RS_Task_to_Outlook_Sync_Status__c = 'Insert Failed';
            }
            when 'update'{
                taskOutput.I_RS_Task_to_Outlook_Sync_Status__c = 'Update Failed';
            }
            when 'delete' {
                taskOutput.I_RS_Task_to_Outlook_Sync_Status__c = 'Delete Failed';
            }
        }
        
        taskOutput.I_RS_Task_to_Outlook_Sync_Error_Message__c = errorMessage;
            
        return Taskoutput;
        
    }
    
    
    
    
    String populateCalloutPayloadWrapper(){
        
        OutlookEventWrapper wrapper = new OutlookEventWrapper();
        //Conor Langan IBM, Bluewolf 04/11/2020
        if(taskToSync != null && taskToSync.I_ST_SACE_Record_Type__c){
        	wrapper.subject = taskToSync.Subject;
        } else{
            wrapper.subject = taskToSync.I_RS_Task_to_Outlook_Sync_Event_Subject__c;
        }

        Time timeInstance = Time.newInstance(0,0,0,0);
        DateTime startDateTime = DateTime.newInstance(taskToSync.ActivityDate, timeInstance);
        DateTime endDateTime = DateTime.newInstance(taskToSync.ActivityDate, timeInstance);
        
        wrapper.start = new OutlookEventWrapper.DateTimeWrapper(
            startDateTime.format(dateFormatString) + outlookEventStartTime, timeZone);
        wrapper.x_end = new OutlookEventWrapper.DateTimeWrapper(
            endDateTime.format(dateFormatString) + outlookEventStartTime, timeZone);

		wrapper.attendees = getAttendees();
		wrapper.body = getBody();
        
        System.debug('wrapper class '+wrapper);

        String payload = reverseSanitize(JSON.serialize(wrapper));
		return payload;

    }
    
    
    List<OutlookEventWrapper.Attendee> getAttendees(){
        
        List<OutlookEventWrapper.Attendee> attendees = new List<OutlookEventWrapper.Attendee>();
        
        OutlookEventWrapper.EmailAddress assignedToEmail = new OutlookEventWrapper.EmailAddress();
        assignedToEmail.address = taskToSync.Owner.Email;
        assignedToEmail.name = taskToSync.Owner.Name;// + ' ' + assignedTo.LastName;
		
       	OutlookEventWrapper.Attendee attendee = new OutlookEventWrapper.Attendee();
        attendee.type = 'required';
        attendee.emailAddress = assignedToEmail;
        
        attendees.add(attendee);
        
        System.debug('attendees '+attendees);
        
        return attendees;
        
    }

	
    OutlookEventWrapper.Body getBody(){
        
        OutlookEventWrapper.Body body = new OutlookEventWrapper.Body();
        body.contentType = 'html';
        //Conor Langan IBM, Bluewolf 04/11/2020
        if(taskToSync != null && taskToSync.I_ST_SACE_Record_Type__c){
        	body.content = taskToSync.I_ST_Task_to_Outlook_Sync_Event_Body__c;
        } else{
            body.content = taskToSync.I_RS_Task_to_Outlook_Sync_Event_Body__c;
        }
        
        System.debug('body '+body);
        return body;
        
    }

    
    /*public String sanitizeVars(String payload) {
        return payload
            .replace('"@odata.', '"x_odata_')
            .replace('"end":', '"x_end":')
            .replace('"dateTime":', '"x_dateTime":');
    }*/

    public String reverseSanitize(String payload) {
        return payload
            .replace('"x_odata_', '"@odata.')
            .replace('"x_end":', '"end":')
            .replace('"x_dateTime":', '"dateTime":');
    }
}