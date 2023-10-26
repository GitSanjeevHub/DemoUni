({
    onInit: function(component) {
        // An Internal server error is thrown if I directly bind the iteration. I have no idea why.
        const iteration = component.find("columnIteration");
        iteration && iteration.set("v.items", component.getReference("v.cells"));
    }
})