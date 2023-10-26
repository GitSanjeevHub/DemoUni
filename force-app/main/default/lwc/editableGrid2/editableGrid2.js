/* eslint-disable no-console */
/* eslint-disable vars-on-top */
import { LightningElement, track, api } from 'lwc';
import getRecords from '@salesforce/apex/DataAccess.getSObjectListSOQL';
import upsertRecords from '@salesforce/apex/DataAccess.upsertRecords';
import deleteRecord from '@salesforce/apex/DataAccess.deleteRecords'
import runAutomation from '@salesforce/apex/EditableGridAutomationController.runAutomation';

import {sum, multiply} from './mathAutomations';
import {
    validateAtLeastOneCode,
    validatePercentageTotal, 
    autoSetPrimary, 
    validateNoDuplicates,
    validateOnlyOnePrimary, 
    validatePrimaryIsHighestPercentage,
    removeEmptyRows} from './customFunctions';

export default class EditableGrid extends LightningElement {

    //@api hideUI = false;

    //Context variables
    @api recordId;
    @api recordTypeId;
    //@api lookupFieldName;
    @api objectMetadata;
    @api picklistMetadata;

    @api 
    get hostRecordApi(){
        return this.hostRecord;
    }
    set hostRecordApi(value){

        if (value){
            this.hostRecord = value;
            if (this.recalculateRecordListWhenHostRecordChanges && this.serverTripInProgress !== true){
                this.customLog('recalculating...');
                this.recalculateRecordsFromHostRecordChange();
            }
        }
    }
    hostRecord;
    
    @api configApi;
    config;

    //@api recordListBaselineFilter;

    @track serverTripInProgress = true;

    //Quantity rules
    /*@api minRowCount = 0;
    @api placeholderRowCount = 1;
    @api maxRowCount = 999;*/
    
    //@api tableBodyHeight;
    get tableBodyStyle(){
        return "display:block;height:"+this.config.tableBodyHeight+";overflow-y:auto !important;";
    }

    get createButtonDisabled(){
        return this.serverTripInProgress ||
        this.apexAutomationsInProgress ||
        (this.config.maxRowCount && 
            this.recordList.length >= this.config.maxRowCount);
    }

    get saveButtonDisabled() {
        return this.serverTripInProgress ||
        this.apexAutomationsInProgress ||
        (this.config.maxRowCount && 
            this.recordList.length > this.config.maxRowCount) ||
            this.preSaveValidationErrors.length > 0;
            ;
    }

    @api lookupDefaults;

    //Nested array that amalgamates column and row data - each row contains 'cells',
    //and each cell contains field information, and a reference to a specific record field
    @track gridData = [];

    //Record list - is kept in sync with gridData
    @track recordList = [];
    //Used when creating dummy records
    @api rowLimit;

    @track rowHeight; 

    //SOQL fields - change these as you want
    /*@api objectName;
    @api filters;*/
    @api sortBy;
    @api sortDirection;

    @track saveFailed;
    erroredRowIndexes = [];

    //@api columnsApi;
    @track columns = [];

    @track gridHasExpandibleColumns = false;
    columnExpansionLevel = 0;
    @api columnExpansionLevelsApi;
    columnExpansionLevels = [];
    @track minExpansionIndexReached = false;
    @track maxExpansionIndexReached = false;
    
    get maxRowsExceeded() {
        return this.config.maxRowCount && 
        this.recordList.length > this.config.maxRowCount;
    }
    get maxRowsExceededMessage() {
        return 'Maximum allowed rows is '+this.config.maxRowCount;
    }

    tableRerenderInterval;

    /*get showSimpleWarningsAndErrors(){
        return !this.preSaveValidationErrors.length && !this.popoverErrorMessage;
    }*/

    preSaveValidationErrors = [];
    simpleErrorMessage;
    simpleWarningMessage;
    standardMessage;
    allOrNoneServerError;

    get popoverErrorMessage(){
        return this.allOrNoneServerError;
    }

    @track showWarningRegardingHiddenColumns = false;

    loggingEnabled = true;
 
    @api recalculateRecordListWhenHostRecordChanges = false;
    recalculationInitiatedForRecordList = false;
    javascriptAutomationsInProgress = 0;
    apexAutomationsInProgress = 0;


    //Logic begins here
    connectedCallback(){
        
        this.customLog('connectedCallback');

        this.config = JSON.parse(JSON.stringify(this.configApi));

        //Set local variables that need to be different from config 
        //data passed in
        this.columns = this.config.columns;
        if (this.columnExpansionLevelsApi)
            this.columnExpansionLevels = JSON.parse(JSON.stringify(this.columnExpansionLevelsApi));

        this.assignColumnWidths();
        this.getRecordsFromServer();

    }


    getColumn(fieldName){

        for (var i=0; i<this.columns.length; i++){
            if (this.columns[i].fieldName === fieldName)
                return this.columns[i];
        }
    }

    assignColumnWidths(){

        for (var j=0; j<this.columns.length; j++){

            var widthInPx = 0;

            if (this.columns[j].width)
                widthInPx = this.columns[j].width;

            else {
                switch(this.columns[j].type){
                    case 'text': 
                        widthInPx = 200;
                        break;
                    case 'picklist':
                        break;
                    case 'textArea':
                        widthInPx = 200;
                        break;
                    case 'number':{
                        if (this.columns[j].formatter === 'currency')
                            widthInPx = 120;
                        else 
                            widthInPx = 100;

                        break;
                    }
                    case 'checkbox':
                        widthInPx = 60;
                        break;
                    case 'lookup':
                        widthInPx = 250;
                        break;
                    case 'jsFormula':
                        widthInPx = 60;
                        break;
                    default:
                        this.customLog('Unsupported field');
                        break;

                }
            }

            if (widthInPx){
                this.columns[j].widthStyle = 'min-width:'+widthInPx+'px; max-width:'+widthInPx+'px;';
                this.setColumnStyling(this.columns[j]);
            }

        }

    }


