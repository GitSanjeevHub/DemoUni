@isTest
public class BudgetCalculatorAuraTest {
    
    public static testmethod void testQuery(){
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        insert budget; 
        
        List<Budget_Line_Item__c> lineItems = new List<Budget_Line_Item__c>();
        for (Integer i=0; i<100; i++){
            lineItems.add(
                TestUtility.newBudgetLineItem(budget.Id)
            );
        }
        
        
        DataAccess.upsertRecords(lineItems, false);
        
        
        DataAccess.getSObjectListSOQL(
            new List<String>{'Name'},
            null, 
            'Budget_Line_Item__c', 
            'I_RS_Budget__c = \''+budget.Id+'\'',
            'Name',
            'ASC NULLS FIRST',
            100,
            0
        );
        
    }
    
    public static testmethod void testLookup(){
        
        Account account = TestUtility.newEmptyExternalAccount('Test Account');
        insert account;
        
        List<String> strList = new List<String>();
        List<LookupSearchResult> lookupSearchResults = 
            BudgetCalculatorAura.search(
            'Account', 
            'Test', 
            'Name',
            'Type__c',
            new List<String>{'I_RS_Part_of_La_Trobe__c'},
            'Name != NULL',
            'standard:icon'
            );
        System.assert(!lookupSearchResults.isEmpty());
        
    }
    
    
    public static testmethod void testSalaryCalculationYears(){
        
        Account org = TestUtility.newEmptyExternalAccount('Test Account');
        insert org;
        
        //Contact contact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, org.Id);
        Contact contact = TestUtility.createContact(org.Id);
        contact.I_RS_Salary_Grade__c = 'TEST 1';
        insert contact;
        
        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.75
        );
        
        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     
        }
        
        insert salaryTableList;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Project_Start_Date__c = Date.today();
        pp.I_RS_Project_End_Date__c = Date.today().addYears(7);
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        budget.I_RS_Actual_Profit__c = 10;
        insert budget;
        
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(new Budget_Line_Item__c(
            I_RS_Budget__c = budget.Id,
            I_RS_Organisation__c = org.Id,
            I_RS_Contact__c = contact.Id,
            I_RS_Unit_of_Time__c = 'Years',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_6_Quantity__c = 1,
            Year_7_Quantity__c = 1,
            Year_1_Cost__c = 0,
            Year_2_Cost__c = 0,
            Year_3_Cost__c = 0,
            Year_4_Cost__c = 0,
            Year_5_Cost__c = 0,
            Year_6_Cost__c = 0,
            Year_7_Cost__c = 0,
            I_RS_Amount__c = 0
        ));
        
        Test.startTest();
        EditableGridAutomationController.runAutomation('calculateSalaries', budgetLineItems);
        Test.stopTest();
        
    }
    
    public static testmethod void testSalaryCalculationMonths(){
        
        Account org = TestUtility.newEmptyExternalAccount('Test Account');
        insert org;
        
        //Contact contact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, org.Id);
        Contact contact = TestUtility.createContact(org.Id);
        contact.I_RS_Salary_Grade__c = 'TEST 1';
        insert contact;
        
        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.75
        );
        
        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
  
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     
        }
        
        insert salaryTableList;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Project_Start_Date__c = Date.today();
        pp.I_RS_Project_End_Date__c = Date.today().addYears(7);
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        budget.I_RS_Actual_Profit__c = 10;
        insert budget;
        
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(new Budget_Line_Item__c(
            I_RS_Budget__c = budget.Id,
            I_RS_Organisation__c = org.Id,
            I_RS_Contact__c = contact.Id,
            I_RS_Unit_of_Time__c = 'Months',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_6_Quantity__c = 1,
            Year_7_Quantity__c = 1,
            Year_1_Cost__c = 0,
            Year_2_Cost__c = 0,
            Year_3_Cost__c = 0,
            Year_4_Cost__c = 0,
            Year_5_Cost__c = 0,
            Year_6_Cost__c = 0,
            Year_7_Cost__c = 0,
            I_RS_Amount__c = 0
        ));
        
        Test.startTest();
        EditableGridAutomationController.runAutomation('calculateSalaries', budgetLineItems);
        Test.stopTest();
        
    }
    
    public static testmethod void testSalaryCalculationWeeks(){
        
        Account org = TestUtility.newEmptyExternalAccount('Test Account');
        insert org;
        
        //Contact contact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, org.Id);
        Contact contact = TestUtility.createContact(org.Id);
        contact.I_RS_Salary_Grade__c = 'TEST 1';
        insert contact;
        
        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.75
        );
        
        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     
        }
        
        insert salaryTableList;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Project_Start_Date__c = Date.today();
        pp.I_RS_Project_End_Date__c = Date.today().addYears(7);
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        budget.I_RS_Actual_Overhead__c = 10;
        insert budget;
        
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(new Budget_Line_Item__c(
            I_RS_Budget__c = budget.Id,
            I_RS_Organisation__c = org.Id,
            I_RS_Contact__c = contact.Id,
            I_RS_Unit_of_Time__c = 'Weeks',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_6_Quantity__c = 1,
            Year_7_Quantity__c = 1,
            Year_1_Cost__c = 0,
            Year_2_Cost__c = 0,
            Year_3_Cost__c = 0,
            Year_4_Cost__c = 0,
            Year_5_Cost__c = 0,
            Year_6_Cost__c = 0,
            Year_7_Cost__c = 0,
            I_RS_Amount__c = 0
        ));
        
        
        Test.startTest();
        EditableGridAutomationController.runAutomation('calculateSalaries', budgetLineItems);
        Test.stopTest();
        
    }
    
    public static testmethod void testSalaryCalculationDays(){
        
        Account org = TestUtility.newEmptyExternalAccount('Test Account');
        insert org;
        
        Contact contact = TestUtility.createContact(org.Id);
        contact.I_RS_Salary_Grade__c = 'TEST 1';
        insert contact;
        
        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.75
        );
        
        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     
        }
        
        insert salaryTableList;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Project_Start_Date__c = Date.today();
        pp.I_RS_Project_End_Date__c = Date.today().addYears(7);
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        budget.I_RS_Actual_Profit__c = 10;
        budget.I_RS_Actual_Overhead__c = 10;
        insert budget;
        
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(new Budget_Line_Item__c(
            I_RS_Budget__c = budget.Id,
            I_RS_Organisation__c = org.Id,
            I_RS_Contact__c = contact.Id,
            I_RS_Unit_of_Time__c = 'Days',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_6_Quantity__c = 1,
            Year_7_Quantity__c = 1,
            Year_1_Cost__c = 0,
            Year_2_Cost__c = 0,
            Year_3_Cost__c = 0,
            Year_4_Cost__c = 0,
            Year_5_Cost__c = 0,
            Year_6_Cost__c = 0,
            Year_7_Cost__c = 0,
            I_RS_Amount__c = 0
        ));
        
        Test.startTest();
        EditableGridAutomationController.runAutomation('calculateSalaries', budgetLineItems);
        Test.stopTest();
        
    }
    
    public static testmethod void testSalaryCalculationHours(){
        
        Account org = TestUtility.newEmptyExternalAccount('Test Account');
        org.I_RS_Maximum_Allowed_On_Cost__c = 30;
        insert org;
        
        //Contact contact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, org.Id);
        Contact contact = TestUtility.createContact(org.Id);
        contact.I_RS_Salary_Grade__c = 'TEST 1';
        insert contact;
        
        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.75
        );
        
        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     
        }
        
        insert salaryTableList;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.I_RS_Project_Start_Date__c = Date.today();
        pp.I_RS_Project_End_Date__c = Date.today().addYears(7);
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        budget.I_RS_Actual_Profit__c = 10;
        insert budget;
        
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(new Budget_Line_Item__c(
            I_RS_Budget__c = budget.Id,
            I_RS_Organisation__c = org.Id,
            I_RS_Contact__c = contact.Id,
            I_RS_Unit_of_Time__c = 'Hours',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_6_Quantity__c = 1,
            Year_7_Quantity__c = 1,
            Year_1_Cost__c = 0,
            Year_2_Cost__c = 0,
            Year_3_Cost__c = 0,
            Year_4_Cost__c = 0,
            Year_5_Cost__c = 0,
            Year_6_Cost__c = 0,
            Year_7_Cost__c = 0,
            I_RS_Amount__c = 0
        ));
        
        Test.startTest();
        EditableGridAutomationController.runAutomation('calculateSalaries', budgetLineItems);
        Test.stopTest();
        
    }
    

    public static testMethod void getTotalIncludingGST(){

        TestUtility.insertGSTRate();

        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(new Budget_Line_Item__c(I_RS_Amount__c = 1000));

        Budget_Line_Item__c budgetLineItemOutput = 
            (Budget_Line_Item__c) EditableGridAutomationController.runAutomation('applyGST', budgetLineItems)[0];

        System.assert(
            budgetLineItemOutput.I_RS_Cash_Amount_Inc_GST_Currency__c > budgetLineItems[0].I_RS_Amount__c,
            'Amount and Amount Incl. GST are the same'
        );
    }
    
    
    public static testmethod void testDelete(){
        
        Object_Metadata__c deletionBlockerCustomSetting = new Object_Metadata__c(
            Name = 'Budget_Line_Item__c',
            I_RS_Enable_Deletion_Blocker__c = true,
            I_RS_Deletion_Blocker_Check_Formula__c = 'I_RS_Line_Item_Permission_Delete__c',
            I_RS_Deletion_Blocker_Error_Message__c = 'Cant delete this'
        );
        insert deletionBlockerCustomSetting;
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        insert budget;
        
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>();
        budgetLineItems.add(TestUtility.newBudgetLineItem(budget.Id));
        
        insert budgetLineItems;
        
        DataAccess.deleteRecords(budgetLineItems);
        
        System.assertequals(0, [select count() from Budget_Line_Item__c]);
        
    }
    
    
    public static testmethod void getBLIRecordTypesByDeveloperName(){
    
        DataAccess.getRecordTypeInfosByDeveloperName('Budget_Line_Item__c');
        
        
    }

}