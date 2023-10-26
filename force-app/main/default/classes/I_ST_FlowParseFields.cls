global class I_ST_FlowParseFields {
    
    @InvocableMethod(label='Parse Object Values')
    public static List<String> ParseObjectValue(List<Request> reqs){
        
        List<String> fieldValues = new List<String>();
        String fieldValue;     
        
        for(Request req : reqs){
            fieldValue = String.valueOf(req.record.get(req.field));
        }
        
        fieldValues.add(fieldValue);
        return fieldValues;
    }
    
    global class Request {
        @InvocableVariable
        global sObject record;
        
        @InvocableVariable
        global String field;   
    }
        
}