    setColumnStyling(column){

        column.style = '';
        if (column.visibilityStyle) {
            column.style += column.visibilityStyle;
        }
        if (column.widthStyle) {
            column.style += column.widthStyle;
        }
    }



    @api
    getRecordsFromServer(){

        this.customLog('getRecordsFromServer');

        this.serverTripInProgress = true;

        let fieldNames = this.getQueryableFieldNames();
        let params = this.constructQueryParamaterMap(fieldNames);
        
        this.customLog(params);

        //Use SOQL to get records
        getRecords(params).then(result => {

            //this.customLog('sanitisedResult');
            let sanitisedResult = JSON.parse(JSON.stringify(result));
            this.customLog(sanitisedResult);

            this.recordList = sanitisedResult;
            
            this.postServerQueryProcessing();

            this.serverTripInProgress = false;

        })
        .catch(error => {
            this.customLog('ERROR! '+JSON.stringify(error));
            this.customLog(error);

            this.serverTripInProgress = false;
        })
     
    }


    postServerQueryProcessing(){

        this.constructGrid();

        this.showOrHideButtonsForExpandingAndCollapsingColumns();

        this.expandColumns();

        if (this.recordList.length > 0){

            //this.customLog('Checking toggle after query');
            this.toggleShowHiddenColumnWarningMessage();

            this.applyPicklistDependenciesOnAll();

            for (var i=0; i<this.recordList.length; i++){
                this.runAutomations(i, 'load');
            }

            this.processPreSaveValidationRule(
                this.maxRowsExceeded,
                this.maxRowsExceededMessage);

        }
        else {
            this.showWarningRegardingHiddenColumns = false;
            this.simpleWarningMessage = '';

            while (this.recordList.length < this.config.placeholderRowCount){
                this.newRecordAndGridRow();
                this.runAutomations(this.recordList.length-1, 'placeholder');
            }
        }
        
        this.alignHeaderWidthsToColumnWidths();
        //this.serverTripInProgress = false;

    }

    addMoreRowsBasedOnMinimumRowCount(){

    }

    renderedCallback(){
        this.customLog('renderedCallback');
        this.alignHeaderWidthsToColumnWidths();
    }


    getQueryableFieldNames(){

        //this.customLog('getQueryableFieldNames');

        var fieldNames = [];
        
        fieldNames.push('Id');
        fieldNames.push(this.config.lookupFieldNameToHostRecord);
        if (this.config.recordTypeName != 'Master')
            fieldNames.push('recordTypeId');

        for (var i=0; i<this.columns.length; i++){
            
            let column = this.columns[i];

            fieldNames.push(column.fieldName);
            
            if (column.type === 'lookup'){

                fieldNames.push(column.lookupObjectRelationship + '.' + column.lookupTitleField);                
                if (column.lookupSubtitleField)
                    fieldNames.push(column.lookupObjectRelationship + '.' + column.lookupSubtitleField);

                //this.customLog(column.lookupAdditionalFieldsToQuery);

                if (column.lookupAdditionalFieldsToQuery){
                    for (var j=0; j<column.lookupAdditionalFieldsToQuery.length; j++){
                        fieldNames.push(column.lookupObjectRelationship + '.' + 
                            column.lookupAdditionalFieldsToQuery[j]);
                    }
                }

            }
            
        }
        this.customLog(fieldNames);
        return fieldNames;
    }

    constructQueryParamaterMap(fieldNames){

        let filterStrings = [];

        if (this.config.lookupFieldNameToHostRecord){
            filterStrings.push(
                '(' +
                this.config.lookupFieldNameToHostRecord + " = '" + 
                this.recordId + 
                '\')'
            );
        }
        if (this.config.recordTypeName != 'Master'){
            filterStrings.push(
                "(recordTypeId = '"+ this.recordTypeId+"')"
            );
        }
        if (this.config.recordListBaselineFilter){
            filterStrings.push(
                "(" + this.config.recordListBaselineFilter + ")"
            );
        }
        let filterString = filterStrings.join(' AND ');

        console.log('filterString '+filterString);

        return {fields: fieldNames, 
            objectName: this.config.objectName, 
            filters: filterString,
            sortBy: this.sortBy, 
            sortDirection: this.sortDirection,
            rowLimit: this.rowLimit
        };
    }


    constructGrid(){
        this.customLog('constructGrid');

        this.gridData = [];

        for (var recordIndex=0; recordIndex < this.recordList.length; recordIndex++){

            let record = this.recordList[recordIndex];
            let newGridRow = this.newGridRow(recordIndex, record);

            this.gridData.push(newGridRow);
        }
    }


    showOrHideButtonsForExpandingAndCollapsingColumns(){
        this.customLog('showOrHideButtonsForExpandingAndCollapsingColumns');
        this.gridHasExpandibleColumns = (this.columnExpansionLevels && this.columnExpansionLevels.length >= 2);
    }

    expandColumns(){
    
        this.customLog('Expand columns');
        this.customLog(this.columnExpansionLevels);
        
        if (this.columnExpansionLevels){

            let defaultInvalidExpansionLevel = 0;

            if (this.columnExpansionLevel === defaultInvalidExpansionLevel){

                let firstColumnExpansionLevel = this.columnExpansionLevels[0];
                this.columnExpansionLevel = firstColumnExpansionLevel;
            }
            else if (this.columnExpansionLevel > defaultInvalidExpansionLevel){

                let currentExpansionLevelIndex = this.columnExpansionLevels.indexOf(this.columnExpansionLevel);
                this.customLog('currentExpansionLevelIndex '+this.currentExpansionLevelIndex);
                
                let newExpansionLevelIndex = currentExpansionLevelIndex + 1;
                if (newExpansionLevelIndex < this.columnExpansionLevels.length){

                    this.columnExpansionLevel = this.columnExpansionLevels[newExpansionLevelIndex];
                    this.customLog('columnExpasionLevel is now '+this.columnExpansionLevel);

                }

            }

            this.checkMinOrMaxColumnExpansionReached();

            this.showOrHideCollapsibleColumns();
        }

    }


