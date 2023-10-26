/**
     * @class L_IL_LogCustomException
     * @author Sethu Venna
     * @date 24-11-2022
     * @description Method to be invoked to insert a record into Apex_Debug_Log__c 
     * 
 */

public with sharing class L_IL_LogCustomException extends Exception { 
    
    /**
     * @description Method to be invoked to insert a record into Apex_Debug_Log__c 
     * @param ex – instance of Standard Exception that holds the exception detail
     * @param relatedToId – Any record that the exception needs to be linked to
     * @param logType – type of error
    */

    public static void LogException(
        Exception ex,
        String relatedToId,
	  	String logType
    ) {
        try
        {
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.'); 
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
                
            //Governer Limit of executingQuery 
            String QueryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String DMLimit = ' 2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String DMLStat = ' 3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String CPUT = ' 4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();

            Apex_Debug_Log__c log = new Apex_Debug_Log__c();
            log.Apex_Class_Name__c = className;
            log.Apex_Class_Method_Name__c = methodName;
            log.Exception_Message__c = ex.getMessage();
            log.Related_To_Id__c = relatedToId;
            log.Exception_stack_trace__c = ex.getStackTraceString();
            log.Log_Type__c = logType;
            //log.Transaction_Description__c = QueryLimit + DMLimit + DMLStat + CPUT;
            database.insert(log);           
        }
        catch (Exception exc) {
            L_IL_LogCustomException.LogException(exc, 'None', 'Error');
        } 

    } 
}