({
	doInit : function(component, event, helper) {
		
        component.set("v.data", 
                      [{
                          category: 'Travel',
                          description: 'Travel cost for 2',
                          inKind : false,
                          org: '0015O000002f0mYQAQ',
                          unitPrice : null,
                          year1Qty: null,
                          year1Cost: 4032,
                          year2Qty: null,
                          year2Cost: 4032,
                          year3Qty: null,
                          year3Cost: null,
                          year4Qty: null,
                          year4Cost: null,
                          year5Qty: null,
                          year5Cost: null,
                          sapCategory : null,
                          justification : 'Youth participants'
                      },
                       {
                          category: 'Equipment',
                          description: 'Communication and Marketing',
                          inKind : true,
                          org: '0015O000002dMlcQAE',
                          unitPrice : null,
                          year1Qty: null,
                          year1Cost: null,
                          year2Qty: null,
                          year2Cost: 3000,
                          year3Qty: null,
                          year3Cost: null,
                          year4Qty: null,
                          year4Cost: null,
                          year5Qty: null,
                          year5Cost: null,
                          sapCategory : null,
                          justification : null
                      },
                       {
                          category: 'Other',
                          description: 'Venue Hire',
                          inKind : false,
                          org: '0015O000002f0mYQAQ',
                          unitPrice : null,
                          year1Qty: null,
                          year1Cost: 3600,
                          year2Qty: null,
                          year2Cost: null,
                          year3Qty: null,
                          year3Cost: null,
                          year4Qty: null,
                          year4Cost: null,
                          year5Qty: null,
                          year5Cost: null,
                          sapCategory : null,
                          justification : null
                      },
                       {
                          category: 'Maintenance',
                          description: 'Mobile Phone',
                          inKind : false,
                          org: null,
                          unitPrice : null,
                          year1Qty: null,
                          year1Cost: null,
                          year2Qty: null,
                          year2Cost: null,
                          year3Qty: null,
                          year3Cost: null,
                          year4Qty: null,
                          year4Cost: null,
                          year5Qty: null,
                          year5Cost: null,
                          sapCategory : null,
                          justification : null
                      },
                       {}
                      ]
                     
                     );
        
	},
    
    
    addRow : function(component, event, helper){
        
		var data = component.get("v.data");
        data.push({});
        
        component.set("v.data", data);
    }
    
})