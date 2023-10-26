public with sharing class ResearchProfessionalServiceProcess {
    
    public static Map<String,Account> mapAccoutWithIds;
    public static Map<String,Account> mapAccountWithName;
    
    
    public static Boolean opportunityStagingRecordProcess(ResearchProfessionalWrapper objRPWrapper, String eligiblityRegions){
        
        List<Funding_Opportunity_Staging__c> lstFundOppStg = new List<Funding_Opportunity_Staging__c>();
        
        String eligibleSeparator = (Label.RP_Eligibility_Separator != null)? Label.RP_Eligibility_Separator : '|';
        //getAccounts();
        if(objRPWrapper != null && objRPWrapper.records.size()  > 0){
            
            try{
                
                Funding_Opportunity_Staging__c objOppStg;
                for( ResearchProfessionalWrapper.Records recs : objRPWrapper.records){
                     objOppStg = new Funding_Opportunity_Staging__c();
                    //Get Opportunity staging name field length and trucate the Opportunity name according to maximum text length.
                    Schema.DescribeFieldResult F = Funding_Opportunity_Staging__c.Name.getDescribe();
					Integer namelength = F.getLength();
                    
                    objOppStg.External_Id__c = String.valueOf(recs.id);
                    objOppStg.I_RS_RP_ID__c = String.valueOf(recs.id);
                    if(recs.name != null && recs.name.length() <= namelength)
                    	objOppStg.Name = recs.name;
                    else
                        objOppStg.Name = recs.name.substring(0, namelength);
                    objOppStg.I_RS_Full_Name__c = recs.name;
                    objOppStg.I_RS_Bullet__c = recs.bullet;
                    objOppStg.I_RS_Description__c  = recs.description;
                    objOppStg.I_RS_Locale__c = recs.locale;
                    if(recs.added != null){
                       objOppStg.I_RS_Date_Added__c =  Date.valueOf(recs.added);
                    }
                    objOppStg.I_RS_Deadline_Info__c = recs.deadlineInfo;
                    if(recs.webpage != null && recs.webpage.length() > 255)
                    	objOppStg.I_RS_Funders_Webpage__c  = recs.webpage.substring(0, 255);
                    else
                        objOppStg.I_RS_Funders_Webpage__c  = recs.webpage;
                    objOppStg.I_RS_Funders_Full_Webpage__c  = recs.webpage;
                    objOppStg.I_RS_Funding_Category__c = recs.australianFundingCategory;
                    if(recs.researchProfessionalWebpage != null && recs.researchProfessionalWebpage.length() > 255)
                    	objOppStg.I_RS_Research_Professional_Webpage__c = recs.researchProfessionalWebpage.substring(0, 255);
                    else
                        objOppStg.I_RS_Research_Professional_Webpage__c = recs.researchProfessionalWebpage;
                    
                    objOppStg.I_RS_Research_Professional_Webpage__c = recs.researchProfessionalWebpage;
                    // Check primary funder account in SFDC and map with Opportunity staging record. Else Create new Account and attach with Opportunity staging record. 
                    if(recs.primaryFunder != null){
                        
                        if(!String.isEmpty(String.valueOf(recs.primaryFunder.id)))
                            objOppStg.I_RS_Primary_Funder_Id__c = String.valueOf(recs.primaryFunder.id);
                        if(!String.isEmpty(recs.primaryFunder.name))
                            objOppStg.I_RS_Primary_Funder_Name__c = recs.primaryFunder.name;
                        if(recs.primaryFunder.region != null){
                            if(!String.isEmpty(recs.primaryFunder.region.name))
                                objOppStg.I_RS_Primary_Funder_Region__c = recs.primaryFunder.region.name;
                            if(!String.isEmpty(recs.primaryFunder.region.regionCode))
                                objOppStg.I_RS_Primary_Funder_Region_Code__c = recs.primaryFunder.region.regionCode;
                        }
                    }
                    //Check for disciplines info and add with '\r\n' separated values.
                    if(recs.disciplines != null && !recs.disciplines.isEmpty() && recs.disciplines.size() > 0 ){
                        for(ResearchProfessionalWrapper.Disciplines discp : recs.disciplines){
                            if(String.isEmpty(objOppStg.I_RS_Discipline__c))
                                objOppStg.I_RS_Discipline__c = discp.label;
                            else
                                objOppStg.I_RS_Discipline__c = objOppStg.I_RS_Discipline__c + '\r\n' + discp.label;
                        }
                    }
                    //Check for purpose info and add with '\r\n' separated values.
                    if(recs.purpose != null && recs.purpose.size() > 0 ){
                        for(ResearchProfessionalWrapper.Purpose purp : recs.purpose){
                            if(String.isEmpty(objOppStg.I_RS_Purpose__c))
                                objOppStg.I_RS_Purpose__c = purp.name;
                            else
                                objOppStg.I_RS_Purpose__c = objOppStg.I_RS_Purpose__c + '\r\n' + purp.name;
                        }
                    }
                    //Check for eligibility info and add with '|' separated values.
                    if(recs.eligibility != null && !recs.eligibility.isEmpty() && recs.eligibility.size() > 0 ){
                        
                        for(ResearchProfessionalWrapper.Eligibility eligible : recs.eligibility){
                            
                            // Add eligibility Host information under Eligible child record.
                            if(!eligible.hosts.isEmpty() && eligible.hosts.size() >0){
                                for(String strHost : eligible.hosts){
                                    if(String.isEmpty(objOppStg.I_RS_Eligibility_Hosts__c))
                                        objOppStg.I_RS_Eligibility_Hosts__c = strHost;
                                    else
                                        objOppStg.I_RS_Eligibility_Hosts__c = objOppStg.I_RS_Eligibility_Hosts__c+ eligibleSeparator + strHost;
                                
                                }
                            }
                       
                            // Add eligibility Region information under parent Opportunity staging record.
                            if(!eligible.regions.isEmpty() && eligible.regions.size() >0){
                                for(ResearchProfessionalWrapper.Region rgion : eligible.regions){
                                    if(String.isEmpty(objOppStg.I_RS_Eligibility_Region_Code__c))
                                        objOppStg.I_RS_Eligibility_Region_Code__c = rgion.regionCode;
                                    else
                                        objOppStg.I_RS_Eligibility_Region_Code__c = (objOppStg.I_RS_Eligibility_Region_Code__c + eligibleSeparator + rgion.regionCode).left(255);
                                    
                                    if(String.isEmpty(objOppStg.I_RS_Eligibility_Regions__c))
                                        objOppStg.I_RS_Eligibility_Regions__c = rgion.name;
                                    else
                                        objOppStg.I_RS_Eligibility_Regions__c = objOppStg.I_RS_Eligibility_Regions__c + eligibleSeparator + rgion.name;
                                    

                                    if (!objOppStg.I_RS_PRIME_Ready__c){

                                        if (!String.isEmpty(rgion.name) && !String.isEmpty(eligiblityRegions) && 
                                            eligiblityRegions.containsIgnoreCase(rgion.name)) {
                                            objOppStg.I_RS_PRIME_Ready__c = true;
                                        }
                                        else { 
                                            objOppStg.I_RS_Funding_Opportunity_Sync_Status__c = 'Region Not Eligible';
                                        }

                                    }
                                    
                                }
                            }
                           
                        }
                     }
                    
                    if(recs.deadlines != null && !recs.deadlines.isEmpty() && recs.deadlines.size() > 0){
                        Funding_Opportunity_Staging__c objFOpp;
                        for(integer i =0; i < recs.deadlines.size() ; i++ ){
                            objFOpp = new Funding_Opportunity_Staging__c();
                            objFOpp = objOppStg.clone();
                            objFOpp.External_Id__c = String.valueOf(recs.id) + '_' + recs.deadlines[i].deadline;
                            //objFOpp.I_RS_Submission_Date__c = Date.parse(recs.deadlines[i].deadline);
                            System.debug('--> Deadline date is: '+ recs.deadlines[i].deadline);
                            objFOpp.I_RS_Submission_Date__c = (!String.isEmpty(recs.deadlines[i].deadline)) ? Date.valueOf(recs.deadlines[i].deadline) : null;
                            objFOpp.Deadline_Forecast__c = recs.deadlines[i].unconfirmed;
                            lstFundOppStg.add(objFOpp);
                        }
                    }
                }
                // Upsert Research Professional Funding Opportunity records into SFDC's Funding Opportunity Staging object.
                Schema.SObjectField extField = Funding_Opportunity_Staging__c.Fields.External_Id__c;
                List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
                try{
                    Database.UpsertResult [] results = Database.upsert(lstFundOppStg,extField,false);
                    Set<String> OppStagingIds = new Set<String>();
                    // On Successfull Upsert of Funding Opportunity staging records, Set the Parent Id into respective eligibility child records .
                    for(Integer index = 0, size = results.size(); index < size; index++) {
                        if(results[index].isSuccess()) {
                         }
                        else{
                            List<String> errorMessages = new List<String>();
                            for(Database.Error err : results[index].getErrors()) {
                                errorMessages.add(err.getMessage());
                            }
                            errorLogs.add(
                                new Apex_Debug_Log__c(
                                    Apex_Class_Name__c = 'ResearchProfessionalServiceProcess',
                                    Apex_Class_Method_Name__c = 'opportunityStagingRecordProcess',
                                    Exception_Message__c = String.join(errorMessages, '; '),
                                    Log_Type__c = 'Error',
                                    Logged_In_Salesforce_User__c = UserInfo.getUserId(),
                                    Request_Data__c = JSON.serialize(lstFundOppStg[index]).left(100000)
                                )
                            );
                        }
                    }
                    if (!errorLogs.isEmpty()){
                        insert errorLogs;
                    }

                }
                catch(DmlException e){
                    System.debug('Error in upserting funding opportunity staging records - ' + e.getMessage());
                }
            }
            catch(exception ex){
                System.debug(ex.getMessage());
            }
            
        }
        return true;
    }
  
    
}