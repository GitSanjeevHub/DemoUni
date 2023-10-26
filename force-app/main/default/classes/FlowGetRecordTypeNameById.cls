public class FlowGetRecordTypeNameById {

    //Assumption is that only one object type will be passed in a a time, hence the inputs[0].objectName
    @InvocableMethod
    public static List<String> flowGetRecordTypeNameById(List<FlowGetRecordTypeNameByIdInput> inputs) {

        System.debug('flowGetRecordTypeNameById');
        List<String> recordTypeNames = new List<String>();
        String objectName = inputs[0].objectName;
        Map<Id, Schema.RecordTypeInfo> recordTypeInfosById = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById();

        for (FlowGetRecordTypeNameByIdInput input : inputs){

            String recordTypeName = recordTypeInfosById.get(input.recordTypeId).getDeveloperName();
            recordTypeNames.add(recordTypeName);
        }

        return recordTypeNames;
    }

    public class FlowGetRecordTypeNameByIdInput{
        @InvocableVariable public String objectName;
        @InvocableVariable public Id recordTypeId;
    }

}