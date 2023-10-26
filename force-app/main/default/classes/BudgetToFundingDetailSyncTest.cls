@isTest
public with sharing class BudgetToFundingDetailSyncTest {
   
    public static testmethod void budgetToFundingDetailSyncTest(){

        Budget__c budget = [select Id from Budget__c];
        List<Id> budgetIdList = new List<Id>{budget.Id};

        //Get Orgs in seperate lists?
        List<Account> ltuOrgs = [select Id from Account where I_RS_Part_of_La_Trobe__c = true];
        List<Account> extOrgs = [select Id from Account where I_RS_Part_of_La_Trobe__c = false];

        //Get record type Ids
        
        
        //'I_RS_Collaborator_SubContractor'
        

        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();

        
        
        for (Account ltuOrg : ltuOrgs){

            List<Budget_Line_Item__c> budgetLineItemsForOrg = new List<Budget_Line_Item__c>();


            //Create some la trobe funder cash
            Budget_Line_Item__c ltuFunderInCash = 
                TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 10000);
            ltuFunderInCash.I_RS_Organisation__c = ltuOrg.Id;

            //Add twice to test rollups
            budgetLineItemsForOrg.add(ltuFunderInCash);
            ltuFunderInCash = ltuFunderInCash.clone(false, false, false, false);
            budgetLineItemsForOrg.add(ltuFunderInCash);


            Budget_Line_Item__c ltuFunderInKind = 
                TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 10000);
            ltuFunderInKind.I_RS_In_Kind__c = true;
            ltuFunderInKind.I_RS_Organisation__c = ltuOrg.Id;

            budgetLineItemsForOrg.add(ltuFunderInKind);
            ltuFunderInKind = ltuFunderInCash.clone(false, false, false, false);
            budgetLineItemsForOrg.add(ltuFunderInKind);


            insert budgetLineItemsForOrg;
            budgetLineItems.addAll(budgetLineItemsForOrg);
        }


        Test.startTest();
        
        BudgetToFundingDetailSync.budgetToFundingDetailSync(budgetIdList);

        Test.stopTest();

    }


    


    @TestSetup
    static void makeData(){
        
        Account LaTrobeUniversity = TestUtility.newEmptyLTUAccount('La Trobe University');
        insert LaTrobeUniversity;

        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        //projectProposal.I_RS_Account_Organisation__c = LaTrobeUniversity.Id;
        insert projectProposal;

        
        /*Junction_Linkage__c preExistingFundingDetailDontDelete = TestUtility.newJunctionLinkage(projectOrg.Id, projectProposal.Id, null);
        preExistingFundingDetailDontDelete.Name = 'Do Not Delete';
        preExistingFundingDetailDontDelete.I_RS_Relationship_Type__c = 'Administering Organisation';*/

        Junction_Linkage__c preExistingFundingDetailToDelete = TestUtility.newJunctionLinkage(null/*LaTrobeUniversity.Id*/, projectProposal.Id, null);
        preExistingFundingDetailToDelete.Name = 'Delete';
        
        List<Junction_Linkage__c> preExistingFundingDetails = new List<Junction_Linkage__c>{
            //preExistingFundingDetailDontDelete,
            preExistingFundingDetailToDelete
        };
        insert preExistingFundingDetails;


        Budget__c budget = TestUtility.newBudget(projectProposal.Id);
        insert budget;

        


        List<Account> fundersAndProvidedToOrgs = new List<Account>();
        for (Integer i=0; i<5; i++){
            Account ltuOrg = TestUtility.newEmptyLTUAccount('LTU Org '+i);
            ltuOrg.ParentId = LaTrobeUniversity.Id;
            
            Account extOrg = TestUtility.newEmptyExternalAccount('Ext Org '+i);
            fundersAndProvidedToOrgs.add(ltuOrg);
            fundersAndProvidedToOrgs.add(extOrg);
        }
        insert fundersAndProvidedToOrgs;




        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        

    }

}