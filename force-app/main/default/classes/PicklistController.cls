/**
 * Created by burnside on 2019-06-02.
 */

public with sharing class PicklistController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPickListValues(String objectType, String selectedField){

        List<Map<String, String>> pickListValuesList = new List<Map<String, String>>();

        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(
                new Map<String, String>{
                    'label' => pickListVal.getLabel(),
                    'value' => pickListVal.getValue()
                }
            );
        }
        return pickListValuesList;

    }

}