public with sharing class EditableGridAutomationController {
    
    @AuraEnabled
    public static List<SObject> runAutomation(String methodName, List<SObject> records){
        
        System.debug('runAutomation '+methodName+records);
		List<SObject> output = new List<SObject>();
        switch on methodName{

            when 'calculateSalaries' {
                output.add(BudgetCalculatorAura.calculateSalaries((Budget_Line_Item__c) records[0]));
            }
            when 'applyGST' {
                output.add(BudgetCalculatorAura.getTotalIncludingGST((Budget_Line_Item__c) records[0]));
            }

        }

        System.debug(output);
        System.debug(JSON.serialize(output));
        return output; 

    }
    

}