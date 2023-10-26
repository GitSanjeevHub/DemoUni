({
    openFlowInModal : function(component, event, helper){

        let flowName = component.get("v.flowName");
        let modalHeader = component.get("v.headerTitle");
        let recordId = component.get("v.recordId");
        
        console.log(flowName);
        console.log(recordId);
        
        $A.createComponents([
            [
                "c:FlowWrapper",
                {
                    flowName: flowName,
                    flowParams: [
                        {
                            name : 'recordId',
                            type : 'String',
                            value : recordId
                        }
                    ]
                }
            ]
        ],
        function(components, status, errorMessage){
            
            if (status === "SUCCESS") {

				console.log("Success!");
                
                component.find('overlayLib').showCustomModal({
                    
                   header: modalHeader,
                   body: components[0],
                    
                   showCloseButton: true,
                   
                   closeCallback: function() {

                   }
               })
            }
            else if (status === "ERROR") {
                
                alert(errorMessage);
                
            }
        }
       );
        
    }
})