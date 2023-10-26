public without sharing class ResearchCodeGridSummaryController {

    @AuraEnabled 
    public static List<ERACodeGrouping> getSummaryData(Id parentId, String pageConfigName){
        
        List<ERACodeGrouping> outputData = new List<ERACodeGrouping>();
        
		I_RS_Editable_Grid_Screen_Config__mdt gridConfig = [
          SELECT
            I_RS_Object_to_aggregate__c,
            I_RS_Parent_Object_Name__c,
			I_RS_Parent_Lookup_Reference__c,
			I_RS_Not_Soft_Deleted_Filter__c,
			I_RS_PRIME_Back_Office_Page_Name__c,
			I_RS_PRIME_Researcher_Page_Name__c,
            I_RS_Parent_Record_Widget_Header__c,
            I_RS_Parent_Record_Display_Fields__c,
            I_RS_Researcher_Portal_if_applicable__c,
            (
                SELECT 
                Label, 
                I_RS_Grid_Config_File_Name__c, 
                I_RS_Grouping_Name__c, 
                I_RS_Grouping_Label__c,
                I_RS_Hide_in_breakdown_list_if_empty__c 
                FROM Research_Code_Grouping_Rows__r 
                ORDER BY I_RS_Grouping_Label__c
            )
            FROM I_RS_Editable_Grid_Screen_Config__mdt
            WHERE DeveloperName = :pageConfigName
            
        ];
        
        DescribeSObjectResult schemaType = Schema.describeSObjects(new String[]{gridConfig.I_RS_Object_to_aggregate__c})[0];
        if (!schemaType.isAccessible()){
            return NULL;
        }

        //Get common variables
        System.debug('gridConfig '+gridConfig);
        List<I_RS_Research_Code_Grouping_Row__mdt> codeGroupConfigList = 
            (List<I_RS_Research_Code_Grouping_Row__mdt>) gridConfig.getSObjects('Research_Code_Grouping_Rows__r');
        
        //Instantate row-by-row payload to send back
        Map<String, ERACodeGrouping> temporaryOutputData = new Map<String, ERACodeGrouping>();
        for (I_RS_Research_Code_Grouping_Row__mdt codeGroupConfig : codeGroupConfigList){
            temporaryOutputData.put(
            	codeGroupConfig.I_RS_Grouping_Name__c,
                new ERACodeGrouping(
                	codeGroupConfig.I_RS_Grouping_Label__c,
                    codeGroupConfig.I_RS_Grid_Config_File_Name__c,
                    codeGroupConfig.I_RS_Hide_in_breakdown_list_if_empty__c
                )
            );
        }
		System.debug('temporaryOutputData '+temporaryOutputData);
        
		//Construct SOQL query then execute it to populate metrics in result rowa
        String childObject = gridConfig.I_RS_Object_to_aggregate__c;
        String parentLookupReference = gridConfig.I_RS_Parent_Lookup_Reference__c;
        String notDisabledFilter = gridConfig.I_RS_Not_Soft_Deleted_Filter__c;
		String codeQuery = 'SELECT Id, I_RS_Classification_Master__r.I_RS_Type__c FROM '+childObject+
            ' WHERE I_RS_Classification_Master__c != NULL AND '+parentLookupReference+' = \''+parentId+'\' AND '+notDisabledFilter;
            
        System.debug('codeQuery '+codeQuery);
        List<SObject> codeRecords = Database.query(codeQuery);
        
        for (SObject codeRecord : codeRecords){
			System.debug('Code record '+codeRecord);
            String codeType = (String) codeRecord.getSObject('I_RS_Classification_Master__r').get('I_RS_Type__c');
        	ERACodeGrouping codeGroup = temporaryOutputData.get(codeType);
            System.debug('codeGroup '+codeGroup);
            if (codeGroup != null){
                codeGroup.activeCodeCount++;
            }
        }
            
        outputData.addAll(temporaryOutputData.values());
            
        //Construct URL
        String url = getGridPageBaseURL(parentId, gridConfig);

        url += '&c__recordWidgetObjectAPIName='+gridConfig.I_RS_Parent_Object_Name__c;
        url += '&c__recordWidgetFields='+gridConfig.I_RS_Parent_Record_Display_Fields__c;
        url += '&c__recordWidgetCardTitle='+gridConfig.I_RS_Parent_Record_Widget_Header__c;
        
        //Loop through output data and either finalise the clickthrough URL, or remove the row if aplicable 
        for (Integer i=0; i<outputData.size();){
        	ERACodeGrouping row = outputData[i];
            if (row.hideIfEmpty && row.activeCodeCount == 0){
                outputData.remove(i);
            }
            else {
        		row.separateTabURL = url+ '&c__configFile='+row.configFileName;
                i++;
            }
        }
            
        return outputData;
        
    }
    
    
    static String getGridPageBaseURL(Id parentId, I_RS_Editable_Grid_Screen_Config__mdt gridConfig){

        String userTypeCode = [select I_RS_Is_Researcher_User__c from User WHERE Id = :UserInfo.getUserId()].I_RS_Is_Researcher_User__c;
        URL_Variable__c baseURL = URL_Variable__c.getOrgDefaults();
        
        switch on userTypeCode {
        	when '1' {
                if (gridConfig.I_RS_Researcher_Portal_if_applicable__c == 'PRIME Researcher'){
                    return baseURL.I_RS_Researcher_Portal_Base_URL__c+'/'+
                        gridConfig.I_RS_PRIME_Researcher_Page_Name__c+'?c__recordId='+parentId;
                }
                else if (gridConfig.I_RS_Researcher_Portal_if_applicable__c == 'PRIME ERA'){
                    return baseURL.I_RS_ERA_Portal_Base_URL__c+'/'+
                        gridConfig.I_RS_PRIME_Researcher_Page_Name__c+'?c__recordId='+parentId;
                }
                return null;
        	}
            when '0' {
                return baseURL.I_RS_Internal_Base_URL__c+'/lightning/n/'+
                    gridConfig.I_RS_PRIME_Back_Office_Page_Name__c+'?c__recordId='+parentId;
            }
            when else {
                return null;
            }
        }
       	
    }
    
    
    public class ERACodeGrouping{
        
		@AuraEnabled public String categoryLabel;
        @AuraEnabled public Integer activeCodeCount;
        @AuraEnabled public String configFileName;
        
        @AuraEnabled public String separateTabURL;
        
        Boolean hideIfEmpty;
        
        ERACodeGrouping(String categoryLabel, String configFileName, Boolean hideIfEmpty){
            this.categoryLabel = categoryLabel;
            this.configFileName = configFileName;
            this.activeCodeCount = 0;
            this.hideIfEmpty = hideIfEmpty;
        }
        
    }
    
}