    collapseColumns(){

        //this.customLog('collapse columns');

        if (this.columnExpansionLevels){

            //if (this.columnExpansionLevel > minimumValidExpansionLevel){
                let currentIndex = this.columnExpansionLevels.indexOf(this.columnExpansionLevel);

                let newIndex = currentIndex - 1;
                this.columnExpansionLevel = this.columnExpansionLevels[newIndex];
            //}

            this.checkMinOrMaxColumnExpansionReached();

            this.showOrHideCollapsibleColumns();
        }

    }


    checkMinOrMaxColumnExpansionReached(){

        if (this.columnExpansionLevels.length >= 2){
            this.minExpansionIndexReached = this.columnExpansionLevel === this.columnExpansionLevels[0];
            this.maxExpansionIndexReached = this.columnExpansionLevel >= this.columnExpansionLevels[this.columnExpansionLevels.length - 1];
        }

        //this.customLog('this.minExpansionIndexReached '+this.minExpansionIndexReached);
        //this.customLog('this.maxExpansionIndexReached'+this.maxExpansionIndexReached);

    }


    toggleShowHiddenColumnWarningMessage(){

        this.customLog('toggleShowHiddenColumnWarningMessage');
        this.customLog(this.maxExpansionIndexReached);
        //this.customLog(this.maxExpansionIndexReached === false);

        this.showWarningRegardingHiddenColumns = (this.maxExpansionIndexReached === false);
    }

    showOrHideCollapsibleColumns(){

        this.customLog('showOrHidecollapsibleColumns');
        this.customLog(this.columnExpansionLevel);

        this.toggleShowHiddenColumnWarningMessage();

        for (var i=0; i<this.columns.length; i++){
            
            let column = this.columns[i];

            let fieldName = column.fieldName;
            this.customLog(fieldName);
            let columnExpansionLevel = column.columnExpansionLevel;
            this.customLog('level '+columnExpansionLevel);

            if (columnExpansionLevel){
                if (columnExpansionLevel <= this.columnExpansionLevel){
                    column.visible = true;
                    column.visibilityStyle = 'display:content;';
                }
                else {
                    column.visible = false;
                    column.visibilityStyle = 'display:none;';
                }
                this.customLog(column.visibilityStyle);

                this.setColumnStyling(column);
                
                for (var j=0; j<this.recordList.length; j++){
                    this.customLog('updating visibility for row '+j+fieldName);
                    this.writeFieldToCell(j, fieldName, 'style', column.style);
                }

            }

        }

    }


    newRecordAndGridRow(){
        
        let lookupFieldName = this.config.lookupFieldNameToHostRecord;
        let newRecord = {
            RecordTypeId : this.recordTypeId
        }
        newRecord[lookupFieldName] = this.recordId;

        let newRecordIndex = this.recordList.length;
        this.recordList[newRecordIndex] = newRecord;

        ////this.customLog(newRecord);

        if (!newRecord.id)
            this.applyRecordDefaults(newRecord, newRecordIndex);

        let newGridRow = this.newGridRow(newRecordIndex, newRecord);
        
        this.gridData.push(newGridRow);

        this.updateGlobalMessagesRegardingUnsavedChanges();

        this.runAutomations(this.recordList.length - 1, 'newRecord');

    }


    applyRecordDefaults(newRecord, recordIndex){

        //this.customLog('apply Record defaults');

        for (var i=0; i<this.columns.length; i++){

            let column = this.columns[i];
            //this.customLog(column.fieldName + ' ' + column.type);

            if (column.type !== 'lookup'){
                if (column.defaultValue !== undefined)
                    newRecord[column.fieldName] = column.defaultValue;
            }
            else {
                let lookupDefault = this.lookupDefaults[column.fieldName];

                if (lookupDefault){
                    //this.customLog('lookup default for '+column.fieldName+' is '+lookupDefault.id+':'+lookupDefault.lookupTitle);
                    
                    newRecord[column.fieldName] = lookupDefault.id;

                    this.updateRecordLookupParentFields(recordIndex, column.fieldName, lookupDefault.payload);

                }
                else {
                    //this.customLog('No lookup default found');
                }
            }
        }

        ////this.customLog(newRecord);

    }

    

    newGridRow(recordIndex, record, editInProgressBool){

        this.customLog('newGridRow');

        var newGridRow = this.newEmptyGridRow(editInProgressBool, recordIndex);

        for (var j=0; j<this.columns.length; j++){
            var newGridCell = this.newGridCell(recordIndex, record, this.columns[j]);
            newGridRow.cells.push(newGridCell);
        }

        return newGridRow;
    }

    newEmptyGridRow(editInProgressBool, recordIndex){

        this.customLog('newEmptyGridRow');
        this.customLog(this.config.canClone);
        this.customLog(this.config.canDelete);

        return {
            index: recordIndex,

            canClone : this.config.canClone,
            canDelete : this.config.canDelete,

            cells: [],
            editInProgress : editInProgressBool,

            showDeleteConfirmation : false,
            
            clientSideWarningMessages : null,

            isError: false,
            errorMessages: null,

            saveSuccesful: false
        };
    }

    getGridRow(index){
        return this.gridData[index];
    }


