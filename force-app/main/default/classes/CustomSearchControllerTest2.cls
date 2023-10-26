@isTest
public class CustomSearchControllerTest2 {

    static String searchConfigName = 'Funding_Opportunity_Researchers';

    static String keywordsToSearch = 'Test Research Opportunity';
    static String keywordsToExclude = 'Invalid';

    static Integer numberOfOppsToInsert = 3000;

    static List<Map<String, Object>> filters = new List<Map<String, Object>>{
        new Map<String, Object>{
            'filterType' => 'picklist',
            'field' => 'I_RS_Type_of_Opportunity__c',
            'operator' => '=',
            'value' => 'Grant'
        },
        new Map<String, Object>{
            'filterType' => 'picklist',
            'field' => 'I_RS_Funding_Category__c',
            'operator' => '=',
            'value' => 'Cat 1'
        },
        new Map<String, Object>{
            'filterType' => 'date',
            'field' => 'I_RS_Submission_Date__c',
            'operator' => '>=',
            'value' => '2000-01-01'
        }    };
    static String filterLogic = '1 AND 2 AND 3';


    public static testmethod void customSearchTest(){


        insert new URL_Variable__c(
            I_RS_Researcher_Portal_Base_URL__c = 'https://latrobe.prime.edu.au/s'
        );

        List<Research_Opportunity__c> researchOpps = [select Id from Research_Opportunity__c LIMIT 2000];
        Test.setFixedSearchResults(new List<Id>(new Map<Id, Research_Opportunity__c>(researchOpps).keySet()));

        Test.startTest();

            Integer setupCPUTime = Limits.getCPUTime();

            ResearchOpportunitySearchController2.Wrapper wrapper = 
                ResearchOpportunitySearchController2.getSearchResults(
                searchConfigName,
                keywordsToSearch,
                null,
                filters,
                filterLogic,
                'Name',
                'asc',
                10,
                0
            );

            Integer searchCPUTime = Limits.getCPUTime() - setupCPUTime;
            if (searchCPUTime > 3000)
            System.assert(false, 'Search is taking too long ('+Limits.getCPUTime()+' seconds');
        
            System.assertequals(2000, wrapper.totalRowCount);
            System.assertequals(10, wrapper.records.size());

        Test.stopTest();
        
    }



    public static testmethod void testColumnMetadataLogic(){

        System.assert(PicklistController.getPickListValues(
                        'Research_Opportunity__c', 'I_RS_Type_Of_Opportunity__c') != null);
    
        System.assert(ResearchOpportunitySearchController2.getColumns_DatatableMetadata(searchConfigName).size() > 0);

    }


    public static testmethod void saveAndLoadSavedSearch(){

       System.debug('---CustomSearchControllerTest2.saveAndLoadSavedSearch---'); 
        
		/*Map<String, Object> initialSearchLoadBeforeAnySaveHasOccurred = 
            ResearchOpportunitySearchController2.getUserSavedSearch();
        System.assertequals(null, initialSearchLoadBeforeAnySaveHasOccurred);*/
        //Would need to run as brand new user so we can guarantee there is no saved search
        
       Map<String, Object> saveSearchData = new Map<String, Object>{
            'keywordsToSearch' => keywordsToSearch,
            'keywordsToExclude' => keywordsToExclude,
            'filters' => filters,
            'useFilterLogic' => true,
            'filterLogic' => filterLogic
        };
            
       	ResearchOpportunitySearchController2.saveUserSearch(saveSearchData);
        
       	Map<String, Object> loadedSavedSearchData = 
           ResearchOpportunitySearchController2.getUserSavedSearch();
        
        System.debug('loadedSavedSearchData '+loadedSavedSearchData);
        
        System.assert(loadedSavedSearchData != null);
        
        System.debug('---CustomSearchControllerTest2.saveAndLoadSavedSearch END---'); 
    }


    @TestSetup
    static void makeData(){
        
        List<Research_Opportunity__c> opps = new List<Research_Opportunity__c>();
        
        Id recordTypeId = Schema.SObjectType.Research_Opportunity__c.getRecordTypeInfosByDeveloperName().get('I_RS_Funding_Opportunity').getRecordTypeId();
        System.assert(recordTypeId != null);

        for (Integer i=0; i<numberOfOppsToInsert; i++){ 
            Research_Opportunity__c opp = TestUtility.newResearchOpportunity(false);
            opp.recordTypeId = recordTypeId;
            opp.I_RS_Type_of_Opportunity__c = 'Grant';
            opp.I_RS_Funding_Category__c = 'Cat 1';
            opp.I_RS_Submission_Date__c = Date.today() + 365;
            opp.I_RS_Minimum_Available_Budget__c = 500;
            opp.I_RS_Student_Led__c = true;

            opps.add(opp);
        }
        insert opps;

    }

    
}