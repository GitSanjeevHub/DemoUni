/**
 * Created by burnside on 2019-05-15.
 */
({
    doInit : function(component, event, helper){

        var flow = component.find("flow");
        flow.startFlow(
            component.get("v.flowName"),
            component.get("v.inputVariables")
        );

    }
})