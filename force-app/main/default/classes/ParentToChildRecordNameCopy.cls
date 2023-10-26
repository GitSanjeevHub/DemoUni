public class ParentToChildRecordNameCopy {

    public static void copyRelatedToDataToChildActivities(List<Task> childActivities)
    {
        Map<String, Object_Metadata__c> parentObjectMetadataMap = new Map<String, Object_Metadata__c>();
        Set<String> parentObjectApiNames = new Set<String>();
        Set<Id> parentRecordIds = new Set<Id>();

        for (Object_Metadata__c metadata : Object_Metadata__c.getAll().values())
        {
            parentObjectMetadataMap.put(metadata.I_RS_First_3_Characters_on_Record_Ids__c, metadata);
        }

        for (Task childActivity : childActivities)
        {
            childActivity.I_RS_Parent_Object_Label_Singular__c = null;
            childActivity.I_RS_Parent_Object_Name__c = null;
            childActivity.I_RS_Parent_Record_Name__c = null;

            if (childActivity.WhatId != null)
            {
                parentRecordIds.add(childActivity.WhatId);

                String objectIdPrefix = ((String) childActivity.WhatId).left(3);
                Object_Metadata__c parentObjectMetadata = parentObjectMetadataMap.get(objectIdPrefix);
                if (parentObjectMetadata != null)
                {
                    childActivity.I_RS_Parent_Object_Label_Singular__c = parentObjectMetadata.I_RS_Object_Label_Singular__c;
                    childActivity.I_RS_Parent_Object_Name__c = parentObjectMetadata.Name;

                    parentObjectApiNames.add(parentObjectMetadata.Name);
                }

                
            }
        }

        for (String parentObjectApiName : parentObjectApiNames)
        {
            String dynamicParentSOQL = 'SELECT Id, Name from '+parentObjectApiName+' WHERE ID IN :parentRecordIds';
            Map<Id, SObject> parentRecords = new Map<Id, SObject>(Database.query(dynamicParentSOQL));

            for (Task childActivity : childActivities)
            {
                if (childActivity.get('WhatId') != null)
                {
                    SObject parentRecord = parentRecords.get((String) childActivity.get('WhatId'));
                    if (parentRecord != null)
                    {
                        childActivity.I_RS_Parent_Record_Name__c = (String) parentRecord.get('Name');
                    }
                }
            }
        }

    }
}