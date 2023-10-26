/**
* Created by burnside on 2019-04-16.
*/

@isTest
public with sharing class TestUtility {
    
    public static User newUser(String userNamePrefix, Id profileId, Id portalRoleId, Id portalContactId){
        return new User(
            UserRoleId = portalRoleId,
            ProfileId = profileId,
            contactId = portalContactId,
            Username = userNamePrefix + UserInfo.getOrganizationId() + '@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            FirstName='Bruce',
            LastName='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
    }
    
    
    public static HERDC_Category__c  newDefaultHERDCCategory(String name) {
    	return new HERDC_Category__c (
            Name = name,
            I_RS_Description__c = name,
            I_RS_Code__c = '0001',
            I_RS_Active__c = true,
            I_RS_Start_Date__c = System.today(),
            I_RS_End_Date__c = System.today() + 60            
        );    
    }
    public static Account newEmptyAccount(String name, String recordTypeName){

        Id recordTypeId = 
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

        return new Account(
            Name = name,
            recordTypeId = recordTypeId,
            I_RS_Default_HERDC_category__c = newDefaultHERDCCategory('1.2 Aust. Comp. Grants Rural R&D').Id
        );
    }

    public static Account newEmptyLTUAccount(String name){
        return newEmptyAccount(name, GlobalConstants.ACCOUNT_RECORD_TYPE_NAME_LTU_ORG_UNIT);
    }
    public static Account newEmptyExternalAccount(String name){
        return newEmptyAccount(name, GlobalConstants.ACCOUNT_RECORD_TYPE_NAME_EXTERNAL_ORG);
    }   
    
    /**
    * @description - simple dynamic creation of single Sobject records
    *
    * @param objectFieldMap - field map of field api names and values
    * @param objName - API Name of the object
    * @return - Instance of an SObject with all the field values and API Names
    **/
    public static SObject newSObjectInstance(
        Map<String, String> objectFieldMap,
        String objName
    ){
        SObject sObj = (SObject) Type.forName('Schema', objName).newInstance();
        for(String fieldAPIName : objectFieldMap.keySet()) {
            sObj.put(fieldAPIName, objectFieldMap.get(fieldAPIName));
        }   
        return sObj;     
    }

    public static Contact newContact(Id accountId){

       // Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(
            //recordTypeDeveloperName).getRecordTypeId();

        return new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = accountId,
           // recordTypeId = recordTypeId,
            Email = System.now().millisecond() + 'test@test.com'
        );
    }

    public static Contact createContact(Id accountId){

        return new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = accountId,
            Email = System.now().millisecond() + 'test@test.com'
        );
    }
    
    
    public static Event newEvent(Id whatId){
        
        return new Event(
            Subject = 'Test Event',
            WhatId = whatId,
            StartDateTime = DateTime.now(),
            durationInMinutes = 60
        );
        
    }
    
    public static Task newTask(Id whatId){
        
        return new Task(
            Subject = 'Test Task',
            WhatId = whatId,
            ActivityDate = Date.today()
        );
        
    }
    
    
    public static Project_Proposal__c newProjectProposal(){
        return new Project_Proposal__c(
            Name = 'Test Title',
            I_RS_IP_Position__c = 'Owned by La Trobe',
            I_RS_Publishing_Rights__c = 'Without Approval',
            I_RS_Project_Start_Date__c = Date.today(),
            I_RS_Submission_Date__c = Date.today().addYears(1),
            I_RS_Project_End_Date__c = Date.today().addYears(7),
            I_RS_Theme__c = 'No theme alignment'
        );
    }
    
    public static Research_Opportunity__c newResearchOpportunity(Boolean isPrivate){
        return new Research_Opportunity__c(
            Name = 'Test Research Opportunity',
            I_RS_Status__c = 'Active',
            I_RS_Source__c = 'Approach by industry',
            I_RS_Proposal_to_be_Submitted_By__c = 'Research Office',
            I_RS_Start_Date__c = Date.today(),
            I_RS_Private__c = isPrivate,
            I_RS_Submission_Date__c = Date.today() + 365
        );
    }
    
    
    public static External_Document__c newExternalDocument(Id contractId, Id projectProposalId, Id researchOpportunityId){
        
        return new External_Document__c(
            Name = 'External Document', 
            I_RS_Contract__c = contractId,
            I_RS_Project_Proposal__c = projectProposalId,
            I_RS_Research_Opportunity__c = researchOpportunityId
        );
        
    }
    
    
    public static Classification_Code__c newClassificationCode(Id classificationMasterId, Id researcherId, Id projectProposalId, Id researchOpportunityId){
        
        return new Classification_Code__c(
            I_RS_Classification_Master__c = classificationMasterId,
            I_RS_Project_Proposal__c = projectProposalId,
            I_RS_Percentage__c = 20
        );
    }
    
    public static Classification_Master__c newClassificationMaster(String name, String clsCode, String type, Boolean active){
        
        return new Classification_Master__c(
            Name = name,
            I_RS_Classification_Code__c = clsCode,
            I_RS_Type__c = type,
            I_RS_Active__c = active
        );
        
    }
    
    public static Junction_Linkage__c newJunctionLinkage(Id accountId, Id projectProposalId, Id researchOpportunity){
        
        return new Junction_Linkage__c(
            I_RS_Awarded_to__c = accountId,
            I_RS_Project_Proposal__c = projectProposalId,
            I_RS_Research_Opportunity__c = researchOpportunity
        );
        
    }
    
    
    public static Contract__c newContract(Id projectProposalId, Id organisationId){

        if (organisationId == null){
            Account organisation = newEmptyAccount('Test Account', 'I_RS_External_Organisation');
            Database.insert(organisation, getAllowDuplicatesDMLOption());
            organisationId = organisation.Id;
        }

        return new Contract__c(
            I_RS_Project_Proposal__c = projectProposalId,
            I_RS_Organisation__c = organisationId
        );
    }
    
    public static Related_Contract__c newRelatedContract(Id contractId){
        return new Related_Contract__c(
            I_RS_Contract__c = contractId
        );
        
    }
    
    public static Project_Team_Member__c newProjectTeamMember(Id projectProposalId, String role, Id userContactId) {
        return new Project_Team_Member__c(
            I_RS_Project_Proposal__c = projectProposalId,
            I_RS_Role__c = role,
            I_RS_Project_Team_Member__c = userContactId,
            I_Rs_Active__c = true
        );
    }

    public static Research_Opportunity_Team_Member__c newFundingOpportunityTeamMember(Id roId, Id userContactId, Id userId) {
        return new Research_Opportunity_Team_Member__c(
            I_RS_Research_Opportunity__c = roId,
            Role__c = 'Primary Contact Person',
            I_RS_Team_Member__c = userContactId,
            I_RS_Status__c = GlobalConstants.RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED,
            I_RS_Internal_Team_Member__c = userId
        );
    }
    
    public static Research_Output__c newResearchOutput(String roName){
    	return new Research_Output__c (
            Name = roName,
            I_RS_Confidential__c = false
        );
    }
    
    public static Authorship_Research_Output_Team_Member__c newAuthorship(String Title, Id ResearchOutputId, Id ContactId, String Role){
    	return new Authorship_Research_Output_Team_Member__c (
        	//Name = Title,
            I_RS_Research_Output__c = ResearchOutputId,
            I_RS_Contact__c = ContactId,
            I_RS_Type_Role__c = Role
        );
    }

    public static Budget__c newBudget(Id projectProposalId){
        return new Budget__c(
            I_RS_Project_Proposal__c = projectProposalId
        );
    }

    public static Budget_Line_Item__c newBudgetLineItem(Id budgetId){
        return new Budget_Line_Item__c(
            I_RS_Budget__c = budgetId,
            I_RS_Category__c = 'Current La Trobe Staff',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_1_Cost__c = 0,
            Year_2_Cost__c = 0,
            Year_3_Cost__c = 0,
            Year_4_Cost__c = 0,
            Year_5_Cost__c = 0
        );
    }
    public static Budget_Line_Item__c newBudgetLineItem(Id budgetId, String recordTypeName, Decimal yearlyCost){

        Map<String,Schema.RecordTypeInfo> rtMapByName = 
            Schema.SObjectType.Budget_Line_Item__c.getRecordTypeInfosByDeveloperName();
        Id recordTypeId = (Id) rtMapByName.get(recordTypeName).getRecordTypeId();

        Budget_Line_Item__c budgetLineItem = new Budget_Line_Item__c(
            I_RS_Budget__c = budgetId,
            recordTypeId = recordTypeId,
            I_RS_Category__c = 'Current La Trobe Staff',
            I_RS_Unit_of_Time__c = 'Years',
            Year_1_Quantity__c = 1,
            Year_2_Quantity__c = 1,
            Year_3_Quantity__c = 1,
            Year_4_Quantity__c = 1,
            Year_5_Quantity__c = 1,
            Year_6_Quantity__c = 1,
            Year_7_Quantity__c = 1,
            Year_1_Cost__c = yearlyCost,
            Year_2_Cost__c = yearlyCost,
            Year_3_Cost__c = yearlyCost,
            Year_4_Cost__c = yearlyCost,
            Year_5_Cost__c = yearlyCost,
            Year_6_Cost__c = yearlyCost,
            Year_7_Cost__c = yearlyCost,
            I_RS_Amount__c = (yearlyCost * 7)
        );
        return budgetLineItem;
    }

    public static Salary_Table__c newSalaryTable(String salaryGradeGroup, Integer salaryGradeNumber, String year, Decimal salary){
        return new Salary_Table__c(
            Name = salaryGradeGroup + ' ' + salaryGradeNumber,
            I_RS_HR_System_Group_ID__c = salaryGradeGroup + ' ' + salaryGradeNumber,
            I_RS_Salary_Grade_Group__c = salaryGradeGroup,
            I_RS_Salary_Grade_Group_Number__c = salaryGradeNumber,
            I_RS_Year__c = year,
            I_RS_Salary__c = salary
        );
    }


    public static void insertGSTRate(){

        GST__c gstSetting = new GST__c(
            Name = 'Org Default',
            I_RS_Current_Rate__c = 10
        );
        insert gstSetting;

    }

 
    public static Database.DMLOptions getAllowDuplicatesDMLOption(){
        Database.DMLOptions dmlOptions = new Database.DMLOptions(); 
        dmlOptions.DuplicateRuleHeader.allowSave = true;

        return dmlOptions;
    }
    
    public static void createBatchScoringCustomSettings(String recTypeIds) {
        I_ST_BatchScoring__c scoreSettings = new I_ST_BatchScoring__c();
        scoreSettings.Name = 'I_RM_AffiliationScoring';
        scoreSettings.I_ST_CronExpression__c = '0 30 1 1/1 * ? *';
        scoreSettings.I_ST_BatchSize__c = 200;
        scoreSettings.I_ST_Last_N_Hour__c = 48;
        scoreSettings.I_ST_RecordType_SFIDs__c = recTypeIds;
        insert scoreSettings;
    }

}