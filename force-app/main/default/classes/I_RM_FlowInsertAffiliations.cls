/**
* I_ST_FlowInsertAffiliations
*@Author - Vanita Walia
*@ Date - 24/02/2022
*@Description - This apex action is used in Schedule Consultation Flow to insert affiliations
* @Modified by Vanita - 17/05/2022 - Updated name to I_RM_FlowInsertAffiliations from I_ST_FlowInsertAffiliations
*/
global class I_RM_FlowInsertAffiliations {
    @InvocableMethod(label='Insert Affiliation')
    global static List<String> InsertAffiliation(List<I_RM_Affiliation__c> affs) {
        //Cast picklist fields due to issue with passing sObjects to invocable methods
        affs = I_ST_GenericUtils.setPicklists(affs);

        //Insert affiliation records and bypass duplicate rules
        return I_ST_GenericUtils.save(affs, 'Insert');
    } 

}