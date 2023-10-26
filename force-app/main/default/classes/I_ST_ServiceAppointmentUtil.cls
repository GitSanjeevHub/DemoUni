public with sharing class I_ST_ServiceAppointmentUtil {
    public static List<I_ST_SendEmail.Request> generateEmailRequests(List<ServiceAppointment> consultations) {
        System.debug('@ServiceAppointmentTriggerHandler after update trigger executed');
        List<I_ST_SendEmail.Request> emailRequests = new List<I_ST_SendEmail.Request>();

        List<String> displayNames = new List<String>();
        displayNames.add('Future Students');
        List<String> orgWideEmailAddressIds = I_ST_OrgWideEmailAddressUtil.getOrgWideEmailAddressId(displayNames);

        if(!orgWideEmailAddressIds.isEmpty()) {
            for(ServiceAppointment sa : consultations) {
                I_ST_SendEmail.Request emailRequest = new I_ST_SendEmail.Request();
                // List<ContentDocumentLink> contentDocumentAttachments;
                // String HTMLbody;
                emailRequest.orgWideEmailAddressId = orgWideEmailAddressIds[0];
                // String plainTextBody;        
                emailRequest.recordId = sa.Id;
                // String replyEmailAddress;        
                // String senderDisplayName;
                emailRequest.SendTOthisOneEmailAddress = sa.Email;
                // List<String> SendTOthisStringCollectionOfEmailAddresses;
                // List<Contact> SendTOtheEmailAddressesFromThisCollectionOfContacts;
                // List<User> SendTOtheEmailAddressesFromThisCollectionOfUsers;        
                // List<Lead> SendTOtheEmailAddressesFromThisCollectionOfLeads;
                // String SendCCthisOneEmailAddress;
                // List<String> SendCCthisStringCollectionOfEmailAddresses;
                // List<Contact> SendCCtheEmailAddressesFromThisCollectionOfContacts;
                // List<User> SendCCtheEmailAddressesFromThisCollectionOfUsers;        
                // List<Lead> SendCCtheEmailAddressesFromThisCollectionOfLeads;
                // String SendBCCthisOneEmailAddress;
                // List<String> SendBCCthisStringCollectionOfEmailAddresses;
                // List<Contact> SendBCCtheEmailAddressesFromThisCollectionOfContacts;
                // List<User> SendBCCtheEmailAddressesFromThisCollectionOfUsers;        
                // List<Lead> SendBCCtheEmailAddressesFromThisCollectionOfLeads;
                    
                /*
                    Static resources do not store file extensions, thus email attachments will have file names without extensions,
                    which is inconvenient for an end user. Disabling this option for now.
                    Possible workarounds:
                    1. Specify full file name in Description of static resource
                    2. Let the user pass file names together with static resource names
                    */                
                // String staticResourceAttachmentNames;
                // Boolean saveAsActivity;
                // String subject;          
                // String templateID;

                if(sa.I_ST_Consultation_To_Be_Sent__c) {
                    emailRequest.templateName = 'Consultation';
                }
                else if(sa.I_ST_Consultation_Change_To_Be_Sent__c) {
                    emailRequest.templateName = 'Consultation Change';
                }

                // String templateLanguage;
                emailRequest.templateTargetObjectId = sa.ContactId;
                emailRequest.UseSalesforceSignature = false;
                emailRequest.allOrNoneEmailSend = false;
                emailRequest.throwFlowExceptionOnSendEmailException = false;
                emailRequests.add(emailRequest);
            }
        }

        return emailRequests;

        // if(!emailRequests.isEmpty()) {
        //     SendEmail.SendEmail(emailRequests);
        // }
    }

    public static Set<Id> SendEmail(List<I_ST_SendEmail.Request> requests) {

        // List<Response> responseList = new List<Response>();
        Set<Id> successEmailSentSaIds = new Set<Id>();
        List<Apex_Debug_Log__c> resultLogs = new List<Apex_Debug_Log__c>();
        
        //System.assert(false, 'Throw an exception here');
        
//      system.debug('Got here SendEmail');
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (I_ST_SendEmail.Request curRequest : requests) {

            String HTMLbody = curRequest.HTMLbody;
            String orgWideEmailAddressId = curRequest.orgWideEmailAddressId;
            String plainTextBody = curRequest.plainTextBody;
            String recordId = curRequest.recordId;
            String replyEmailAddress = curRequest.replyEmailAddress;
            String senderDisplayName = curRequest.senderDisplayName;
            String subject = curRequest.subject;
            String templateID = curRequest.templateID;
            String templateName = curRequest.templateName;
            String templateLanguage = curRequest.templateLanguage;
            String templateTargetObjectId = curRequest.templateTargetObjectId;
            Boolean useSalesforceSignature = curRequest.useSalesforceSignature == null?true:curRequest.useSalesforceSignature;
            Boolean saveAsActivity = curRequest.saveAsActivity == null?true:curRequest.saveAsActivity;
            if (recordId==null)saveAsActivity = curRequest.saveAsActivity == null?false:curRequest.saveAsActivity;
            if (subject != null && (subject.length() == 0) ) subject = null;
            Boolean allOrNoneEmailSend = curRequest.allOrNoneEmailSend;
            Boolean throwFlowExceptionOnSendEmailException = curRequest.throwFlowExceptionOnSendEmailException;
         
            //from https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_forcecom_email_outbound.htm

            // First, reserve email capacity for the current Apex transaction to ensure
            // that we won't exceed our daily email limits when sending email after
            // the current transaction is committed.
            //Messaging.reserveSingleEmailCapacity(2);

            // Processes and actions involved in the Apex transaction occur next,
            // which conclude with sending a single email.

            // Now create a new single email message object
            // that will send out a single email to the addresses in the To, CC & BCC list.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            // Strings to hold the email addresses to which you are sending the email.
            //String[] toAddresses = new String[] {oneAddress}; 
            Map<String, Object> m = I_ST_SendEmail.GenerateMap(curRequest);
            // Boolean maxEmailRecipientsReached = false;
            // try {
            //     Messaging.reserveSingleEmailCapacity(m.size());
            // } catch (Exception e) {
            //     System.debug('Maximum daily recipients reached... terminating this send and attempting next');
                // maxEmailRecipientsReached = true;
            //     continue;
            // }
                                    
            String[] toAddresses = I_ST_SendEmail.BuildAddressList('TO',m); 
            String[] ccAddresses = I_ST_SendEmail.BuildAddressList('CC',m); 
            String[] bccAddresses = I_ST_SendEmail.BuildAddressList('BCC', m);
                
            // Assign the addresses for the To and CC lists to the mail object.
            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            System.debug(ccAddresses);
            mail.setBccAddresses(bccAddresses);

            //outgoing email can either use an orgWideEmailAddress or specify it here, but not both
            if (orgWideEmailAddressId != null && orgWideEmailAddressId != '') {
                mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
            } else {
                // Specify the address used when the recipients reply to the email. 
                mail.setReplyTo(replyEmailAddress);

                // Specify the name used as the display name.
                mail.setSenderDisplayName(senderDisplayName);
            }

            // Specify the subject line for your email address.
            mail.setSubject(subject);

            // Set to True if you want to BCC yourself on the email.
            mail.setBccSender(false);

            // Optionally append the salesforce.com email signature to the email.
            // The email address of the user executing the Apex Code will be used.
            // True by default unless the user passes a value in.
            mail.setUseSignature(useSalesforceSignature);
            mail = I_ST_SendEmail.AddAttachments(mail, curRequest.contentDocumentAttachments, null);
            
            if (templateName != null && templateID != null)
                // throw new InvocableActionException('You\'re trying to pass in both the name of the template and a template ID. Gotta pick one or the other. Use templateName to select the first matching template qualified with \'Language="xxx_YY"\' in the Description.  The templateId represents a specific Salesforce Email Template (either Classic or Lightning).');

            System.debug('@templateName: ' + templateName);


            if (templateName != null){
                templateID = I_ST_SendEmail.getTemplateIdFromName(templateName,templateLanguage);
                if (templateID == null){
                    // throw new InvocableActionException('Could not find email template named "'+templateName+'".  Please have your administrator check the name and/or accessibility of this template');
                }
            }

            System.debug('@templateID: ' + templateID);

            if (templateID != null && ((HTMLbody != null) || (plainTextBody != null)))
                // throw new InvocableActionException('You\'re trying to pass in both a plaintext/html body and a template ID. Gotta pick one or the other. Make sure you\'re not confusing the Text Template resources in Flow, (which you can pass into either the HTMLBody or the plainTextBody) with the templateId, which represents a Salesforce Email Template (either Classic or Lightning).');
            
            if (templateID == null  && HTMLbody == null && plainTextBody == null)
                // throw new InvocableActionException('Body text must be provided to Send HTML Email Action, either via HTMLbody, plainTextBody, or a templateId');
                
            if (saveAsActivity == true && recordId == null)
                // throw new InvocableActionException('In order to log this email send to activity history, you need to pass in a recordId');
            
            // Boolean completed = true;
            // String error;
            Messaging.SendEmailResult[] sendEmailResults;
            if (templateTargetObjectId != NULL) mail.setTargetObjectId(templateTargetObjectId);
//            System.debug('recordId is: ' + recordId);
            if (recordId != null) {
                mail.setWhatId(ID.valueOf(recordId));
            }

            // Specify the text content of the email.
            if (plainTextBody != NULL) mail.setPlainTextBody(plainTextBody);
            if (HTMLbody != NULL) mail.setHtmlBody(HTMLbody);
            if (saveAsActivity != NULL) mail.setSaveAsActivity(saveAsActivity);
            
            if (String.isNotBlank(templateID)) {
                mail.setTemplateID(templateID);
            }
            mails.add(mail);
        }


        // Send the email you have created.
        String error;
        try {
            List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(mails, false);
            //report back the results
            for(Integer i = 0; i < sendEmailResults.size(); i++) {
                Messaging.SendEmailResult sendEmailResult = sendEmailResults[i];
                Messaging.SingleEmailMessage mail = mails[i];
                I_ST_SendEmail.Request request = requests[i];
                String errors = '';
                
                //Return result data back in flow
                if (sendEmailResult.isSuccess()) {
                    successEmailSentSaIds.add(request.recordId);
                }
                else {
                    Messaging.SendEmailError[] curErrors = sendEmailResult.getErrors();
                    for(Messaging.SendEmailError curError : curErrors ) {
                        errors = errors + curError.getMessage() + '/n';
                    }
                }

                if (String.isNotBlank(errors)) {
                    //Create Apex Debug Log
                    resultLogs.add(
                        new Apex_Debug_Log__c(
                            Apex_Class_Name__c = 'ServiceAppointmentUtil',
                            Apex_Class_Method_Name__c = 'sendEmail',
                            Log_Type__c = 'Info',
                            Request_Data__c = JSON.serializePretty(request),
                            Exception_Message__c = 'The following errors occurred: \n\n' + errors
                        )
                    );
                }
            }
        } catch (Exception e){
            resultLogs.add(
                new Apex_Debug_Log__c(
                    Apex_Class_Name__c = 'ServiceAppointmentUtil',
                    Apex_Class_Method_Name__c = 'sendEmail',
                    Log_Type__c = 'Error',
                    Exception_Message__c = e.getMessage(),
                    Exception_Stack_Trace__c = e.getStackTraceString()
                )
            );
        }
        
        if (!resultLogs.isEmpty()){
            insert resultLogs;
        }

        return successEmailSentSaIds;
    }

    public static void updateServiceAppointment(Set<Id> saIds) {
        List<ServiceAppointment> consultations = [SELECT I_ST_Consultation_To_Be_Sent__c, I_ST_Consultation_Change_To_Be_Sent__c 
                                                FROM ServiceAppointment
                                                WHERE Id IN: saIds];
        
        for(ServiceAppointment consultation : consultations) {
            consultation.I_ST_Consultation_To_Be_Sent__c = false;
            consultation.I_ST_Consultation_Change_To_Be_Sent__c = false;
        }

        List<Database.SaveResult> srs = Database.update(consultations, false);

        List<Apex_Debug_Log__c> resultLogs = new List<Apex_Debug_Log__c>();
        
        for (Database.SaveResult sr : srs) {
            if (!sr.isSuccess()) {
                String errors = '';
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                    errors += err.getMessage() + ' ';
                }

                resultLogs.add(
                    new Apex_Debug_Log__c(
                        Apex_Class_Name__c = 'ServiceAppointmentUtil',
                        Apex_Class_Method_Name__c = 'updateServiceAppointment',
                        Log_Type__c = 'Error',
                        Exception_Message__c = 'The following errors occurred: \n\n' + errors
                    )
                );
            }
        }

        if (!resultLogs.isEmpty()){
            insert resultLogs;
        }

    }
}