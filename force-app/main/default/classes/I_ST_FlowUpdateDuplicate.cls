global class I_ST_FlowUpdateDuplicate {
    @InvocableMethod(label='Update Contact')
    global static List<String> SaveContact(List<Contact> cons) {
        //Cast picklist fields due to issue with passing sObjects to invocable methods
        cons = I_ST_GenericUtils.setPicklists(cons);

        //Save records and bypass duplicate rules
        return I_ST_GenericUtils.save(cons, 'Update');
    }
}