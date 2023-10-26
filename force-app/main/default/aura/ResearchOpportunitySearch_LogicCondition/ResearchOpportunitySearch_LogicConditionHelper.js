/**
 * Created by burnside on 2019-05-23.
 */
({

    setUIBasedOnValues : function(component, event, helper){

        if (component.get("v.filter.value"))
            component.set("v.displayValue", component.get("v.filter.value"));
        if (component.get("v.filter.operator"))
            component.set("v.displayOperator", component.get("v.filter.operator"));

        if (component.get("v.filter.filterType") == 'relatedRecords'){
            if (component.get("v.displayValue")){

                var relatedRecordIds = component.get("v.displayValue");
                var compressedIds = relatedRecordIds.join(";");
                component.set("v.lookupValue", compressedIds);

            }
        }

    },


    setFilterSelectionOptions : function(component, event, helper){

        //////console.log('setFilterSelectionOptions');

        component.set(
            "v.filterSelectionOptions",
            [
                //{label:'Find records that do not have', value:'textNotInRecord'},
                {label: 'Submission Date', value: 'submissionDate'},
                //{label:'Min Budget No More Than', value:'minBudget'},
                //{label:'Max Budget At Least', value:'maxBudget'},
                //{label:'Is Student Led', value:'studentLed'},
                {label: 'HERDC Category', value:'HERDCCategory'},
                {label: 'Opportunity Type', value:'opportunityType'}
            ]
        );

        component.set("v.trueOrFalseOptions",
            [{value:'TRUE', label:'Yes'},{value:'FALSE', label:'No'}]
        );

    },


    mapFilterTypeBasedOnFilterSelection : function(component, event, helper){

        //////console.log('mapFilterTypeBasedOnFilterSelection');

        var filterSelection = component.get("v.filter.filterSelection");
        switch (filterSelection) {
            case 'textInRecord': case'textNotInRecord':
                component.set("v.filter.filterType", "text");
                break;
            case 'FORCodes':
                component.set("v.filter.filterType", "relatedRecords");
                break;
            case 'submissionDate':
                component.set("v.filter.filterType", "date");
                break;
            case 'maxBudget': case 'minBudget': //Add more here
                component.set("v.filter.filterType", "number");
                break;
            case 'studentLed':
                component.set("v.filter.filterType", "boolean");
                break;
            case 'HERDCCategory': case 'opportunityType':
                component.set("v.filter.filterType", "picklist");
                break;
        }

    },

    renderOperatorsByUserSelectedFilterType : function(component, event, helper){

        //////console.log('renderOperatorsByUserSelectedFilterType');

        var operators = [];
        var filterSelection = component.get("v.filter.filterSelection");

        switch(filterSelection){

            case 'submissionDate':
                operators = [
                    {label: 'Before or on', value: '<='},
                    {label: 'On date', value: '='},
                    {label: 'On or after', value: '>='},
                ];
                break;

            case 'FORCodes':
                operators = [
                    {label: 'Include', value: 'IN'},
                    {label: 'Exclude', value: 'NOT IN'}
                ];
                break;

            case 'HERDCCategory': case 'opportunityType':
                operators = [
                    {label: 'Equal To', value: '='},
                    {label: 'Not Equal', value: '!='},
                ];
                break;

        }

        //////console.log('operators '+operators);

        component.set("v.validOperators", operators);

        if (operators.length > 0){
            component.set("v.operatorFieldRequired", true);
            component.set("v.displayOperator", operators[0].value);
        }
        else {
            component.set("v.operatorFieldRequired", false);
        }

    },

    writeUserFilterPreferencesToJson : function(component, event, helper){

        //////console.log('writeUserFilterPreferencesToJson');

        var filterSelection = component.get("v.filter.filterSelection");
        var displayValue = component.get("v.displayValue");
        var displayOperator = component.get("v.displayOperator");

        //////console.log('displayOperator '+displayOperator);
        //////console.log('displayValue '+displayValue);

        switch(filterSelection){

            case 'textInRecord':
                //////console.log('textInRecord');
                component.set("v.filter.operator", 'includes');
                component.set("v.filter.value", displayValue);
                break;

            case 'textNotInRecord':
                //////console.log('textNotInRecord');
                component.set("v.filter.operator", 'excludes');
                component.set("v.filter.value", displayValue);
                break;

            case 'FORCodes':
                if (displayValue){
                    var FORCodes = displayValue.split(';');
                    //////console.log(topics);

                    component.set("v.filter.relatedObject", "Classification_Code__c");
                    component.set("v.filter.researchOpportunityLookupField", "I_RS_Research_Opportunity__c");
                    component.set("v.filter.researchOpportunityRelationshipName", "Classification_Codes__r");
                    component.set("v.filter.idFieldToCheckAgainstSet", "I_RS_Classification_Master__c");
                    component.set("v.filter.operator", displayOperator);
                    component.set("v.filter.value", FORCodes);

                }
                break;

            case 'submissionDate':
                component.set("v.filter.field", "I_RS_Submission_Date__c");
                component.set("v.filter.operator", displayOperator);
                component.set("v.filter.value", displayValue);
                break;

            case 'minBudget':
                component.set("v.filter.field", "I_RS_Minimum_Available_Budget__c");
                component.set("v.filter.operator", "<=");
                component.set("v.filter.value", displayValue);
                break;

            case 'maxBudget' :
                component.set("v.filter.field", "I_RS_Maximum_Available_Budget__c");
                component.set("v.filter.operator", ">=");
                component.set("v.filter.value", displayValue);
                break;

            case 'studentLed' :
                component.set("v.filter.field", "I_RS_Student_Led__c");
                component.set("v.filter.operator", "=");
                component.set("v.filter.value", displayValue);
                break;

            case 'HERDCCategory' :
                component.set("v.filter.field", "I_RS_Funding_Category__c");
                component.set("v.filter.operator", displayOperator);
                component.set("v.filter.value", displayValue);
                break;

            case 'opportunityType' :
                component.set("v.filter.field", "I_RS_Type_of_Opportunity__c");
                component.set("v.filter.operator", displayOperator);
                component.set("v.filter.value", displayValue);
                break;

        }

        ////////console.log(JSON.stringify(component.get("v.filter")));

    },

})