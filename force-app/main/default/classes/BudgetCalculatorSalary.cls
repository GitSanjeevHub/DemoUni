public without sharing class BudgetCalculatorSalary {
    

    public static List<Budget_Line_Item__c> calculateSalaries(BudgetCalculator data, List<Budget_Line_Item__c> budgetLineItemsInput){
        
        List<Budget_Line_Item__c> budgetLineItemsOutput = new List<Budget_Line_Item__c>();
        
        
        // Fetching custom setting to check if there are any shortfalls
        On_Cost_Default_Values__c latrobeDefaultOnCost = [SELECT Id, Name, I_RS_Maximum_Allowed_On_Cost__c FROM On_Cost_Default_Values__c WHERE Name = 'La Trobe University'];


        List<Map<String, Salary_Table__c>> salaryTableMap = getSalaryTableMap(budgetLineItemsInput, data.contacts);
        Map<String, Salary_Table__c> salaryTableMapUnique = salaryTableMap[0];
        Map<String, Salary_Table__c> salaryTableMapFirstMatchingGroup = salaryTableMap[1];
            

        for (Integer outputIndex=0; outputIndex<budgetLineItemsInput.size(); outputIndex++){

            Budget_Line_Item__c budgetLineItemInput = budgetLineItemsInput[outputIndex];
            Budget_Line_Item__c budgetLineItemOutput = budgetLineItemsInput[outputIndex];

            budgetLineItemOutput.I_RS_Amount__c = 0;
            budgetLineItemOutput.I_RS_Short_Fall__c = 0;

            System.debug('Beginning calculation for '+budgetLineItemOutput);
            
            //Key fields
            //Id budgetId = budgetLineItemOutput[outputIndex].I_RS_Budget__c;
            Budget__c budget = data.budgets.get(budgetLineItemInput.I_RS_Budget__c);
            Account lineItemFundingBody = data.funders.get(budgetLineItemInput.I_RS_Organisation__c);
            
            Integer calendarYear = (Integer) budget.I_RS_Year_1_Starts__c;
            Integer projectDuration = (Integer) budget.I_RS_Project_Proposal__r.I_RS_Project_Duration_In_Years__c; //formula on budget
        
            System.debug('calendarYear '+calendarYear);
            System.debug('projectDuration '+projectDuration);

            Salary_Table__c initialSalaryTable = getInitialSalaryTable(budgetLineItemInput, data.contacts, salaryTableMapFirstMatchingGroup);
            
            if (initialSalaryTable != null){
                String salaryGradeGroup = initialSalaryTable.I_RS_Salary_Grade_Group__c;
                Decimal salaryGradeLevelNumber = initialSalaryTable.I_RS_Salary_Grade_Group_Number__c;
    
                for (Integer yearArrayIndex=0; yearArrayIndex<projectDuration && yearArrayIndex < 7; yearArrayIndex++)
                { 
                    System.debug('>>>yearArrayIndex '+yearArrayIndex);
                    system.debug('calendarYear>>>>' + calendarYear);
                    system.debug('salaryGradeLevelNumber+++' + salaryGradeLevelNumber);
                    
                    Decimal yearSalaryCostOutput = 0;
    
                    Map<String, String> yearColumnBundle = data.yearColumnBundles.get(yearArrayIndex);
                    system.debug('yearColumnBundle>>>' + yearColumnBundle);
    
                    String baseSalaryField = yearColumnBundle.get('baseSalaryField');
                    String quantityField = yearColumnBundle.get('quantityField');
                    String costField = yearColumnBundle.get('costField');
    
    
                    Salary_Table__c salaryRecordToCalculate = salaryTableMapUnique.get(
                        salaryGradeGroup +'|'+ salaryGradeLevelNumber + '|' + string.valueOf(calendarYear)
                    );
    
    
    
                    system.debug('salaryRecordToCalculate>>>>' + salaryRecordToCalculate);
                    if(salaryRecordToCalculate != null)
                    {
                        //Init year cost field
                        yearSalaryCostOutput = salaryRecordToCalculate.I_RS_Salary__c;
    
                        //Set base salary field and apply multipliers
                        Decimal baseSalary = salaryRecordToCalculate.I_RS_Salary__c;
                        System.debug('yearSalarybaseSalary '+baseSalary);
    
                        baseSalary = applyQuantityAndUnitOfTime(baseSalary, budgetLineItemInput, quantityField);
                        budgetLineItemOutput.put(baseSalaryField, baseSalary);
    
                        Boolean applyAdditionalRates = budgetLineItemInput.I_RS_Category__c != 'Student' && budgetLineItemInput.I_RS_Category__c != 'Non-La Trobe researcher';
                        if(applyAdditionalRates)
                        {
                            
                            if (!budgetLineItemInput.I_RS_In_Kind__c){
                                Decimal shortFall = getShortFall(baseSalary, 
                                    latrobeDefaultOnCost.I_RS_Maximum_Allowed_On_Cost__c, 
                                    lineItemFundingBody.I_RS_Maximum_Allowed_On_Cost__c
                                    ).setScale(2);
                                System.debug('shortfall for year '+shortFall);
                                
                                budgetLineItemOutput.I_RS_Short_Fall__c += shortFall;
                            }
                                
                            Decimal maxAllowedOncost = lineItemFundingBody.I_RS_Maximum_Allowed_On_Cost__c;
                            system.debug('maxAllowedOncost>>>' + maxAllowedOncost);
                            yearSalaryCostOutput = applyMaxOnCost(yearSalaryCostOutput, maxAllowedOncost);
                            System.debug('yearSalaryCostOutputAfterApplyingOnCost>>>'+yearSalaryCostOutput);
    
                            //Apply profit and overhead for external and in cash salary items
                            Boolean externalCashSalaryItem = !lineItemFundingBody.I_RS_Part_of_La_Trobe__c && !budgetLineItemInput.I_RS_In_Kind__c;
                            if(externalCashSalaryItem)
                            {
                                Decimal overhead = budget.I_RS_Actual_Overhead__c;
                                Decimal profit = budget.I_RS_Actual_Profit__c;
                                system.debug('OverHead>>>' + overhead);
                                system.debug('Profit>>>' + profit);
    
                                yearSalaryCostOutput = applyProfitAndOverHead(yearSalaryCostOutput, profit, overhead);
                                System.debug('yearSalaryCostOutputAfterApplyingProfitAndOverhead>>>'+yearSalaryCostOutput);
    
                            }
                        }
                        
                        yearSalaryCostOutput = applyQuantityAndUnitOfTime(yearSalaryCostOutput, budgetLineItemInput, quantityField);
                        System.debug('yearSalaryCostOutputAfterApplyingQuantity>>>' + yearSalaryCostOutput);
    
                        //Round to 2 decimal places
                        yearSalaryCostOutput = yearSalaryCostOutput.setScale(2);
    
    
                        budgetLineItemOutput.put(costField, yearSalaryCostOutput);
                        budgetLineItemOutput.I_RS_Amount__c += yearSalaryCostOutput;
                        budgetLineItemOutput.I_RS_Cash_Amount_Inc_GST_Currency__c = budgetLineItemOutput.I_RS_Amount__c;
    
                        
    
    
                        String salaryTableForNextYearNextLevel =
                            salaryGradeGroup +'|'+ (salaryGradeLevelNumber+1) + '|' + string.valueOf(calendarYear+1);
                        String salaryTableForNextYearSameLevel = 
                            salaryGradeGroup +'|'+ salaryGradeLevelNumber + '|' + string.valueOf(calendarYear+1);
    
                        System.debug('salaryTableForNextYearNextLevel '+salaryTableForNextYearNextLevel);
                        System.debug('salaryTableForNextYearSameLevel '+salaryTableForNextYearSameLevel);
                       
                        System.debug('Available keys '+salaryTableMapUnique.keySet());
    
                        if (salaryTableMapUnique.get(salaryTableForNextYearNextLevel) != null){
                            System.debug('next level found');
                            salaryGradeLevelNumber++;
                            calendarYear++;
                        }
                        else if (salaryTableMapUnique.get(salaryTableForNextYearSameLevel) != null){
                            System.debug('This level found');
                            calendarYear++;
                        }
                        else {
                            System.debug('No matches found at all. Breaking...');
                            break;
                        }
                    }
                
                }  
                
                
                System.debug(budgetLineItemOutput.I_RS_Amount__c);
                
            }
            else {
                data.recordFailedRow(
                    'FYI: This Budget Line Item could not find a matching Salary Grade so no salary calculation was performed', 
                    'Warning',
                    budgetLineItemOutput);
            }

        }

        
        //Return line item. DO NOT SAVE IT TO DATABASE - this will happen on lwc component or other method
        return budgetLineItemsOutput;
        
        
    }  

    

    static Salary_Table__c getInitialSalaryTable(Budget_Line_Item__c budgetLineItem, 
    Map<Id, Contact> contacts, Map<String, Salary_Table__c> salaryTableMapFirstMatchingGroup){

        Boolean searchByCodeOnBLI = budgetLineItem.I_RS_Sub_Category__c != null && 
        budgetLineItem.I_RS_Sub_Category__c != 'Not Applicable';

        if (searchByCodeOnBLI){
            return salaryTableMapFirstMatchingGroup.get(
                budgetLineItem.I_RS_Sub_Category__c);
        }
        else {
            Contact matchingContact = contacts.get(budgetLineItem.I_RS_Contact__c);
            return salaryTableMapFirstMatchingGroup.get(
                matchingContact.I_RS_Salary_Grade__c);
        }

    }


    



    


     

    static List<Map<String, Salary_Table__c>> getSalaryTableMap (List<Budget_Line_Item__c> budgetLineItems, Map<Id, Contact> contacts){

        List<Set<String>> salaryTableCodes = getSalaryTableCodes(budgetLineItems, contacts);
        
        List<Salary_Table__c> salaryTables = getSalaryTableItemsByCodes(salaryTableCodes);

        return constructSalaryTableMap(salaryTables);
    }

    
    static List<Set<String>> getSalaryTableCodes(List<Budget_Line_Item__c> budgetLineItems, Map<Id, Contact> contacts){
        
        System.debug('getSalaryTableCodes');
        
        List<Set<String>> codeSets = new List<Set<String>>();
        Set<String> standardCodes = new Set<String>();
        Set<String> hrCodes = new Set<String>();

        for (Budget_Line_Item__c budgetLineItem : budgetLineItems) {      

            system.debug('bli '+budgetLineItem);
            
            Boolean searchByCodeOnBLI = budgetLineItem.I_RS_Sub_Category__c != null && 
                budgetLineItem.I_RS_Sub_Category__c != 'Not Applicable';

            if (searchByCodeOnBLI){
                String standardCode = budgetLineItem.I_RS_Sub_Category__c;
                if (standardCode != null)
                    standardCodes.add(standardCode);
            }
            else {
                Contact matchingContact = contacts.get(budgetLineItem.I_RS_Contact__c);
                String hrCode = matchingContact.I_RS_Salary_Grade__c;
                if (hrCode != null)
                    hrCodes.add(hrCode);
            }

        }
        System.debug(standardCodes);
        System.debug(hrCodes);

        codeSets.add(standardCodes);
        codeSets.add(hrCodes);

        return codeSets;

    }



    static List<Salary_Table__c> getSalaryTableItemsByCodes(List<Set<String>> salaryTableCodes){

        Set<String> standardCodes = salaryTableCodes[0];
        Set<String> hrCodes = salaryTableCodes[1];    
        
        Set<String> salaryGradeGroups = new Set<String>();

        for(Salary_Table__c salaryTableInitialMatch : [SELECT 
            I_RS_Salary_Grade_Group__c
            FROM Salary_Table__c 
            WHERE Name IN :standardCodes OR I_RS_HR_System_Group_ID__c IN :hrCodes]){
                salaryGradeGroups.add(salaryTableInitialMatch.I_RS_Salary_Grade_Group__c);
            }

        return [SELECT Id, Name, I_RS_HR_System_Group_ID__c, I_RS_Salary__c, I_RS_Year__c, 
                    I_RS_Salary_Grade_Group__c, I_RS_Salary_Grade_Group_Number__c
                FROM Salary_Table__c 
                 WHERE I_RS_Salary_Grade_Group__c IN :salaryGradeGroups];

        
    }


    static List<Map<String, Salary_Table__c>> constructSalaryTableMap(List<Salary_Table__c> salaryTableList){

        System.debug('constructSalaryTableMap');
        System.debug(salaryTableList);

        List<Map<String, Salary_Table__c>> salaryTableMaps = new List<Map<String, Salary_Table__c>>();
        Map<String, Salary_Table__c> salaryTableMapUnique = new Map<String, Salary_Table__c>(); 
        Map<String, Salary_Table__c> salaryTableMapFirstMatchingGroup = new Map<String, Salary_Table__c>(); 
        
        for(Salary_Table__c salary : salaryTableList)
        {
            String salaryTableKey;

            if(salary.I_RS_Salary_Grade_Group_Number__c != null){
                salaryTableKey = salary.I_RS_Salary_Grade_Group__c + '|' + salary.I_RS_Salary_Grade_Group_Number__c + '|' + salary.I_RS_Year__c;   
            }
            else {
                salaryTableKey = salary.I_RS_Salary_Grade_Group__c + '|' + 0 + '|' + salary.I_RS_Year__c; 
            }
            
            System.debug('salaryTableKey '+salaryTableKey);
            System.debug('salary ' + salary);

            salaryTableMapUnique.put(salaryTableKey, salary); 

            salaryTableMapFirstMatchingGroup.put(salary.Name, salary);
            salaryTableMapFirstMatchingGroup.put(salary.I_RS_HR_System_Group_ID__c, salary);
            
        }
        system.debug('salaryTableMapUnique>>>>' + salaryTableMapUnique.keySet());
        system.debug('salaryTableMapFirstMatchingGroup>>>>' + salaryTableMapFirstMatchingGroup.keySet());

        salaryTableMaps.add(salaryTableMapUnique);
        salaryTableMaps.add(salaryTableMapFirstMatchingGroup);

        return salaryTableMaps;
    }


    static Decimal getShortFall(Decimal baseSalary, Decimal benchmarkOnCost, Decimal onCostToSubtract){

        System.debug('getShortfall '+baseSalary+' '+benchmarkOnCost+' '+onCostToSubtract);
        Decimal shortFall = (((baseSalary * benchmarkOnCost)/100) - ((baseSalary * onCostToSubtract)/100)).setScale(2);
        system.debug('>>>shortFall ' + shortFall);

        if (shortFall != null)
            return shortFall;
        else 
            return 0;

    }

    static Decimal applyMaxOnCost(Decimal inputSalaryAmount, Decimal maxAllowedOncost){
        
        System.debug('applyMaxOnCost '+inputSalaryAmount+' '+maxAllowedOncost);
        Decimal maxOnCost = (inputSalaryAmount + (inputSalaryAmount * maxAllowedOncost)/100);
        System.debug('>>>maxOnCost '+maxOnCost);
        return maxOnCost;
    }


    static Decimal applyProfitAndOverHead(Decimal inputSalaryAmount, Decimal profit, Decimal overhead){

        System.debug('applyProfitAndOverHead '+inputSalaryAmount+' '+profit+' '+overhead);

        if (profit == null)
            profit = 0;
        if (overhead == null)
            overhead = 0;
        
        Decimal totalAdd = profit + overhead;
        system.debug('total>>> ' + totalAdd);

        Decimal outputSalaryAmount = inputSalaryAmount + (inputSalaryAmount * totalAdd)/100;
        System.debug('>>>outputSalaryAmount '+outputSalaryAmount);
        return outputSalaryAmount;

    }


    static Decimal applyQuantityAndUnitOfTime(Decimal yearlyAmount, Budget_Line_Item__c budgetLineItem, String quantityField){

        Decimal output = yearlyAmount;

        Decimal quantity = (Decimal) budgetLineItem.get(quantityField);
        output = applyQuantity(output, quantity);

        output = applyUnitOfTime(output, budgetLineItem.I_RS_Unit_of_Time__c);

        return output;

    }


    static Decimal applyUnitOfTime(Decimal yearSalaryCostOutput, String unitOfTime){

        switch on unitOfTime {
            when 'Years' {
                return yearSalaryCostOutput;
            }
            when 'Months'{
                return yearSalaryCostOutput/12.0;
            }
            when 'Weeks'{
                return yearSalaryCostOutput/47.0;
            }
            when 'Days'{
                return yearSalaryCostOutput/235.0;
            }
            when 'Hours'{
                return yearSalaryCostOutput/1645.0;
            }
        }
        return null;
    }
    
    static Decimal applyQuantity(Decimal inputSalaryAmount, Decimal quantity){

        if (quantity == null)
            return 0;
        else 
            return inputSalaryAmount * quantity;

    }

}