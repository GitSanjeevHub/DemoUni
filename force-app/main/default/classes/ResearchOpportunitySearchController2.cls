public class ResearchOpportunitySearchController2 {

    static Search_Component_Configuration__mdt config;
    static String objectName;
    static String baselineFilters;
    static String baselineFieldsToQuery;
    
	static List<String> userFieldFilters = new List<String>();
    
    static String filterLogic;
    static String orderBy;
    static String orderDirection;
    static Integer rowLimit;
    static Integer offset;
    
    static String fieldsToQuery;
    
    static List<SObject> records;
    
    public class Wrapper {
        @AuraEnabled public List<SObject> records
                = new List<SObject>();
        @AuraEnabled public Integer offset;
        @AuraEnabled public Integer totalRowCount;
        @AuraEnabled public Boolean endOfList = false;

        @AuraEnabled public String clickthroughBaseURL;
    }
    
    @AuraEnabled
    public static Wrapper getSearchResults(
        	String configName,
            String keywordsToSearch_String,
            String keywordsToExclude_String,
            List<Map<String, Object>> filters,
            String filterLogic,
            String orderBy,
            String orderDirection,
            Integer rowLimit,
            Integer offset
    ){
    
        System.debug('getResearchOpportunities');
        System.debug(keywordsToSearch_String);
        System.debug(keywordsToExclude_String);

        getConfig(configName);

        ResearchOpportunitySearchController2.filterLogic = filterLogic;
        ResearchOpportunitySearchController2.orderBy = orderBy;
        ResearchOpportunitySearchController2.orderDirection = orderDirection;
        ResearchOpportunitySearchController2.rowLimit = rowLimit;
        ResearchOpportunitySearchController2.offset = offset;
        

        setFieldFilters(filters, filterLogic);
        
        if (keywordsToSearch_String != null && keywordsToSearch_String.length() > 0)
            records = getRecordsViaSOSL(keywordsToSearch_String, keywordsToExclude_String);
        
        else 
            records = getRecordsViaEmptySOQLQuery();
        
        Wrapper wrapper = createWrapper();
        return wrapper;
    }
    
    
    static Wrapper createWrapper(){

        System.debug('createWrapper');
        Wrapper wrapper = new Wrapper();

        wrapper.offset = offset;
        wrapper.totalRowCount = records.size();

        Boolean endOfList = (offset + rowLimit) >= records.size();
        if (endOfList)
            wrapper.endOfList = true;
        
        wrapper.records = getRecordSubset(records, rowLimit, offSet);
        
        wrapper.clickthroughBaseURL = getClickthroughBaseURL();

        System.debug('wrapper '+wrapper);
        return wrapper;

    }

    static List<SObject> getRecordSubset(List<SObject> records, Integer rowLimit, Integer offset){
        List<SObject> recordSubset = new List<SObject>();
        for (Integer i=offset; i<offset+rowLimit; i++)
            if (i < records.size())
                recordSubset.add(records.get(i));
        return recordSubset;
    }

    
    static List<SObject> getRecordsViaEmptySOQLQuery(){
        
		System.debug('getRecordsViaEmptySOQLQuery');
        
		String SOQLQuery = 'SELECT '+baselineFieldsToQuery+', '+fieldsToQuery+' FROM '+objectName;
            
        SOQLQuery += ' WHERE '+baselineFilters;

        if (!userFieldFilters.isEmpty())
            SOQLQuery += ' AND (' + getUserDefinedFilters() + ')';
        
        if (orderBy != null){
            SOQLQuery += ' ORDER BY '+orderBy+' '+orderDirection;
         
            if (orderDirection == 'asc') SOQLQuery += ' NULLS FIRST';
            else if (orderDirection == 'desc') SOQLQuery += ' NULLS LAST';
        }
        
        /*if (offset != null)
            SOQLQuery += ' OFFSET '+offset;*/
        
        System.debug('SOQLQuery '+SOQLQuery);
        
        List<SObject> records = Database.query(SOQLQuery);
        System.debug(records.size() + ' records');

		return records;        

    }
    

    static List<SObject> getRecordsViaSOSL(String keywordsToSearch, String keywordsToExclude){

        List<SObject> records = new List<SObject>();

        String keywordsToSearch_OR_Format = tokeniseThenJoinKeywordsWithDelimiter(keywordsToSearch, ' OR ');
        String keywordsToExclude_OR_Format = tokeniseThenJoinKeywordsWithDelimiter(keywordsToExclude, ' OR ');

        /*String allKeywordsSOSL = createSOSLQuery(keywordsToSearch, 
                                                keywordsToExclude_OR_Format, 
                                                null);
        List<SObject> recordsFromAllKeywordsSosl = Search.query(allKeywordsSOSL)[0];         
        records.addAll(recordsFromAllKeywordsSosl);
        Set<Id> recordIdsToExcludeIn2ndSOSL = new Map<Id, SObject>(recordsFromAllKeywordsSosl).keySet();*/
        

        String anyKeywordSOSL = createSOSLQuery(keywordsToSearch_OR_Format, 
                                            keywordsToExclude_OR_Format, 
                                            null); //replace with 'recordIdsToExcludeIn2ndSOSL' if using above lines
        List<SObject> recordsFromAnyKeywordSosl = Search.query(anyKeywordSOSL)[0];
        records.addAll(recordsFromAnyKeywordSosl);

        System.debug('records: '+records);

        return records;
    }


    static String createSOSLQuery(String keywordsToSearch, String keywordsToExclude, Set<Id> idsToExclude){

         System.debug('createSOSLQuery');
         System.debug(keywordsToSearch);
         System.debug(keywordsToExclude);
         System.debug(idsToExclude);

         String SOSLQuery = 'FIND {('+keywordsToSearch+')';
         if (keywordsToExclude != null)
            SOSLQuery += ' AND NOT ('+keywordsToExclude + ')';
         
         SOSLQuery += '} IN ALL FIELDS RETURNING '+objectName;

         SOSLQuery += '(';
            
            SOSLQuery += baselineFieldsToQuery + ', ' + fieldsToQuery+' ';

            SOSLQuery += ' WHERE '+baselineFilters;

            if (idsToExclude != null)
                SOSLQuery += ' AND (Id NOT IN '+idSetToSOQLString(idsToExclude)+')';

            if (!userFieldFilters.isEmpty())
                SOSLQuery += ' AND (' + getUserDefinedFilters() + ')';
            
	        if (orderBy != null){
                SOSLQuery += ' ORDER BY '+orderBy+' '+orderDirection;
                
                if (orderDirection == 'asc') SOSLQuery += ' NULLS FIRST';
	            else if (orderDirection == 'desc') SOSLQuery += ' NULLS LAST';
            }
        	
            /*if (offset != null)
                SOSLQuery += ' OFFSET '+offset;*/
        
        SOSLQuery += ')';

        System.debug('SOSLQuery '+SOSLQuery);
        
		return SOSLQuery; 

    }


    
    static String getUserDefinedFilters(){
        
        String filtersWithLogic = '('+filterLogic+')';

        for (Integer index=0; index<userFieldFilters.size(); index++) {
            String filterLogicCode = String.valueOf(index + 1);
            filtersWithLogic = filtersWithLogic.replaceFirst(filterLogicCode, 'FILTER_'+filterLogicCode);
        }

        for (Integer index=0; index<userFieldFilters.size(); index++) {
            String userFieldFilter = userFieldFilters[index];
            String filterLogicCode = String.valueOf(index + 1);
            filtersWithLogic = filtersWithLogic.replaceFirst('FILTER_'+filterLogicCode, userFieldFilter);
        }

        System.debug('filtersWithLogic '+filtersWithLogic);
        
        return filtersWithLogic;
    }
    
    
    static void setFieldFilters(List<Map<String, Object>> filters, String filterLogic){
        
        for (Integer index=0; index<filters.size(); index++){

            Map<String, Object> filter = filters[index];
            System.debug('filter '+filter);

            String filterType = (String) filter.get('filterType');
            System.debug('filterType '+filterType);

            switch on filterType {

                when 'picklist' {
                    userFieldFilters.add(getFieldFilter_Text(filter));
                }
                when 'date' {
					userFieldFilters.add(getFieldFilter_Date(filter));
                }
                when 'number' {
					userFieldFilters.add(getFieldFilter_Number(filter));
                }
                when 'boolean' {
					userFieldFilters.add(getFieldFilter_Boolean(filter));
                }

            }
        }
    }
    
    
    static String tokeniseThenJoinKeywordsWithDelimiter(String preTokenisedString, String delimiter){

        List<String> tokens = tokeniseKeywordFilter(preTokenisedString);

        if (!tokens.isEmpty())
            return String.join(tokens, delimiter);
        else
            return null;

    }


	static List<String> tokeniseKeywordFilter(String fullKeywordString){

        List<String> tokens = new List<String>();

        if (fullKeywordString == null)
            return tokens;

        String doubleQuotesRegex = '"(.+?)"';
        fullKeywordString = tokeniseByRegex(tokens, fullKeywordString, doubleQuotesRegex);

        System.debug(tokens);

        String nonWhiteSpaceRegex = '[^\\s]+';
        fullKeywordString = tokeniseByRegex(tokens, fullKeywordString, nonWhiteSpaceRegex);

        System.debug(tokens);

        return tokens;

    }


    static String tokeniseByRegex(List<String> tokenArrayReference, String fullKeywordString, String regex){

        System.debug('tokeniseByRegex '+fullKeywordString+' '+regex);

        Pattern p;

        p = Pattern.compile(regex);

        Matcher matcher = p.matcher(fullKeywordString);
        while (matcher.find() == true) {

            //String output = matcher.group(1);

            String output;

            if (matcher.groupCount() > 1)
                output = matcher.group(1);
            else
                output = matcher.group(0);

            String parsedOutput = parseTokenForSOSL(output);
            System.debug('parsedToken '+parsedOutput);
            if (parsedOutput != null)
                tokenArrayReference.add(parsedOutput);

            fullKeywordString = matcher.replaceFirst('');

            matcher = p.matcher(fullKeywordString);
        }

        System.debug('fullKeywordString '+fullKeywordString);
        return fullKeywordString;

    }

    static String parseTokenForSOSL(String token){

        System.debug('parseTokenForSOSL '+null);

        String noToken = null;

        if (token.length() < 2) return noToken;

        token = token.trim();
        token = String.escapeSingleQuotes(token);

        if (token.toLowerCase() == 'and') return '"and"';
        if (token.toLowerCase() == 'or') return '"or"';

        token = token.replaceAll('-', ('\\\\'+'-'));

        token = token+'*';

        return token;
    }

    
    static String getFieldFilter_Text(Map<String, Object> filterData) {

        String field = (String) filterData.get('field');
        String operator = (String) filterData.get('operator');
        String value = (String) filterData.get('value');

        String soqlFilter = field + ' ' + operator + ' \'' + value + '\'';

        return soqlFilter;
    }
    
    static String getFieldFilter_Date(Map<String, Object> filterData) {

        String field = (String) filterData.get('field');
        String operator = (String) filterData.get('operator');
        String value = (String) filterData.get('value');

        String soqlFilter = field + ' ' + operator + ' ' + value;

        return soqlFilter;

    }

    static String getFieldFilter_Number(Map<String, Object> filterData) {

        String field = (String) filterData.get('field');
        String operator = (String) filterData.get('operator');
        Decimal amount = Integer.valueOf((String) filterData.get('value'));

        String soqlFilter = field + ' ' + operator + ' ' + amount;

        return soqlFilter;

    }

    static String getFieldFilter_Boolean(Map<String, Object> filterData) {

        String field = (String) filterData.get('field');
        String trueOrFalse = (String) filterData.get('value');

        String soqlFilter = field + ' = ' + trueOrFalse;

        return soqlFilter;

    }
    
    static String idSetToSOQLString(Set<Id> ids){
        return
                '(\'' +
                String.join(new List<Id>(ids), '\',\'') +
                '\')';
    }



    
    static void getConfig(String configName){
        Search_Component_Configuration__mdt configMetadata = [select Id, I_RS_Object__r.QualifiedAPIName, I_RS_Baseline_Filters__c, I_RS_Baseline_Fields__c, 
        		(SELECT I_RS_Search_Component_Configuration__c, Id, DeveloperName, 
                 I_RS_Header_Title__c, I_RS_Field_Reference__r.QualifiedAPIName, I_RS_Field_Reference__r.DataType,
                 I_RS_Sortable__c, I_RS_Order__c
            		FROM Search_Component_Configuration_Columns__r WHERE I_RS_Active__c = TRUE ORDER BY I_RS_Order__c ASC)
			FROM Search_Component_Configuration__mdt WHERE DeveloperName = :configName];
        
        config = configMetadata;
        objectName = config.I_RS_Object__r.QualifiedAPIName;
        
        
        baselineFilters = config.I_RS_Baseline_Filters__c;
        baselineFieldsToQuery = config.I_RS_Baseline_Fields__c;
        
        List<String> columnFieldNames = new List<String>();
        for (Search_Component_Configuration_Column__mdt columnConfig : config.Search_Component_Configuration_Columns__r){
            if (columnConfig.I_RS_Field_Reference__c != null)
                columnFieldNames.add(columnConfig.I_RS_Field_Reference__r.QualifiedAPIName);
        }
        fieldsToQuery = String.join(columnFieldNames, ', ');
        
    }

	@AuraEnabled
    public static Map<String, Object> getUserSavedSearch(){
    	User user = [select
                I_RS_Funding_Opportunity_Saved_Search__c, I_RS_Funding_Opp_Saved_Search_Use_Logic__c, I_RS_Funding_Opp_Saved_Search_Logic__c
                from User where Id = :UserInfo.getUserId()];

        if (user.I_RS_Funding_Opportunity_Saved_Search__c != null)
	        return (Map<String, Object>) JSON.deserializeUntyped(user.I_RS_Funding_Opportunity_Saved_Search__c);
		else 
           	return null;
    }

    
    @AuraEnabled
    //public static void saveUserSearch(List<Map<String, Object>> filters, Boolean useFilterLogic, String filterLogic){
    public static void saveUserSearch(Map<String, Object> data){

    	User user = new User(Id = UserInfo.getUserId());
        String dataJSON = JSON.serializePretty(data);

        System.debug('savedSearch '+dataJSON);

        user.I_RS_Funding_Opportunity_Saved_Search__c = dataJSON;
        
        update user;

    }
    
    @AuraEnabled
    public static List<Map<String, String>> getColumns_DatatableMetadata(String configName){
        
        system.debug('getColumns_DatatableMetadata '+configName);
        
        List<Map<String, String>> columns = new List<Map<String, String>>();
        getConfig(configName);
        
        for (Search_Component_Configuration_Column__mdt columnConfig : config.Search_Component_Configuration_Columns__r){

            Map<String, String> column = new Map<String, String>{
                'label' => columnConfig.I_RS_Header_Title__c,
                'fieldName' => columnConfig.I_RS_Field_Reference__r.QualifiedAPIName,
                'sortable' => (columnConfig.I_RS_Sortable__c ? 'true' : 'false'),
                'dataType' => columnConfig.I_RS_Field_Reference__r.DataType
            };

            String dataType = columnConfig.I_RS_Field_Reference__r.DataType;
            if (dataType.toLowerCase().contains('currency')){
                column.put('type', 'number');
                column.put('formatter', 'currency');
                column.put('step', '0.01');
            }
            if (dataType.toLowerCase().contains('number')){
                column.put('type', 'number');
            }

            columns.add(column);
        }
        
        System.debug(columns);
        
        return columns;
        
    }


    static String getClickthroughBaseURL(){

        System.debug('getClickthroughBaseURL');
        URL_Variable__c baseURLsVariable = URL_Variable__c.getOrgDefaults();
        String researcherPortalBaseURL =  baseURLsVariable.I_RS_Researcher_Portal_Base_URL__c;

        String clickThroughBaseURL = researcherPortalBaseURL;

        clickThroughBaseURL = clickThroughBaseURL.replace('/s','');

        System.debug('clickThroughBaseURL '+clickThroughBaseURL);

        return clickthroughBaseURL;

    }
    
}