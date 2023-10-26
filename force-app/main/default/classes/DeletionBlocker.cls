public without sharing class DeletionBlocker {
    
    public static List<SObject> blockDelete(String objectName, List<SObject> records)
    {

        String debugPrefix = 'DeletionBlocker.blockDelete>>> ';
        System.debug(debugPrefix + objectName);
        System.debug(debugPrefix + records);


        Object_Metadata__c blockerCustomSetting = Object_Metadata__c.getInstance(objectName);       
        System.debug(debugPrefix + blockerCustomSetting);


        if (blockerCustomSetting != null && blockerCustomSetting.I_RS_Enable_Deletion_Blocker__c) 
        {

            List<SObject> failedRecords = new List<SObject>();

            String fieldNameToValidate = blockerCustomSetting.I_RS_Deletion_Blocker_Check_Formula__c;
            String errorMessage = blockerCustomSetting.I_RS_Deletion_Blocker_Error_Message__c;

            
            for (SObject record : records){

                Boolean validToDelete = (Boolean) record.get(fieldNameToValidate);
                if (!validToDelete){
                    failedRecords.add(record);
                    record.addError(errorMessage);
                }
            }

            System.debug(debugPrefix + failedRecords);
            return failedRecords;

        }
        else if (blockerCustomSetting != null && !blockerCustomSetting.I_RS_Enable_Deletion_Blocker__c)
        {
            System.debug(debugPrefix + ' Delete blocker disabled');
            return new List<SObject>{};
        }
        else if (blockerCustomSetting == null)
        {
            System.debug(debugPrefix + ' Delete blocker not found');
        }
        
        return null;
    }

}