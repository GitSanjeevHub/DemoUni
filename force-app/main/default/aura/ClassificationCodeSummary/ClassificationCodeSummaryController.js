({
	doInit : function(component, event, helper) {
		
        var actions = [
            { label: 'Show Codes', name: 'show_codes' },
        ];
        
        component.set("v.columns", [
            {
            	label: 'Type of Code', fieldName: 'separateTabURL', type: 'url', 
            	typeAttributes: {label: {
            		fieldName: 'categoryLabel'}, target: '_blank'
            	}, 
            	cellAttributes: { alignment: 'left' }
            },            
            {label: 'Number of Codes', fieldName: 'activeCodeCount', type: 'number', cellAttributes: { alignment: 'left'}},
        ]);
        
        helper.getServerData(component, event, helper);
	},
    
    refreshButtonClicked : function(component, event, helper){
        helper.getServerData(component, event, helper);
    }
})