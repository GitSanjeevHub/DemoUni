/**
 * @author Jie Tan
 * @date 06/10/2020
 * 
 * @group IST
 * 
 * @description To provide an invocable method for flows to convert ServiceAppointmentFields to String
 */

global with sharing class I_ST_FlowFlattenFields {
    /**
     * @description Convert a List of ServiceAppointmentFields to a List of Strings
     * @param
     *      inputs - a List of ServiceAppointmentFields
     * @return A List of Strings
     */
    @InvocableMethod(label='Convert ServiceAppointmentFields to Strings')
    global static List<String> getStrings(List<ServiceAppointmentFields> inputs)
    {
        List<String> outputs = new List<String>();

        for(ServiceAppointmentFields input : inputs) {
            String output = JSON.serialize(input, true);
            output = output.replace('IsNewConsultation', 'I_ST_Consultation_To_Be_Sent__c');
            output = output.replace('IsRescheduledConsultation', 'I_ST_Consultation_Change_To_Be_Sent__c');
            outputs.add(output);
        }
        
        return outputs;
    }

    global class ServiceAppointmentFields {
        @InvocableVariable
        global String AdditionalInformation;

        @InvocableVariable
        global String AppointmentType;

        @InvocableVariable
        global String Comments;

        @InvocableVariable
        global String ParentRecordId;

        @InvocableVariable
        global String ServiceTerritoryId;

        @InvocableVariable
        global String ServiceResourceId;

        @InvocableVariable
        global String Street;

        @InvocableVariable
        global String City;

        @InvocableVariable
        global String State;

        @InvocableVariable
        global String Country;

        @InvocableVariable
        global String PostalCode;

        @InvocableVariable
        global Datetime SchedStartTime;

        @InvocableVariable
        global Datetime SchedEndTime;

        @InvocableVariable
        global String WorkTypeId;

        @InvocableVariable
        global String WorkTypeGroupId;

        @InvocableVariable
        global String Id;

        @InvocableVariable
        global String Description;

        @InvocableVariable
        global String Subject;

        @InvocableVariable
        global String Phone;

        @InvocableVariable
        global String Email;

        @InvocableVariable
        global String ContactId;

        @InvocableVariable
        global Boolean isSlotChanged;

        @InvocableVariable
        global Boolean IsNewConsultation;

        @InvocableVariable
        global Boolean IsRescheduledConsultation;
    }
}