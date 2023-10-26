({
  doInit: function(component, event, helper) {
    component.set("v.data", [
      {
        category: "Salary",
        contactId: "0035O000001rekcQAA",
        description: "@E2 starting 2019 as year1",
        inKind: false,
        org: "0015O000002f0mYQAQ",
        fte: "Yearly",
        year1Qty: 0.1,
        year1Cost: 13000,
        year2Qty: 0.1,
        year2Cost: 13500,
        year3Qty: 0.2,
        year3Cost: 28000,
        year4Qty: null,
        year4Cost: null,
        year5Qty: null,
        year5Cost: null,
        sapCategory: null,
        justification: null
      },
      {
        category: "Salary",
        contactId: "0035O000001rekrQAA",
        description: "Future Staff",
        inKind: false,
        org: "0015O000002f0mYQAQ",
        fte: "Monthly",
        year1Qty: 1,
        year1Cost: 10883,
        year2Qty: 1,
        year2Cost: 11000,
        year3Qty: 1,
        year3Cost: 11500,
        year4Qty: null,
        year4Cost: null,
        year5Qty: null,
        year5Cost: null,
        sapCategory: null,
        justification: null
      },
      {},
        {}
    ]);
  },

  addRow: function(component, event, helper) {
    var data = component.get("v.data");
    data.push({});

    component.set("v.data", data);
  }
});