@isTest
public class TaskToOutlookTest {

    static public Boolean forceCalloutFail = false; 
    

    
    public static testmethod void calloutTest_Insert_Success(){
        doAThing('insert', false, 'Insert Successful');
    }
    
    public static testmethod void calloutTest_Insert_Failure(){
        doAThing('insert', true, 'Insert Failed');      
    }
    
    public static testmethod void calloutTest_Delete_Success(){
        doAThing('delete', false, 'Delete Successful');
    }
    
    public static testmethod void calloutTest_Delete_Failure(){
        doAThing('delete', true, 'Delete Failed');      
    }

    public static void doAThing(String operationType, Boolean forceCalloutFail, String expectedSyncStatus){
        
        Test.setMock(HttpCalloutMock.class, new TaskToOutlookCalloutMock());
		TaskToOutlookTest.forceCalloutFail = forceCalloutFail;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Theme__c = 'No theme alignment ';
        insert pp;
        
        Task taskToCallout = TestUtility.newTask(pp.Id);
        insert taskToCallout;
        
        Task processedTask;
        
        Test.startTest();
       	processedTask = new TaskToOutlookCalendarCallout(taskToCallout, operationType).execute();
        Test.stopTest();
        
        update processedTask;
        
        System.assert((processedTask.I_RS_Task_to_Outlook_Sync_Error_Message__c != null) == forceCalloutFail);
        System.assertequals(expectedSyncStatus, processedTask.I_RS_Task_to_Outlook_Sync_Status__c);
        
    }
    
    
    
    
    public static testmethod void batchHandlerTest(){
        
        Test.setMock(HttpCalloutMock.class, new TaskToOutlookCalloutMock());
        TaskToOutlookTest.forceCalloutFail = false;

        
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'LTU Partner Community User' Limit 1];
        
		Account portalAccount = TestUtility.newEmptyExternalAccount('TestAccount');
		insert portalAccount;

        Contact portalContact = TestUtility.newContact(portalAccount.Id);
        insert portalContact;
        
        User portalUser = TestUtility.newUser('outlook', portalProfile.Id, null, portalContact.Id);
        insert(portalUser);
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Theme__c = 'No theme alignment ';
        insert pp;
        
        Task taskToCallout = TestUtility.newTask(pp.Id);
        taskToCallout.OwnerId = portalUser.Id;
        taskToCallout.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Ethics').getRecordTypeId();
        taskToCallout.I_RS_Task_to_Outlook_Sync_Status__c = 'Insert Pending';
        insert taskToCallout;
        
		Test.startTest();
        
        Database.executeBatch(new TaskToOutlookCalendarBatchHandler('insert'), 1);
        
        Test.stopTest();
        
          //System.assertequals('Insert Successful', [select I_RS_Task_to_Outlook_Sync_Status__c from Task].I_RS_Task_to_Outlook_Sync_Status__c);
        
    }
    
    public static testmethod void schedulerTest(){
        
        String scheduleExpression = '0 0 23 * * ?'; 
        
        TaskToOutlookCalendarBatchScheduler schedulableInstance = new TaskToOutlookCalendarBatchScheduler('insert', 1);
        
        Test.startTest();
            
		System.schedule('Task To Outlook Insert', scheduleExpression, schedulableInstance);
        
        Test.stopTest(); 
    
    } 
    
    
}