@isTest 
public class LiveLookupCalloutTest {

    static testmethod void testPostCallout() {
       
        Test.setMock(HttpCalloutMock.class, new LiveLookupCalloutMock()); 

        String sampleName = 'Test Customer';
        String sampleABN = '123456';
        
        String response = LiveLookupController.calloutToSAP(sampleName, sampleABN);
       
    }
    
}