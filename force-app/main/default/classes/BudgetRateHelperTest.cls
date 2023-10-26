@isTest
public class BudgetRateHelperTest {

    public static testmethod void budgetRateHelperTest(){
        
        //LCI
        Account org = TestUtility.newEmptyExternalAccount('Test Account');
        insert org;
        
        //Contact contact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, org.Id);
        Contact contact = TestUtility.createContact(org.Id);
        contact.I_RS_Salary_Grade__c = 'TEST 1';
        insert contact;
        
        //CUSTOM SETTINGS
        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.75
        );

        insert new Overheads_and_Profit_Default_Values__c(
            Name = 'Non-Research Consultancy',
            I_RS_Rate_Type__c = 'Non-Research Consultancy', 
            I_RS_Overhead__c = 10, 
            I_RS_Profit__c = 10, 
            I_RS_Non_Salary_Overhead__c = 10
        );
        
        Salary_Table__c salaryTable = TestUtility.newSalaryTable('TEST', 1, Date.today().Year() + '', 110000);
        insert salaryTable;
        
        //PROEJCT PROPOSAL AND BUDGET
        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Lead_Chief_Investigator__c = contact.Id;
        insert projectProposal;
        
        
        Budget__c budget = TestUtility.newBudget(projectProposal.Id);
        insert budget;
        
        budget.I_RS_Actual_Rate_Type__c = 'Non-Research Consultancy';
        budget.I_RS_Actual_Overhead__c = 0;
        budget.I_RS_Actual_Profit__c = 0;
        budget.I_RS_Actual_Non_Salary_Overhead__c = 0;
        
        budget.I_RS_Maximum_Allowed_On_Cost__c = 35;
		budget.I_RS_Actual_Overhead__c = 0;
		budget.I_RS_Actual_Profit__c = 0; 
		budget.I_RS_Actual_Non_Salary_Overhead__c = 0;
        
        update budget;
        
        Budget__c[] budgetList = new List<Budget__c>{budget};
            
        
    
    
        //APPLY METHODS ON DATA - VERIFY RECORD HAS CHANGED
		budgetList = BudgetRateHelper.provideActualRatesBasedOnRateType(budgetList);
        
		budgetList = BudgetRateHelper.provideDailyChargeoutRates_Aura(budgetList);
        
        budget = budgetList[0];
        
        System.assert(budget.I_RS_Actual_Overhead__c > 0);
        System.assert(budget.I_RS_Actual_Profit__c > 0);
        System.assert(budget.I_RS_Actual_Non_Salary_Overhead__c > 0);
        
        System.assert(budget.I_RS_Daily_On_Costs__c > 0);
        System.assert(budget.I_RS_Daily_Overheads__c > 0);
        System.assert(budget.I_RS_Daily_Profits__c > 0);
        System.assert(budget.I_RS_Daily_Salary__c > 0);

        
        //NOW REMOVE SALARY TABLE - THIS WILL CAUSE DAILY FIELDS TO BECOME 0
        delete salaryTable;
        
        budgetList = BudgetRateHelper.provideDailyChargeoutRates_Aura(budgetList);
        
        budget = budgetList[0];
        
        System.assert(budget.I_RS_Daily_On_Costs__c == 0);
        System.assert(budget.I_RS_Daily_Overheads__c == 0);
        System.assert(budget.I_RS_Daily_Profits__c == 0);
        System.assert(budget.I_RS_Daily_Salary__c == 0);

        
    }
    
}