/**
 * Created by burnside on 2019-05-29.
 */
({

    validateFilters : function(component, event, helper){

        //console.log('validateFilters');

        var filtersValid = true;
        
        var keywordsToSearch = component.get("v.keywordsToSearch");
		var keywordsToExclude = component.get("v.keywordsToExclude");
        
        if (!keywordsToSearch){
            filtersValid = false;
            alert('Please specify keywords to search'); 
        }
    
    	else if(keywordsToSearch.trim().length < 2 ||
          (keywordsToExclude && keywordsToExclude.trim().length < 2)){
        	filtersValid = false;
            alert('keyword search must be at least 2 characters');
        }
        
        else {
            var filters = component.get("v.filters");
            for (var index in filters){
                var filter = filters[index];
    
                if (!filter.value || !filter.operator){
                    filtersValid = false;
                
                    alert("Please specify or remove field filters");
                    break;
                }

                console.log(filter.filterSelection);
                console.log(filter.value);
                var today = new Date();

                var todaysYearString = today.getFullYear();
                var todaysMonthString = '0' + (today.getMonth() + 1);
                var todaysDayString = '0' + today.getDate();

                var todaysDateString = todaysYearString + '-' + todaysMonthString + '-' + todaysDayString;
                /*console.log(todaysYearString + '-' + todaysMonthString + '-' + todaysDayString);

                var todaysDateString = 
                    todaysYearString + '-'+
                    todaysMonthString.slice(todaysMonthString.length - 3, todaysMonthString.length -1);
                    + '-'+
                    todaysDayString.slice(todaysDayString.length - 3, todaysDayString.length -1);*/
                console.log(todaysDateString);

                if (filter.filterSelection == "submissionDate" && 
                    filter.value < todaysDateString
                ){
                    filtersValid = false;

                    alert("Submission date filter must be today or in the future");
                    break;

                }
            }
        }

        return filtersValid;

    },


    setFilterLogic : function(component){

        //console.log('setFilterLogic');

        var useFilterLogic = component.get("v.useFilterLogic");
        if (!useFilterLogic) {

            var filters = component.get("v.filters");
            var numberOfFilters = filters.length;

            var filterNumberArray = [];
            for (var index=0; index<filters.length; index++){
                filterNumberArray.push(index + 1);
            }

            var filterLogic = filterNumberArray.join(' AND ');
            component.set("v.filterLogic", filterLogic);
        }

    },


    search : function(component, event, helper){

        //console.log('search');

        if (!this.validateFilters(component))
            return;

        this.setFilterLogic(component);

        var appEvent = $A.get("e.c:ResearchOpportunitySearch_SearchRequest");
        appEvent.setParams(
            {
                "keywordsToSearch":component.get("v.keywordsToSearch"),
                "keywordsToExclude":component.get("v.keywordsToExclude"),
                "filters" : component.get("v.filters"),
                "filterLogic" : component.get("v.filterLogic")
            }
        );
        //console.log(JSON.stringify(appEvent.getParams()));
        appEvent.fire();

    },




    saveSearch : function(component, event, helper){

        //console.log('saveUserSearch');

        if (!this.validateFilters(component))
            return;

        this.setFilterLogic(component);

        var action = component.get("c.saveUserSearch");

        var params = {
            'keywordsToSearch' : component.get('v.keywordsToSearch'),
            'keywordsToExclude' : component.get('v.keywordsToExclude'),
            'filters' : component.get("v.filters"),
            'useFilterLogic' : component.get("v.useFilterLogic"),
            'filterLogic' : component.get("v.filterLogic")
        }

        action.setParam('data', params);
            
        //console.log(JSON.stringify(action.getParams()));

        action.setCallback(this, function(response) {

            var state = response.getState();
            //console.log(state);

            if (state === "SUCCESS") {
                this.showToast(component, 'info', 'Search has been saved');

                component.find("overlayLib").notifyClose();
            }
            else if (state === "ERROR") {

                this.showToast(component, 'error', 'Save unsuccessful. Please notify your admin');

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

            ////console.log('End of getDataList');

        });

        $A.enqueueAction(action);
    },


    addFilter : function(component, event, helper){

        //console.log('addFilter');

        var filters = component.get("v.filters");
        var numberOfFilters = filters.length;

        var newFilterIndex = numberOfFilters + 1;
        var newFilterLogic = component.get("v.filterLogic");
        if (numberOfFilters > 0)
            newFilterLogic += ' AND '
        newFilterLogic += newFilterIndex;
        component.set("v.filterLogic", newFilterLogic);

        var newFilter = {
            filterType:'',
            index:numberOfFilters
        }
        filters.push(newFilter);
        component.set("v.filters", filters);

    },

    deleteFilter : function(component, event, helper){

        //console.log('deleteFilter');

        var filters = component.get("v.filters");

        if (filters.length > 1){

            //Remove filter
            var indexToRemove = event.getParam("index");
            filters.splice(indexToRemove, 1);

            //Update indexes on filter entries
            for (var loopIndex=0; loopIndex < filters.length; loopIndex++){
                filters[loopIndex].index = loopIndex;
            }
            component.set("v.filters", filters);

            //Set filter logic
            var filterLogicString = component.get("v.filterLogic");
            ////console.log(filterLogicString);

            var filterLogicEntryToRemove = indexToRemove+1;
            filterLogicString = filterLogicString.replace(filterLogicEntryToRemove, '');

            component.set("v.filterLogic", filterLogicString);

        }
        else {
            component.set("v.filters", []);
            component.set("v.filterLogic", "");
        }

    },

    clearAllSearchData : function(component, event, helper){

        component.set("v.filters", []);
        component.set("v.useFilterLogic", false);
        component.set("v.filterLogic", "");

    },

    showToast : function(component, variant, message){

        //console.log('showToast');
        component.find('notifLib').showToast({
            "variant": variant,
            "message": message
        });

    }

})