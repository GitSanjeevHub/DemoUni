@isTest
public with sharing class I_ST_SendEmailTest {
/**
    Test classes that create standard object records can cause failures if the deploying org has customized required fields,  
    validations, triggers, . . . because it is complex to find and mimic these customizations and a failure in creation will stop the deployment
    Inversely, not doing these tests can cause code coverage % failures.  For pre-deployment testing purposes, TEST_WITH_CREATED_RECORDS should be set to true,
    but for version release, should be set to false.
**/
    private Static Final Boolean TEST_WITH_CREATED_RECORDS = true;
//
    private Static Final String TEMPLATE_NAME = 'xxxyyy Test Email Template yyyxxx';
    private Static Final String TEMPLATE_DEVNAME = 'xxxyyy_Test_Email_Template_yyyxxx';
    private Static Final String TEMPLATE_LANGUAGE = 'en_US';
    private Static Final String TEMPLATE_NOSUCH = 'ZZXZ_XYZZY';
    private Static Final String TEMPLATE_NAME_NOSUCH = 'ZZXZ XYZZY';
    private Static Final String EMAIL_SUBJECT = 'this is the subject';
    private Static Final String EMAIL_BODY = 'this is the body';
    private Static Final String EMAIL_NOSUCH = 'test@foo.com';
    private Static Final String EMAIL_NAME_NOSUCH = 'Do Not Reply';
    private Static Final Integer TEST_CONTACTS_COUNT = 1;

//  set up two email templates - one language enabled, the other not.   These will also be used as the relatedTo (WhatId/recordId)
    @testSetup static void testSetupdata(){
            EmailTemplate validEmailTemplate = new EmailTemplate(
            isActive = true,
            Name = TEMPLATE_NAME,
            DeveloperName = TEMPLATE_DEVNAME,
            TemplateType = 'custom',
            Description = 'Test Email Template - No Language Specified',
            FolderId = UserInfo.getUserId(),
            Subject = 'Test Email Template'
        );
        if (TEST_WITH_CREATED_RECORDS){
            validEmailTemplate.UIType = 'SFX';
            validEmailTemplate.RelatedEntityType = 'Account';
        }
        insert validEmailTemplate;

        validEmailTemplate = new EmailTemplate(
            isActive = true,
            Name = TEMPLATE_NAME,
            DeveloperName = TEMPLATE_DEVNAME+'_'+TEMPLATE_LANGUAGE,
            TemplateType = 'custom',
            Description = 'Test Email Template - Language Specified (Language="'+TEMPLATE_LANGUAGE+'")',
            FolderId = UserInfo.getUserId(),
            Subject = 'Test Email Template - Language'
        );
        if (TEST_WITH_CREATED_RECORDS){
            validEmailTemplate.UIType = 'SFX';
            validEmailTemplate.RelatedEntityType = 'Account';
        }
        insert validEmailTemplate;
    }
// Check to see if email is deliverable (enabled and capacity not exceeded)    
    private static Boolean emailDeliverabilityEnabled(){
        Boolean emailDeliverabilityEnabled = true;
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            emailDeliverabilityEnabled = false;
        }
        return emailDeliverabilityEnabled;
    }

//  Create Content and content links for testing 'attachments'
    private static List<ContentDocumentLink> emailCreateAttachments(ID validEmailTemplateId){
        ContentVersion content=new ContentVersion(); 
            content.Title='Test_Content'; 
            content.PathOnClient='/' + content.Title + '.txt'; 
            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            content.VersionData=bodyBlob; 
            //content.LinkedEntityId=sub.id;
            content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
            contentlink.LinkedEntityId=validEmailTemplateId;
            contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
            contentlink.ShareType = 'V';
            test.starttest();
        insert contentlink;
        List<ContentDocumentLink> cdls=new List<ContentDocumentLink>();
        cdls.add(contentlink);
        System.assertEquals(1, cdls.size());
        return cdls;
    }
//  Create a contact to test email field merge (recipient && relatedTo[WhichId,relatedId])
    private static List<Contact> emailCreateTestContacts(integer howMany){
        List<Contact> ctList = new List<Contact>();
        for (Integer i = 0; i < howMany; i++){
            ctList.add(new Contact(
                    LastName    = 'Contact '+ ('0000'+i).right(4),
                    FirstName   = 'Test',
                    email       = 'e'+('0000'+i).right(4)+EMAIL_NOSUCH
                )
            );
        }
        insert ctList;
        return ctList;
    }
