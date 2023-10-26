({    
    invoke : function(component, event, helper) {
        var redirectURL = component.get("v.redirectURL");
        window.open(redirectURL, "_self");
    }
})