    //Amalgmate column information and record information to represent state in
    //a single grid cell
    newGridCell(recordIndex, record, column){

        var newGridCell = {
            //Basic fields
            'index' : recordIndex,
            'dataId' : recordIndex + '-' + column.fieldName,
            'value' : record[column.fieldName]
        }
        for (var key in column) {
            newGridCell[key] = column[key];
        }
        if (!this.config.canSave)
            newGridCell.canUpdate = false;

        //Lookup-related fields
        if (column.type === 'lookup'){
            
            var lookupHasValue = newGridCell.value;
            if (lookupHasValue){
                ////this.customLog('lookupObjectRelationship '+column.lookupObjectRelationship);
                ////this.customLog(JSON.parse(JSON.stringify(record)));
                
                if (record[column.lookupObjectRelationship]){
                    newGridCell.lookupTitle = record[column.lookupObjectRelationship][column.lookupTitleField];
                    newGridCell.lookupSubtitle = record[column.lookupObjectRelationship][column.lookupSubtitleField];

                    if (newGridCell.nonReparentable){
                        newGridCell.canUpdate = false;
                    }
                }

            }
   
        }
        
        return newGridCell;
    }



    getGridCell(gridRow, fieldName){
        ////this.customLog('getGridCell '+fieldName);
        return gridRow.cells.find(function(element) {
            return element.fieldName === fieldName;
          });
    }



    alignHeaderWidthsToColumnWidths(){

        this.customLog('alignHeaderWidthsToColumnWidths');
        let tableCellsInFirstRow = this.getTDElementsInHTMLTableRow(0);
        let allWidthsAreZero = true;

        if (tableCellsInFirstRow.length > 0){

            let tableHeaders = this.template.querySelectorAll('th');
            for (var i=0; i<tableHeaders.length; i++){

                ////this.customLog('th '+i);
                let tableHeader = tableHeaders[i];
                let matchingHTMLCell = tableCellsInFirstRow.find(
                    function(element) {
                        return element.dataset.name === tableHeader.dataset.name;
                    }
                );
                
                let columnWidth = matchingHTMLCell.offsetWidth - 1;
                ////this.customLog(columnWidth);
                tableHeader.style.width = columnWidth + 'px';

                if (columnWidth > 0){
                    allWidthsAreZero = false;
                }

            }

            let renderFailedDueToCachingOnPortal = allWidthsAreZero;
            if (renderFailedDueToCachingOnPortal){
                
                if (!this.tableRerenderInterval){
                    
                    let thisTemp = this;

                    this.tableRerenderInterval = window.setInterval(function(){
                        thisTemp.alignHeaderWidthsToColumnWidths();
                    }, 1000);
                }
            }
            else {
                if (this.tableRerenderInterval){
                    window.clearInterval(this.tableRerenderInterval);
                }
            }

        }

        this.customLog('end of alignHeaderWidthsToColumnWidths');

    }


    getTDElementsInHTMLTableRow(index){

        var output = [];
        
        let allElementsWithMatchingIndex = this.template.querySelectorAll('[data-index="'+index+'"]');
        if (allElementsWithMatchingIndex !== null){
            
            for (var i=0; i<allElementsWithMatchingIndex.length; i++){
                
                let element = allElementsWithMatchingIndex[i];                
                let nodeName = element.nodeName;

                if (nodeName.toLowerCase() === 'td')
                    output.push(element);

            }
        }

        return output;
    }
    

    getRecord(index){
        return this.recordList[index];
    }

    getRecordValue(index, fieldPath){
        ////this.customLog('getRecordValue '+index+fieldPath);

        let fieldIsOnParentObject = fieldPath.indexOf('.') !== -1;

        if (!fieldIsOnParentObject){
            ////this.customLog('returning '+this.recordList[index][fieldPath]);
            return this.recordList[index][fieldPath];
        }
        else {
            let fieldPathLevels = fieldPath.split('.');
            ////this.customLog('traversing...'+fieldPathLevels[0]+' '+fieldPathLevels[1]);

            let lookupRelationship = fieldPathLevels[0];
            let fieldNameOnParent =  fieldPathLevels[1];

            if (this.recordList[index][lookupRelationship] != null){
                return this.recordList[index][lookupRelationship][fieldNameOnParent];
            }
            else {
                return null;
            }
        }
    }

    applyPicklistDependencies(index){

        ////this.customLog('applyPicklistDependencies '+index);
        let picklistDependencies = this.objectMetadata.dependentFields;
        ////this.customLog(JSON.parse(JSON.stringify(picklistDependencies)));

        // eslint-disable-next-line guard-for-in
        for (var key in picklistDependencies){
            let controllingField = key;
            var dependentField;

            let dependentFieldJSON = picklistDependencies[controllingField];
            ////this.customLog(JSON.parse(JSON.stringify(dependentFieldJSON)));

            //Only designed to run once and get first KEY
            for (var key2 in dependentFieldJSON){
                dependentField = key2;
                break;
            }

            ////this.customLog(controllingField);
            ////this.customLog(dependentField);

            let controllingFieldValue = this.recordList[index][controllingField];
            let dependentFieldValue = this.recordList[index][dependentField];
            
            var dependentPicklistMetadata = JSON.parse(JSON.stringify(this.picklistMetadata[dependentField]))

            if (dependentPicklistMetadata.values.length > 0){
                ////this.customLog(dependentPicklistMetadata);

                let controllerValues = this.picklistMetadata[dependentField].controllerValues;
                let controllingValueIndex = controllerValues[controllingFieldValue];
                var currentDependentFieldValueIsValid = true;


                for (var i=0; i<dependentPicklistMetadata.values.length;){
                    let value = dependentPicklistMetadata.values[i];
                    ////this.customLog(value);

                    if (!value.validFor.includes(controllingValueIndex)){
                        ////this.customLog('Removing value: '+value.value);
                        if (value.value === dependentFieldValue){
                            ////this.customLog('Current field value is invalid - will remove');
                            currentDependentFieldValueIsValid = false;
                        }

                        dependentPicklistMetadata.values.splice(i, 1);
                    }
                    else {
                        i++;
                    }

                }

                let gridRow = this.getGridRow(index);
                let gridCell = this.getGridCell(gridRow, dependentField);

                gridCell.picklistValues = dependentPicklistMetadata.values;

                if (dependentPicklistMetadata.values.length !== 1){
                    if (!currentDependentFieldValueIsValid)
                        this.writeField(index, dependentField, 'value', null);
                }
                else {
                    this.writeField(index, dependentField, 'value', dependentPicklistMetadata.values[0].value);
                }

            }
        }

    }

