/**
 * Created by burnside on 2019-05-15.
 */
({

    getDataList : function(component, event, helper){

        var action = component.get("c.getSearchResults");

        var configName = component.get("v.configName");
        
        var SOSL_keywordsToSearch = component.get("v.keywordsToSearch");
        var SOSL_keywordsToExclude = component.get("v.keywordsToExclude");

        var SOQL_limit = component.get("v.rowsPerPage");
        var SOQL_offset = component.get("v.currentPageIndex") * component.get("v.rowsPerPage");
        var SOQL_filters = component.get("v.filters");
        var SOQL_filterLogic = component.get("v.filterLogic");
        
        var SOQL_orderDirection = component.get("v.orderDirection");

        var orderByInComponent = component.get("v.orderBy");
        var SOQL_orderBy = (orderByInComponent !== "relativeURL" ? orderByInComponent : "Name");

        //console.log(component.get("v.hasMatchScoreColumn"));
        //console.log(SOQL_filters.length);
        //var SOQL_matchScoring = ((
          //  component.get("v.hasMatchScoreColumn") && SOQL_filters.length > 0) ? true : false);

        action.setParams({
            'configName' : configName,
            'keywordsToSearch_String' : SOSL_keywordsToSearch,
            'keywordsToExclude_String' : SOSL_keywordsToExclude,
            'rowLimit' : SOQL_limit,
            'offset' : SOQL_offset,
            'filters' : SOQL_filters,
            'filterLogic' : SOQL_filterLogic,
            'orderBy' : SOQL_orderBy,
            'orderDirection' : SOQL_orderDirection,
        });

        //console.log(JSON.stringify(action.getParams()));

        component.set("v.isLoading", true);

        action.setCallback(this, function(response) {

            var state = response.getState();

            ////console.log(state);
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
                this.postQueryRecordLogic(data);
                
                console.log(data.records);
                console.log(data.totalRowCount);
                console.log(data.endOfList);

                component.set("v.data", data.records);
                component.set("v.offset", data.offset);
                component.set("v.totalRowCount", data.totalRowCount);
                component.set("v.endOfList", data.endOfList);

            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }

                 this.showSearchError(component);
            }

            component.set("v.isLoading", false);
            ////console.log('End of getDataList');

        });

        $A.enqueueAction(action);
    },

    
    postQueryRecordLogic : function(data){
        
        for (var i=0; i<data.records.length; i++){

            let record = data.records[i];

            //Current - breaks in production
            record.relativeURL = data.clickthroughBaseURL + '/' + record.Id;
            
        }
        
    },
    
    
    showSearchError : function(component, event, helper){

        component.find('notifLib').showToast({
            "variant": "error",
            "header": "Something has gone wrong!",
            "message": "An error has occurred. Please check your filters or contact your administrator"
        });

    },

    goToFullOpportunityRecord : function(component, event, helper, row){

        ////console.log('helper.goToFullRecord');

        var url= row.I_RS_Record_URL__c;
        window.open(url,'_blank');

    },

    expressInterest : function(component, event, helper, row){

        ////console.log('helper.expressInterest');

        var researchOpportunityId = row.Id;
        var flowComponentVariables =
        {
            flowName : 'Express_Interest',
            inputVariables : [{
                name : 'recordId',
                type : 'String',
                value : row.Id
            }]
        };

        this.openFlowInModal(component, "Start Proposal", flowComponentVariables);
    },

    recommend : function(component, event, helper, row){

       ////console.log('helper.recommend');

       var researchOpportunityId = row.Id;
       var flowComponentVariables =
       {
           flowName : 'Recommend_a_RO',
           inputVariables : [{
               name : 'recordId',
               type : 'String',
               value : row.Id
           }]
       };

       this.openFlowInModal(component, "Recommend Opportunity", flowComponentVariables);

    },

    openFlowInModal : function(component, header, flowComponentVariables){

        ////console.log('helper.openFlowInModal');

        var modalBody;

        $A.createComponent("c:FlowContainer", flowComponentVariables,
        function(content, status, errorMessage) {

           ////console.log(status);

           if (status === "SUCCESS") {
               modalBody = content;
               component.find('overlayLib').showCustomModal({
                   header: header,
                   body: modalBody,
                   showCloseButton: true
               })
           }
           else
            console.log('Error: '+errorMessage);
        });

    },


    getColumns : function(component, event, helper){

        var isPhone = $A.get("$Browser.isPhone");
        if (!isPhone){

            var action = component.get("c.getColumns_DatatableMetadata");
            action.setParam("configName", component.get("v.configName"));
            action.setCallback(this, function(response) {

                var state = response.getState();

                ////console.log(state);
                if (state === "SUCCESS") {
                    var columns = response.getReturnValue();
                    console.log(columns);

                    this.postQueryColumnLogic(component, columns);
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                     errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }


                }

                ////console.log('End of getColumns');
            });

            $A.enqueueAction(action);

        }
        else {
            var columns = [{label: 'Title', fieldName: 'Name'}];
            this.postQueryColumnLogic(component, columns);
        }

    },


    postQueryColumnLogic : function(component, columns){

        try {
        
            this.addActionButtons(component, columns);
    
            this.makeNameColumnClickable(columns);
            
            component.set("v.columns", columns);
            
        }
        catch (e){
            console.log(e.message);
        }
    },


    

    
    makeNameColumnClickable : function(columns){
      
        for (var i=0; i<columns.length; i++){
            let column = columns[i];
            if (column.fieldName == 'Name'){
                
                column.type = 'url';
                column.fieldName = 'relativeURL';
                column.target = "_self";
                column.typeAttributes = {
                    label : {
                    	fieldName: 'Name'
                    }
                }
            }
        }
        
    },

    addActionButtons : function(component, columns){

        columns.push({
            type: 'action', typeAttributes: {
                rowActions: [
                    { label: 'Show details', name: 'show_details' },
                    { label: 'Start Proposal', name: 'express_interest' },
                    { label: 'Recommend', name: 'recommend' }
                ]
            }
        });

    },

    //setUrlTableElements : function(component, columns){
      //  columns.push({label:'Organisation', fieldName:'I_RS_Organisation__r_Name'});

    //}

})