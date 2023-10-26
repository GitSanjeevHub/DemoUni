public class BudgetRateHelper {

    public static Integer yearlyToDailyRateDivider = 235;
    
    
    public static Map<String, Overheads_and_Profit_Default_Values__c> getDefaultRateValueMap(){
        
        Map<String, Overheads_and_Profit_Default_Values__c> defaultRateValueMap = 
            new Map<String, Overheads_and_Profit_Default_Values__c>();
          
        for (Overheads_and_Profit_Default_Values__c defaultValue : [
            select Id, 
            	I_RS_Rate_Type__c, 
            	I_RS_Overhead__c, 
            	I_RS_Profit__c, 
            I_RS_Non_Salary_Overhead__c
            from Overheads_and_Profit_Default_Values__c]){
         
            defaultRateValueMap.put(defaultValue.I_RS_Rate_Type__c, defaultValue);
        }
        
        return defaultRateValueMap;
    }

    
    
  
    public static List<Budget__c> provideActualRatesBasedOnRateType(Budget__c[] budgetsToProcess){
        
        Map<String, Overheads_and_Profit_Default_Values__c> defaultRateValueMap =
            getDefaultRateValueMap();

            
        for (Budget__c budget : budgetsToProcess){
            
            String rateType = budget.I_RS_Actual_Rate_Type__c;
            if (rateType != null){
            	Overheads_and_Profit_Default_Values__c defaultValue = defaultRateValueMap.get(rateType);

				System.debug(defaultValue);
                
                //if (defaultValue != null){
                    budget.I_RS_Actual_Overhead__c = defaultValue.I_RS_Overhead__c;
                    budget.I_RS_Actual_Profit__c = defaultValue.I_RS_Profit__c;
                    budget.I_RS_Actual_Non_Salary_Overhead__c = defaultValue.I_RS_Non_Salary_Overhead__c;
                //}
            }
            
            system.debug(budget);
        }
        
        return budgetsToProcess;
    }

    @AuraEnabled
    public static List<Budget__c> provideActualRatesBasedOnRateType_Aura(List<Budget__c> budgetsToProcess) {
        System.debug('provideActualRatesBasedOnRateType_Aura');
        
        return provideActualRatesBasedOnRateType(budgetsToProcess);
    }   
    
    @InvocableMethod(label='Assign Budget Rate Values' description='Assign Rate values to Budget based on Actual Rate Type')  
    public static List<Budget__c> provideActualRatesBasedOnRateType_Flow(List<Budget__c> budgetsToProcess) {
        System.debug('provideActualRatesBasedOnRateType_Flow');
        
        return provideActualRatesBasedOnRateType(budgetsToProcess);
    }   
    
    
    
    
    
    public static List<Budget__c> provideDailyChargeoutRates(List<Budget__c> budgetsToProcess){
        
		Map<Id, Budget__c> budgetMap = new Map<Id, Budget__c>(budgetsToProcess);
        Set<Id> budgetIds = budgetMap.keySet();
        
		List<Budget__c> budgetListInclParentData = [
            select Id, 
            I_RS_Year_1_Starts__c,
            I_RS_Project_Proposal__r.I_RS_Lead_Chief_Investigator__r.I_RS_Salary_Grade__c
            from Budget__c where Id in :budgetIds
        ];

        On_Cost_Default_Values__c ltuMaxOnCost = On_Cost_Default_Values__c.getInstance('La Trobe University');
        
        Map<String, Salary_Table__c> salaryTableMap = getSalaryTableMapForBudgetLCIs(budgetListInclParentData);
        
        for (Budget__c budget : budgetListInclParentData){
            
            String salaryGradeName = budget.I_RS_Project_Proposal__r.I_RS_Lead_Chief_Investigator__r.I_RS_Salary_Grade__c;
            Decimal budgetStartYear = budget.I_RS_Year_1_Starts__c;

            String salaryTableMapKey = salaryGradeName+'|'+budgetStartYear;
            
            Salary_Table__c matchingSalaryTable = salaryTableMap.get(salaryTableMapKey);
            
            Budget__c budgetToProcess = budgetMap.get(budget.Id);
            
            if (matchingSalaryTable != null){
                
                Decimal year1BaseSalary = matchingSalaryTable.I_RS_Salary__c;
                
                Decimal onCostPercentage = ltuMaxOnCost.I_RS_Maximum_Allowed_On_Cost__c / 100;
                
                Decimal overheadPercentage = 
                    (budgetToProcess.I_RS_Actual_Overhead__c != null ? 
                     	budgetToProcess.I_RS_Actual_Overhead__c / 100 :
                    	0);
                
                Decimal profitPercentage = 
                    (budgetToProcess.I_RS_Actual_Profit__c != null ? 
                     	budgetToProcess.I_RS_Actual_Profit__c / 100 :
                    	0);
                
                Decimal nonSalaryOverheadPercentage = 
                    (budgetToProcess.I_RS_Actual_Non_Salary_Overhead__c != null ? 
                     	budgetToProcess.I_RS_Actual_Non_Salary_Overhead__c / 100 :
                    	0);
                
                System.debug('overheadPercentage '+overheadPercentage);
                
                Decimal onCostAmountYearly = year1BaseSalary * onCostPercentage;
                Decimal overheadAmountYearly = (year1BaseSalary + onCostAmountYearly) * overheadPercentage ;
                Decimal profitAmountYearly = (year1BaseSalary + onCostAmountYearly) * profitPercentage;
                Decimal nonSalaryOverheadAmountYearly = year1BaseSalary * nonSalaryOverheadPercentage;

                System.debug('onCostAmountYearly '+onCostAmountYearly);
                System.debug('overheadAmountYearly '+overheadAmountYearly);
                System.debug('profitAmountYearly '+profitAmountYearly);
                System.debug('nonSalaryOverheadAmountYearly '+nonSalaryOverheadAmountYearly);
                
				budgetToProcess.I_RS_Base_Salary__c = year1BaseSalary;
                
                budgetToProcess.I_RS_Daily_On_Costs__c = (onCostAmountYearly / yearlyToDailyRateDivider).setScale(2);
                budgetToProcess.I_RS_Daily_Overheads__c = (overheadAmountYearly / yearlyToDailyRateDivider).setScale(2);
                budgetToProcess.I_RS_Daily_Profits__c = (profitAmountYearly/ yearlyToDailyRateDivider).setScale(2);
                budgetToProcess.I_RS_Daily_Salary__c = (year1BaseSalary / yearlyToDailyRateDivider).setScale(2);

            }
            else {
                budgetToProcess.I_RS_Daily_On_Costs__c = 0;
                budgetToProcess.I_RS_Daily_Overheads__c = 0;
                budgetToProcess.I_RS_Daily_Profits__c = 0;
                budgetToProcess.I_RS_Daily_Salary__c = 0;   
            }
            
            System.debug('budgetToProcess '+budgetToProcess);
            
        }
        
        return budgetsToProcess;
        
    }
    
    @AuraEnabled
    public static List<Budget__c> provideDailyChargeoutRates_Aura(List<Budget__c> budgetsToProcess){
        System.debug('provideDailyChargeoutRates_Aura');
        return provideDailyChargeoutRates(budgetsToProcess);
    }
    
	/*@InvocableMethod(label='Assign Budget Daily Chargeout Rate Values' description='Calculate Budget Daily Chargeout Rate fields')  
    public static List<Budget__c> provideDailyChargeoutRates_Flow(List<Budget__c> budgetsToProcess){
        System.debug('provideDailyChargeoutRates_Flow');
        return provideDailyChargeoutRates(budgetsToProcess);
    }    */
    
    
    static Map<String, Salary_Table__c> getSalaryTableMapForBudgetLCIs(Budget__c[] budgets){
        
        Map<String, Salary_Table__c> salaryTableUniqueMap = new Map<String, Salary_Table__c>();
        
        Set<String> salaryGradeCodes = new Set<String>();
        for (Budget__c budget : budgets){
            String salaryGrade = budget.I_RS_Project_Proposal__r.I_RS_Lead_Chief_Investigator__r.I_RS_Salary_Grade__c;
            if (salaryGrade != null)
                salaryGradeCodes.add(salaryGrade);
        }
        System.debug(salaryGradeCodes);
        
        List<Salary_Table__c> salaryTableList = [SELECT Id, Name, I_RS_HR_System_Group_ID__c, I_RS_Year__c, I_RS_Salary__c FROM Salary_Table__c WHERE
                                                I_RS_HR_System_Group_ID__c IN :salaryGradeCodes];
        System.debug(salaryTableList);
        
        for (Salary_Table__c salaryTableRecord : salaryTableList){
            
            salaryTableUniqueMap.put(
                salaryTableRecord.I_RS_HR_System_Group_ID__c+'|'+salaryTableRecord.I_RS_Year__c,
                //salaryTableRecord.Name+'|'+salaryTableRecord.I_RS_Year__c,
                salaryTableRecord);
            
        }
        
        return salaryTableUniqueMap;
        
    }
    
}