    applyPicklistDependenciesOnAll(){

        this.customLog('applyPicklistDependenciesOnAll');
        for (var i=0; i<this.recordList.length; i++){
            this.applyPicklistDependencies(i);
        }

    }


    recalculateRecordsFromHostRecordChange(){

        this.customLog('recalculateRecordsFromHostRecordChange');
        
        this.recalculationInitiatedForRecordList = false;

        for (var i=0; i<this.recordList.length; i++){
            this.runAutomations(i, 'recalculate');
        }

        this.recalculationInitiatedForRecordList = true;
        this.customLog('All recalcs initiated');

        this.checkForEndOfRecalculation();

    }


    runAutomations(index, eventType, triggerField){

        this.customLog('runAutomations '+index+eventType+triggerField);

        for (var i=0; i<this.config.automations.length; i++){

            let automation = this.config.automations[i];

            if (!automation.name){
                alert('Automation '+i+' missing name');
            }

            if (automation.runOn.includes(eventType) &&
                (triggerField === undefined ||
                automation.triggerFields.includes(triggerField))
            ){

                this.customLog(JSON.parse(JSON.stringify(automation)));

                ////this.customLog('Run this event');
                ////this.customLog(automation.type);

                if (this.evaluateAutomationCriteria(automation, index) === true){

                    if (automation.type === 'javascript'){
                        this.runJavascriptAutomation(automation, index);
                    }
                    else if (automation.type === 'apex'){
                        this.runApexAutomation(automation, index);
                    }
                    else    
                        alert("unsupported automation type");

                }
                
            }

        }

    }

    runJavascriptAutomation(automation, index){

        this.javascriptAutomationsInProgress++;

        this.customLog('runJavascriptAutomation '+this.recordTypeId+automation.name+index);

        //this.customLog('JS '+this.config.automationsInProgress + 'automations in progress');

        if (automation.customFunction){
            
            console.log('custom function '+automation.customFunction);

            switch (automation.customFunction) {
                case 'validateAtLeastOneCode' : {
                    validateAtLeastOneCode(this, automation);
                    break;
                }
                case 'validatePercentageTotal' : {
                    validatePercentageTotal(this, automation);
                    break;
                }
                case 'autoSetPrimary' : {
                    autoSetPrimary(this, automation);
                    break;
                }
                case 'validateNoDuplicates' : {
                    validateNoDuplicates(this, automation);
                    break;
                }
                case 'validateOnlyOnePrimary' : {
                    validateOnlyOnePrimary(this, automation);
                    break;
                }
                case 'validatePrimaryIsHighestPercentage' : {
                    validatePrimaryIsHighestPercentage(this, automation);
                    break;
                }
                case 'removeEmptyRows' : {
                    removeEmptyRows(this, automation);
                    break;
                }
            }
        }
        else {
            for (var j=0; j<automation.assignments.length; j++){
                //this.customLog('assignment '+j);

                let assignment = automation.assignments[j];
                let attribute = assignment.attribute;
                
                let destination = assignment.destination;

                ////this.customLog('Destination '+destination);
                
                if (destination === 'gridCell'){
                    let gridRow = this.getGridRow(index);
                    for (var k=0; k<assignment.cellFieldNames.length; k++){

                        let cellFieldName = assignment.cellFieldNames[k];
                        ////this.customLog(cellFieldName);
                        let targetCell = this.getGridCell(gridRow, cellFieldName);
                        let newValue = assignment.value;

                        targetCell[attribute] = newValue;
                    }
                }

                if (destination === 'row'){

                    let targetCellFieldName = assignment.cellIdentifierInRow;
                    //this.customLog(targetCellFieldName);
                    ////this.customLog(assignment.valueType);

                    switch(assignment.valueType){
                        case 'static': {
                            let newValue = assignment.value;
                            this.writeField(index, targetCellFieldName, 'value', newValue);
                            break;
                        }
                        case 'copy': {
                            let source = this.getSourceEntityByName(assignment.source, index);
                            let newValue = source[assignment.copyFrom];
                            ////this.customLog(newValue);
                            this.writeField(index, targetCellFieldName, 'value', newValue);
                            break;
                        }
                        case 'sum': {
                            
                            let addends = assignment.addends;
                            let sumValue = sum(this, addends, index);
                            this.writeField(index, targetCellFieldName, 'value', sumValue);
                            break;
                        }
                        case 'multiply': {
                            let factors = assignment.factors;
                            let product = multiply(this, factors, index);
                            this.writeField(index, targetCellFieldName, 'value', product);
                            break;
                        }
                        default : {
                            alert("Unsupported automation assignment type");
                        }
                    }
                }

            }

            this.runDependentAutomations(index, automation);

        }

        this.javascriptAutomationsInProgress--;
        this.checkForEndOfRecalculation();


    }

    getSourceEntityByName(sourceName, dataRowIndex){
        ////this.customLog('getSourceEntityValue '+sourceName+dataRowIndex);

        if (sourceName === 'hostRecord')
            return this.hostRecord;
        else if (sourceName === 'row') 
            return this.recordList[dataRowIndex];

        return null;
    }

    getSourceEntityValueByName(sourceName, dataRowIndex, fieldName){
        ////this.customLog('getSourceEntityValueByName '+sourceName+dataRowIndex+fieldName);

        if (sourceName === 'hostRecord')
            return this.hostRecord.fields[fieldName].value;
        else if (sourceName === 'row') 
            return this.recordList[dataRowIndex][fieldName];

        return null;
    }

