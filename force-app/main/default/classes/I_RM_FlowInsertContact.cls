/**
* I_ST_FlowInsertContact
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @Modification logs
* 24/02/2022 - Vanita Walia - Modified the code as part of remediation and removed all the logic 
* This apex action is used in Schedule Consultation Flow to insert contacts bypassing duplicates
* Updated Class name from I_ST_FlowInsertDuplicate to I_ST_FlowInsertContact
* @Modified by Vanita - 17/05/2022 - Updated name to I_RM_FlowInsertContact from I_ST_FlowInsertContact
*/

global class I_RM_FlowInsertContact{
    
    @InvocableMethod(label='Insert Contact')
    global static List<String> SaveContact(List<Contact> cons) {
         //Save records and bypass duplicate rules
        return I_ST_GenericUtils.save(cons, 'Insert');
    } 
}