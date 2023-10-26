@isTest
public class FlowUtilityTest {

    public static testmethod void checkIfRecordIsLocked(){
        
        Test.startTest();
        
		Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Status__c = 'Submitted';
        pp.I_RS_Theme__c = 'No theme alignment ';
        insert pp;
        
        Test.stopTest();
        
        System.assert(
            FlowUtility.checkIfRecordIsLocked(
                new List<Id>{pp.Id}
            )[0].isLocked
        );
        
    }
    
}