    runApexAutomation(automation, index){

        for (var i=0; i<this.recordList.length; i++){
            this.recordList[i].sobjectType = this.config.objectName;
        }

        var inputData;
        if (automation.inputData == 'oneRow')
            inputData = [this.recordList[index]];
        else if (automation.inputData == 'allRows')
            inputData = this.recordList;

        this.customLog(JSON.parse(JSON.stringify(inputData)));

        this.customLog('runApexAutomation '+automation.name+index);

        this.apexAutomationsInProgress++;
        //this.customLog(this.config.automationsInProgress + 'automations in progress');

        runAutomation({methodName: automation.methodName, records : inputData}).then(result => {
            
            //this.customLog('result');
            this.customLog(result);
            this.serverTripInProgress = true;
            

            for (var resultIndex=0; resultIndex<result.length; resultIndex++){

                this.customLog('resultIndex '+resultIndex);
                let resultRecord = result[resultIndex];
                
                var indexToWriteTo;
                if (automation.inputData == 'oneRow')
                    indexToWriteTo = index;
                else if (automation.inputData == 'allRows')
                    indexToWriteTo = resultIndex;

                console.log('resultRecord '+resultRecord);

                for (var fieldName in resultRecord){
                    let value = resultRecord[fieldName];
                    this.writeField(indexToWriteTo, fieldName, 'value', value);   
                }
                this.runDependentAutomations(indexToWriteTo, automation);

            }

            this.serverTripInProgress = false;

            this.apexAutomationsInProgress--;
            this.checkForEndOfRecalculation();

        }).catch(error => {
            this.customLog(error);
            //("Unhandled exception. Working on it.");

            this.serverTripInProgress = false;

            this.apexAutomationsInProgress--;
            this.checkForEndOfRecalculation();
            
        });

    }


    checkForEndOfRecalculation(){

        /*('checkForEndOfRecalculation');
        this.customLog('recalc initated '+this.recalculationInitiatedForRecordList);
        this.customLog('load already in progress '+this.serverTripInProgress);*/
        
        if (this.recalculateRecordListWhenHostRecordChanges && 
            this.recalculationInitiatedForRecordList === true &&
            this.serverTripInProgress !== true
            ){

            if (this.javascriptAutomationsInProgress == 0 && this.apexAutomationsInProgress == 0){

                this.customLog("No more automations for "+this.recordTypeId+" Saving now...");
                //this.customLog(this.recordList);
                this.save();
            }

        }

    }
    

    evaluateAutomationCriteria(automation, index){

        this.customLog('evaluateAutomationCriteria for '+automation.name);

        //Evaluate criteria
        for (var i=0; i<automation.criteria.length; i++){
            
            ////this.customLog(i);
            let criterion = automation.criteria[i];
            ////this.customLog(criterion.values);


            let fieldName = criterion.fieldName;

            var dataValue;

            if (criterion.source === 'config'){
                dataValue = this.config[fieldName];
            }
            else { 
                dataValue = this.getRecordValue(index, fieldName);
            }

            if (dataValue === undefined)
                dataValue = null;

            let dataValueInValueSet = criterion.values.includes(dataValue);
            var dataValueMeetsCriteria;

            this.customLog('field name is '+fieldName);
            this.customLog('value is '+dataValue);
            this.customLog('value is in set? '+dataValueInValueSet);

            if (criterion.operator === '=')
                dataValueMeetsCriteria = dataValueInValueSet;
            else if (criterion.operator === '!=')
                dataValueMeetsCriteria = !dataValueInValueSet;

            if (!dataValueMeetsCriteria){
                this.customLog('record does not meet criteria');
                return false;
            }

        }

        return true;

    }


    runDependentAutomations(index, automation){

        if (automation.dependentAutomations){
            ////this.customLog('Running Dependent Automations for '+automation.name);

            for (var j=0; j<automation.dependentAutomations.length; j++){
                ////this.customLog('dependent automation '+j);

                let fieldName = automation.dependentAutomations[j];
                ////this.customLog(fieldName);

                this.runAutomations(index, 'change', fieldName);
            }

            ////this.customLog('End of run dependent automations for '+automation.name);
        }

    }


    
    //If you ever need to quickly get a specific cell...
    getCell(index, fieldName){
        let dataId = index+'-'+fieldName;
        let cell = this.template.querySelector('[data-id="'+dataId+'"]');
        ////this.customLog(cell.value);
    }


    


    //Sort both record list and grid row structure (doesn't work on strings yet)
    handleSortDataEvent(event){

        ////this.customLog('sorting...');
        ////this.customLog(JSON.parse(JSON.stringify(event)));

        let sortBy = event.detail.sortBy;
        let sortDirection = event.detail.sortDirection;

        this.sortBy = sortBy;
        this.sortDirection = sortDirection;

        if (sortBy){

            this.gridData = [];

            this.recordList.sort(function(a, b){

                let recordAValue = a[sortBy];
                let recordBValue = b[sortBy];

                ////this.customLog(recordAValue);
               // //this.customLog(recordBValue);

                if (sortDirection === 'asc'){
                    if (recordAValue === undefined)
                        return 1;
                    return (recordAValue < recordBValue) ? 1 : -1;
                }
                else if (sortDirection === 'desc'){
                    if (recordBValue === undefined)
                        return 1;
                    return (recordAValue > recordBValue) ? 1 : -1;
                }
                else {
                    //this.customLog('No sort direction');
                }
            });

            ////this.customLog(this.recordList);

            this.constructGrid();

            this.applyPicklistDependenciesOnAll();

            for (var i=0; i<this.recordList.length; i++){
                this.runAutomations(i, 'load');
            }

        }
        else 
            alert("Sorting error occurred");
    }




    
    //Handle whenever a grid cell changes - write data to record and grid structure
    handleRecordFieldChange(event){

        //this.customLog('handleRecordFieldChange');
        var payload = JSON.parse(event.detail.data);
        ////this.customLog(payload);

        var index = payload.index;
        var fieldName = payload.fieldName;
        var type = payload.type;
        var value = payload.newValue;

        this.writeField(index, fieldName, 'value', value);

        if (type === 'picklist'){
            this.applyPicklistDependencies(index);
        }

        if (type === 'lookup'){
            this.updateRecordLookupParentFields(index, fieldName, payload);
            this.updateLookupFieldUIComponent(index, fieldName);            
        }

        //this.preSaveValidationErrors = [];

        this.runAutomations(index, 'change', fieldName);

        this.updateGlobalMessagesRegardingUnsavedChanges();

    }

    


