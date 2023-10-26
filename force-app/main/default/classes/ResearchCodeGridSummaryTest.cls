@isTest
public with sharing class ResearchCodeGridSummaryTest {
    
    public static testmethod void positiveCase_AllData() {

        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Theme__c = 'No theme alignment ';
        insert projectProposal;

        List<Classification_Master__c> cms = new List<Classification_Master__c>{
            TestUtility.newClassificationMaster('CM1', 'CM1', GlobalConstants.CLASSIFICATION_MASTER_TYPE_FOR, true),
            TestUtility.newClassificationMaster('CM2', 'CM2', GlobalConstants.CLASSIFICATION_MASTER_TYPE_FOR_2008, true),
            TestUtility.newClassificationMaster('CM3', 'CM3', GlobalConstants.CLASSIFICATION_MASTER_TYPE_SEO, true),
            TestUtility.newClassificationMaster('CM4', 'CM4', GlobalConstants.CLASSIFICATION_MASTER_TYPE_SEO_2008, true),
            TestUtility.newClassificationMaster('CM5', 'CM5', GlobalConstants.CLASSIFICATION_MASTER_TYPE_TOA, true)
        };
        insert cms;
        
        List<Classification_Code__c> ccs = new List<Classification_Code__c>();
        for (Classification_Master__c cm : cms){
            ccs.add(TestUtility.newClassificationCode(cm.Id, null, projectProposal.Id, null));
            ccs.add(TestUtility.newClassificationCode(cm.Id, null, projectProposal.Id, null));
            
            Classification_Code__c softDeletedCode = TestUtility.newClassificationCode(cm.Id, null, projectProposal.Id, null);
            softDeletedCode.I_RS_Inactive_for_non_admins__c = true;
            ccs.add(softDeletedCode);
        }
		insert ccs;
        
        List<ResearchCodeGridSummaryController.ERACodeGrouping> groupings = 
            ResearchCodeGridSummaryController.getSummaryData(projectProposal.Id, 'Classification_Codes_Project_Proposal');
        
        System.assertequals(5, groupings.size());
        
        for (ResearchCodeGridSummaryController.ERACodeGrouping grouping : groupings){
            System.assertequals(2, grouping.activeCodeCount);
        }
    }
    
    
 public static testmethod void positiveCase_NoData() {

        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Theme__c = 'No theme alignment ';
        insert projectProposal;

        List<ResearchCodeGridSummaryController.ERACodeGrouping> groupings = 
            ResearchCodeGridSummaryController.getSummaryData(projectProposal.Id, 'Classification_Codes_Project_Proposal');
        
        System.assertequals(3, groupings.size());
        
        for (ResearchCodeGridSummaryController.ERACodeGrouping grouping : groupings){
            System.assertequals(0, grouping.activeCodeCount);
        }
    }
}