//  Create leads to test coverage for sent to leads)
    private static List<Lead> emailCreateTestLeads(integer howMany){
        List<Lead> ldList = new List<Lead>();
        for (Integer i = 0; i < howMany; i++){
            ldList.add(new Lead(
                    LastName    = 'Lead '+ ('0000'+i).right(4),
                    FirstName   = 'Test',
                    email       = 'e'+('0000'+i).right(4)+EMAIL_NOSUCH,
                    Company = 'abc'
                )
            );
        }
        insert ldList;
        return ldList;
    }

//  Create a contact to test email field merge (recipient && relatedTo[WhichId,relatedId])
    private static List<Account> emailCreateTestAccount(integer howMany, ID relatedContactId){
        List<Account> accountList = new List<Account>();
        for (Integer i = 0; i < howMany; i++){
            accountList.add(
                TestUtility.newEmptyExternalAccount('Test Account '+ ('0000'+i).right(4))
            );
        }
        insert AccountList;
        return AccountList;
    }

    
// @Test t001_canSendEmail: emailDeliverabilityEnabled and capacity not exceeded or not emailDeliverabilityEnabled
    @isTest
    public static void t001_canSendEmail () {

        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.HTMLbody = EMAIL_BODY;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.SendCCthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.SendBCCthisOneEmailAddress = EMAIL_NOSUCH;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);

        Boolean exceptionHit = false;
        try {            
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t001_errorIfNoAddress: '+e.getMessage());
        }
        
        Boolean emailDeliverabilityEnabled = emailDeliverabilityEnabled();
        if(emailDeliverabilityEnabled){
            System.assertEquals(exceptionHit,false,'emailDeliverabilityEnabled and capacity exceeded');
        } else {
            System.assertEquals(emailDeliverabilityEnabled,false,'emailDeliverabilityEnabled');
        }
    }

// @Test t002_errorIfNoAddress: Error expected if no addresses specified
    @isTest
    public static void t002_1_errorIfNoAddress_NoException () {

        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.HTMLbody = EMAIL_BODY;
        testReq.allOrNoneEmailSend = true;
        testReq.throwFlowExceptionOnSendEmailException = false;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        I_ST_SendEmail.SendEmail(reqList);
        List<Apex_Debug_Log__c> errorLogs = [SELECT Exception_Message__c, Exception_Stack_Trace__c FROM Apex_Debug_Log__c];
        system.debug('t002_1_errorLogs: '+errorLogs);
        System.assertEquals(1,[SELECT COUNT() FROM Apex_Debug_Log__c],'Apex Debug Log should have been created but wasnt');
    }
    
    @isTest
    public static void t002_2_errorIfNoAddress_ThrowException () {

        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.HTMLbody = EMAIL_BODY;
        testReq.allOrNoneEmailSend = true;
        testReq.throwFlowExceptionOnSendEmailException = true;
        //testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean exceptionHit = false;
        try {            
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t002_2_errorIfNoAddress: '+e.getMessage());
        }
        System.assertEquals(exceptionHit,true,'Error expected if no addresses specified');
    }

// @Test t003_errorIfBothTemplateAndBody: Error expected if both body and templateId set
    @isTest
    public static void t003_errorIfBothTemplateAndBody () {

        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.HTMLbody = EMAIL_BODY;
        testReq.templateID = TEMPLATE_NOSUCH;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.throwFlowExceptionOnSendEmailException = true;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean exceptionHit=false;
        try {
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t003_errorIfBothTemplateAndBody error: '+e.getMessage());
        }
        System.assertEquals(true, exceptionHit,'Error expected if flow attempts to set both body and templateId');
    }

// @Test t004_errorIfTemplateButNoContextRecord: Error expected if templateID does not exist
    @isTest
    public static void t004_errorIfTemplateButNoContextRecord () {

        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        //testReq.HTMLbody = EMAIL_BODY;
        testReq.templateID = TEMPLATE_NOSUCH;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.throwFlowExceptionOnSendEmailException = true;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean exceptionHit=false;
        try {
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t004_errorIfTemplateButNoContextRecord error: '+e.getMessage());
        }
        System.assertEquals(true, exceptionHit,'Error expected if templateID does not exist');
    }

