({
	doInit : function(component, event, helper) {
        component.set("v.calloutState", "SUCCESS"); 
        helper.setColumns(component);
        //helper.loadSampleData(component);
	},
    
	handleSearchClick : function(component, event, helper) {
		helper.performCallout(component, event, helper);
	},
    
	handleSearchInputOverride : function(component, event, helper) {
        let lName = component.find("LastName").get("v.value"); 
        console.log("LName: " + lName);
        let sId = component.find("StudentId").get("v.value"); 
        console.log("sId: " + sId);
        
        let test1 = (lName == null);
        let test2 = (lName == "");
        let test3 = (sId == null);
        let test4 = (sId == "");
        let noValueFound = ((test1 || test2) && (test3 || test4));
        
        console.log("(lName == null): " + test1);
        console.log("(lName == ''): " + test2);
        console.log("(sId == null): " + test3);
        console.log("(sId == ''): " + test4);
        
        console.log("noValueFound: " + noValueFound);
        component.find("searchButton").set("v.disabled", noValueFound);
	},
    
    handleRowAction : function(component, event, helper){
        console.log('handleRowAction');
	    var row = event.getParam('row');
        console.log(JSON.stringify(row));
        helper.writeSelectedRowFieldsToOutputData(component, row);
    }
})