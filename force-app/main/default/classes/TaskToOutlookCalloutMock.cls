public class TaskToOutlookCalloutMock implements HttpCalloutMock {
    
    public HTTPResponse respond(HTTPRequest req) {
        
        Boolean failThisCallout = TaskToOutlookTest.forceCalloutFail;
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        
        switch on (req.getMethod()){
            when 'POST' {
                if (!failThisCallout){
	                res.setStatusCode(201);    
	                res.setBody('{"id" : "exchangeidhere"}');
                }
                else {
                    res.setStatusCode(401);
                    res.setBody('Failure');
                }
            }
            when 'DELETE' {
                if (!failThisCallout){
	            	res.setStatusCode(204);
                }
                else {
                    res.setStatusCode(404);
	                res.setBody('Failure');
                }
            }
            
        }
        return res;

    }
    
}