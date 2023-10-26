/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_UnitTestUtilities
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jie Tan   <tanjie@au1.ibm.com>
* @version        1.0
* @created        2021-01-28
* @description    Utility class for unit tests, providing:
*                 1. Common setup functions
*                 2. Data setup functions (e.g. createAccount, createContact)
*                 3. Any other reusable functions for test classes
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0            Jie Tan
* 2021-01-28      Created
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@IsTest
public with sharing class I_ST_UnitTestUtilities {
    
    //Gets a list of users with the supplied profile name.
    public static List<User> getUsers(String profileName) {
        return [SELECT Id, Name FROM User WHERE Profile.Name = :profileName AND IsActive = true];
    }
    
    //Gets record type with name for the supplied SObject
    public static Id getRecordTypeId(String sObjectName, String recordTypeName) {
        return Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }
    
    //Returns a Contact instance
    public static Contact createContact() {
        String fn = generateRandomString(6);
        String ln = generateRandomString(6);
        return new Contact(
            FirstName = fn,
            LastName = ln,            
            Email = fn + '.' + ln + '@test.com'
        );
    }
    
    //Returns a CourseParent__c instance
    public static CourseParent__c createCourseParent() {
        String extId = generateRandomString(6);
        return new CourseParent__c(
            I_ST_ExternalId__c = extId
        );
    }
    
    //Returns a CourseInstance__c instance
    public static CourseInstance__c createCourseInstance(Id courseParentId) {
        String extId = generateRandomString(6);
        return new CourseInstance__c(
            I_ST_ExternalId__c = extId,
            L_AD_CourseParent__c = courseParentId
        );
    }
    
    //Returns a CourseAvailability__c instance
    public static CourseAvailability__c createCourseAvailability(Id courseInstanceId) {
        String extId = generateRandomString(6);
        return new CourseAvailability__c(
            I_ST_ExternalId__c = extId,
            L_AD_CourseInstance__c = courseInstanceId
        );
    }
    
    
    //Returns a I_RM_Affiliation__c instance
    public static I_RM_Affiliation__c createAffiliation(Id contactId) {
        String extId = generateRandomString(6);
        return new I_RM_Affiliation__c(
            I_RM_External_Id__c = extId,
            I_RM_Contact__c = contactId
            
        );
    }
    
    

    
    //Returns an I_ST_Student_Course__c instance
    public static I_ST_Student_Course__c createStudentCourse(Id contactId, Id courseAvailabilityId) {
        String extId = generateRandomString(6);
        return new I_ST_Student_Course__c(
            I_ST_ExternalId__c = extId,
            I_ST_CourseAvailability__c = courseAvailabilityId,
            I_ST_Student__c = contactId
        );
    }

    //Returns an I_ST_Application__c instance
    public static I_ST_Application__c createApplication(Id contactId, Id courseAvailabilityId) {
        String name = generateRandomString(6);
        String extId = generateRandomString(6);
        return new I_ST_Application__c(
            Name = name,
            I_ST_ExternalId__c = extId,
            I_ST_Course_Availability__c = courseAvailabilityId,
            I_ST_Contact__c = contactId
        );
    }
    
    public static String generateRandomString(Integer len) {
        Final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }
    
   /* public static void setCTEFireAlways() {
        if(!ContactTriggerHandler.runCTEAlways) {
            ContactTriggerHandler.runCTEAlways = true;
        }
    }*/
    
    public static void skipLeadAccountCleanup() {
        if(ContactTriggerHandler.runLeadAccountCleanup) {
            ContactTriggerHandler.runLeadAccountCleanup = false;
        }
    }
    
    //returns the String of recordTypeIds comma separated
    public static String recordTypeIds(String sObjectName, String recordTypeAPINameCommaSeparated) {
        String recordTypeIdsString;
        
        Set<String> recordTypeSet = new Set<String>();
        set<String> recordtypeIDs = new Set<String>();
        recordTypeSet.addAll(GlobalUtility.trimStringList(recordTypeAPINameCommaSeparated.split(GlobalConstants.COMMA)));
        for(RecordType recType: [Select Id From RecordType WHERE IsActive=True AND sObjectType =: sObjectName and DeveloperName IN :recordTypeSet]) {
            recordtypeIDs.add(recType.Id);
        }     
        recordTypeIdsString = string.valueof(recordtypeIDs).replace('{','').replace('}','');
        return recordTypeIdsString;
    } 
    
    //IST - Create custom setting Batch Scoring
    public static List<I_ST_BatchScoring__c> createBatchScoringCustomSetting(String affiliationRecordTypeIds,
                                                                             Integer contactBatchSize,
                                                                             String caseRecordTypeIds,
                                                                             Integer activityBatchSize,
                                                                             String interactionRecordTypeIds,
                                                                             Integer interactionBatchSize){
                                                                                 List<I_ST_BatchScoring__c> listBatchScoringSetting = new List<I_ST_BatchScoring__c>();
                                                                                 if(affiliationRecordTypeIds != null){
                                                                                     I_ST_BatchScoring__c batchScoringSettings = new I_ST_BatchScoring__c(
                                                                                         I_ST_BatchSize__c = contactbatchSize,
                                                                                         I_ST_RecordType_SFIDs__c= affiliationRecordTypeIds,
                                                                                         I_ST_CronExpression__c = '0 35 17 * * ?', 
                                                                                         I_ST_Last_N_Hour__c= 24,
                                                                                         Name = GlobalConstants.I_RM_AFFILIATIONSCORING);
                                                                                     
                                                                                     listBatchScoringSetting.add(batchScoringSettings);
                                                                                 }
                                                                                 if(caseRecordTypeIds != null){
                                                                                     I_ST_BatchScoring__c batchScoringSettings1 = new I_ST_BatchScoring__c(
                                                                                         I_ST_BatchSize__c = activityBatchSize,
                                                                                         I_ST_RecordType_SFIDs__c= caseRecordTypeIds,
                                                                                         I_ST_CronExpression__c ='0 30 18 * * ?', 
                                                                                         I_ST_Last_N_Hour__c = 24,
                                                                                         Name = GlobalConstants.I_ST_CASESCORING);
                                                                                     listBatchScoringSetting.add(batchScoringSettings1);
                                                                                 }        
                                                                                 if(interactionRecordTypeIds != null){
                                                                                     I_ST_BatchScoring__c batchScoringSettings2 = new I_ST_BatchScoring__c(
                                                                                         I_ST_BatchSize__c = interactionBatchSize,
                                                                                         I_ST_RecordType_SFIDs__c= interactionRecordTypeIds,
                                                                                         I_ST_CronExpression__c ='0 30 19 * * ?', 
                                                                                         I_ST_Last_N_Hour__c = 24,
                                                                                         Name = GlobalConstants.I_ST_INTERACTIONSCORING);
                                                                                     listBatchScoringSetting.add(batchScoringSettings2);
                                                                                 }
                                                                                 return listBatchScoringSetting;
                                                                             }
    
    public static I_RM_Affiliation_Settings__c createAffiliationSettings(){
        I_RM_Affiliation_Settings__c objAffiliationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Inactive_Status',
                                                                                               I_RM_Status__c = 'Inactive');
        return objAffiliationSettings;        
    }
    
     public static I_RM_Affiliation_Settings__c createEarlyEntryCourses(){
        I_RM_Affiliation_Settings__c objAffiliationSettings = new I_RM_Affiliation_Settings__c(Name = 'I_RM_Early_Entry_Courses',
        Value__c ='Enabling Course,Non Award Course,Preliminary,Study Abroad - UG,Foundation Course UG,Study Abroad - PG,Cross Institution Undergrad,Cross Institutional - Post Grad');
        return objAffiliationSettings;        
    }

    
    //IST - Create instance of Domestic Lead
    public static Contact createContactForScore(String fname, 
                                                String lName, 
                                                String emailStr, 
                                                String personalEmailStr,                                                
                                                String postCode)
                                                {       
                                                    Contact newDomesticLead = new Contact(FirstName = fname, 
                                                                                          LastName = lName,
                                                                                          Email = emailStr,
                                                                                          I_ST_Personal_Email__c = personalEmailStr,                                                                                          
                                                                                          OtherPostalCode = postCode);
                                                                                         
                                                    return newDomesticLead;
                                                }
    
    public static list<I_RM_Affiliation__c> createAffiliationRecords(String recordTypeId,Id ContactId){
        List<I_RM_Affiliation__c> lstAffiliation = new List<I_RM_Affiliation__c>();
    	I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = ContactId,
                                                                     recordTypeId = recordTypeId,
                                                                  I_RM_Enquirer_Type__c ='Year 10',
                                                                  I_RM_Time_Frame_to_Study__c= '3-6 months',
                                                                  I_RM_Incremental_Score__c = 0,
                                                                  I_RM_Mobile_Phone__c = '0415822665',
                                                                  I_RM_Status__c  ='Not Qualified',
                                                                  I_RM_Role__c ='Domestic Lead',   
                                                                  I_RM_Score__c = 0   
                                                                 );
        lstAffiliation.add(newAffiliation);
        return lstAffiliation;
        
   	}
    
    public static list<I_RM_Affiliation__c> createApplicantAffiliationRecords(String recordTypeId,Id ContactId){
        List<I_RM_Affiliation__c> lstAffiliation = new List<I_RM_Affiliation__c>();
    	I_RM_Affiliation__c newAffiliation = new I_RM_Affiliation__c(I_RM_Contact__c = ContactId,
                                                                     recordTypeId = recordTypeId,
                                                                  I_RM_Enquirer_Type__c ='Year 11',
                                                                  I_RM_Time_Frame_to_Study__c= '3-6 months',
                                                                  I_RM_Incremental_Score__c = 0,
                                                                  I_RM_Mobile_Phone__c = '0415822665',
                                                                  I_RM_Role__c ='Applicant',
                                                                  I_RM_Status__c  ='Not Processed',   
                                                                  I_RM_Score__c = 0   
                                                                 );
        lstAffiliation.add(newAffiliation);
        system.debug('lstAffiliation'+lstAffiliation);
        return lstAffiliation;
        
   	}
    
    //IST - Create instance of Interaction
    public static I_ST_Interaction__c newListOfContactRelatedInteractions(Id InteractionRecordTypeId,Contact contactforTest,String fname,String lname,
                                                                          String mobileNo,String email,String catagory,String subCategory,I_RM_Affiliation__c affiliationForTest){
                                                                              
                                                                              I_ST_Interaction__c newInteraction1 = new I_ST_Interaction__c(I_ST_FirstName__c = fname,
                                                                                                                                            I_ST_Last_Name__c = lname,
                                                                                                                                            I_ST_Mobile__c = mobileNo,
                                                                                                                                            I_ST_Email__c = email, 
                                                                                                                                            I_ST_Source_Category__c = catagory,
                                                                                                                                            I_ST_Source_Sub_Category__c= subCategory,                                     
                                                                                                                                            I_ST_Contact__c = contactforTest.id,
                                                                                                                                            I_RM_Affiliation__c = affiliationForTest.id,
                                                                                                                                            RecordTypeId = InteractionRecordTypeId);
                                                                              
                                                                              return newInteraction1;
                                                                          }    
    
    //Get list of cases for incremental score.
    public static Case newListOfContactRelatedCases(Id CaseRecordTypeId,Contact contactforTest,Integer incrementalScore,Boolean doNotScore,String Title,String status,String email,I_RM_Affiliation__c affiliationForTest){
       	id affiliationid = null;
        if(affiliationForTest != null){
            affiliationid = affiliationForTest.id; 
        }
        
        Case newCase1 = new Case(Subject = Title,
                                 Type='Entry Requirements',
                                 I_ST_Do_not_Score__c = doNotScore,
                                 RecordTypeId = CaseRecordTypeId,
                                 I_ST_Incremental_Score__c = incrementalScore,
                                 Status = status,
                                 SuppliedEmail = email,
                                 I_ST_Score_Calculated__c = false,
                                 I_RM_Affiliation__c = affiliationid,
                                 ContactId = contactforTest.id);
        return newCase1;     
    }
    
    //IST - Create instance of User
    public static User newUser(String userNamePrefix, Id profileId){
        return new User(
            ProfileId = profileId,
            Username = userNamePrefix + UserInfo.getOrganizationId() + '@test.com',
            Alias = 'batman1',
            Email='bruce.wayne1@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            FirstName='Bruce1',
            LastName='Wayne1',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
    }
    
    // Creating instance of contacts     
    public static List<Contact> createTestContactRecords(Integer noOfContact,Boolean withAccount){
        List<Contact> lstNewContact = new List<Contact>();
        Id AdminAccountRecordType = [SELECT Id FROM recordType WHERE developername =: GlobalConstants.ACCOUNT_RECORD_TYPE_NAME_Admin_Account AND sObjectType = 'Account' LIMIT 1].id;
        //Id AccountId = [SELECT Id,Name FROM Account WHERE RecordTypeId =:AdminAccountRecordType WITH SECURITY_ENFORCED Limit 1].Id;
        for(Integer i=1; i<=noOfContact; i++){
            Contact objContact = new Contact();
            objContact.FirstName = 'TestFirst'+i;
            objContact.LastName = 'TestLast'+i;
            objContact.MobilePhone= '0415 822 605';
            if(withAccount){
                //objContact.AccountId = AccountId;
            }
            lstNewContact.add(objContact);
        }
        return lstNewContact;
    }


}