public without sharing class AccountTriggerHelper {
    
    public static void handleBudgetRelatedFieldChanges(List<Account> accountsAfterDML, 
        Map<Id, Account> accountsBeforeDML){

            System.debug('handleBudgetRelatedFieldChanges');

            Set<Id> orgIdsToRecalculateBudgetsFor = new Set<Id>();

            for (Account accountAfterDML : accountsAfterDML){

                System.debug('Organisation changed?');

                Account accountBeforeDML = accountsBeforeDML.get(accountAfterDML.Id);
                
                Boolean partOfLaTrobeChanged = 
                    accountBeforeDML.I_RS_Part_Of_La_Trobe__c != accountAfterDML.I_RS_Part_Of_La_Trobe__c;
                System.debug('partOfLaTrobeChanged '+partOfLaTrobeChanged);

                Boolean maxOnCostChanged = 
                    accountBeforeDML.I_RS_Maximum_allowed_on_cost__c != accountAfterDML.I_RS_Maximum_allowed_on_cost__c;
                System.debug('maxOnCostChanged '+maxOnCostChanged);

                Boolean applyGSTChanged = 
                    accountBeforeDML.I_RS_Include_GST_In_Budgeting__c != accountAfterDML.I_RS_Include_GST_In_Budgeting__c;
                System.debug('applyGSTChanged '+applyGSTChanged);

                if (partOfLaTrobeChanged || maxOnCostChanged || applyGSTChanged){
                    orgIdsToRecalculateBudgetsFor.add(accountAfterDML.Id);
                }
                    
            }

            System.debug(orgIdsToRecalculateBudgetsFor);

            if (!orgIdsToRecalculateBudgetsFor.isEmpty()){
                System.enqueueJob(new RecordMergeBudgetHandler(orgIdsToRecalculateBudgetsFor, 'Account'));
            }

    }

    //LTU360-1640
    public static void updateEndDate(List<Account> accList, Map<Id, Account> oldAccMap){

        for(Account acc : accList){
            if(((oldAccMap != null && oldAccMap.get(acc.Id).I_RS_Status__c != 'Closed') && acc.I_RS_Status__c == 'Closed') 
            || (oldAccMap == null && acc.I_RS_Status__c == 'Closed')){
                acc.I_RS_End_Date__c = System.today();
            }
        }
    }

    // LTU360-2508
    public static void updatePortfolio(List<Account> listOfUpdatedAccountCountries){

        Map<String, String> countryReferencesMap = New Map<String, String>();

        try{
            for(L_PR_Country_Reference__c cr : [SELECT Id, Name, L_PR_Country_Alias__c, L_PR_Portfolio__c FROM L_PR_Country_Reference__c]){
                countryReferencesMap.put(cr.L_PR_Country_Alias__c, cr.L_PR_Portfolio__c);
            }
            system.debug('$$$countryReferencesMap'+countryReferencesMap);
            Map<Account, List<String>> accountIdandPortfolioMap = New Map<Account, List<String>>();
            List<String> countryRefsList = New List<String>();
        
            for(Account acc : listOfUpdatedAccountCountries){
                for(String cr : countryReferencesMap.keySet()){
                    if(cr != null){
                        if(cr.equalsIgnoreCase(acc.ShippingCountry)){
                            countryRefsList.add(countryReferencesMap.get(cr));
                            break;
                        }else if(cr.containsIgnoreCase(acc.ShippingCountry)){
                            countryRefsList.add(countryReferencesMap.get(cr));
                      }
                    }

                accountIdandPortfolioMap.put(acc,countryRefsList);
                }
                system.debug('$$$accountIdandPortfolioMap'+accountIdandPortfolioMap);
            }

            for(Account acc : accountIdandPortfolioMap.keySet()){

                List<String> listOfPortfolio = accountIdandPortfolioMap.get(acc);
                system.debug('$$$listOfPortfolio'+listOfPortfolio);
                system.debug('$$$listOfPortfolio.size()'+listOfPortfolio.size());
                if(listOfPortfolio != null){
                    if(listOfPortfolio.size() == 1){
                        acc.L_PR_Portfolio__c = listOfPortfolio[0];
                    }else{
                        acc.L_PR_Portfolio__c = null;
                    }
                }
            }
        }Catch(Exception e){
            Apex_Debug_Log__c debugLog = new Apex_Debug_Log__c();
            debugLog.Apex_Class_Name__c = 'AccountTriggerHelper';
            debugLog.Apex_Class_Method_Name__c = 'updatePortfolio';
            debugLog.Exception_message__c = e.getMessage();
            debugLog.Log_Type__c = 'Error';
            Insert debugLog;
        }
    }
}