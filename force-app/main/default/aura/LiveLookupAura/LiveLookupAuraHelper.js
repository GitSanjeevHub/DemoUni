({
    
    populateNameSearchField : function(component){
    
        let legalName = component.find("legalName").get("v.value");
        let legalNameExists = legalName && legalName.length > 0;
        
        if (!legalNameExists){
            
            let standardName = component.find("name").get("v.value");
            component.find("legalName").set("v.value", standardName);
        }
        
    },
    
    calloutToFinanceSystem : function(component){
    
        console.log('calloutToFinanceSystem');
        
        component.set("v.calloutState", "IN_PROGRESS");
        
        var data = [];
        
        let action = component.get("c.calloutToSAP");
        let ABN = component.find("abn").get("v.value");
		let legalName = component.find("legalName").get("v.value");
        
        action.setParams({ ABN : ABN, name: legalName});

        //component.find("dataTable").set("v.isLoading", true);
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                try {

					console.log(JSON.parse(response.getReturnValue()));                    
                    
                    let result = JSON.parse(
                        response.getReturnValue()).LTU_MT_HUB_SearchCustomer_Response.CustomerDetails;				
                    console.log(result);
                    
                    let resultsFound = result !== undefined;
                    
                    if (resultsFound){
                        let moreThanOne = result[0];
                        let exactlyOne = !moreThanOne && result.Key;
                        
                        
                        if (moreThanOne){
                            console.log(result.length + ' rows returned');
                            for (var i=0; i<result.length; i++){
                                console.log('result '+i);
                                let row = result[i];
                                this.processAndAddRow(data, row);
                            }
                        }
                        else if (exactlyOne){
                            console.log('One row returned');
                            this.processAndAddRow(data, result);
                        }
                        
                        component.set("v.calloutState", "SUCCESS");
                        
                    }
                    
                    else {
                        console.log('No results returned');
                        component.set("v.calloutState", "NO_RESULTS");
                    }
                    
                    //console.log(data);
                    component.set("v.data", data);
                        
                }
                catch (e){
                    console.log('Callout error: '+e.message);
                    component.set("v.calloutState", "CALLOUT_ERROR");
                }
                
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                
                component.set("v.calloutState", "CALLOUT_ERROR");
            }
            
            
        });

        $A.enqueueAction(action);

    },
    
    
    
    processAndAddRow : function(data, row){
        
        this.setABN(row);
        this.setSAPCustomerNumber(row);
        this.setAddress(row);
        this.setCustomerNotes(row);
        
        console.log(row);
        
        data.push(row);
        
    },
    
    
    /*loadSampleData : function(component){
    
        var data = [];
        for (var i=0; i<50; i++){
            
            let row = {
                CustomerName: 'LUDWIG INSTITUTE FOR CANCERRESEARCH LTD1'+i, 
                 CustomerReference: '9999', 
                 Address: {
           			Street:"Stadelhoferstrasse 22",
           			HouseNumber: "22",
                   	PostalCode:"8024",
                   	City:"ZURICH",
                   	Country:"CH",
                   	Region:"",
                   	POBox:"123",
                   	Postal:"3421"
        		},
                CustomerNotes1: 'Customer Notes 1',
                CustomerNotes2: 'Customer Notes 2'
            }
            
            this.setAddress(row);
            this.setCustomerNotes(row);
            
            data.push(row);
                
        }
        component.set("v.data", data);
    },*/
    
    setABN : function(row){
       row.CustomerReference = row.Key.CustomerReference.toString();
    },
    
    setSAPCustomerNumber : function(row){
        row.CustomerID = row.Key.CustomerID.toString();
    },
    
    setAddress : function(row){
    
        let addressJSON = row.Address;

        let POBox = (
            addressJSON.POBox.length > 0 ? 
            "PO Box " + addressJSON.POBox : 
        	""
        );
        
        let addressConcat = 
            this.returnString(addressJSON.HouseNumber) + ' ' +
            this.returnString(addressJSON.Street) + ' ' +
            this.returnString(POBox) + ' ' +
            ', ' + 
        	this.returnString(addressJSON.City) + ' ' +
            this.returnString(addressJSON.Region) + ' ' +
            this.returnString(addressJSON.Postal) + ' ' +
            this.returnString(addressJSON.Country);
        
        row.AddressConcat = addressConcat;
    },
    
    
    returnString : function(string){
    
        return (
            string ?
            string :
            ''
        );
    },
    
    
    setCustomerNotes : function(row){
        
        //console.log('setCustomerNotes');
        
        if (row.CustomerNotes1.length > 0 && row.CustomerNotes2.length > 0){
            //console.log('Both provided');
            row.CustomerNotesConcat = row.CustomerNotes1 + '. ' + row.CustomerNotes2;
        }
        else if (row.CustomerNotes1.length > 0 && row.CustomerNotes2.length === 0){
            //console.log('c1 provided');
            row.CustomerNotesConcat = row.CustomerNotes1;
        }
        else if (row.CustomerNotes1.length === 0 && row.CustomerNotes2.length > 0){
            //console.log('c2 provided');
            row.CustomerNotesConcat = row.CustomerNotes2;
       	}
        //console.log(row.CustomerNotesConcat);
    },
    
    setColumns : function(component){
      
        component.set("v.columns", [
			{
				type: 'button', 
				typeAttributes: {
                    label: 'Save to Org',
                    name: 'selectRecord',
                    title: 'selectRecord',
                    disabled: false,
                    value: 'test'
                },
                fixedWidth: 180
            },
                      
            {label: 'Name', fieldName: 'CustomerName', type: 'text', initialWidth: 250},
            {label: 'ABN', fieldName: 'CustomerReference', initialWidth: 110},
            {label: 'Finance Customer Number', fieldName: 'CustomerID', initialWidth: 150},
            {label: 'Address', fieldName: 'AddressConcat', type: 'text'},
            {label: 'Customer Notes', fieldName: 'CustomerNotesConcat', type: 'text'},
            
            
        ]);
        
    },
    
    showToast : function(component){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": "Success!",
            "message": "Organisation details have been saved."
        });
        
    	toastEvent.fire();
    }
})