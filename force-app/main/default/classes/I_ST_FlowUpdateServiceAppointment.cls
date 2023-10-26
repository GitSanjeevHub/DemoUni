/**
 * 
 * @description To provide an invocable method for flows to update service appointments
 **/
public without sharing class I_ST_FlowUpdateServiceAppointment {
    /**
     * @description update service appointments / consultations
     * @param
     *      inputs - a List of String to be encrypted
     * @return Encrypted string
     */
    @InvocableMethod(label='Update Service Appointments')
    public static List<String> updateServiceAppointments(List<ServiceAppointment> serviceAppointments)
    {
        List<String> outputs = new List<String>();
        if(!serviceAppointments.isEmpty()) {
            update serviceAppointments;
        }
        return outputs;
    }
}