// @Test t005_errorIfTemplateNameAndTemplateID: Error expected if templateID and templateName both used
    @isTest
    public static void t005_errorIfTemplateNameAndTemplateID () {
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        //testReq.HTMLbody = EMAIL_BODY;
        testReq.templateID = TEMPLATE_NOSUCH;
        testReq.templateName = TEMPLATE_NAME_NOSUCH;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.throwFlowExceptionOnSendEmailException = true;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean ExceptionHit=false;
        try {
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            ExceptionHit=true;
            system.debug('t005_errorIfTemplateNameAndTemplateID error: '+e.getMessage());
        }
        System.assertEquals(true, ExceptionHit,'Error expected if templateID and templateName both used');
    }
// @Test t006_coverageIfTemplateNameAndNoLanguage: Can select the Organization LanguageLocaleKey template if no language specified.  However, if LanguageLocaleKey isn't en_US, still works
    @isTest
    public static void t006_coverageIfTemplateNameAndNoLanguage() {
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.templateName = TEMPLATE_NAME;
        testReq.templateTargetObjectId = UserInfo.getUserId();
        // if templateTargetObjectId type = user, saveAsActivity must be false
        testReq.saveAsActivity = false;
        testReq.throwFlowExceptionOnSendEmailException = true;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean noExceptionHit=true;
        List<I_ST_SendEmail.Response> testResponseList;
        try {
            testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            noExceptionHit=false;
            system.debug('t006_coverageIfTemplateNameAndNoLanguage error: '+e.getMessage());
        }
//      Depending on the organization locallangage key, could be either
        if ([Select LanguageLocaleKey From Organization limit 1].LanguageLocaleKey == TEMPLATE_LANGUAGE){
            System.assertEquals(testResponseList[0].templateUsed,
                                [Select Id from EmailTemplate where DeveloperName=:(TEMPLATE_DEVNAME+'_'+TEMPLATE_LANGUAGE)].Id);
        } else {
            System.assertEquals(testResponseList[0].templateUsed, [Select Id from EmailTemplate where DeveloperName=:TEMPLATE_DEVNAME].Id);
        }
    }

// @Test t007_coverageIfTemplateNameDoesntExist: Error expected if Named Template non-existent 
    @isTest
    public static void t007_coverageIfTemplateNameDoesntExist() {
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.templateName = TEMPLATE_NOSUCH;
        testReq.throwFlowExceptionOnSendEmailException = true;

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean ExceptionHit=false;
        List<I_ST_SendEmail.Response> testResponseList;
        try {
            testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            ExceptionHit=true;
            system.debug('t007_coverageIfTemplateNameDoesntExist error: '+e.getMessage());
        }
        System.assertEquals(true, ExceptionHit,'Error expected if Named Template non-existent');
    }
