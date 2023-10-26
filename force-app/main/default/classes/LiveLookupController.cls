public class LiveLookupController {

    @AuraEnabled
    public static String calloutToSAP(String ABN, String name){
      
        // Instantiate a new http object
        Http h = new Http();
    
         // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        
        String requestBody = '{"PageInfo":{"PageSize":"100","PagePointer":"0"},';
        if (ABN != null && ABN != ''){
            requestBody += '"CustomerABN_Equals":"'+ABN+'"';
        }
        if (ABN != null && ABN != '' && name != null && name != ''){
            requestBody += ',';
        }
        if (name != null && name != ''){
            requestBody += '"CustomerName_Like":"'+name+'"';
        }
        requestBody += '}';
        
        System.debug('requestBody: '+requestBody);
        
        req.setBody(requestBody);
        req.setTimeout(60000);
    	req.setEndpoint('callout:Customer_Live_Look_Up');
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        
        System.debug(res);
        System.debug('-->'+res.getBody());
        
        return res.getBody();
        
    }
    
    
    /*static List<Map<String, Object>> loadSampleData(){
        
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        for (Integer i=0; i<50; i++){
            
            Map<String, Object> responseRecord = new Map<String, Object>{
              
                'CustomerName' => 'LUDWIG INSTITUTE FOR CANCERRESEARCH LTD1'+i, 
                 'CustomerReference' => '99999999999', 
                 'Address' => new Map<String, Object>{
           			'Street' => 'Stadelhoferstrasse 22',
           			'HouseNumber' =>'22',
                   	'PostalCode'=> '8024',
                   	'City'=> 'ZURICH',
                   	'Country'=>'CH',
                   	'Region'=>'',
                   	'POBox'=>'123',
                   	'Postal'=>'3421'
        		},
                'CustomerNotes1' => 'Customer Notes 1',
                'CustomerNotes2' => 'Customer Notes 2'
                
            };
               
           	System.debug(responseRecord);
                
            results.add(responseRecord);
            
        }
        
        return results;
        
    }*/
    
}