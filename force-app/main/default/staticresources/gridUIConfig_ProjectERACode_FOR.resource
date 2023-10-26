{
    "cardTitle" : "Fields of Research",
    "objectName" : "ERA_Classification_Code__c",
    "recordTypeName" : "I_RS_Project",
    "columns" : [
        {
            "fieldName": "I_RS_Classification_Master__c", 
            "label": "Classification Code", 
            "type" : "lookup",
            "lookupObjectName": "Classification_Master__c",
            "lookupObjectRelationship": "I_RS_Classification_Master__r",

            "lookupBaselineFilter" : "I_RS_Type__c = 'Fields of Research (FOR)' AND I_RS_Active__c = TRUE",
    
            "width": 800,

            "lookupIconName": "custom:custom48",
            "lookupTitleField": "I_RS_Full_Code_and_Name__c",
            
            "visible": true,
            "canUpdate": true,

            "required": true
        },
        {
            "fieldName": "I_RS_Percentage__c", 
            "label": "Percentage", 
            "type": "number",
            "defaultValue": 0,
            "min" : 10,
            "step" : "0",
            "canUpdate": true,
            "required": true
        },
        {
            "fieldName": "I_RS_Primary__c", 
            "label": "Primary", 
            "type": "checkbox", 
            "defaultValue": false,
            "required": false,
            "visible": true,
            "canUpdate": true,
            "width": 90,
            "helpText" : "Each project must be assigned a primary field of research. In most cases this will be the largest percentage. Where there are two or more equal largest, one of these must be selected."
        }

    ],
    "automations" : [
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
                "I_RS_Percentage__c",
                "I_RS_Primary__c"
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
            "name" : "Auto set Primary based on highest",
            "type" : "javascript",
            "runOn": [
                "change",
                "delete"
            ],
            "criteria" : [],
            "customFunction" : "autoSetPrimary",
            "triggerFields": [
                "I_RS_Percentage__c"
            ],
            "params" : {
                "percentageFieldName" : "I_RS_Percentage__c",
                "primaryFieldName" : "I_RS_Primary__c"
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
            "name" : "Check only one is marked as Primary",
            "type" : "javascript",
            "runOn": [
                "load",
                "change",
                "delete"
            ],
            "criteria" : [],
            "customFunction" : "validateOnlyOnePrimary",
            "triggerFields": [
                "I_RS_Percentage__c",
                "I_RS_Primary__c"
            ],
            "params" : {
                "primaryFieldName" : "I_RS_Primary__c"
            }
        },
        {
            "name" : "Check Primary is highest percentage",
            "type" : "javascript",
            "runOn": [
                "load",
                "change",
                "delete"
            ],
            "criteria" : [],
            "customFunction" : "validatePrimaryIsHighestPercentage",
            "triggerFields": [
                "I_RS_Classification_Master__c",
                "I_RS_Percentage__c",
                "I_RS_Primary__c"
            ],
            "params" : {
                "percentageFieldName" : "I_RS_Percentage__c",
                "primaryFieldName" : "I_RS_Primary__c"
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
                    "I_RS_Percentage__c",
                    "I_RS_Primary__c"
                ]
            }        
        }
    ],

    "recordListBaselineFilter" : 
        "I_RS_Classification_Master__r.I_RS_Type__c = 'Fields of Research (FOR)' AND I_RS_Inactive_for_Non_Admins__c = FALSE AND I_RS_ERA_Collection__c = NULL",

    "lookupFieldNameToHostRecord" : "I_RS_Project_Proposal__c",
    "hostRecordFields" : ["Project_Proposal__c.Name"],

    "placeholderRowCount" : 3,
    "maxRowCount" : 3,

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