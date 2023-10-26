({
    onInit: function(component, event, helper) {
        if (component.get("v.buildWhen")) {
            component.clearReference("v.buildWhen");

            const callback = component.get("v.onBuild");
            if (callback) {
                $A.enqueueAction(callback);
            }
        }
    },

    checkBuild: function(component, event, helper) {
        if (component.get("v.buildWhen")) {
            component.build();
        }
    },

    build: function(component, event, helper) {
        let baseComponent = component;
        while (!baseComponent.getType().endsWith(":DelayedConstruction")) {
            baseComponent = baseComponent.getSuper();
        }

        const ifWrapper = baseComponent.find("renderWrapper");
        // don't attempt to build more than once.
        if (ifWrapper.get("v.isTrue")) return;

        baseComponent.clearReference("v.buildWhen");
        ifWrapper.set("v.isTrue", true);

        const callback = baseComponent.get("v.onBuild");
        if (callback) {
            $A.enqueueAction(callback);
        }
    }
})