// @Test t008_coverageWithAttachments: Can add Attachments and send to collections (Contact, Lead, User)
    @isTest
    public static void t008_coverageWithAttachments_throwException() {
        String devName = TEMPLATE_DEVNAME+'_'+TEMPLATE_LANGUAGE;
        EmailTemplate validEmailTemplate = [Select Id,Name from EmailTemplate where DeveloperName=:devName];
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        List<ContentDocumentLink> cdls = emailCreateAttachments(validEmailTemplate.Id);
        testReq.templateName = validEmailTemplate.Name;
        testReq.recordId = validEmailTemplate.Id;
        testReq.allOrNoneEmailSend = true;
        testReq.throwFlowExceptionOnSendEmailException = true;
        if (TEST_WITH_CREATED_RECORDS){
            List<Contact>sendToContactCollection = emailCreateTestContacts(TEST_CONTACTS_COUNT);
            testReq.templateTargetObjectId = sendToContactCollection[0].Id;
            testReq.recordId = emailCreateTestAccount(1,testReq.templateTargetObjectId)[0].Id;
            // also do code coverage test for sentTo Contact Collection
            List<Id> theseIds = new List<Id>();
            for (Contact thisContact : sendToContactCollection) theseIds.Add(thisContact.Id);
            sendToContactCollection = [Select Id,Email from Contact where Id in :theseIds ];
            testReq.SendBCCtheEmailAddressesFromThisCollectionOfContacts = sendToContactCollection;
            // also do code coverage test for sentTo Lead Collection
            List<Lead>sendToLeadCollection = emailCreateTestLeads(TEST_CONTACTS_COUNT);
            theseIds = new List<Id>();
            for (Lead thisLead : sendToLeadCollection) theseIds.Add(thisLead.Id);
            sendToLeadCollection = [Select Id,Email from Lead where Id in :theseIds ];
            testReq.SendBCCtheEmailAddressesFromThisCollectionOfLeads = sendToLeadCollection;

            // Contact showContact = [SELECT Id,Name,Email from Contact where Id = :testReq.templateTargetObjectId];
            // system.debug('showContact.Id: '+ showContact.Id + ' showContact.Name: '+ showContact.Name + ' showContact.Email: '+ showContact.Email);
        }else{
            testReq.templateTargetObjectId = UserInfo.getUserId();
            testReq.recordId = validEmailTemplate.Id;
            // if templateTargetObjectId type = user, saveAsActivity must be false
            testReq.saveAsActivity = false;
            testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        }
        testReq.contentDocumentAttachments = cdls;
        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        system.debug('attachlist: '+cdls);
        Boolean ExceptionHit=false;
        try {
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            ExceptionHit=true;
            system.debug('t008_coverageWithAttachments error: '+e.getMessage());
        }
        // This will fail to send because WhatId is not available for sending emails to UserIds.
        if (TEST_WITH_CREATED_RECORDS){
            System.assertEquals(false, ExceptionHit,'Cannot add Attachments and/or send to collections (Contact, Lead, User)');
        } else {
            System.assertEquals(true, ExceptionHit,'WhatId is not available for sending emails to UserIds when using User as targetObject');
        }
    }

// @Test t009_coverageTestActivity: Can allow email record as activity on recordId object
    @isTest
    public static void t009_coverageTestActivity_throwException() {
        String devName = TEMPLATE_DEVNAME+'_'+TEMPLATE_LANGUAGE;
        EmailTemplate validEmailTemplate = [Select Id,Name from EmailTemplate where DeveloperName=:devName];
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.templateName = validEmailTemplate.Name;
        testReq.recordId = validEmailTemplate.Id;
        testReq.allOrNoneEmailSend = true;
        testReq.throwFlowExceptionOnSendEmailException = true;
        if (TEST_WITH_CREATED_RECORDS){
            testReq.templateTargetObjectId = emailCreateTestContacts(TEST_CONTACTS_COUNT)[0].Id;
            testReq.recordId = emailCreateTestAccount(1,testReq.templateTargetObjectId)[0].Id;
            testReq.saveAsActivity = true;
        }else{
            testReq.templateTargetObjectId = UserInfo.getUserId();
            // if templateTargetObjectId type = user, saveAsActivity must be false
            testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
            testReq.saveAsActivity = false;
        }

        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);
        Boolean ExceptionHit=False;
        try {
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
            system.debug('testResponseList: ' + testResponseList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            ExceptionHit=true;
            String error = e.getMessage();
            system.debug('t009_coverageTestActivity error: '+e.getMessage());
        }
        if (TEST_WITH_CREATED_RECORDS){
            System.assertEquals(false, ExceptionHit,'Cannot allow email record as activity on recordId object');
        } else {
            System.assertEquals(true, ExceptionHit,'WhatId is not available for sending emails to UserIds when using User as targetObject');
        }
    }

// @Test t010_canSendEmailCCUsers: Can send email to a collection of users, email addresses and useSalesforceSignature
    @isTest
    public static void t010_canSendEmailCCToCollectionOfUsers() {

        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.HTMLbody = EMAIL_BODY;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.SendBCCthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.SendCCtheEmailAddressesFromThisCollectionOfUsers = [Select Id,Email from User where Id=:UserInfo.getUserId()];
        testReq.SendBCCthisStringCollectionOfEmailAddresses = new List<String>{EMAIL_NOSUCH};
        testReq.useSalesforceSignature = true;
        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);

        Boolean exceptionHit = false;
        try {            
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t001_errorIfNoAddress: '+e.getMessage());
        }
        
        Boolean emailDeliverabilityEnabled = emailDeliverabilityEnabled();
        if(emailDeliverabilityEnabled){
            System.assertEquals(exceptionHit,false,'Cannot send email to a collection of users and email addresses and/or useSalesforceSignature');
        } else {
            System.assertEquals(emailDeliverabilityEnabled,false,'emailDeliverabilityDisabled Enabled or capacity exceeded');
        }
    }
