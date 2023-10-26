({
    toggleSort: function(component) {
        if (component.get("v.sortable")) {
            const sortOrder = component.get("v.sortOrder") === "ASC" ? "DESC" : "ASC";
            component.set("v.sortOrder", sortOrder);

            component.getEvent("sortChanged").fire({
                column: component,
                compareFunction: component.get("v.compareFunction"),
                sortOrder: sortOrder
            });
        }
    },

    getCompareFunction: function(field) {
        const fieldList = (field && field.split(".")) || [];
        return (a, b) => this.compare(this.getVal(a, fieldList), this.getVal(b, fieldList));
    },

    getVal: function(value, fieldList) {
        for (const field of fieldList) {
            value = value && value[field];
        }
        return value;
    },

    compare: function(a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;

        if (a.localeCompare) {
            return a.localeCompare(b);
        } else {
            if (a < b) return -1;
            if (a > b) return 1;
            return 0;
        }
    }
})