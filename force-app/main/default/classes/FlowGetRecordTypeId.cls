public with sharing class FlowGetRecordTypeId {

    public class FlowGetRecordTypeInput {
        @InvocableVariable(required=true)
        public String objectName;

        @InvocableVariable(required=true)
        public String recordTypeName;
    }

    @InvocableMethod(label='Get Record Type Id')
    public static List<Id> getRecordTypeIdByName(List<FlowGetRecordTypeInput> inputs)
    {
        List<Id> recordTypeIdOutput = new List<Id>();

        String objectName = inputs[0].objectName;
        String recordTypeName = inputs[0].recordTypeName;

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);  
        Schema.DescribeSObjectResult resultDescribe = sObjectType.getDescribe(); 
        Map<String, Schema.RecordTypeInfo> recordTypeInfos = resultDescribe.getRecordTypeInfosByDeveloperName();  
        
        Id recordTypeId = recordTypeInfos.get(recordTypeName).getRecordTypeId();

        for (Integer i=0; i<inputs.size(); i++){
            recordTypeIdOutput.add(recordTypeId);
        }
        
        return recordTypeIdOutput;
    }
}