// @Test t011_ErrorIfNoBody: Error expected if (templateID == null  && HTMLbody == null && plainTextBody == null)
    @isTest
    public static void t011_ErrorIfNoBody() {
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);

        Boolean exceptionHit = false;
        try {            
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t011_ErrorIfNoBody: '+e.getMessage());
        }
        
        Boolean emailDeliverabilityEnabled = emailDeliverabilityEnabled();
        if(emailDeliverabilityEnabled){
            System.assertEquals(exceptionHit,true,'Error not received when (templateID == null  && HTMLbody == null && plainTextBody == null)');
        } else {
            System.assertEquals(emailDeliverabilityEnabled,false,'emailDeliverabilityDisabled Enabled or capacity exceeded');
        }
    }
// @Test t012_ErrorIfSaveAsActivityAndNoRecordId: Error expected if (saveAsActivity == true && recordId/whatId == null)
    @isTest
    public static void t012_ErrorIfSaveAsActivityAndNoRecordId() {
        I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
        testReq.Subject = EMAIL_SUBJECT;
        testReq.HTMLbody = EMAIL_BODY;
        testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
        testReq.saveAsActivity = true;
        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        reqList.add(testReq);

        Boolean exceptionHit = false;
        try {            
            List<I_ST_SendEmail.Response> testResponseList = I_ST_SendEmail.SendEmail(reqList);
        } catch (I_ST_SendEmail.InvocableActionException e) {
            exceptionHit=true;
            system.debug('t012_ErrorIfSaveAsActivityAndNoRecordId: '+e.getMessage());
        }
        
        Boolean emailDeliverabilityEnabled = emailDeliverabilityEnabled();
        if(emailDeliverabilityEnabled){
            System.assertEquals(exceptionHit,true,'Error not received when (saveAsActivity == true && recordId/whatId == null)');
        } else {
            System.assertEquals(emailDeliverabilityEnabled,false,'emailDeliverabilityDisabled Enabled or capacity exceeded');
        }
    }
// @Test t013_CoverageAttemptForOrgWideEmailAddress : Error expected if (saveAsActivity == true && recordId/whatId == null)
    @isTest
    public static void t013_ErrorIfSaveAsActivityAndNoRecordId() {
        List<I_ST_SendEmail.Request> reqList = new List<I_ST_SendEmail.Request>();
        for (OrgWideEmailAddress orgAddrs : [SELECT id, DisplayName, Address FROM OrgWideEmailAddress 
                                            WHERE DisplayName = 'Future Students']){
            I_ST_SendEmail.Request testReq = new I_ST_SendEmail.Request();
            testReq.Subject = EMAIL_SUBJECT;
            testReq.HTMLbody = EMAIL_BODY;
            testReq.SendTOthisOneEmailAddress = EMAIL_NOSUCH;
            testReq.orgWideEmailAddressId = orgAddrs.Id;
            reqList.add(testReq);
        }
        if (reqList.size() > 0){
            Boolean exceptionHit = false;
            List<I_ST_SendEmail.Response> testResponseList = new List<I_ST_SendEmail.Response>();
            Test.startTest();
            try {            
                testResponseList = I_ST_SendEmail.SendEmail(reqList);
            } catch (I_ST_SendEmail.InvocableActionException e) {
                exceptionHit=true;
                system.debug('t013_CoverageAttemptForOrgWideEmailAddress: '+e.getMessage());
            }
            Test.stopTest();
            Boolean emailDeliverabilityEnabled = emailDeliverabilityEnabled();
            if(emailDeliverabilityEnabled){
                for(I_ST_SendEmail.Response thisTest : testResponseList){
                    system.debug('t013_CoverageAttemptForOrgWideEmailAddress Response:' + thisTest.isSuccess + ' Template Errors: ' + thisTest.errors + ' Template Used: '+ thisTest.templateUsed);
                }
//                System.assertEquals(exceptionHit,false,'Error on orgWideEmailAddressId');
            } else {
                System.assertEquals(emailDeliverabilityEnabled,false,'emailDeliverabilityDisabled Enabled or capacity exceeded');
            }
        } else {
            System.Debug('Unable to test orgWideEmailAddressId.  No orgWideEmailAddress available.');
        }
    }
}