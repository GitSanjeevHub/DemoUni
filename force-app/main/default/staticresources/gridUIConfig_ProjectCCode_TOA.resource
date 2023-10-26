{
    "cardTitle" : "Type of Activity",
    "objectName" : "Classification_Code__c",
    "recordTypeName" : "TOA_Codes",
    "columns" : [
        {
            "fieldName": "I_RS_Classification_Master__c", 
            "label": "Classification Code", 
            "type" : "lookup",
            "lookupObjectName": "Classification_Master__c",
            "lookupObjectRelationship": "I_RS_Classification_Master__r",

            "lookupBaselineFilter" : "I_RS_Type__c = 'Type of Activity (TOA)' AND I_RS_Active__c = TRUE",
    
            "width": 800,

            "lookupIconName": "custom:custom48",
            "lookupTitleField": "I_RS_Full_Code_and_Name__c",
            
            "visible": true,
            "canUpdate": true
        },
        {
            "fieldName": "I_RS_Percentage__c", 
            "label": "Percentage", 
            "type": "number",
            "defaultValue": 0,
            "min" : 1,
            "step" : "0",
            "canUpdate": true,
            "required": true
        }

    ],
    "automations" : [
        {
            "name" : "Override 'disable validation' hack",
            "type" : "javascript",
            "runOn" : [
                "load"
            ],
            "criteria" : [],
            "assignments" : [
                {
                    "destination": "row",
                    "valueType": "static",
                    "cellIdentifierInRow": "I_RS_Disable_Grid_Validation__c",
                    "value": false
                }
            ]
        },
        {
            "name" : "Check for at least one code",
            "type" : "javascript",
            "runOn": [
                "load",
                "placeholder",
                "change",
                "delete"
            ],
            "criteria" : [],
            "customFunction" : "validateAtLeastOneCode",
            "triggerFields": [
                "I_RS_Classification_Master__c",
                "I_RS_Percentage__c"
            ],
            "params" : {
                "classificationMasterFieldName" : "I_RS_Classification_Master__c"
            }
        },
        {
            "name" : "Check that percentages equal 100%",
            "type" : "javascript",
            "runOn": [
                "load",
                "placeholder",
                "change",
                "delete"
            ],
            "criteria" : [],
            "customFunction" : "validatePercentageTotal",
            "triggerFields": [
                "I_RS_Percentage__c"
            ],
            "params" : {
                "percentageFieldName" : "I_RS_Percentage__c"
            }
        },
        {
            "name" : "Check for duplicate Classification Masters",
            "type" : "javascript",
            "runOn": [
                "load",
                "change",
                "delete"
            ],
            "criteria" : [],
            "customFunction" : "validateNoDuplicates",
            "triggerFields": [
                "I_RS_Classification_Master__c"
            ],
            "params" : {
                "classificationMasterFieldName" : "I_RS_Classification_Master__c"
            }
        },
        {
            "name" : "Remove empty rows",
            "type" : "javascript",
            "runOn": [
                "presave"
            ],
            "criteria" : [],
            "customFunction" : "removeEmptyRows",
            "triggerFields": [],
            "params" : {
                "fieldsToCheck" : [
                    "I_RS_Classification_Master__c",
                    "I_RS_Percentage__c"
                ]
            }
        }
    ],

    "recordListBaselineFilter" : 
        "I_RS_Classification_Master__r.I_RS_Type__c = 'Type of Activity (TOA)' AND I_RS_Inactive_for_Non_Admins__c = FALSE",
        
    "lookupFieldNameToHostRecord" : "I_RS_Project_Proposal__c",
    "hostRecordFields" : ["Project_Proposal__c.Name"],

    "placeholderRowCount" : 4,
    "maxRowCount" : 4,

    "canCreate" : true,
    "canClone" : false,
    "canDelete" : true,
    "canSave" : true,

    "showSimpleWarningsAndErrors" : false,

    "allOrNothingUpserts" : true,

    "softDeleteField" : "I_RS_Inactive_for_Non_Admins__c",
    "softDeleteValue" : true,

    "tableBodyHeight" : "35vh",

    "refreshPageOnSave" : false

}