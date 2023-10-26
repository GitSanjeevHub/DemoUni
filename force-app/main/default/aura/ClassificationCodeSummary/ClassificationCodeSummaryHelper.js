({
	getServerData : function(component) {
		let action = component.get("c.getSummaryData");
        
        action.setParams({ 
            parentId : component.get("v.recordId"),
            pageConfigName : component.get("v.parentObject")
        });
        
        component.set("v.isLoading", true);

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let returnData = response.getReturnValue();

                if (returnData){
                    let currentURL = window.location.href;
                    console.log(currentURL);
                    console.log(encodeURIComponent(currentURL));
                    for (let i=0; i<returnData.length;i++){
                        returnData[i].separateTabURL += '&c__retURL='+encodeURIComponent(currentURL);
                    }
                    console.log(returnData);
                    component.set("v.data", returnData);
                    component.set("v.isVisible", true);
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
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
            
            component.set("v.isLoading", false);
            
        });

        $A.enqueueAction(action);

    }
	
})