    updateRecordLookupParentFields(index, cellFieldName, payload){

        //this.customLog('updateRecordLookupParentFields '+index+cellFieldName);
        //this.customLog(JSON.parse(JSON.stringify(payload)));

        let record = this.recordList[index];

        let lookupObjectRelationshipRef = this.getColumn(cellFieldName).lookupObjectRelationship;

        //this.customLog(lookupObjectRelationshipRef);
        record[lookupObjectRelationshipRef] = {}
        let currentLookupObjectData = record[lookupObjectRelationshipRef];


        if (payload.lookupData){

            let newLookupObjectData = payload.lookupData.record;
            //this.customLog(newLookupObjectData);

            for (var key in newLookupObjectData){
                //this.customLog(key);
                currentLookupObjectData[key] = newLookupObjectData[key];
            }

        }
        else 
        {
            record[lookupObjectRelationshipRef] = null;
        }

        ////this.customLog(JSON.parse(JSON.stringify(record)));

    }


    updateLookupFieldUIComponent(index, cellFieldName){

        //onsole.log('updateLookupFieldUIComponent '+cellFieldName+' '+index);
        let record = this.recordList[index];

        let gridRow = this.getGridRow(index);
        let gridCell = this.getGridCell(gridRow, cellFieldName);
        ////this.customLog(JSON.parse(JSON.stringify(gridCell)));

        let lookupObjectRelationship = gridCell.lookupObjectRelationship;
        let lookupTitleField = gridCell.lookupTitleField;

        ////this.customLog(lookupObjectRelationship);
        ////this.customLog(lookupTitleField);

        if (record[lookupObjectRelationship])
            gridCell.lookupTitle = record[lookupObjectRelationship][lookupTitleField];
        else 
            gridCell.lookupTitle = null;
    }


    //Write field change to storage
    writeField(index, cellFieldName, cellAttribute, value){

        this.customLog('writeField '+index+' '+cellFieldName+' '+value);
        //WRite field to record

        if (cellAttribute === 'value'){
            ////this.customLog('writing '+value+' to record');
            this.writeFieldToRecord(index, cellFieldName, value);
        }
    
        this.writeFieldToCell(index, cellFieldName, cellAttribute, value);
        
    }

    writeFieldToCell(index, cellFieldName, cellAttribute, value){

        this.customLog('writeFieldToCell '+index+cellFieldName+cellAttribute+value);
        let gridRow = this.getGridRow(index);
        let gridCell = this.getGridCell(gridRow, cellFieldName);
        if (gridCell && gridCell !== undefined)
            gridCell[cellAttribute] = value;

    }

    writeFieldToRecord(index, cellFieldName, value){

        this.customLog('writeFieldToRecord '+index+cellFieldName+value);
        this.recordList[index][cellFieldName] = value;

        this.customLog(this.recordList[index]);
        
    }


    updateGlobalMessagesRegardingUnsavedChanges(){
        this.standardMessage = '';
        this.simpleWarningMessage = 'Please Save before exiting this screen.';
        this.simpleErrorMessage = '';
    }

    
    save(){

        this.customLog('save()');

        this.serverTripInProgress = true;

        this.resetSaveStatusData();

        this.runAutomations(null, 'presave');

        for (var i=0; i<this.recordList.length; i++){
            this.recordList[i].sobjectType = this.config.objectName;
        }

        let params = {
            records: this.recordList,
            allOrNothing: this.config.allOrNothingUpserts
        };
        this.customLog(JSON.parse(JSON.stringify(params)));

        upsertRecords(params).then(result => {

            let resultJSON = JSON.parse(result);
            this.customLog(resultJSON);
            
            var errorCount = 0;
            var successCount = 0;

            for (var i=0; i<resultJSON.length; i++){

                let gridRow = this.getGridRow(i);
                let saveSuccessful = resultJSON[i].success;

                if (saveSuccessful === true){
                    
                    successCount++;

                    if (!gridRow.clientSideWarningMessages)
                        gridRow.saveSuccesful = true;
                    else 
                        gridRow.clientSideWarningMessages = 
                        'Row saved with warning(s): ' + gridRow.clientSideWarningMessages;

                    this.reevaluateCellsAfterSave(i);

                    this.recordList[i].Id = resultJSON[i].id;
                }
                else{
                    errorCount++;
                    
                    let errors = resultJSON[i].errors;
                    this.addServerErrorMessagesToRow(gridRow, errors);
                }

            }

            this.standardMessage = successCount + ' rows saved.';

            if (errorCount > 0)
                this.simpleErrorMessage = errorCount + ' rows failed to save.';
            
            this.dispatchEvent(new CustomEvent('successfulsave'));
            
            this.serverTripInProgress = false;
            
        }).catch(error => {

            this.customLog(JSON.stringify(error));

            this.allOrNoneServerError = error.body.pageErrors[0].message;
            
            this.serverTripInProgress = false;
        });

    }

    reevaluateCellsAfterSave(dataRowIndex){
        console.log('reevaluateCellsAfterSave' + dataRowIndex);
        this.lockNonReparentableLookups(dataRowIndex);
    }

