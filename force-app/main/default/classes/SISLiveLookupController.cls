public class SISLiveLookupController {
    @AuraEnabled
    public static String calloutToSIS(String firstName, String lastName, String email, String studentId){
      	String feildQuery = '';
        // Instantiate a new http object
        Http h = new Http();
    
         // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        
        if (studentId != null && studentId != ''){
            feildQuery += '"StudentID_Equals":'+studentId;
        }
        /*if (firstName != null && firstName != ''){
            if (feildQuery != null && feildQuery != ''){
                feildQuery += ',';
            }
            feildQuery += '"SISFirstName_Equals":"'+firstName+'"';
        }*/
        if (lastName != null && lastName != ''){
            if (feildQuery != null && feildQuery != ''){
                feildQuery += ',';
            }
            feildQuery += '"FamilyName_In":"'+lastName+'"';
        }
        /*if (email != null && email != ''){
            if (feildQuery != null && feildQuery != ''){
                feildQuery += ',';
            }
            feildQuery += '"Customeremail_Like":"'+email+'"';
        }*/
        String requestBody = '{"PageInfo":{"PageSize":"100","PagePointer":"0"},' + feildQuery + '}';
        
        System.debug('requestBody: '+requestBody);
        
        req.setBody(requestBody);
        req.setTimeout(60000);
    	req.setEndpoint('callout:SISLookup');
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        
        System.debug(res);
        System.debug('-->'+res.getBody());
        
        return res.getBody();
        
    }
    
}