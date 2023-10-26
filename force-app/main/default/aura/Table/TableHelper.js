({
    /*
        Initialization & Reconstruction
    */
    linkColumns: function(component) {
        // Populates the definitions for cells and footers.
        const columns = component.get("v.body");
        const cellDefinitions = this.buildColumns(component, columns);

        component.set("v.cells", cellDefinitions.cells);

        if (cellDefinitions.footers.some((definition) => !$A.util.isEmpty(definition))) {
            component.set("v.columnFooters", cellDefinitions.footers);
        } else {
            component.set("v.columnFooters", []);
        }
    },

    buildColumns: function(component, columns) {
        // Dives into the column hierarchy to find and return columns and footers from the TableColumn components.
        let cellDefinitions = [];
        let footers = [];

        for (const column of columns) {
            if (!column.isInstanceOf) {
                throw new Error("Table bodies can only consist of columns.");
            } else if (column.isInstanceOf("c:TableColumnBase")) {
                cellDefinitions.push({
                    body: column.get("v.body"),
                    class: column.get("v.cellClass")
                });
                footers.push(column.get("v.footer"));

                const sortable = column.get("v.sortable");
                const sortOrder = column.get("v.sortOrder");
                const compareFunction = column.get("v.compareFunction");

                // Default sort requires a default sort order.
                if (sortable && sortOrder) {
                    component.set("v.sortColumn", column);
                    component.set("v.compareFunction", compareFunction);
                    component.set("v.sortOrder", sortOrder);
                }
            } else if (column.isInstanceOf("aura:iteration") || column.isInstanceOf("aura:if")) {
                const innerDefinitions = this.buildColumns(component, column.get("v.body"));
                cellDefinitions = cellDefinitions.concat(innerDefinitions.cells);
                footers = footers.concat(innerDefinitions.footers);
            } else {
                throw new Error("Table bodies can only consist of columns.");
            }
        }

        return {
            cells: cellDefinitions,
            footers: footers
        };
    },

    rebuildRows: function(component) {
        const items = component.get("v.items") || [];

        this.buildRows(component, 0, items.length, newRows => {
            this.sortRows(component, newRows);
            component.set("v.rows", newRows);
        });
    },

    appendRows: function(component, newItems) {
        const items = component.get("v.items") || [];
        // TODO: Find a better way to prevent the item change event from firing
        component.set("v.suspendRowRebuild", true);
        component.set("v.items", items.concat(newItems));
        component.set("v.suspendRowRebuild", false);

        this.buildRows(component, items.length, newItems.length, newRows => {
            const rows = component.get("v.rows") || [];
            const allRows = rows.concat(newRows);

            this.sortRows(component, allRows);
            component.set("v.rows", allRows);
        });
    },

    buildRows: function(component, offset, count, callback) {
        const varName = component.get("v.var");
        const cells = component.getReference("v.cells");
        const cellClass = component.getReference("v.cellClass");
        const rowTemplate = component.getReference("v.rowTemplate");
        const filterFunction = component.get("v.filterFunction");

        const rowDefs = [];
        for (let n = offset; n < offset + count; n++) {
            rowDefs.push([
                "c:TableRow", {
                    item: [component.getReference(`v.items[${n}]`)],
                    var: varName,
                    index: n,
                    cells: cells,
                    cellClass: cellClass,
                    rowTemplate: rowTemplate,
                    initialVisibility: !filterFunction || filterFunction.apply(null, [component.get(`v.items[${n}]`)])
                }
            ]);
        }

        $A.createComponents(rowDefs, callback);
    },


    /*
        Filter & Sort Updates
    */
    applySort: function(component, newCompare, newOrder, newColumn) {
        const rows = component.get("v.rows");
        const currentColumn = component.get("v.sortColumn");

        if (currentColumn && (!newColumn || currentColumn.getGlobalId() !== newColumn.getGlobalId())) {
            currentColumn.set("v.sortOrder", "");
        }

        component.set("v.sortOrder", newOrder);
        component.set("v.compareFunction", newCompare)
        component.set("v.sortColumn", newColumn);

        this.sortRows(component, rows);
        component.set("v.rows", rows);
    },

    sortRows: function(component, rows) {
        const compareFunction = component.get("v.compareFunction");

        if (compareFunction) {
console.log(compareFunction);
            const sortOrder = component.get("v.sortOrder");
            if (sortOrder === "DESC") {
                this.mergeSort(rows, (a, b) => compareFunction.apply(null, [a.get("v.item[0]"), b.get("v.item[0]")]));
            } else {
                this.mergeSort(rows, (a, b) => compareFunction.apply(null, [b.get("v.item[0]"), a.get("v.item[0]")]));
            }
        }
    },

    updateFilter: function(component) {
        const filterFunction = component.get("v.filterFunction");

        for (const row of component.get("v.rows")) {
            if (!filterFunction || filterFunction.apply(null, [row.get("v.item[0]")])) {
                $A.util.removeClass(row, "hiddenRow");
            } else {
                $A.util.addClass(row, "hiddenRow");
            }
        }
    },

    /*
        Merge Sort
    */

    // Javascript's sort() function is usually unstable, items which are equal may change positions
    // relative to each other. We want to preserve the order of items which are equal.
    mergeSort: function(array, evalFunction) {
        this._mergeSortSplit(array.slice(), array, 0, array.length, evalFunction);
    },
    _mergeSortMerge: function(array1, array2, startIndex, middleIndex, endIndex, evalFunction) {
        let leftIndex = startIndex;
        let rightIndex = middleIndex;

        for (let index = startIndex; index < endIndex; index++) {
            if (leftIndex < middleIndex &&
                (rightIndex >= endIndex || evalFunction(array1[leftIndex], array1[rightIndex]) <= 0)
            ) {
                array2[index] = array1[leftIndex];
                leftIndex++;
            } else {
                array2[index] = array1[rightIndex];
                rightIndex++;
            }
        }
    },
    _mergeSortSplit: function(array1, array2, startIndex, endIndex, evalFunction) {
        if (endIndex - startIndex <= 1) return;

        const middleIndex = Math.floor((startIndex + endIndex) / 2);
        this._mergeSortSplit(array2, array1, startIndex, middleIndex, evalFunction);
        this._mergeSortSplit(array2, array1, middleIndex, endIndex, evalFunction);
        this._mergeSortMerge(array1, array2, startIndex, middleIndex, endIndex, evalFunction);
    }
})