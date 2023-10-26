public without sharing class FundingOppStagingToLiveSync {
    
    List<Funding_Opportunity_Staging__c> fossPostUpsert;
    Map<Id, Funding_Opportunity_Staging__c> fossMapPreUpsert;
    
    List<Funding_Opportunity_Field_Mapping__mdt> oppFieldMappings = new List<Funding_Opportunity_Field_Mapping__mdt>();
     
    @TestVisible public static Boolean throwError = false;

    public void run(List<Funding_Opportunity_Staging__c> fossPostUpsert, Map<Id, Funding_Opportunity_Staging__c> fossMapPreUpsert){
        
        getFieldMappingConfigSettings();
            
        List<Funding_Opportunity_Staging__c> foss;
        foss = getEligibleStagingFundingOpps(fossPostUpsert, fossMapPreUpsert);
            
        try {

            if (throwError)
                throw new DMLException('Simulated error here');

            Map<String, Account> keyToOrgMap = getKeyToOrgMap_ExistingOrgs(foss);

            //Loop through records and designate new or existing Funder
            for (Integer index=0; index<foss.size();){

                Funding_Opportunity_Staging__c fos = foss[index];
                Account accountForFO = findExistingFunderInKeyToOrgMap(fos, keyToOrgMap);

                if (accountForFO != null){
                    //accountForFO.I_RS_Funder_Id__c = fos.I_RS_Primary_Funder_Id__c;
                    accountForFO.I_RS_Funder_Name__c = fos.I_RS_Primary_Funder_Name__c;
                    //accountForFO.I_RS_Funder_Region__c = fos.I_RS_Primary_Funder_Region__c;
                    //accountForFO.I_RS_Funder_Region_Code__c = fos.I_RS_Primary_Funder_Region_Code__c;

                    System.debug('existing org'+accountForFO.I_RS_Funder_Id__c+' '+accountForFO);
                    keyToOrgMap.put(accountForFO.I_RS_Funder_Id__c, accountForFO);
                        
                    index++;
                }
                else {
                    fos.I_RS_Funding_Opportunity_Sync_Status__c = 'No Matching Funder in PRIME';
                    fos.I_RS_PRIME_Ready__c = false;
                    foss.remove(index);
                }

            }
            
            if (!foss.isEmpty()){
                List<Research_Opportunity__c> fundingOpps = createFundingOpportunities(foss, keyToOrgMap);
            }
            
        }
        catch (Exception e){

            Apex_Debug_Log__c customApexDebugLog = new Apex_Debug_Log__c(
                Apex_Class_Name__c = 'FundingOppStagingToLiveSync',
                Apex_Class_Method_Name__c = 'run',
                Exception_Message__c = e.getMessage(),
                Exception_stack_trace__c = e.getStackTraceString(),
                Log_Type__c = 'Error',
                Logged_In_Salesforce_User__c = UserInfo.getUserId(),
                Request_Data__c = JSON.serialize(fossPostUpsert).left(100000)
            );
            insert customApexDebugLog;

            for (Funding_Opportunity_Staging__c fos : foss){
                fos.I_RS_Prime_Ready__c = false;
                fos.I_RS_Funding_Opportunity_Sync_Status__c = 'Failed';
                fos.I_RS_Funding_Opp_Sync_Error_Message__c = 
                    'Unhandled Exception - see Log at '+customApexDebugLog.Id;
            }

        }

        System.debug('CPU Time - ' + Limits.getCPUTime());
    }
        
    

    static Account findExistingFunderInKeyToOrgMap(Funding_Opportunity_Staging__c fos, 
                                                Map<String, Account> keyToOrgMap){

        Account matchingFunderById = keyToOrgMap.get(fos.I_RS_Primary_Funder_Id__c);
        if (matchingFunderById != null) {
            System.debug('Matching Funder By Id '+matchingFunderById);
            return matchingFunderById;
        }

        return null;
        
    }


    static Map<String, Account> getKeyToOrgMap_ExistingOrgs(List<Funding_Opportunity_Staging__c> foss){

        Set<String> funderIdSet = new Set<String>();
        Set<String> funderNameSet = new Set<String>();

        for (Funding_Opportunity_Staging__c fos : foss){
            if (fos.I_RS_Primary_Funder_Id__c != null)
                funderIdSet.add(fos.I_RS_Primary_Funder_Id__c);
        }

        Map<String, Account> keyToOrgMap = new Map<String, Account>();
        for (Account org : [SELECT Id, Name, I_RS_Funder_Id__c from Account where 
            I_RS_Funder_Id__c != NULL AND I_RS_Funder_Id__c IN :funderIdSet]){

                keyToOrgMap.put(org.I_RS_Funder_Id__c, org);
        }

        return keyToOrgMap;
    }

        
    
    void getFieldMappingConfigSettings(){
        
        oppFieldMappings = 
            [SELECT 
             I_RS_Object__c,
             Staging_API_Name__c, 
             Actual_API_Name__c, 
             I_RS_Field_Type__c, 
             I_RS_Concatenation_Order__c,
             I_RS_Hard_Coded_Text_Value__c, 
             I_RS_Update_Funding_Opp_When_Modified__c
             FROM Funding_Opportunity_Field_Mapping__mdt 
             ORDER BY I_RS_Concatenation_Order__c];
        
    }
    
        
    List<Funding_Opportunity_Staging__c> getEligibleStagingFundingOpps(
        List<Funding_Opportunity_Staging__c> stagingOppsAfterUpsert,
        Map<Id, Funding_Opportunity_Staging__c> stagingOppsBeforeUpsert
    ){
        System.debug('getEligibleStagingFundingOpps');
        
        Boolean isInsert = stagingOppsBeforeUpsert == null;
            
        List<Funding_Opportunity_Staging__c> eligibleFundingOpportunities = 
            new List<Funding_Opportunity_Staging__c>();
        
        for (Funding_Opportunity_Staging__c fos : stagingOppsAfterUpsert){
            
            //System.debug('fos '+fos);
            
            Boolean primeReady = fos.I_RS_Prime_Ready__c == true;
            Boolean wasNotPRIMEReadyBefore = !isInsert && 
                stagingOppsBeforeUpsert.get(fos.Id).I_RS_Prime_Ready__c == false;
            
            if (primeReady && (isInsert || wasNotPRIMEReadyBefore)) {
                //System.debug('Changed to PRIME Ready');
                eligibleFundingOpportunities.add(fos);
                continue;
            }
            
            
            if (!isInsert){
                for (Funding_Opportunity_Field_Mapping__mdt oppFieldMapping : oppFieldMappings){

                    String fieldName = oppFieldMapping.Staging_API_Name__c;
                    if (fieldName != null){

                        if (oppFieldMapping.I_RS_Update_Funding_Opp_When_Modified__c){
                            
                            //system.debug('fieldName '+fieldName);
                            
                            Funding_Opportunity_Staging__c stagingOppBeforeUpsert = 
                                stagingOppsBeforeUpsert.get(fos.Id);
                            
                            Object fieldBeforeUpsert = stagingOppBeforeUpsert.get(fieldName);
                            Object fieldAfterUpsert = fos.get(fieldName);
                            
                            //System.debug('fieldBeforeUpsert '+fieldBeforeUpsert);
                            //System.debug('fieldAfterUpsert '+fieldAfterUpsert);
                            
                            if (fieldBeforeUpsert != fieldAfterUpsert){
                                eligibleFundingOpportunities.add(fos);
                                break;
                            }
                        }

                    }
                }
            }
            
            //System.debug('Isnt eligible');
        }
        
        System.debug('eligibleFundingOpportunities '+eligibleFundingOpportunities);
        return eligibleFundingOpportunities;
    }
    
    
    List<Research_Opportunity__c> createFundingOpportunities(
        List<Funding_Opportunity_Staging__c> foss,
        Map<String, Account> keyToOrgMap
    ){
        System.debug('createFundingOpportunities');
        List<Research_Opportunity__c> newFundingOpportunities = new List<Research_Opportunity__c>();
        
        Set<Id> existingFOSIds = getRecordIds(foss);
        List<Funding_Opportunity_Staging__c> FOSsPlusROs = getStagingAndLiveFundingOpportunities(existingFOSIds);
        Map<Id, Research_Opportunity__c> ROsMap = getROsMap(FOSsPlusROs);
    
        for (Funding_Opportunity_Staging__c fos : foss){
            Research_Opportunity__c ro = newOrExistingFundingOpportunity(fos, ROsMap);
            
            Id recordTypeId =
                  Schema.SObjectType.Research_Opportunity__c.getRecordTypeInfosByDeveloperName().
                get('I_RS_Funding_Opportunity').getRecordTypeId();
            ro.recordTypeId = recordTypeId;
            
			for (Funding_Opportunity_Field_Mapping__mdt fieldMapping : oppFieldMappings){
                ro.put(fieldMapping.Actual_API_Name__c, null);
            }
            for (Funding_Opportunity_Field_Mapping__mdt fieldMapping : oppFieldMappings){
                copyFieldValue(fos, ro, fieldMapping);
            }
            System.debug('ro '+ro);
            
            
            Account matchingOrg = getFOSsOrgFromKeyToOrgMap(fos, keyToOrgMap);
            if (matchingOrg != null){
                System.debug('Linking to org');
                ro.I_RS_Organisation__c = matchingOrg.Id;
            }
            System.debug('New Funding Opportunity '+ro);            
            newFundingOpportunities.add(ro);
        }
        
        List<Database.UpsertResult> results = Database.Upsert(newFundingOpportunities, false);
        System.debug('CPU - Just upserted '+Limits.getCPUTime());
        
        List<Apex_Debug_Log__c> errorApexDebugLogs = new List<Apex_Debug_Log__c>();
        for (Integer index=0; index<results.size(); index++){
            Database.UpsertResult result = results[index];
            Funding_Opportunity_Staging__c fos = foss[index];
            Research_Opportunity__c fo = newFundingOpportunities[index];
            
            if (result.getId() != null)
                fos.I_RS_Funding_Opportunity_Record_Id__c = result.getId();
            
            fos.I_RS_Funding_Opp_Sync_Error_Message__c = '';
            
            if (result.isSuccess())
                fos.I_RS_Funding_Opportunity_Sync_Status__c = 'Successful';
            else {
                fos.I_RS_Funding_Opportunity_Sync_Status__c = 'Failed';
                
                for(Database.Error err : result.getErrors()) {
                    fos.I_RS_Funding_Opp_Sync_Error_Message__c += 
                        (err.getStatusCode() + ': ' + err.getMessage()) + '\r\n';

                    errorApexDebugLogs.add(
                        new Apex_Debug_Log__c(
                            Apex_Class_Name__c = 'FundingOppStagingToLiveSync',
                            Apex_Class_Method_Name__c = 'run',
                            Exception_Message__c = err.getMessage(),
                            Log_Type__c = 'Error',
                            Logged_In_Salesforce_User__c = UserInfo.getUserId(),
                            Request_Data__c = (JSON.serialize(fos) + ' | ' +
                                JSON.serialize(fo)).left(100000)
                        )
                    );
                }

                fos.I_RS_PRIME_Ready__c = false;

            }
            
        }
        if (!errorApexDebugLogs.isEmpty()){
            insert errorApexDebugLogs;
        }
        
        return newFundingOpportunities;
    }

    static Account getFOSsOrgFromKeyToOrgMap(Funding_Opportunity_Staging__c fos, Map<String, Account> keyToOrgMap){

        Account matchingOrg = keyToOrgMap.get(fos.I_RS_Primary_Funder_Id__c);
        return matchingOrg;

    }
    
    Map<Id, Research_Opportunity__c> getROsMap(List<Funding_Opportunity_Staging__c> foss){
        
        Map<Id, Research_Opportunity__c> ROsMap = new Map<Id, Research_Opportunity__c>();
        for (Funding_Opportunity_Staging__c fos : foss){
            
            if (Funding_Opportunity_Staging__c.I_RS_Funding_Opportunity_Record_Id__c != null)
                ROsMap.put(fos.I_RS_Funding_Opportunity_Record_Id__c, 
                          fos.I_RS_Funding_Opportunity_Record_Id__r);
        }
        
        return ROsMap;
    }
    
    Set<Id> getRecordIds(List<SObject> records){
        System.debug('getRecordIds');
        Set<Id> recordIds = new Set<Id>();
        
        for (SObject record : records){
            if (record.Id != null){
                recordIds.add(record.Id);
            }
        }
        
        System.debug('recordIds '+recordIds);
        
        return recordIds;
    }
    
    List<Funding_Opportunity_Staging__c> getStagingAndLiveFundingOpportunities(Set<Id> fosIds){
        
        System.debug('getStagingAndLiveFundingOpportunities');
        
        String SOQLQuery;
        Set<String> FOSQueryFields = new Set<String>();
        Set<String> ROQueryFields = new Set<String>();
        String FOSQueryFieldString;
        String ROQueryFieldString;
        List<Funding_Opportunity_Staging__c> stagingAndLiveFundingOpportunities;
        
        for (Funding_Opportunity_Field_Mapping__mdt fieldMapping: oppFieldMappings){
            if (fieldMapping.Staging_API_Name__c != null)
                FOSQueryFields.add(fieldMapping.Staging_API_Name__c);
            
            if (fieldMapping.Actual_API_Name__c != null)
                ROQueryFields.add('I_RS_Funding_Opportunity_Record_Id__r.'+fieldMapping.Actual_API_Name__c);
        }
        FOSQueryFieldString = String.join(new List<String>(FOSQueryFields), ', ');
        ROQueryFieldString = String.join(new List<String>(ROQueryFields), ', ');
        System.debug('FOSQueryFieldString '+FOSQueryFieldString);
        System.debug('ROQueryFieldString '+ROQueryFieldString);
        
        
        SOQLQuery = 'SELECT Id, '+FOSQueryFieldString+', '+
            ROQueryFieldString + ' FROM Funding_Opportunity_Staging__c WHERE Id IN :fosIds';
        system.debug('SOQL Query '+SOQLQuery);
        
        stagingAndLiveFundingOpportunities = Database.query(SOQLQuery);
        system.debug('stagingAndLiveFundingOpportunities '+stagingAndLiveFundingOpportunities);
        for (Funding_Opportunity_Staging__c fos : stagingAndLiveFundingOpportunities){
            System.debug('I_RS_Funding_Opportunity_Record_Id__c '+fos.I_RS_Funding_Opportunity_Record_Id__c );
        }
        
        return stagingAndLiveFundingOpportunities;
        
    }
    
    Research_Opportunity__c newOrExistingFundingOpportunity(Funding_Opportunity_Staging__c fos, Map<Id, Research_Opportunity__c> ROsMap){
        
        system.debug('newOrExistingFundingOpportunity Id: '+fos.I_RS_Funding_Opportunity_Record_Id__c);
        
        if (fos.I_RS_Funding_Opportunity_Record_Id__c != null){
            
            Research_Opportunity__c existingOpp = ROsMap.get(fos.I_RS_Funding_Opportunity_Record_Id__c);
            if (existingOpp != null){
                System.debug('existingOpp '+existingOpp);
                return existingOpp;
            }
        }
        System.debug('Returning new Research Opportunty');
        return new Research_Opportunity__c();
        
    }
    
    
    void copyFieldValue(Funding_Opportunity_Staging__c fos, Research_Opportunity__c ro, Funding_Opportunity_Field_Mapping__mdt fieldMapping){
        String srcFieldName = fieldMapping.Staging_API_Name__c;
        String destFieldName = fieldMapping.Actual_API_Name__c;
        
        if (srcFieldName != null){
            
            Object srcFieldValue = fos.get(srcFieldName);
            if (srcFieldValue != null){
                
                switch on fieldMapping.I_RS_Field_Type__c{
                    
                    when 'Text' {
                        String newDestValue = '';
                        String originalDestFieldValue = (String) ro.get(destFieldName);
                        if (originalDestFieldValue == null)
                            newDestValue = '';
                        else 
                            newDestValue = originalDestFieldValue + '\r\n\r\n';
                            
                        if (fieldMapping.I_RS_Hard_Coded_Text_Value__c != null)
                            newDestValue += fieldMapping.I_RS_Hard_Coded_Text_Value__c + ' ';
                            
                        newDestValue += (String) srcFieldValue;
                        newDestValue = newDestValue.replaceAll('<[^>]+>', '\r\n\r\n');
                        newDestValue = newDestValue.replaceAll('\r\n\r\n\r\n', '\r\n\r\n');
                        ro.put(destFieldName, newDestValue);
                    }
                    when 'Date' {
                        ro.put(destFieldName, (Date) srcFieldValue);
                    }
                    when 'DateTime' {
                        ro.put(destFieldName, (DateTime) srcFieldValue);
                    }
                    when 'Integer'{
                        ro.put(destFieldName, (Integer) srcFieldValue);
                    }
                    when 'Decimal'{
                        ro.put(destFieldName, (Decimal) srcFieldValue);
                    }
                    when 'Lookup'{
                        ro.put(destFieldName, (Id) srcFieldValue);
                    }
                    when 'Boolean'{
                        ro.put(destFieldName, (Boolean) srcFieldValue);
                    }
                    when else {
                        System.assert(false, 'Unsupported data type in field mapping');
                    }
                }
            }
        }
        else if (fieldMapping.I_RS_Hard_Coded_Text_Value__c != null){
            ro.put(destFieldName, fieldMapping.I_RS_Hard_Coded_Text_Value__c);
        }
        else {
        	ro.put(destFieldName, null);        
        }
        
    }

    
}