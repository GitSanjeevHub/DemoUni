public class BudgetToFundingDetailSync {

    //Note: Assumption is only one Budget will be passed in at a time in a visual workflow, but it is technically 
    //possible to pass in a small number of them without hitting limits

    @InvocableMethod(label='Sync Budget to Funding Details' 
    description='Extracts Budget Line Items and aggregates data in Project Proposal\'s Funding Detail records')
    public static void budgetToFundingDetailSync(List<Id> budgetIds) {

        System.debug('budgetToFundingDetailSync');
        
        List<Junction_Linkage__c> fundingDetailsToInsert = new List<Junction_Linkage__c>();
        
        List<Budget__c> budgets = [SELECT Id, I_RS_Project_Proposal__c, 
            (SELECT Id, I_RS_Organisation__c,I_RS_Organisation_being_funded__c
             FROM Budget_Line_Items__r) FROM Budget__c WHERE Id IN :budgetIds];
        
        removeOldFundingDetailsRecords(budgets);

        for (Budget__c budget : budgets){
            fundingDetailsToInsert.addAll(createFundingDetailsForBudget(budget));
        }

        if (!fundingDetailsToInsert.isEmpty())
            insert fundingDetailsToInsert;

    }


    static void removeOldFundingDetailsRecords(List<Budget__c> budgets){

        Set<Id> projectProposalIds = GlobalUtility.getParentIds(budgets, 'I_RS_Project_Proposal__c');

        delete [SELECT Id FROM Junction_Linkage__c WHERE I_RS_Project_Proposal__c IN :projectProposalIds];

    }


    static List<Junction_Linkage__c> createFundingDetailsForBudget(Budget__c budget){

        List<Junction_Linkage__c> fundingDetailsToInsert = new List<Junction_Linkage__c>();

        fundingDetailsToInsert.addAll(
            createFundingDetailsForOrgs(
                budget, 
                'I_RS_Organisation__c',
                'I_RS_Organisation__r', 
                'Budget_Line_Items_Org__r'));

        fundingDetailsToInsert.addAll(
            createFundingDetailsForOrgs(
                budget, 
                'I_RS_Organisation_Being_Funded__c',
                'I_RS_Organisation_Being_Funded__r', 
                'Budget_Line_Items_Orgs_Being_Funded__r'));

        return fundingDetailsToInsert;

    }


    static List<Junction_Linkage__c> createFundingDetailsForOrgs(
                                        Budget__c budget, 
                                        String bliToOrgLookupFieldName,
                                        String bliToOrgRelationshipName, 
                                        String orgToBLIRelationship){

        List<Junction_Linkage__c> fundingDetailsToInsert = new List<Junction_Linkage__c>();
        
        Set<Id> budgetIds = new Set<Id>{budget.Id};
        Set<Id> allOrgIds = GlobalUtility.getParentIds(budget.Budget_Line_Items__r, bliToOrgLookupFieldName);
        
        List<Account> orgsAndBLIs = getOrgAndBLICombinations(orgToBLIRelationship, budgetIds, allOrgIds);
    
        for (Account org : orgsAndBLIs){
    
            List<Junction_Linkage__c> fundingDetailsToInsertForOrg = createFundingDetailsForOrg(org, orgToBLIRelationship, bliToOrgRelationshipName);
            fundingDetailsToInsert.addAll(fundingDetailsToInsertForOrg);

        }

        return fundingDetailsToInsert;

    }


    static List<Junction_Linkage__c> createFundingDetailsForOrg(Account parentOrg, 
                                                                String orgToBLIRelationshipName, 
                                                                String bliToOrgRelationshipName){

        List<Junction_Linkage__c> fundingDetailsToInsertForOrg = new List<Junction_Linkage__c>();

        Map<String, Junction_Linkage__c> temporaryFundingDetailsMap = new Map<String, Junction_Linkage__c>();
        
        for (Budget_Line_Item__c funderBudgetLineItem : (List<Budget_Line_Item__c>) parentOrg.getSObjects(orgToBLIRelationshipName)){

            Junction_Linkage__c fundingDetailForBLI;
            String fundingDetailBucketName = getBucketName(funderBudgetLineItem, bliToOrgRelationshipName);

            if (fundingDetailBucketName != null) {

                fundingDetailForBLI = temporaryFundingDetailsMap.get(fundingDetailBucketName);
                if (fundingDetailForBLI == null){
                    fundingDetailForBLI = createNewFundingDetail(funderBudgetLineItem, bliToOrgRelationshipName, fundingDetailBucketName);
                }
                assignVariablesBasedOnFundingDetailType(fundingDetailForBLI, funderBudgetLineItem, fundingDetailBucketName, bliToOrgRelationshipName);
                System.debug('fundingDetailForBLI '+fundingDetailForBLI);
                


                incrementFundingDetailBasedOnBLI(fundingDetailForBLI, funderBudgetLineItem);

                temporaryFundingDetailsMap.put(fundingDetailBucketName, fundingDetailForBLI);

                System.debug('temporaryFundingDetailsMap '+temporaryFundingDetailsMap);

            }

        }

        for (Junction_Linkage__c fundingDetailToInsert : temporaryFundingDetailsMap.values()){
            System.debug('fundingDetailToInsert '+fundingDetailToInsert);
            fundingDetailsToInsertForOrg.add(fundingDetailToInsert);
        }
        System.debug('fundingDetailsToInsertForOrg '+fundingDetailsToInsertForOrg);

        return fundingDetailsToInsertForOrg;

    }



    static List<Account> getOrgAndBLICombinations(String budgetChildRelationshipName, Set<Id> budgetIds, Set<Id> orgIds){

        System.debug('getOrgAndBLICombinations');

        String query = 
            'SELECT Id, Name, I_RS_Part_of_La_trobe__c, '+
                '(SELECT '+
                    'I_RS_Budget__c, Id, I_RS_In_Kind__c, I_RS_Category__c,'+
                    'I_RS_Year_1_Base_Salary__c, Year_1_Cost__c,'+
                    'Year_2_Cost__c,'+
                    'Year_3_Cost__c,'+
                    'Year_4_Cost__c,'+
                    'Year_5_Cost__c,'+
                    'Year_6_Cost__c,'+
                    'Year_7_Cost__c,'+
                    'I_RS_Amount__c,'+
                    'I_RS_Budget__r.I_RS_Project_Proposal__c,'+
                    'I_RS_Organisation__c, I_RS_Organisation__r.Name, I_RS_Organisation__r.I_RS_Part_Of_La_Trobe__c,'+
                    'I_RS_Organisation_Being_Funded__c, I_RS_Organisation_Being_Funded__r.Name,'+
                        'I_RS_Organisation_Being_Funded__r.I_RS_Part_Of_La_Trobe__c '+
                'FROM '+budgetChildRelationshipName+' WHERE I_RS_Budget__c IN :budgetIds) '+
                'FROM Account WHERE Id IN :orgIds';

        System.debug('query '+query);
        List<Account> orgAndBLICombination = (List<Account>) Database.query(query);
        System.debug('org '+orgAndBLICombination);
        for (Account org : orgAndBLICombination){
            System.debug('blis '+org.getSObjects(budgetChildRelationshipName));
        }
        return orgAndBLICombination;

    }


    static String getBucketName(Budget_Line_Item__c funderBudgetLineItem, String bliToOrgRelationshipName) {

        Account funder = (Account) funderBudgetLineItem.getSObject(bliToOrgRelationshipName);
        String fundingDetailBucketName = null;

        //Provided To
        if (bliToOrgRelationshipName == 'I_RS_Organisation_Being_Funded__r'){
            fundingDetailBucketName = 'Provided To';

        }
        //Funder
        else if (bliToOrgRelationshipName == 'I_RS_Organisation__r'){
            if (funder.I_RS_Part_of_La_Trobe__c){

                if (!funderBudgetLineItem.I_RS_In_Kind__c){

                    if (funderBudgetLineItem.I_RS_Category__c != 'Cash External'){
                        fundingDetailBucketName = 'La Trobe Internal Cash';
                    }
                    else {
                        fundingDetailBucketName = 'La Trobe External Cash';
                    }

                }
                else {

                    if (funderBudgetLineItem.I_RS_Category__c != 'Cash External'){
                        fundingDetailBucketName = 'La Trobe In-Kind';
                    }
                    else {
                        //Do Nothing?
                    }

                }

            }
            else {

                //if (!funderBudgetLineItem.I_RS_In_Kind__c){ 
                    fundingDetailBucketName = 'External';
                //}

            }
        }
        System.debug('fundingDetailBucketName '+fundingDetailBucketName);

        return fundingDetailBucketName;

    }

    

    //Could probably outsource most of these to field defaults?
    static Junction_Linkage__c createNewFundingDetail(Budget_Line_Item__c budgetLineItem, 
                                                    String bliToOrgRelationshipName, 
                                                    String fundingDetailBucketName){

        Junction_Linkage__c newFundingDetail = new Junction_Linkage__c(
            I_RS_Awarded_To__c = (Id) budgetLineItem.getSObject(bliToOrgRelationshipName).get('Id'),
            I_RS_Project_Proposal__c = budgetLineItem.I_RS_Budget__r.I_RS_Project_Proposal__c,
            I_RS_Status__c = 'Not Cancelled',
            I_RS_Year_1_Suggested_Amount__c = 0,
            I_RS_Year_2_Suggested_Amount__c = 0,
            I_RS_Year_3_Suggested_Amount__c = 0,
            I_RS_Year_4_Suggested_Amount__c = 0,
            I_RS_Year_5_Suggested_Amount__c = 0,
            I_RS_Year_6_Suggested_Amount__c = 0,
            I_RS_Year_7_Suggested_Amount__c = 0,
            I_RS_Amount_Suggested__c = 0
        );
        System.debug('newFundingDetail '+newFundingDetail);
        return newFundingDetail;

    }


    static void incrementFundingDetailBasedOnBLI(Junction_Linkage__c fundingDetailForBLI, 
                                                Budget_Line_Item__c funderBudgetLineItem){

        System.debug('incrementFundingDetailsBasedOnBLI');
        System.debug('fundingDetailForBLI '+fundingDetailForBLI);
        System.debug('funderBudgetLineItem '+funderBudgetLineItem);

        fundingDetailForBLI.I_RS_Year_1_Suggested_Amount__c += funderBudgetLineItem.Year_1_Cost__c;
        fundingDetailForBLI.I_RS_Year_2_Suggested_Amount__c += funderBudgetLineItem.Year_2_Cost__c;
        fundingDetailForBLI.I_RS_Year_3_Suggested_Amount__c += funderBudgetLineItem.Year_3_Cost__c;
        fundingDetailForBLI.I_RS_Year_4_Suggested_Amount__c += funderBudgetLineItem.Year_4_Cost__c;
        fundingDetailForBLI.I_RS_Year_5_Suggested_Amount__c += funderBudgetLineItem.Year_5_Cost__c;
        fundingDetailForBLI.I_RS_Year_6_Suggested_Amount__c += funderBudgetLineItem.Year_6_Cost__c;
        fundingDetailForBLI.I_RS_Year_7_Suggested_Amount__c += funderBudgetLineItem.Year_7_Cost__c;

        fundingDetailForBLI.I_RS_Amount_Suggested__c += funderBudgetLineItem.I_RS_Amount__c;

    }
    

    


    static Junction_Linkage__c assignVariablesBasedOnFundingDetailType(Junction_Linkage__c fundingDetail, 
                                                                        Budget_Line_Item__c budgetLineItem, 
                                                                        String bucketName, 
                                                                        String bliToOrgRelationshipName){

        System.debug('assignVariablesBasedOnFundingDetailType');

        String orgName = (String) budgetLineItem.getSObject(bliToOrgRelationshipName).get('Name');

         switch on (bucketName){
             when 'La Trobe Internal Cash' {
                fundingDetail.Name = orgName + ' Internal Cash';
                fundingDetail.I_RS_Relationship_Type__c = bucketName;
             }
             when 'La Trobe External Cash' {
                fundingDetail.Name = orgName + ' External Cash';
                fundingDetail.I_RS_Relationship_Type__c = bucketName;
             }
             when 'La Trobe In-Kind' {
                fundingDetail.Name = orgName + ' In-Kind';
                fundingDetail.I_RS_Relationship_Type__c = bucketName;
             }
             when 'Provided To' {
                 fundingDetail.Name = 'Provided To ' + orgName;
                 fundingDetail.I_RS_Relationship_Type__c = 'Other Organisation';
             }
             //In cash where Funder is external
             when else {
                 fundingDetail.Name = orgName;
                 fundingDetail.I_RS_Relationship_Type__c = 'Funding Body';
             }

         }
   
        System.debug('fundingDetail '+fundingDetail);
         return fundingDetail;

    }



    
}