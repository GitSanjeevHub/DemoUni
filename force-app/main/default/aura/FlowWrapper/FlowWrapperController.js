({
	doInit : function(component, event, helper) {
		
        let flowRunner = component.find("flow");
        let flowName = component.get("v.flowName")
        let flowParams = component.get("v.flowParams");
        
       	flowRunner.startFlow(flowName, flowParams);
        
	}
})