({
    setColumns : function(component){
      
        component.set("v.columns", [
			{
				type: 'button', 
				typeAttributes: {
                    label: 'Create Contact',
                    name: 'selectRecord',
                    title: 'selectRecord',
                    disabled: false,
                    value: 'test'
                },
                fixedWidth: 150
            },
                      
            {label: 'First Name', fieldName: 'GivenName', type: 'text', initialWidth: 200},
            {label: 'Last Name', fieldName: 'FamilyName', type: 'text', initialWidth: 200},
            {label: 'Student Id', fieldName: 'StudentID', type: 'text', initialWidth: 150},
            {label: 'Email', fieldName: 'LTUEmail', type: 'email'},
            
            
        ]);
        
    },
            
    /*loadSampleData : function(component){
    
        var data = [];
        for (var i=0; i<50; i++){
            
            let row = {
                FirstName: 'First Name '+i, 
                LastName: 'Last Name ' + i,
                StudentId: 'Student' + i,
                Email: 'FirstName@au'+i+'.lastName.com',
                HiddenField: 'hiddenField'
            }
                       
            data.push(row);
                
        }
        component.set("v.data", data);
    },*/


	//Perform Callout - basically here we are
	//	Marking status as in-progress so spinner starts
	//	Performing an asynchronous Apex call (javascript is async, Apex is sync)
	//	When result comes back (i.e. a callback), update the component appropriately with status
    performCallout : function(component){
    
        console.log('performCallout');
        
        //Enable loading screem
        component.set("v.calloutState", "IN_PROGRESS");
        
        //This is the array variable that will eventually be the resutls from the latest search
        var data = [];
        
        //Define Apex method - Apex method name must be different from javascript method name
        let action = component.get("c.calloutToSIS");
        
        //Set Apex method params - map keys must exactly match Apex method parameter names
        let fName  = component.find("FirstName").get("v.value");
        let lName  = component.find("LastName").get("v.value");
        let studentemail = component.find("email").get("v.value");
        let sId = component.find("StudentId").get("v.value");
        action.setParams({ firstName: fName, lastName: lName, email: studentemail, studentId: sId});

        //In this 'setCallback', this is what happens AFTER the asynchronous Apex call has completed
        action.setCallback(this, function(response) {
            //.getState() refers to whether the Apex method call succeeded or had issues, i.e. no internet
            var state = response.getState();
            if (state === "SUCCESS") {

                try {
                    //'.getReturnValue' is the data returned from the Apex method - it needs to be JSON
					console.log(JSON.parse(response.getReturnValue()));                    
                    let result = JSON.parse(
                        response.getReturnValue()).LTU_MT_HUB_ReadStudentEnrolment_Response.Student;				

                    console.log(result);

                    let resultsFound = result !== undefined;
                    if (resultsFound){
                        let moreThanOne = result.length > 1;
                        let exactlyOne = !moreThanOne;
                        console.log('moreThanOne: ' + moreThanOne);
                        console.log('exactlyOne: ' + exactlyOne);
                        
                        
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
        console.log('in Process and add row');
        console.log(row);
        
        data.push(row);
        
    },
    
    validValue : function(fieldVal) {
        console.log("fieldVal: " +fieldVal );
        return !((fieldVal == null) || (fieldVal == "") || (fieldVal == undefined));
    },
    
    
    writeSelectedRowFieldsToOutputData : function(component, row){
        
		console.log('writeSelectedRowFieldsToOutputData');
        
        //Extract JSON values from row and write them to component instance variables.
        //This way, they can be written back out to the enclosing Flow.
        if (this.validValue(row.StudentID)) {
    		component.set("v.selected_StudentID", row.StudentID);
        } else {
    		component.set("v.selected_StudentID", '');
        }
        
        if (this.validValue(row.Salutation)) {
        	component.set("v.selected_Salutation", row.Salutation);
        } else {
        	component.set("v.selected_Salutation", '');
        }
        
        if (this.validValue(row.GivenName)) {
        	component.set("v.selected_FirstName", row.GivenName);
        } else {
        	component.set("v.selected_FirstName", '');
        }
        
        if (this.validValue(row.FamilyName)) {
        	component.set("v.selected_LastName", row.FamilyName);
        } else {
        	component.set("v.selected_LastName", '');
        }
        
        if (this.validValue(row.PreferredGivenName)) {
        	component.set("v.selected_PreferredGivenName", row.PreferredGivenName);
        } else {
        	component.set("v.selected_PreferredGivenName", '');
        }
        
        if (this.validValue(row.FormalName)) {
        	component.set("v.selected_FormalName", row.FormalName);
        } else {
        	component.set("v.selected_FormalName", '');
        }
        
        if (this.validValue(row.Gender)) {
        	component.set("v.selected_Gender", row.Gender);
        } else {
        	component.set("v.selected_Gender", '');
        }
        
        if (this.validValue(row.CountryOfBirth)) {
        	component.set("v.selected_CountryOfBirth", row.CountryOfBirth);
        } else {
        	component.set("v.selected_CountryOfBirth", '');
        }
        
        if (this.validValue(row.UserName)) {
        	component.set("v.selected_UserName", row.UserName);
        } else {
        	component.set("v.selected_UserName", '');
        }
        
        if (this.validValue(row.ATSI)) {
        	component.set("v.selected_ATSI", row.ATSI);
        } else {
        	component.set("v.selected_ATSI", '');
        }
        
        if (this.validValue(row.CourseStatus)) {
        	component.set("v.selected_CourseStatus", row.CourseStatus);
        } else {
        	component.set("v.selected_CourseStatus", '');
        }
        
        if (this.validValue(row.CitizenshipStatus)) {
        	component.set("v.selected_CitizenshipStatus", row.CitizenshipStatus);
        } else {
        	component.set("v.selected_CitizenshipStatus", '');
        }
        
        if (this.validValue(row.CountryOfCitizenship)) {
        	component.set("v.selected_CountryOfCitizenship", row.CountryOfCitizenship);
        } else {
        	component.set("v.selected_CountryOfCitizenship", '');
        }
        
        if (this.validValue(row.CountryOfResidence)) {
        	component.set("v.selected_CountryOfResidence", row.CountryOfResidence);
        } else {
        	component.set("v.selected_CountryOfResidence", '');
        }
        
         if (this.validValue(row.LTUEmail)) {
       		component.set("v.selected_email", row.LTUEmail);
        } else {
       		component.set("v.selected_email", '');
        }
        
        if (this.validValue(row.ActiveStudent)) {
        	component.set("v.selected_ActiveStudent", row.ActiveStudent);
        } else {
        	component.set("v.selected_ActiveStudent", '');
        }
        
        if (this.validValue(row.FieldOfEducation)) {
        	component.set("v.selected_FieldOfEducation", row.FieldOfEducation);
        } else {
        	component.set("v.selected_FieldOfEducation", '');
        }
        
        if (this.validValue(row.OtherGivenNames)) {
        	component.set("v.selected_OtherGivenNames", row.OtherGivenNames);
        } else {
        	component.set("v.selected_OtherGivenNames", '');
        }
        
        if (this.validValue(row.OrgUnitCode)) {
        	component.set("v.selected_OrgUnitCode", row.OrgUnitCode);
        } else {
        	component.set("v.selected_OrgUnitCode", '');
        }

        if (this.validValue(row.OrgUnitDesc)) {
        	component.set("v.selected_OrgUnitDesc", row.OrgUnitDesc);
        } else {
        	component.set("v.selected_OrgUnitDesc", '');
        }
        
        if (this.validValue(row.Deceased)) {
        	component.set("v.selected_Deceased", row.Deceased);
        } else {
        	component.set("v.selected_Deceased", '');
        }
        
        if (this.validValue(row.CourseCode)) {
        	component.set("v.selected_CourseCode", row.CourseCode);
        } else {
        	component.set("v.selected_CourseCode", '');
        }
        
        if (this.validValue(row.CourseDesc)) {
        	component.set("v.selected_CourseDesc", row.CourseDesc);
        } else {
        	component.set("v.selected_CourseDesc", '');
        }
        
        if (this.validValue(row.CreatedTimestamp)) {
        	component.set("v.selected_CreatedTimestamp", row.CreatedTimestamp);
        } else {
        	component.set("v.selected_CreatedTimestamp", '');
        }
        
        if (this.validValue(row.ModifiedTimestamp)) {
	        component.set("v.selected_ModifiedTimestamp", row.ModifiedTimestamp);
        } else {
	        component.set("v.selected_ModifiedTimestamp", '');
        }

    
    
    	/*component.set("v.selected_StudentID", row.StudentID);
        component.set("v.selected_Salutation", row.Salutation);
        component.set("v.selected_FirstName", row.GivenName);
        component.set("v.selected_LastName", row.FamilyName);
        component.set("v.selected_FormalName", row.FormalName);
        component.set("v.selected_Gender", row.Gender);
        component.set("v.selected_CountryOfBirth", row.CountryOfBirth);
        component.set("v.selected_UserName", row.UserName);
        component.set("v.selected_ATSI", row.ATSI);
        component.set("v.selected_CourseStatus", row.CourseStatus);
        component.set("v.selected_CitizenshipStatus", row.CitizenshipStatus);
        component.set("v.selected_CountryOfCitizenship", row.CountryOfCitizenship);
        component.set("v.selected_CountryOfResidence", row.CountryOfResidence);
        component.set("v.selected_email", row.LTUEmail);
        component.set("v.selected_ActiveStudent", row.ActiveStudent);
        component.set("v.selected_FieldOfEducation", row.FieldOfEducation);
        component.set("v.selected_OtherGivenNames", row.OtherGivenNames);
        component.set("v.selected_OrgUnitCode", row.OrgUnitCode);
        component.set("v.selected_OrgUnitDesc", row.OrgUnitDesc);
        component.set("v.selected_Deceased", row.Deceased);
        component.set("v.selected_CourseCode", row.CourseCode);
        component.set("v.selected_CourseDesc", row.CourseDesc);
        component.set("v.selected_CreatedTimestamp", row.CreatedTimestamp);
        component.set("v.selected_ModifiedTimestamp", row.ModifiedTimestamp);*/
        
        //This is an out-of-the-box snippet to get the surrounding Flow to navigate to the next screen
        var navigate = component.get("v.navigateFlow");
      	navigate("NEXT");
    }
    
})