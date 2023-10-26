@isTest
public class LoggerTest {

    public static testmethod void positiveCase_AllData(){ 

        Account acc = TestUtility.newEmptyExternalAccount('Test account');
        insert acc;

        Test.startTest();
        
        Logger.log( 

            new Map<String, Object>{
                Logger.LOG_TYPE => Logger.LOG_TYPE_VALUE_ERROR,
                Logger.TRANSACTION_TYPE => Logger.TRANSACTION_TYPE_VALUE_SERVICE_REST,
                    
                Logger.RELATED_TO_ID => acc.id,
 
                Logger.CLASS_NAME => 'ClassName',
                Logger.CLASS_METHOD_NAME => 'MethodName',
                    
                Logger.TRANSACTION_DESCRIPTION => 'Some notes about the transaction go here - equivalent to a comment',

                Logger.EXCEPTION_MESSAGE => 'Error in class',
                Logger.EXCEPTION_STACK_TRACE => 'Line 9, row 1 million',

                Logger.REQUEST_DATA => 'Request Body',
                    
                Logger.RESPONSE_STATUS_CODE => 500

            });

        Test.stopTest();
        
        Apex_Debug_Log__c a = getLog();

        System.assert(a.Transaction_Type__c != null);
        System.assert(a.Log_Type__c != null);
        
        System.assert(a.Related_To_Id__c != null);

        System.assert(a.Apex_Class_Name__c != null);
        System.assert(a.Apex_Class_Method_Name__c != null);
        
        System.assert(a.Transaction_Description__c != null);

        System.assert(a.Exception_Message__c != null);
        System.assert(a.Exception_Stack_Trace__c != null);

        System.assert(a.Request_Data__c != null);

        System.assert(a.Response_Status_Code__c != null);
        
        System.assert(a.Logged_In_Salesforce_User__c != null);

    }



    public static testmethod void negativeCase_Empty(){
        Logger.log(new Map<String, Object>{});

        System.assertequals(1, [select count() from Apex_Debug_Log__c]);
    }
    
    
    public static testmethod void negativeCase_InvalidData(){
        
        String classNameTooLong = '12345678901234567890123456789012345678901234567890';
        
        Logger.log(

            new Map<String, Object>{
                Logger.CLASS_NAME => classNameTooLong
            }
        );
        
        System.assertequals(0, [select count() from Apex_Debug_Log__c]);
    }

    public static testmethod void testAttachments(){

        //Create long-ass strings (>200k chars)
        String longAssString = '';
        for (Integer i=1; i<=10000; i++){
            longAssString += '01234567890123456789';
        }
        
        Logger.log( 

            new Map<String, Object>{
                Logger.REQUEST_DATA => longAssString,
                Logger.RESPONSE_BODY => longAssString
            });
        
        //Check attachment file has been created
        Apex_Debug_Log__c a = [select Id from Apex_Debug_Log__c];
        
		System.assert([select Id from FeedItem].size() > 0, 'Creating attachment failed');        
        
    }
    
    static Apex_Debug_Log__c getLog(){
        return [select Id,
            Transaction_Type__c, Log_Type__c,
            Related_To_Id__c,
            Apex_Class_Name__c, Apex_Class_Method_Name__c,
            Transaction_Description__c,
			Exception_Message__c, Exception_Stack_Trace__c,
            Request_Data__c, Response_Status_Code__c,
			Logged_In_Salesforce_User__c
        	from Apex_Debug_Log__c][0];
    }
    
}