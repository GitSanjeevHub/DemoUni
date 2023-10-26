({
	invoke : function(component, event, helper) {
        let url = component.get("v.url");
        location.assign(url);
	}
})