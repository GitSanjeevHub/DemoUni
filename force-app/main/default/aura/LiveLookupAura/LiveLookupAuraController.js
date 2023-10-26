({
    
    doInit : function(component, event, helper){
      
        console.log('doInit');
        helper.setColumns(component);
        
    },
    
    handleRecordDataLoad : function(component, event, helper){
        
        helper.populateNameSearchField(component);
        
		helper.calloutToFinanceSystem(component);    
	},
    
    handleSearchInputOverride : function(component, event, helper){
        component.find("searchButton").set("v.disabled", false);
    },
    
    handleSearchClick : function(component, event, helper){
        console.log('handleSearchClick');
        component.find("searchButton").set("v.disabled", true);
        helper.calloutToFinanceSystem(component);
    },
    
    handleSuccessfulSave : function(component, event, helper){
        
        console.log('handleSuccessfulSave');
        
        helper.showToast(component);
        
        console.log('success handled');
        
        $A.get("e.force:closeQuickAction").fire();
    },
    
	handleRowAction : function(component, event, helper) {
		console.log('handleRowAction');
	    var row = event.getParam('row');
    
        console.log(JSON.parse(JSON.stringify(row)));
        
        if (row.CustomerName.length > 0)
        	component.find("legalName").set("v.value", row.CustomerName);
        
        if (row.Key.CustomerID.length > 0)
            component.find("sapCustomerNumber").set("v.value", row.CustomerID);
            
        if (row.CustomerReference.length > 0)
	        component.find("abn").set("v.value", row.CustomerReference);
    
        
        console.log('submitting...');
        
        console.log(component.find("editForm"));
        component.find("editForm").submit();
        
        console.log('submitted');
	},

    
    calloutToFinanceSystem : function(component){

        
	}
})