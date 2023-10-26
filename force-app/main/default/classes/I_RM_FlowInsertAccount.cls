/*
* @Modified by Vanita - 01/03/2022 : As part of remediation renamed the class name from I_ST_FlowInsertDuplicateAccount to I_ST_FlowInsertAccount
* @Modified by Vanita - 17/05/2022 - Updated name to I_RM_FlowInsertAccount from I_ST_FlowInsertAccount
*/

global class I_RM_FlowInsertAccount {
    
    @InvocableMethod(label='Insert Account')
    global static List<String> SaveAccount(List<Account> accts) {
        //Cast picklist fields due to issue with passing sObjects to invocable methods
        accts = I_ST_GenericUtils.setPicklists(accts);

        //Save records and bypass duplicate rules
        return I_ST_GenericUtils.save(accts, 'Insert');
    } 
}