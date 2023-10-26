@isTest
public class SISLookupCalloutTest {
    static testmethod void testPostCallout() {
       
        Test.setMock(HttpCalloutMock.class, new LiveLookupCalloutMock()); 

        String sampleFirstName = '';
        String sampleLastName = 'Test Customer';
        String sampleEmail = '';
        String sampleStudentId = '123456';
        
        String SISLiveLookupController = SISLiveLookupController.calloutToSIS(sampleFirstName, sampleLastName, sampleEmail, sampleStudentId);
       
    }
}