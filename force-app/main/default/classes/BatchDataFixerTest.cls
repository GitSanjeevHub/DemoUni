@isTest
public with sharing class BatchDataFixerTest {

    @TestSetup
    static void makeData(){
        //
        Data_Fixer_Job_Setting__c jobConfig = new Data_Fixer_Job_Setting__c(
            Name = 'Set Task fields',
            I_RS_Unique_Identifier__c = 'SetTaskFields',
            I_RS_Object_Name__c = 'Task',
            I_RS_Record_Filter__c = 'Subject = "Task To Update"'
        );
        
        List<Map<String, String>> newFieldValues = 
            new List<Map<String, String>>{
                new Map<String, String>{
                    'fieldName' => 'Description',
                    'dataType' => 'text',
                    'newValue' => 'Description goes here'
                },  
                /*new Map<String, String>{
                    'fieldName' => 'I_RS_Milestone_Amount__c',
                    'dataType' => 'number',
                    'newValue' => '10'
                },*/
                new Map<String, String>{
                    'fieldName' => 'ActivityDate',
                    'dataType' => 'date',
                    'newValue' => 'TODAY'
                }/*,
                new Map<String, String>{
                    'fieldName' => 'IsVisibleInSelfService',
                    'dataType' => 'boolean',
                    'newValue' => 'false'
                }*/
            };
        jobConfig.I_RS_New_Field_Values__c = JSON.serialize(newFieldValues);
        System.debug(jobConfig.I_RS_New_Field_Values__c);

        insert jobConfig;

        Task taskToUpdate = TestUtility.newTask(null);
        taskToUpdate.Subject = 'Task to Update';
        taskToUpdate.ActivityDate = Date.today()+7;
        insert taskToUpdate;

        Task taskToIgnore = TestUtility.newTask(null);
        taskToIgnore.ActivityDate = Date.today()+1;
        insert taskToIgnore;
    }

    public static testmethod void validBatch() {

        //Kick off immediate batch based on config - make case-insensitive
        Test.startTest();

        Database.executeBatch(new BatchDataFixer('SetTaskFields'));

        Test.stopTest();

        List<Apex_Debug_Log__c> errorLogs = [select Id, Exception_Message__c
        from Apex_Debug_Log__c];
        for (Apex_Debug_Log__c errorLog : errorLogs){
            System.debug(errorLog);
        }
        System.assertequals(0, errorLogs.size());

        Task updatedTask = [SELECT Description, I_RS_Milestone_Amount__c, ActivityDate,
                IsVisibleInSelfService FROM Task
                WHERE ActivityDate = TODAY];
        System.assertequals('Description goes here' , updatedTask.Description);
        //System.assertequals(10 , updatedTask.I_RS_Milestone_Amount__c);
        System.assertequals(Date.today(), updatedTask.ActivityDate);
        //System.assertequals(false , updatedTask.IsVisibleInSelfService);

    }

    public static testmethod void validSchedule(){

        String scheduleExpression = '0 0 0 * * ?'; 
        BatchDataFixerScheduler schedulableInstance = new BatchDataFixerScheduler('SetTaskFields', 10);
        
        Test.startTest();
            
		System.schedule('Regular data fixer', scheduleExpression, schedulableInstance);
        
        Test.stopTest(); 

    }

    //Invalid scenarios will simply manifest as exceptions,
    //It is up to the admins to properly configure the fields 


}