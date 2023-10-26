@isTest
public class BudgetCalculatorTest {
    
    public static testmethod void testBudgetCalculation() {

        TestUtility.insertGSTRate();

        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.88
        );

        Account org = TestUtility.newEmptyExternalAccount('Org One');
        insert org;

        //Contact salaryPerson = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null);
        Contact salaryPerson = TestUtility.createContact(null);
        salaryPerson.I_RS_Salary_Grade__c = 'Level A 1';
        insert salaryPerson;

        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('Level A', index, currentYear, 100000 + (1000 * index) ));
        }
        insert salaryTableList;

        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Account_Organisation__c = org.Id;
        projectProposal.I_RS_Lead_Chief_Investigator__c = salaryPerson.Id;
        insert projectProposal;

        //
        //BUDGET AND LINE ITEM INITIAL CALCULATIONS
        //
        //Insert Budget, apply daily chargeout rate calculation
        Budget__c budget = TestUtility.newBudget(projectProposal.Id);
        budget.I_RS_Actual_Overhead__c = 30;
        budget.I_RS_Actual_Profit__c = 30;
        budget.I_RS_Actual_Non_Salary_Overhead__c = 30;

        insert budget;

        BudgetRateHelper.provideDailyChargeoutRates(new List<Budget__c>{budget});
        update budget;

        budget = [SELECT Id, I_RS_Daily_Salary__c from Budget__c WHERE Id = :budget.Id];
        System.assert(budget.I_RS_Daily_Salary__c > 0);
        Decimal initialDailyBaseSalary = budget.I_RS_Daily_Salary__c;

        //Create Budget Line Items
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>{
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 0),
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 0),
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Non_Salary', 0)
        };
        budgetLineItems[0].I_RS_Contact__c = salaryPerson.Id;
        budgetLineItems[0].I_RS_Organisation__c = org.Id;

        budgetLineItems[1].I_RS_Category__c = 'Future La Trobe Staff';
        budgetLineItems[1].I_RS_Sub_Category__c = 'Level A 1';
        budgetLineItems[1].I_RS_Contact__c = salaryPerson.Id;
        budgetLineItems[1].I_RS_Organisation__c = org.Id;

        budgetLineItems[2].I_RS_Category__c = 'Travel';
        budgetLineItems[2].I_RS_Organisation__c = org.Id;
        budgetLineItems[2].Unit_Price__c = 100;

        insert budgetLineItems;

        //
        //ACTUAL TEST
        //
        Test.startTest();

        new BudgetCalculator(budgetLineItems).recalculateAndSave();

        Test.stopTest();

        //Verify Salary Items
        List<Budget_Line_Item__c> salaryItems = [
            SELECT Id, I_RS_Amount__c FROM Budget_Line_Item__c 
            WHERE RecordType.DeveloperName = 'I_RS_Salary' ORDER BY I_RS_Category__c];

        System.debug('Salary Item 0 cost '+salaryItems[0].I_RS_Amount__c);
        System.debug('Salary Item 1 cost '+salaryItems[1].I_RS_Amount__c);

        System.assert(salaryItems[0].I_RS_Amount__c > 0);
        System.assert(salaryItems[1].I_RS_Amount__c > 0);

        //Assert more stuff here

        List<Budget_Line_Item__c> nonSalaryItems = [
            SELECT Id, I_RS_Amount__c FROM Budget_Line_Item__c 
            WHERE RecordType.DeveloperName = 'I_RS_Non_Salary' ORDER BY I_RS_Category__c];

        System.assert(nonSalaryItems[0].I_RS_Amount__c > 0);

    }

    public static testmethod void testMergeOrgs() {

        TestUtility.insertGSTRate();

        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.88
        );

        List<Account> orgs = new List<Account>{
            TestUtility.newEmptyExternalAccount('Org One'),
            TestUtility.newEmptyExternalAccount('Org Two')
        };
        orgs[1].I_RS_Maximum_Allowed_On_Cost__c = 50;

        insert orgs;

        //Contact salaryPerson = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null);
        Contact salaryPerson = TestUtility.createContact(null);
        salaryPerson.I_RS_Salary_Grade__c = 'TEST 1';
        insert salaryPerson;

        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     
        }
        
        insert salaryTableList;

        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Account_Organisation__c = orgs[0].Id;
        projectProposal.I_RS_Lead_Chief_Investigator__c = salaryPerson.Id;
        insert projectProposal;

        //Insert Budget, apply daily chargeout rate calculation
        Budget__c budget = TestUtility.newBudget(projectProposal.Id);
        budget.I_RS_Actual_Overhead__c = 30;
        budget.I_RS_Actual_Profit__c = 30;
        budget.I_RS_Actual_Non_Salary_Overhead__c = 30;

        insert budget;

        BudgetRateHelper.provideDailyChargeoutRates(new List<Budget__c>{budget});
        update budget;

        budget = [SELECT Id, I_RS_Total_Daily_Charge_Out_Rate_Formula__c from Budget__c WHERE Id = :budget.Id];
        System.assert(budget.I_RS_Total_Daily_Charge_Out_Rate_Formula__c > 0);
        Decimal initialDailyChargeoutRate = budget.I_RS_Total_Daily_Charge_Out_Rate_Formula__c;

        //Create Budget Line Items
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>{
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 0),
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 0)
        };
        budgetLineItems[0].I_RS_Contact__c = salaryPerson.Id;
        budgetLineItems[1].I_RS_Contact__c = salaryPerson.Id;

        budgetLineItems[0].I_RS_Organisation__c = orgs[0].Id;
        budgetLineItems[1].I_RS_Organisation__c = orgs[1].Id;

        insert budgetLineItems;


        Test.startTest();

        orgs[0].I_RS_Maximum_Allowed_On_Cost__c = orgs[1].I_RS_Maximum_Allowed_On_Cost__c;
        merge orgs[0] orgs[1];

        Test.stopTest();

        //Verify Budget chargeout rate has changed
        budget = [SELECT Id, I_RS_Maximum_Allowed_On_Cost__c from Budget__c WHERE Id = :budget.Id];
        System.assertequals(orgs[1].I_RS_Maximum_Allowed_On_Cost__c, budget.I_RS_Maximum_Allowed_On_Cost__c);

        //Verify Salary Items
        List<Budget_Line_Item__c> salaryItems = [
            SELECT Id, I_RS_Amount__c FROM Budget_Line_Item__c WHERE RecordType.DeveloperName = 'I_RS_Salary'];

        System.debug('Salary Item 0 cost '+salaryItems[0].I_RS_Amount__c);
        System.debug('Salary Item 1 cost '+salaryItems[1].I_RS_Amount__c);

        System.assert(salaryItems[0].I_RS_Amount__c > 0);
        System.assert(salaryItems[1].I_RS_Amount__c > 0);

        System.assertequals(salaryItems[0].I_RS_Amount__c, salaryItems[1].I_RS_Amount__c);

        //Verify Non-Salary Items
        List<Budget_Line_Item__c> nonSalaryItems = [
            SELECT Id, I_RS_Amount__c FROM Budget_Line_Item__c WHERE RecordType.Name = 'I_RS_Non_Salary'];


    }

    public static testmethod void testMergeContacts(){

        TestUtility.insertGSTRate();

        insert new On_Cost_Default_Values__c(
            Name = 'La Trobe University',
            I_RS_Maximum_Allowed_On_Cost__c = 35.88
        );

        Account org = TestUtility.newEmptyExternalAccount('Org One');
        insert org;

        List<Contact> salaryPersons = new List<Contact>{
            //TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null),
            //TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null)
            TestUtility.createContact(null),
            TestUtility.createContact(null)
        };
        salaryPersons[0].I_RS_Salary_Grade__c = 'TEST 1';
        salaryPersons[1].I_RS_Salary_Grade__c = 'JEST 1';
        insert salaryPersons;

        List<Salary_Table__c> salaryTableList = new List<Salary_Table__c>();
        Integer todaysYear = Date.today().year();
        for (Integer index=1; index<=10; index++){
            String currentYear = (todaysYear + index - 1) + '';
            salaryTableList.add(TestUtility.newSalaryTable('TEST', index, currentYear, 100000 + (1000 * index) ));     

            salaryTableList.add(TestUtility.newSalaryTable('JEST', index, currentYear, 200000 + (1000 * index) ));     
        }
        
        insert salaryTableList;

        Project_Proposal__c projectProposal = TestUtility.newProjectProposal();
        projectProposal.I_RS_Account_Organisation__c = org.Id;
        projectProposal.I_RS_Lead_Chief_Investigator__c = salaryPersons[0].Id;
        insert projectProposal;

        //
        //BUDGET AND LINE ITEM INITIAL CALCULATIONS
        //
        //Insert Budget, apply daily chargeout rate calculation
        Budget__c budget = TestUtility.newBudget(projectProposal.Id);
        budget.I_RS_Actual_Overhead__c = 30;
        budget.I_RS_Actual_Profit__c = 30;
        budget.I_RS_Actual_Non_Salary_Overhead__c = 30;

        insert budget;

        BudgetRateHelper.provideDailyChargeoutRates(new List<Budget__c>{budget});
        update budget;

        budget = [SELECT Id, I_RS_Daily_Salary__c from Budget__c WHERE Id = :budget.Id];
        System.assert(budget.I_RS_Daily_Salary__c > 0);
        Decimal initialDailyBaseSalary = budget.I_RS_Daily_Salary__c;

        //Create Budget Line Items
        List<Budget_Line_Item__c> budgetLineItems = new List<Budget_Line_Item__c>{
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 0),
            TestUtility.newBudgetLineItem(budget.Id, 'I_RS_Salary', 0)
        };
        budgetLineItems[0].I_RS_Contact__c = salaryPersons[0].Id;
        budgetLineItems[1].I_RS_Contact__c = salaryPersons[1].Id;

        budgetLineItems[0].I_RS_Organisation__c = org.Id;
        budgetLineItems[1].I_RS_Organisation__c = org.Id;

        insert budgetLineItems;

        //
        //ACTUAL TEST
        //
        Test.startTest();

        salaryPersons[0].I_RS_Salary_Grade__c = salaryPersons[1].I_RS_Salary_Grade__c;
        merge salaryPersons[0] salaryPersons[1];

        Test.stopTest();

        //Verify Budget chargeout rate has changed
        budget = [SELECT Id, I_RS_Maximum_Allowed_On_Cost__c from Budget__c WHERE Id = :budget.Id];

        //Verify Salary Items
        List<Budget_Line_Item__c> salaryItems = [
            SELECT Id, I_RS_Amount__c FROM Budget_Line_Item__c WHERE RecordType.DeveloperName = 'I_RS_Salary'];

        System.debug('Salary Item 0 cost '+salaryItems[0].I_RS_Amount__c);
        System.debug('Salary Item 1 cost '+salaryItems[1].I_RS_Amount__c);

        System.assert(salaryItems[0].I_RS_Amount__c > 0);
        System.assert(salaryItems[1].I_RS_Amount__c > 0);

        System.assertequals(salaryItems[0].I_RS_Amount__c, salaryItems[1].I_RS_Amount__c);

    }
}