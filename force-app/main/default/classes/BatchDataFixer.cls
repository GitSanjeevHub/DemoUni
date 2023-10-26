public without sharing class BatchDataFixer implements Database.Batchable<SObject> {
    
    String jobConfigName;
    Boolean isActive;
    String objectAPIName;
    String filter;
    List<DataFixerNewFieldValue> newFieldValues;

    public BatchDataFixer(String jobConfigName) {

        Data_Fixer_Job_Setting__c jobConfig = [
            SELECT Id, I_RS_Object_Name__c, I_RS_Record_Filter__c, I_RS_New_Field_Values__c, I_RS_Active__c 
            FROM Data_Fixer_Job_Setting__c 
            WHERE I_RS_Unique_Identifier__c = :jobConfigName
        ];

        isActive = jobConfig.I_RS_Active__c;

        objectAPIName = jobConfig.I_RS_Object_Name__c;
        filter = jobConfig.I_RS_Record_Filter__c.replaceAll('"','\'');
        newFieldValues = (List<DataFixerNewFieldValue>) 
                JSON.deserialize(jobConfig.I_RS_New_Field_Values__c, List<DataFixerNewFieldValue>.class);

    }

    public Database.QueryLocator start(Database.BatchableContext BC){

        String query = 'SELECT Id FROM '+objectAPIName+
            ' WHERE '+filter;
        System.debug('query '+query);
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> records){

        if (isActive){
            for (SObject record : records){
                for (DataFixerNewFieldValue field : newFieldValues){

                    String fieldName = field.fieldName;
                    System.debug('fieldName '+fieldName);
                    System.debug('dataType '+field.dataType);

                    switch on field.dataType {
                        when 'text' {
                            record.put(fieldName, field.newValue);
                        }
                        when 'number' {
                            record.put(fieldName, Decimal.valueOf(field.newValue));
                        }
                        when 'date' {
                            switch on field.newValue.toUpperCase() {
                                when 'TODAY' {
                                    record.put(fieldName, Date.today());
                                }
                                //Add other dymamic options here
                            }
                        }
                        when 'time' {
                            switch on field.newValue.toUpperCase() {
                                when 'NOW' {
                                    record.put(fieldName, System.now());
                                }
                                //Add other dymamic options here
                            }
                        }
                        when 'boolean' {
                            switch on field.newValue.toLowerCase() {
                                when 'true' {
                                    record.put(fieldName, true);
                                }
                                when 'false' {
                                    record.put(fieldName, false);
                                }
                            }
                        }
                    }
                    System.debug('newValue '+record.get(fieldName));
                }
                System.debug('record '+record);
            }
            List<Database.SaveResult> updateResults = Database.update(records, false);

            List<Apex_Debug_Log__c> errorLogs = GlobalUtility.constructErrorLogsForDMLErrors(
                updateResults, records, 'BatchDataFixer', jobConfigName);

            if (!errorLogs.isEmpty()){
                Database.insert(errorLogs, false);
            }

        }

    }

    public void finish(Database.BatchableContext BC){

    }


    class DataFixerNewFieldValue {
        String fieldName;
        String dataType;
        String newValue;

        /*DataFixerNewFieldValue(String fieldName, String dataType, String newValue){
            this.fieldName = fieldName;
            this.dataType = dataType;
            this.newValue = newValue;
        }*/

    }

}