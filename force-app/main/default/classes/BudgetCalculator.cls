public without sharing class BudgetCalculator {
    
    //Boolean returnOutputFieldsOnly = false;

    //BLI data
    List<Budget_Line_Item__c> bliInput;

    List<Budget_Line_Item__c> blisSalaryWithCalc = new List<Budget_Line_Item__c>();
    //List<Budget_Line_Item__c> blisSalaryWithoutCalc;

    //List<Budget_Line_Item__c> blisCollabSubcontractor;
    List<Budget_Line_Item__c> blisNonSalary = new List<Budget_Line_Item__c>();

    //Parent data
    public Map<Id, Budget__c> budgets;
    public Map<Id, Contact> contacts;
    public Map<Id, Account> funders;

    //Metadata
    Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Budget_Line_Item__c.getRecordTypeInfosByDeveloperName();
    Map<ID, Schema.RecordTypeInfo> recordTypesById = Schema.SObjectType.Budget_Line_Item__c.getRecordTypeInfosById();
    public List<Map<String, String>> yearColumnBundles = new List<Map<String, String>>{
        new Map<String, String>{
            'quantityField' => 'Year_1_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_1_Base_Salary__c',
            'costField' => 'Year_1_Cost__c'
        },
        new Map<String, String>{
            'quantityField' => 'Year_2_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_2_Base_Salary__c',
            'costField' => 'Year_2_Cost__c'
        },
        new Map<String, String>{
            'quantityField' => 'Year_3_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_3_Base_Salary__c',
            'costField' => 'Year_3_Cost__c'
        },
        new Map<String, String>{
            'quantityField' => 'Year_4_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_4_Base_Salary__c',
            'costField' => 'Year_4_Cost__c'
        },
        new Map<String, String>{
            'quantityField' => 'Year_5_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_5_Base_Salary__c',
            'costField' => 'Year_5_Cost__c'
        },
        new Map<String, String>{
            'quantityField' => 'Year_6_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_6_Base_Salary__c',
            'costField' => 'Year_6_Cost__c'
        },
        new Map<String, String>{
            'quantityField' => 'Year_7_Quantity__c',
            'baseSalaryField' => 'I_RS_Year_7_Base_Salary__c',
            'costField' => 'Year_7_Cost__c'
        }
    };
        
    public List<Apex_Debug_Log__c> apexDebugLogs = new List<Apex_Debug_Log__c>();
        

    public BudgetCalculator(List<Budget_Line_Item__c> bliInput){

        System.debug('BudgetCalcaultor '+bliInput);

        this.bliInput = bliInput;

        funders = getFunders(bliInput);
        budgets = getBudgets(bliInput);
        
        for (Budget_Line_Item__c bli : bliInput){

            resetAmountFields(bli);

            System.debug('recordTypeId '+bli.recordtypeId);
            String bliRecordTypeName = recordTypesById.get(bli.recordTypeId).getDeveloperName();
            System.debug('recordtypeName '+bliRecordTypeName);
            switch on bliRecordTypeName {
                when 'I_RS_Salary' {
                    if (
                        bli.I_RS_Category__c != NULL &&    
                        bli.I_RS_Category__c != 'Non-La Trobe Researcher' &&
                        (
                            (bli.I_RS_Category__c == 'Current La Trobe staff' && bli.I_RS_Contact__c != NULL) || 
                         	(bli.I_RS_Category__c != 'Current La Trobe staff' && bli.I_RS_Sub_Category__c != NULL)
                        ) &&
                        bli.I_RS_Organisation__c != NULL &&
                        bli.I_RS_Unit_of_Time__c != NULL
                    ){

                        blisSalaryWithCalc.add(bli);
                        
                        /*else 
                            blisSalaryWithoutCalc.add(bli);*/
                    }
                }
                when 'I_RS_Non_Salary' {blisNonSalary.add(bli);}
            }
        }
        if (!blisSalaryWithCalc.isEmpty()){
            contacts = getContacts(bliInput);
        }

    }

    //Currently only works for existing BLIs
    public void recalculateAndSave(){

        calculate();

        System.debug(bliInput[0].I_RS_Amount__c);

        System.debug('Saving...');

        List<Database.SaveResult> updateResults = Database.update(bliInput, false);
        GlobalUtility.constructErrorLogsForDMLErrors(
            updateResults, bliInput, 'BudgetCalculator', 'recalculateAndSave');

    }

    public void calculate(){

        System.debug('calculate');

        if (!blisSalaryWithCalc.isEmpty()){
            calculateSalaryWithSalaryTable();
        }
        if (!blisNonSalary.isEmpty()){
            calculateNonSalary();
        }

        if (!apexDebugLogs.isEmpty()){
            insert apexDebugLogs;
        }

    }



    void calculateSalaryWithSalaryTable(){

        System.debug('run salary calculation');

        BudgetCalculatorSalary.calculateSalaries(this, blisSalaryWithCalc);

        for (Budget_Line_Item__c bli : blisSalaryWithCalc){
            if (funderIsEligibleForGST(bli) == true && isInKind(bli) == false){
                applyGST(bli);
            }
        }

    }

    /*void calculateSalaryTableWithSumming(){

    }*/


    void calculateNonSalary(){

        for (Budget_Line_Item__c bli : blisNonSalary){
            calculateYearCostsByAmountAndQty(bli);

            if (bli.I_RS_Category__c != 'Adjustment' && !isInKind(bli) && 
                bli.I_RS_Organisation__c != null && hasExternalFunder(bli)){
                applyNonSalaryOverhead(bli);
            }

            calculateTotalCostByTallyingYearCosts(bli);

            if (funderIsEligibleForGST(bli) == true && isInKind(bli) == false){
                applyGST(bli);
            }
            else {
                bli.I_RS_Cash_Amount_Inc_GST_Currency__c = bli.I_RS_Amount__c;
            }
        }
        

    }



    void applyNonSalaryOverhead(Budget_Line_Item__c bli){
        Budget__c budget = budgets.get(bli.I_RS_Budget__c);

        Decimal nonSalaryOverhead = (Decimal) budget.I_RS_Actual_Non_Salary_Overhead__c;

        if (nonSalaryOverhead != null){
            for (Map<String, String> bundle : yearColumnBundles){
                String yearCostField = bundle.get('costField');
                Decimal yearCost = (Decimal) bli.get(yearCostField);
    
                bli.put(yearCostField, yearCost * ((nonSalaryOverhead / 100) + 1));
            }
        }
        else {
            recordFailedRow(
                'Non-Salary Budget Line Item cannot be recalculated '+
                'as Budget is missing Actual Non-Salary Overhead',
                'Error', bli);
        }
    }


    Boolean funderIsEligibleForGST(Budget_Line_Item__c bli){
        System.debug('funderIsEligibleForGST');
        if (bli.I_RS_Organisation__c != null){
            Account funder = funders.get(bli.I_RS_Organisation__c);
            System.debug('funder '+funder);

            return !funder.I_RS_Part_of_La_Trobe__c && funder.I_RS_Include_GST_In_Budgeting__c;
        }
        return null;
    }

    Boolean hasExternalFunder(Budget_Line_Item__c bli){
        System.debug('hasExternalFunder');
        if (bli.I_RS_Organisation__c != null){
            Account funder = funders.get(bli.I_RS_Organisation__c);
            System.debug('funder '+funder);

            return !funder.I_RS_Part_of_La_Trobe__c;
        }
        return false;
    }

    Boolean isInKind(Budget_Line_Item__c bli){
        return bli.I_RS_In_Kind__c;
    }


    void applyGST(Budget_Line_Item__c bli){

        Decimal gstAmount = GST__c.getOrgDefaults().I_RS_Current_Rate__c;
        bli.I_RS_Cash_Amount_Inc_GST_Currency__c = 
            bli.I_RS_Amount__c * ((gstAmount / 100) + 1);

    }

    void calculateYearCostsByAmountAndQty(Budget_Line_Item__c bli){
    
        for (Map<String, String> bundle : yearColumnBundles){

            String yearQtyField = bundle.get('quantityField');
            Decimal yearQty = (Decimal) bli.get(yearQtyField);

            String yearCostField = bundle.get('costField');

            if (bli.Unit_Price__c != null && yearQty != null){
                
                Decimal yearCost = yearQty * bli.Unit_Price__c;
                bli.put(yearCostField, yearCost); 
            }
            else {
                bli.put(yearCostField, 0); 
            }

        }

    }

    void calculateTotalCostByTallyingYearCosts(Budget_Line_Item__c bli){

        Decimal totalCost = 0;
        for (Map<String, String> bundle : yearColumnBundles){

            String yearCostField = bundle.get('costField');
            Decimal yearCost = (Decimal) bli.get(yearCostField);

            if (yearCost != null)
                totalCost += yearCost;
            else {
                totalCost += 0;
            }

        }
        bli.I_RS_Amount__c = totalCost;

    }


    Map<Id, Budget__c> getBudgets(List<Budget_Line_Item__c> budgetLineItems){
        Set<Id> budgetIds = GlobalUtility.getParentIds(budgetLineItems, 'I_RS_Budget__c');
        List<Budget__c> budgets = [SELECT Id, I_RS_Year_1_Starts__c, I_RS_Project_End_Date__c, 
        I_RS_Project_Proposal__r.I_RS_Project_Duration_In_Years__c, I_RS_Actual_Overhead__c,
            I_RS_Actual_Profit__c, I_RS_Actual_Non_Salary_Overhead__c FROM Budget__c WHERE Id IN :budgetIds];
        System.debug('budgets '+budgets);
        
        return new Map<Id, Budget__c>(budgets);
    }


    Map<Id, Contact> getContacts(List<Budget_Line_Item__c> budgetLineItems){
        Set<Id> contactIds = GlobalUtility.getParentIds(budgetLineItems, 'I_RS_Contact__c');
        List<Contact> contacts = [SELECT Id, I_RS_Salary_Grade__c
                FROM Contact WHERE Id IN :contactIds];
        System.debug('contacts '+contacts);
        
        return new Map<Id, Contact>(contacts);
    }

    Map<Id, Account> getFunders(List<Budget_Line_Item__c> budgetLineItems){

        Set<Id> funderIds = GlobalUtility.getParentIds(budgetLineItems, 'I_RS_Organisation__c');
        List<Account> funders = [SELECT Id, I_RS_Maximum_Allowed_On_Cost__c, 
            I_RS_Part_of_La_Trobe__c, I_RS_Include_GST_In_Budgeting__c FROM Account WHERE Id IN :funderIds]; 

        System.debug('Funders '+funders);

        return new Map<Id, Account>(funders);

    }

    
    public void recordFailedRow(String message, String logType, SObject failedRow){
        apexDebugLogs.add(
            new Apex_Debug_Log__c(
                Log_Type__c = logType,
                Apex_Class_Name__c = 'BudgetCalculatorSalary',
                Apex_Class_Method_Name__c = 'calculateSalaries',
                Exception_message__c = message,
                Request_Data__c = JSON.serializePretty(failedRow),
                Related_To_Id__c = (String) failedRow.get('Id')
        	)
        );
    }


    void resetAmountFields(Budget_Line_Item__c bli){

        bli.I_RS_Amount__c = 0;
        bli.I_RS_Year_1_Base_Salary__c = 0;
        bli.I_RS_Year_2_Base_Salary__c = 0;
        bli.I_RS_Year_3_Base_Salary__c = 0;
        bli.I_RS_Year_4_Base_Salary__c = 0;
        bli.I_RS_Year_5_Base_Salary__c = 0;
        bli.I_RS_Year_6_Base_Salary__c = 0;
        bli.I_RS_Year_7_Base_Salary__c = 0;
        bli.Year_1_Cost__c = 0;
        bli.Year_2_Cost__c = 0;
        bli.Year_3_Cost__c = 0;
        bli.Year_4_Cost__c = 0;
        bli.Year_5_Cost__c = 0;
        bli.Year_6_Cost__c = 0;
        bli.Year_7_Cost__c = 0;
        bli.I_RS_Short_Fall__c = 0;
    
    }


}