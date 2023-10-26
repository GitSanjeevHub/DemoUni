({
	
    handleRecordLoad : function(component, event, helper){
        component.set("v.searchTerm", component.get("v.record.I_RS_Primary_Funder_Name__c"));
        component.set("v.defaultSearchTerm", component.get("v.record.I_RS_Primary_Funder_Name__c"));
        helper.runSearch(component, event, helper);
    },
    
    handleViewRowRecordClick : function(component, event, helper){

        let rowId = event.target.id;        
        let url = '/'+rowId;
        window.open(url,'_blank');
    },
    
    handleRowRecordSyncClick : function(component, event, helper) {
        let rowRecordId = event.target.id;        
        
        helper.runSyncWizard(component, rowRecordId);
	},
    
    handleNewRecordSyncClick : function(component, event, helper){
        
      	helper.runSyncWizard(component, null);  
    },
    
    handleSearchButtonClick : function(component, event, helper){
        helper.runSearch(component, event, helper);
    },
    
    handleResetSearchButtonClick : function(component, event, helper){
    	component.set("v.searchTerm", component.get("v.defaultSearchTerm"));
        helper.runSearch(component, event, helper);
	}
})