    lockNonReparentableLookups(dataRowIndex){

        console.log('lockNonReparentableLookups' + dataRowIndex);
        
        let gridRow = this.getGridRow(dataRowIndex);

        for (var i=0; i<this.columns.length; i++){
            let column = this.columns[i];
            
            let isNonReparentableLookup = column.type == 'lookup' && column.nonReparentable == true;
            if (isNonReparentableLookup){
                console.log(JSON.stringify(column));

                let cellToLock = this.getGridCell(gridRow, column.fieldName);
                cellToLock.canUpdate = false;
            }
        }
    }

    addServerErrorMessagesToRow(gridRow, errors){

        gridRow.isError = true;
        var errorMessages = [];

        for (var j=0; j<errors.length; j++){
            this.customLog(errors[j]);
            this.customLog(errors[j].message)
            errorMessages.push(errors[j].message);
        }
        gridRow.errorMessages = errorMessages.join('... ');
    }


    resetSaveStatusData(){

        this.allOrNoneServerError = '';

        this.standardMessage = '';
        this.simpleWarningMessage = '';
        this.simpleErrorMessage = '';

        for (var i=0; i<this.gridData.length; i++){
            let gridRow = this.gridData[i];

            gridRow.clientSideWarningMessages = '';

            gridRow.isError = false;
            gridRow.errorMessages = '';

            gridRow.saveSuccesful = false;
        }
        
    }


    toggleDeletePromptOnRecord(event){

        //this.customLog(JSON.parse(JSON.stringify(event)));
        let index = event.detail.index;
        let togglePreference = event.detail.togglePreference;

        let gridRow = this.getGridRow(index);
        gridRow.showDeleteConfirmation = togglePreference;

    }

    deleteRecord(event){

        let index = event.detail.index;
        let record = this.recordList[index];

        let existsInDatabase = record.Id;
        if (existsInDatabase){
            this.deleteRecordFromServer(index);
        }
        else 
        {
            this.removeRecordFromList(index);
        }

    }

    deleteRecordFromServer(dataRowIndex){

        this.customLog('deleteRecordFromServer '+dataRowIndex);

        let deleteFunction;
        let params;

        let gridRow = this.getGridRow(dataRowIndex);

        this.customLog('softDeleteField '+this.config.softDeleteField);
        this.customLog('softDeleteValue '+this.config.softDeleteValue);

        if (!this.config.softDeleteField && !this.config.softDeleteValue){
            deleteFunction = deleteRecord;
            params = {records : [this.recordList[dataRowIndex]]};
        }
        else {
            deleteFunction = upsertRecords;
            
            let recordToDelete = this.recordList[dataRowIndex];
            let deleteParameter = {}
            deleteParameter.Id = recordToDelete.Id;
            deleteParameter[this.config.softDeleteField] = this.config.softDeleteValue;
            
            params = {
                records : [deleteParameter],
                allOrNothing : true
            };
        }

        this.serverTripInProgress = true;

        deleteFunction(params).then(result => {

            let parsedResult = JSON.parse(result);
            if (parsedResult[0].success === true){
                this.removeRecordFromList(dataRowIndex);

                this.dispatchEvent(new CustomEvent('successfulsave'));

            }
            else {

                let errors = parsedResult[0].errors;
                //this.customLog(JSON.stringify(errors));
                
                this.addServerErrorMessagesToRow(gridRow, errors);

                this.updateGlobalMessageAfterDeleteFailed();

            }
            this.serverTripInProgress = false;


        }).catch(error => {

            this.customLog(JSON.stringify(error));

            let errors = error.body.pageErrors;
            this.addServerErrorMessagesToRow(gridRow, errors);

            gridRow.showDeleteConfirmation = false;

            this.serverTripInProgress = false;
        });

    }

    removeRecordFromList(index){

        //this.customLog('removeRecordFromList '+index);

        //this.customLog(this.recordList);

        this.recordList.splice(index, 1);
        this.gridData.splice(index, 1);

        this.updateGlobalMessagesAfterDeleteSuccessful();

        for (var i=0; i<this.recordList.length; i++){
            this.runAutomations(i, 'delete');
        }

        this.processPreSaveValidationRule(
            this.maxRowsExceeded,
            this.maxRowsExceededMessage);

    }

    updateGlobalMessagesAfterDeleteSuccessful(){

        this.standardMessage = 'Row deleted.';
        //this.simpleWarningMessage = 'Row deleted.';
        this.simpleErrorMessage = '';

    }

    updateGlobalMessageAfterDeleteFailed(){

        this.standardMessage = '';
        //this.simpleWarningMessage = 'Row deleted.';
        this.simpleErrorMessage = 'Row delete failed.';

    }


    cloneRecord(event){

        let index = event.detail.index;
        let clonedRecord = JSON.parse(JSON.stringify(this.recordList[index]));
        clonedRecord.Id = null;
        //this.customLog(clonedRecord);

        this.recordList.splice(index, 0, clonedRecord);
        //this.customLog(this.recordList);

        let newGridRow = this.newGridRow(index, clonedRecord);
        this.gridData.splice(index, 0, newGridRow);

        this.applyPicklistDependencies(index);

        this.runAutomations(index, 'newRecord');

    }

    processPreSaveValidationRule(isError, simpleErrorMessage){

        this.customLog('processPreSaveValidationRule '+simpleErrorMessage+' '+isError);

        let existingErrorMessageIndex = 
            this.preSaveValidationErrors.indexOf(simpleErrorMessage);
        this.customLog('existingErrorMessageIndex '+existingErrorMessageIndex);

        if (isError === true){
            if (existingErrorMessageIndex == -1){
                this.customLog('Pushing '+simpleErrorMessage);
                this.preSaveValidationErrors.push(simpleErrorMessage);
            }
        }
        else {
            if (existingErrorMessageIndex != -1){
                this.customLog('Removing '+simpleErrorMessage);
                this.preSaveValidationErrors.splice(existingErrorMessageIndex, 1);
            }
        }

    }

    customLog(content){
        if (this.loggingEnabled){
            console.log(content);
        }
    }

}