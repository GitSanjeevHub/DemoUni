({
	doInit : function(component, event, helper) {

        try {

            //Record Id
            if (!component.get("v.recordId")){
                let urlParam_recordId = helper.getURLParameter('c__recordId');
                if (urlParam_recordId)
                    component.set("v.recordId", urlParam_recordId);
            }
            
            //Object
            if (!component.get("v.objectAPIName")){
                let urlParam_objectAPIName = helper.getURLParameter('c__recordWidgetObjectAPIName');
                if (urlParam_objectAPIName)
                    component.set("v.objectAPIName", urlParam_objectAPIName);
            }
            
            //Fields
            let fieldConcat = component.get("v.fieldConcat");
            if (!fieldConcat){
                fieldConcat = helper.getURLParameter('c__recordWidgetFields');
            }
                
            console.log('c__fromRecordDisplayFields'+fieldConcat)
        
            let fields;
            if (fieldConcat.includes(','))
                fields = fieldConcat.split(",");
            else
                fields = fieldConcat.split("%2C");
            
            console.log('fields '+fields);
            
            component.set("v.fields", fields);
            
            //Header
            if (!component.get("v.cardTitle"))
                component.set("v.cardTitle", helper.getURLParameter('c__recordWidgetCardTitle'));
                
            //Return URL
            component.set("v.returnURL", helper.getURLParameter('c__retURL'));

            console.log(console.log('returnURL '+component.get("v.returnURL")));

        }
        catch (e){
            console.log(e);
        }
        
	}
    
})