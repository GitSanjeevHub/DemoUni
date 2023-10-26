/**
─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_CaseTriggerHelper
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author Teja Yenduri
* @date 2022-02-18
* 

* LTU360-886   createLeadAffiliation method is used to copy Attributes to the Domestic Lead Affiliation if an enquiry is raised.
* @description : This class is used For Case trigger helper methods
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public  without sharing class I_ST_CaseTriggerHelper {
    public static Id caseEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Enquiry').getrecordTypeId();
    public static ID leadRecordID = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId();
    public static Id caseActivityBooking = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('I_ST_Activity_Booking').getrecordTypeId();
    public static Id CASE_INT_ENQUIRY_RECTYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORD_TYPE_NAME_INT_ENQUIRY).getRecordTypeId();
    public static Id AFFILIATION_INT_LEAD_RECTYPE_ID = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_INT_LEAD).getRecordTypeId();
    public static List<Id> IDS_THAT_REQUIRE_CONTACT_UPSERT = new List<Id>{
        caseEnquiryId,
        caseActivityBooking,
        CASE_INT_ENQUIRY_RECTYPE_ID
    };
    public static List<Id> IDS_THAT_REQUIRE_AFFILIATION_UPSERT = new List<Id>{
        caseEnquiryId,
        CASE_INT_ENQUIRY_RECTYPE_ID
    };
    public static Id AffiliationExternalContact = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_External_Contact').getrecordTypeId();
    public static List<String> inactiveStatus = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');    
    public static string APPLICANT='Applicant';
    public static string DOMESTICLEAD='Domestic Lead';
    public static string INTERNATIONAL_LEAD_ROLE = 'Student Lead (Int)';
    public static string SCHOOLREPRESENTATIVE='School Representative';
    public static List<String> ROLES_THAT_REQUIRE_AFFILIATION_UPSERT = new List<String>{
        APPLICANT,
        DOMESTICLEAD,
        INTERNATIONAL_LEAD_ROLE
    };

    public static void updateContactOnCase(List<Case> caseList){
        Set<String> keysToMatch = new Set<String>();
        Set<String> emailKeysToMatch = new Set<String>();
        Set<String> phoneKeysToMatch = new Set<String>();
        Map<String,Case> caseMapToContact= new Map<String,Case>();
        
        
        
        for(case caseDetail:caseList){
            //if suppliedemail is not null match the affiliation email with the case supplied email and link matching contact to case.
            //query on affiliation with email find matching affiliation.contactId. 
            //if contact id is exists link to currect case.
            //if not than create contact and link to case.
            String firstName, lastName, keyStr;
            firstName = caseDetail.I_ST_Contact_First_Name__c;
            lastName = caseDetail.I_ST_Contact_Last_Name__c; 
            if( IDS_THAT_REQUIRE_CONTACT_UPSERT.contains(caseDetail.RecordTypeId) && 
                caseDetail.ContactId == null
            ){
                if(caseDetail.SuppliedEmail!=null){
                    caseMapToContact.put(caseDetail.SuppliedEmail,caseDetail);
                    emailKeysToMatch.add(caseDetail.SuppliedEmail);
                    keysToMatch.add(caseDetail.SuppliedEmail);
                }else if(caseDetail.SuppliedPhone!=null){
                    keyStr = (!String.isBlank(firstName)) ? (caseDetail.SuppliedPhone + firstName)
                                                          : caseDetail.SuppliedPhone;
                    keyStr = (!String.isBlank(lastName)) ? (keyStr + lastName)
                                                         : keyStr;
                    caseMapToContact.put(keyStr,caseDetail); //added SuppliedPhone as key insted of keyStr
                    phoneKeysToMatch.add(caseDetail.SuppliedPhone);
                    keysToMatch.add(caseDetail.SuppliedPhone);
                }
                
            }
            if(caseDetail.RecordTypeId == caseActivityBooking){
                    if(caseDetail.I_ST_Proposed_Activity_Start_Datetime__c!=NULL) {
                        caseDetail.I_ST_Proposed_Start_Date_and_Time__c=datetime.valueOf(caseDetail.I_ST_Proposed_Activity_Start_Datetime__c);
                    }
                    if(caseDetail.I_ST_Proposed_Activity_End_Datetime__c!=NULL) {
                        caseDetail.I_ST_Proposed_End_Date_and_Time__c=datetime.valueOf(caseDetail.I_ST_Proposed_Activity_End_Datetime__c);
                    }
                    
                    
                }
        }
        if(!emailKeysToMatch.isEmpty()) {

            keysToMatch.addAll(emailKeysToMatch);

        }

        if(!phoneKeysToMatch.isEmpty()) {

            keysToMatch.addAll(phoneKeysToMatch);

        }
        
        //First get the affilations, populate the ContactID from the affiliation to Case
        //<----->
        
        map<string,string> caseContactMap=new  map<string,string>();
        Map<String,Case> caseCreateContactMap=new Map<String,Case>();
        
        List<I_RM_Affiliation__c> affliationList = new List<I_RM_Affiliation__c>();

        if(!emailKeysToMatch.isEmpty() && !phoneKeysToMatch.isEmpty()) {

            affliationList = [SELECT I_RM_Contact__c,I_RM_Contact__r.id,I_RM_Mobile_Phone__c,I_RM_Contact__r.Name, CreatedDate,

                                     I_RM_Email__c,I_RM_Work_Email__c,I_RM_Student_Email__c,I_RM_Contact__r.FirstName,I_RM_Contact__r.LastName,

                                     I_RM_Phone__c,I_RM_Other_Phone__c, I_RM_Role__c, I_RM_Status__c, RecordTypeId

                              FROM I_RM_Affiliation__c

                              WHERE (I_RM_Email__c IN : emailKeysToMatch OR

                                     I_RM_Student_Email__c IN : emailKeysToMatch OR

                                     I_RM_Work_Email__c IN : emailKeysToMatch OR

                                     I_RM_Mobile_Phone__c IN : phoneKeysToMatch OR

                                     I_RM_Phone__c IN : phoneKeysToMatch OR

                                     I_RM_Other_Phone__c IN : phoneKeysToMatch

                                    )

                              ORDER BY CreatedDate DESC];    

        }
        else if(!emailKeysToMatch.isEmpty()) {

            affliationList = [SELECT I_RM_Contact__c,I_RM_Contact__r.id,I_RM_Mobile_Phone__c,I_RM_Contact__r.Name, CreatedDate,

                                     I_RM_Email__c,I_RM_Work_Email__c,I_RM_Student_Email__c,I_RM_Contact__r.FirstName,I_RM_Contact__r.LastName,

                                     I_RM_Phone__c,I_RM_Other_Phone__c, I_RM_Role__c, I_RM_Status__c, RecordTypeId

                              FROM I_RM_Affiliation__c

                              WHERE (I_RM_Email__c IN : emailKeysToMatch OR

                                     I_RM_Student_Email__c IN : emailKeysToMatch OR

                                     I_RM_Work_Email__c IN : emailKeysToMatch

                                    )

                              ORDER BY CreatedDate DESC];    

        }
        else if(!phoneKeysToMatch.isEmpty()) {

            affliationList = [SELECT I_RM_Contact__c,I_RM_Contact__r.id,I_RM_Mobile_Phone__c,I_RM_Contact__r.Name, CreatedDate,

                                     I_RM_Email__c,I_RM_Work_Email__c,I_RM_Student_Email__c,I_RM_Contact__r.FirstName,I_RM_Contact__r.LastName,

                                     I_RM_Phone__c,I_RM_Other_Phone__c, I_RM_Role__c, I_RM_Status__c, RecordTypeId

                              FROM I_RM_Affiliation__c

                              WHERE (I_RM_Mobile_Phone__c IN : phoneKeysToMatch OR

                                     I_RM_Phone__c IN : phoneKeysToMatch OR

                                     I_RM_Other_Phone__c IN : phoneKeysToMatch

                                    )

                              ORDER BY CreatedDate DESC];    

        }

      
        for(case cse:caseList){   
            if(((cse.I_ST_Contact_First_Name__c != NULL && cse.I_ST_Contact_Last_Name__c !=NULL && cse.SuppliedPhone != NULL)
                || (cse.SuppliedName != NULL && cse.SuppliedPhone != NULL)) || cse.SuppliedEmail != NULL){
                    for(I_RM_Affiliation__c aff:affliationList){
                        String phoneKeyStr = aff.I_RM_Phone__c + aff.I_RM_Contact__r.FirstName + aff.I_RM_Contact__r.LastName;
                        String mobileKeyStr = aff.I_RM_Mobile_Phone__c + aff.I_RM_Contact__r.FirstName + aff.I_RM_Contact__r.LastName;                                        
                        String OtherphoneKeyStr = aff.I_RM_Other_Phone__c + aff.I_RM_Contact__r.FirstName + aff.I_RM_Contact__r.LastName; 
                        if ((caseMapToContact.containskey(aff.I_RM_Email__c)) || (caseMapToContact.containskey(aff.I_RM_Student_Email__c))|| 
                            (caseMapToContact.containskey(aff.I_RM_Work_Email__c)) || (caseMapToContact.containskey(phoneKeyStr)) || 
                            (caseMapToContact.containskey(mobileKeyStr)) || (caseMapToContact.containskey(OtherphoneKeyStr))){
                                
                                if(caseContactMap.get(cse.Id)==null){
                                    caseContactMap.put(cse.Id, aff.I_RM_Contact__c);  
                                }
                                
                            }
                        
                    }
                    
                }
        }
        if(caseContactMap.isEmpty() && affliationList.size()==0 && keysToMatch.size()>0 ){
            for(case cse:caseList){
                if(caseCreateContactMap.get(cse.id)==null)
                    caseCreateContactMap.put(cse.id,cse);
            }
        }
        map<string,case> contactCaseMapToUpdate=new  map<string,case>();
        if(!caseContactMap.isEmpty()){
            for(case cse:caseList){
                cse.ContactId=caseContactMap.get(cse.Id);
                if(cse.I_ST_Residency_Citizenship_Status__c!=null || cse.SuppliedEmail!=null){
                    contactCaseMapToUpdate.put( cse.ContactId, cse);
                    
                }
                
                
            }
            if(contactCaseMapToUpdate!=null){
                updateContact(contactCaseMapToUpdate);
            }
        }
        if(caseContactMap.isEmpty() && !caseCreateContactMap.isEmpty()){
            map<string,string> caseContactIDMap=getContactList(caseCreateContactMap);
            if(!caseContactIDMap.isEmpty()){
                for(case cse:caseList){
                    if(caseCreateContactMap.get(cse.Id)!=null && caseContactIDMap.get(cse.Id)!=null){
                        
                        cse.ContactId=caseContactIDMap.get(cse.Id);
                        
                    }
                }
            }
            
        }
    }
    
    private static void updateContact(map<string,case> contactCaseMapToUpdate){
        List<contact> contactList=new  List<contact>();
        for(contact contactDetail:[SELECT I_ST_Personal_Email__c,I_RS_Residency_Status__c FROM contact WHERE  Id=:contactCaseMapToUpdate.keyset()]){
            contactDetail.I_ST_Personal_Email__c=contactCaseMapToUpdate.get(contactDetail.Id).SuppliedEmail;
            contactDetail.I_RS_Residency_Status__c=contactCaseMapToUpdate.get(contactDetail.Id).I_ST_Residency_Citizenship_Status__c;
            contactList.add(contactDetail);
        }
        if(contactList.size()>0){
            update contactList;
        }
    }
    private static map<string,string> getContactList( Map<String,Case> caseCreateContactMap){
        list<Contact> contactList=new list<Contact>();
        List<Case> caseErrorList=new List<Case>();
        map<string,string> newContactKeyStrMap=new map<string,string>();
        for(string caseID: caseCreateContactMap.keySet()){
            if(caseCreateContactMap.get(caseID).Origin =='Email' && caseCreateContactMap.get(caseID).suppliedName!=null){
               
                Contact con = new Contact();
                con.FirstName = caseCreateContactMap.get(caseID).suppliedName.SubStringBefore(' ');
                con.LastName = caseCreateContactMap.get(caseID).suppliedName.SubStringAfter(' ');
                con.Title = caseCreateContactMap.get(caseID).I_ST_Position_Title__c;
                con.I_ST_Personal_Email__c = caseCreateContactMap.get(caseID).SuppliedEmail;
                con.MobilePhone = caseCreateContactMap.get(caseID).SuppliedPhone;
                con.I_RS_Residency_Status__c = caseCreateContactMap.get(caseID).I_ST_Residency_Citizenship_Status__c;
                String keyStr = caseCreateContactMap.get(caseID).SuppliedEmail;
                if (String.isBlank(keyStr)){
                    keyStr = caseCreateContactMap.get(caseID).SuppliedPhone + con.FirstName +  con.LastName;    
                }
                newContactKeyStrMap.put(keyStr,caseID); 
                contactList.add(con);
            }else if(caseCreateContactMap.get(caseID).Origin !='Email' && caseCreateContactMap.get(caseID).I_ST_Contact_First_Name__c!=null && caseCreateContactMap.get(caseID).I_ST_Contact_Last_Name__c!=null){
              
                Contact con = new Contact();
                con.FirstName = caseCreateContactMap.get(caseID).I_ST_Contact_First_Name__c;
                con.LastName = caseCreateContactMap.get(caseID).I_ST_Contact_Last_Name__c;
                con.Title = caseCreateContactMap.get(caseID).I_ST_Position_Title__c;
                con.I_ST_Personal_Email__c = caseCreateContactMap.get(caseID).SuppliedEmail;
                con.MobilePhone = caseCreateContactMap.get(caseID).SuppliedPhone;
                con.I_RS_Residency_Status__c = caseCreateContactMap.get(caseID).I_ST_Residency_Citizenship_Status__c;
                String keyStr = caseCreateContactMap.get(caseID).SuppliedEmail;
                if (String.isBlank(keyStr)){
                    keyStr = caseCreateContactMap.get(caseID).SuppliedPhone + con.FirstName  + con.LastName;    
                }
                newContactKeyStrMap.put(keyStr,caseID); 
                contactList.add(con);
            }
            else if(caseCreateContactMap.get(caseID).Origin !='Email' && caseCreateContactMap.get(caseID).Origin != 'Chat' && caseCreateContactMap.get(caseID).I_ST_Contact_First_Name__c==null && caseCreateContactMap.get(caseID).I_ST_Contact_Last_Name__c==null){
                
                caseErrorList.add(caseCreateContactMap.get(caseID));
            }
        }
        if(caseErrorList.size()>0){
            List<Apex_Debug_Log__c> insertDebugStatement = new List<Apex_Debug_Log__c>();
            for(case caseDetail:caseErrorList){
                Apex_Debug_Log__c debugLog2 = new Apex_Debug_Log__c();
                debugLog2.Apex_Class_Name__c = 'I_ST_CaseTriggerHelper';
                debugLog2.Apex_Class_Method_Name__c = 'updateContactOnCase';
                debugLog2.Exception_message__c = 'FirstName and LastName Not Available To Create Contact::' + caseDetail.Subject;
                debugLog2.Log_Type__c = 'Error';
                insertDebugStatement.add(debugLog2);
            }
            if(insertDebugStatement.size()>0){
                insert insertDebugStatement;
            }
        }
        map<string,string> caseContactIDMap=new map<string,string>();
        set<string> contactSetID=new set<string>();
         
        if(contactList.size()>0){
            
            try{                
                List<Database.upsertResult> uResults = Database.upsert(contactList,false);                
                for(Database.upsertResult result:uResults) {
                    if (result.isSuccess() && result.isCreated()) 
                        contactSetID.add(result.getId());
                }
            }
            catch(dmlException ex){
                Apex_Debug_Log__c debugLog2 = new Apex_Debug_Log__c();
                debugLog2.Apex_Class_Name__c = 'I_ST_CaseTriggerHelper';
                debugLog2.Apex_Class_Method_Name__c = 'updateContactOnCase';
                debugLog2.Exception_message__c = ex.getMessage();
                debugLog2.Log_Type__c = 'Error';
                insert debugLog2;
            }
            
        }  
        for(contact contactDetail:[SELECT I_ST_Personal_Email__c,MobilePhone,FirstName,LastName FROM Contact where id=:contactSetID]){
            string emailStr = contactDetail.I_ST_Personal_Email__c;
            if (String.isBlank(emailStr)){
                emailStr = contactDetail.MobilePhone + contactDetail.FirstName + contactDetail.LastName;    
            }
            caseContactIDMap.put(newContactKeyStrMap.get(emailStr), contactDetail.Id);
        }
        if(caseContactIDMap!=null){
            return caseContactIDMap;
        }else {
            return null;
        }
    }

    public static void updateAffiliation(List<Case> caseList) {
        List<String> orgNames = new List<String>();
        for(case caseDetail:caseList){
            orgNames.add(caseDetail.I_ST_School_or_Educational_body__c);
        }
        
        Map<String, Organisation_Alias__c> accountAliasIdMap = new Map<String, Organisation_Alias__c>();
        for(Organisation_Alias__c acc: [SELECT I_RS_Organisation__c,Name,I_RS_Organisation__r.Name,I_RS_Organisation_Name_Long__c 
                                        FROM Organisation_Alias__c 
                                        WHERE I_RS_Organisation_Name_Long__c IN : orgNames]){
                                            accountAliasIdMap.put(acc.I_RS_Organisation_Name_Long__c.toLowerCase(), acc);//ARC to arc as a key. 
                                           
                                        }
        I_ST_Anonymous_Edu_Inst__c DefaultAcc = I_ST_Anonymous_Edu_Inst__c.getInstance();
        Id defaultOrgId = null;
        
        if (accountAliasIdMap.isEmpty()){
            defaultOrgId =DefaultAcc.I_ST_Default_School_Name__c;
        }
        
        Set<String> contactIdSet=new Set<String>();
        set<string> roleSet=new set<string>();
        set<string> accountSet=new set<string>();
        for(Case caseDetail:caseList){
            if(caseDetail.I_RM_Affiliation__c==null){
                if(caseDetail.ContactId!=null){
                    contactIdSet.add(caseDetail.ContactId);
                    if(caseDetail.RecordTypeId == caseEnquiryId){
                        
                        roleSet.add(APPLICANT);
                        roleSet.add(DOMESTICLEAD);
                    }
                    else if(caseDetail.RecordTypeId == CASE_INT_ENQUIRY_RECTYPE_ID){
                        roleSet.add(INTERNATIONAL_LEAD_ROLE);
                    }
                    else if(caseDetail.RecordTypeId == caseActivityBooking){ 
                         
                        if (caseDetail.AccountId != null){
                            accountSet.add(caseDetail.AccountId);
                        }
                        else if (caseDetail.I_ST_School_or_Educational_body__c!=null && accountAliasIdMap.get(caseDetail.I_ST_School_or_Educational_body__c.toLowerCase()) <> null){
                            caseDetail.AccountId = accountAliasIdMap.get(caseDetail.I_ST_School_or_Educational_body__c.toLowerCase()).I_RS_Organisation__c;
                            accountSet.add(caseDetail.AccountId);
                        }
                        else {
                            caseDetail.AccountId = defaultOrgId;
                            accountSet.add(caseDetail.AccountId);
                        }
                        roleSet.add(SCHOOLREPRESENTATIVE);
                    }
                }
            }
        }
        map<id,I_RM_Affiliation__c> affilationMap=new map<id,I_RM_Affiliation__c>();
       
        for(I_RM_Affiliation__c   affiliation: [SELECT I_RM_Contact__c,I_RM_Contact__r.id,I_RM_Mobile_Phone__c,I_RM_Contact__r.Name, CreatedDate,
                                                I_RM_Email__c,I_RM_Work_Email__c,I_RM_Student_Email__c,I_RM_Contact__r.FirstName,I_RM_Contact__r.LastName,
                                                I_RM_Account__c, I_RM_Phone__c,I_RM_Other_Phone__c, I_RM_Role__c, I_RM_Status__c, RecordTypeId                          
                                                FROM I_RM_Affiliation__c WHERE I_RM_Contact__c = :contactIdSet 
                                                AND I_RM_Role__c IN:roleSet ORDER BY CreatedDate DESC]){
                                                    if( ROLES_THAT_REQUIRE_AFFILIATION_UPSERT.contains(affiliation.I_RM_Role__c)
                                                        && !affilationMap.containsKey(affiliation.I_RM_Contact__c) 
                                                        && !inactiveStatus.contains(affiliation.I_RM_Status__c)) 
                                                    {
                                                         affilationMap.put(affiliation.I_RM_Contact__c,affiliation);
                                                    }else if (!affilationMap.containsKey(affiliation.I_RM_Contact__c) && affiliation.I_RM_Role__c=='School Representative' && accountSet.contains(affiliation.I_RM_Account__c) && !inactiveStatus.contains(affiliation.I_RM_Status__c)){
                                                        affilationMap.put(affiliation.I_RM_Contact__c,affiliation);
                                                    }
                                                }
        
        Map<Id,Case> mapCases=new  Map<Id,Case>();
        Map<Id,Case> mapUpdateCases=new  Map<Id,Case>();
        
        for(Case caseDetail:caseList){
            
            if(caseDetail.I_RM_Affiliation__c==null && (caseDetail.RecordTypeId == caseActivityBooking)){
                if(!affilationMap.isEmpty() && 
                   affilationMap.get(caseDetail.ContactId)!=null && 
                   caseDetail.ContactId==affilationMap.get(caseDetail.ContactId).I_RM_Contact__c && 
                   caseDetail.AccountId ==affilationMap.get(caseDetail.ContactId).I_RM_Account__c && 
                   affilationMap.get(caseDetail.ContactId).I_RM_Role__c == 'School Representative' ){
                       
                       caseDetail.I_RM_Affiliation__c=affilationMap.get(caseDetail.ContactId).Id;
                   }else{
                       mapCases.put(caseDetail.id,caseDetail);
                   }  
            }else if(IDS_THAT_REQUIRE_AFFILIATION_UPSERT.contains(caseDetail.RecordTypeId)){                
              
                if(!affilationMap.isEmpty() && caseDetail.I_RM_Affiliation__c==null 
                   && affilationMap.get(caseDetail.ContactId)!=null &&                   
                   caseDetail.ContactId == affilationMap.get(caseDetail.ContactId).I_RM_Contact__c && 
                   ROLES_THAT_REQUIRE_AFFILIATION_UPSERT.contains(affilationMap.get(caseDetail.ContactId).I_RM_Role__c) 
                   ) {
                        caseDetail.I_RM_Affiliation__c = affilationMap.get(caseDetail.ContactId).Id;
                        mapUpdateCases.put(caseDetail.Id, caseDetail);
                    }else if (caseDetail.I_RM_Affiliation__c!=null){
                        mapUpdateCases.put(caseDetail.Id, caseDetail);
                    }else{
                       mapCases.put(caseDetail.id,caseDetail);
                   } 
            }          
                    
        }
        
        if(!mapCases.isEmpty()){
            createAffiliationForCase(caseList);
        }
        if(!mapUpdateCases.isEmpty()){
            updateAffiliationFieldsAssociatedToCase(mapUpdateCases);
        }
        
    }
    public static void updateAffiliationFieldsAssociatedToCase(Map<Id,Case> mapCases){
        set<Id> affId = new set<Id>(); 
        List<I_RM_Affiliation__c> affList = new List<I_RM_Affiliation__c>(); 
        for (Case cse: mapCases.values()){
            affId.add(cse.I_RM_Affiliation__c);    
        }
        Map<Id, I_RM_Affiliation__c> affliationMap = new Map<Id, I_RM_Affiliation__c>(
            [SELECT Id,Name,RecordTypeId,I_RM_Contact__c,I_RM_Email__c,I_RM_Mobile_Phone__c,I_RM_Role__c, I_RM_Course_Availability__c, I_RM_Course_Parent__c, I_RM_Status__c,I_RM_StartDate__c FROM I_RM_Affiliation__c WHERE Id in : affId]
        );
        
        for (Case cse: mapCases.values()){
            I_RM_Affiliation__c Aff = affliationMap.get(cse.I_RM_Affiliation__c);
            
            if  ( IDS_THAT_REQUIRE_AFFILIATION_UPSERT.contains(cse.RecordTypeId) && 
                  (Aff <> NULL) && 
                  ROLES_THAT_REQUIRE_AFFILIATION_UPSERT.contains(Aff.I_RM_Role__c)
                )  
            {  
                updateAffilationFieldsFromCase(Aff,cse);
                affList.add(Aff);
            }
            
        }       
        if (affList.size() >0){
            try{
                upsert affList;
            }
            catch(dmlException ex){
                Apex_Debug_Log__c debugLog3 = new Apex_Debug_Log__c();
                debugLog3.Apex_Class_Name__c = 'I_ST_CaseTriggerHelper';
                debugLog3.Apex_Class_Method_Name__c = 'updateAffiliationFieldsAssociatedToCase';
                debugLog3.Exception_message__c = ex.getMessage();
                debugLog3.Log_Type__c = 'Error';
                insert debugLog3;
            }            
        }else{
            createAffiliationForCase(mapCases.values());
        }
    }
    private static void updateAffilationFieldsFromCase(I_RM_Affiliation__c aff, Case cse){
        Map<Id,Case> oldMap = (Map<Id,Case>)trigger.oldMap;        
        case oldCase = oldMap != null ? oldMap.get(cse.Id) : null;
        if((oldCase != null && oldCase.ContactId != cse.ContactId && cse.ContactId != null && Aff.I_RM_Contact__c == null) 
           || (oldCase == null && cse.ContactId != null && Aff.I_RM_Contact__c == null)) {Aff.I_RM_Contact__c = cse.ContactId;}  
         
        if((oldcase != null && oldCase.I_ST_Study_Interest__c != cse.I_ST_Study_Interest__c && cse.I_ST_Study_Interest__c != null && cse.I_ST_Study_Interest__c != '')
            || (oldcase == null && cse.I_ST_Study_Interest__c != null && cse.I_ST_Study_Interest__c != '')){Aff.I_RM_Study_Interest__c = cse.I_ST_Study_Interest__c;Aff.I_RM_Career_Area__c = cse.I_ST_Career_Area__c;}
        
        if((oldcase != null && oldCase.I_ST_Campus_Interest__c != cse.I_ST_Campus_Interest__c && cse.I_ST_Campus_Interest__c != null && cse.I_ST_Campus_Interest__c != '')
            || (oldcase == null && cse.I_ST_Campus_Interest__c != null && cse.I_ST_Campus_Interest__c != '')){Aff.I_RM_Campus_Interest__c = cse.I_ST_Campus_Interest__c;}       
       
        if((oldcase != null && oldCase.I_ST_Study_Level__c != cse.I_ST_Study_Level__c && cse.I_ST_Study_Level__c != null && cse.I_ST_Study_Level__c != '')
            || (oldcase == null && cse.I_ST_Study_Level__c != null && cse.I_ST_Study_Level__c != '')){Aff.I_RM_Study_Level__c = cse.I_ST_Study_Level__c;}
       
        if((oldcase != null && oldCase.I_ST_Timeframe_To_Study__c != cse.I_ST_Timeframe_To_Study__c && cse.I_ST_Timeframe_To_Study__c != null && cse.I_ST_Timeframe_To_Study__c != '')
            || (oldcase == null && cse.I_ST_Timeframe_To_Study__c != null && cse.I_ST_Timeframe_To_Study__c != '')){Aff.I_RM_Time_Frame_to_Study__c = cse.I_ST_Timeframe_To_Study__c;}
        
        if((oldcase != null && oldCase.I_ST_Course_Availability__c != cse.I_ST_Course_Availability__c && cse.I_ST_Course_Availability__c != null)
            || (oldcase == null && cse.I_ST_Course_Availability__c != null)){Aff.I_RM_Course_Availability__c = cse.I_ST_Course_Availability__c;}
        
       
        if((oldcase != null && oldCase.I_ST_Course_Name__c != cse.I_ST_Course_Name__c && cse.I_ST_Course_Name__c != null)
            || (oldcase == null && cse.I_ST_Course_Name__c != null)){Aff.I_RM_Course_Parent__c = cse.I_ST_Course_Name__c;}
        
        if((oldcase != null && oldCase.SuppliedEmail != cse.SuppliedEmail && String.isNotBlank(cse.SuppliedEmail))
            || (oldcase == null && String.isNotBlank(cse.SuppliedEmail))){Aff.I_RM_Email__c = cse.SuppliedEmail;}
            
        if((oldcase != null && oldCase.SuppliedPhone != cse.SuppliedPhone && String.isNotBlank(cse.SuppliedPhone))
            || (oldcase == null && String.isNotBlank(cse.SuppliedPhone))){Aff.I_RM_Mobile_Phone__c = cse.SuppliedPhone;}
       
        if((oldCase != null && oldCase.I_ST_Postcode__c != cse.I_ST_Postcode__c && cse.I_ST_Postcode__c != '' && cse.I_ST_Postcode__c != null) 
           || (oldCase == null && cse.I_ST_Postcode__c != null && cse.I_ST_Postcode__c != '')){Aff.I_RM_Postcode__c = cse.I_ST_Postcode__c;}
        
        if((oldCase != null && oldCase.I_ST_Enquirer_Type__c != cse.I_ST_Enquirer_Type__c && cse.I_ST_Enquirer_Type__c != null) 
           || (oldCase == null && cse.I_ST_Enquirer_Type__c != null && cse.I_ST_Enquirer_Type__c != '')){Aff.I_RM_Enquirer_Type__c = cse.I_ST_Enquirer_Type__c;}
        
    }
    private static void createAffiliationForCase(List<Case> caseList){
        List<I_RM_Affiliation__c> affList = new List<I_RM_Affiliation__c>();
        for(case cse : caseList){
            id recTypeId;
            string leadSource;
            string affRole;
            string leadsourceSubCatagory = null; 
            
            if( cse.RecordTypeId == caseEnquiryId ) 
            {
                recTypeId = leadRecordID;
                affRole = DOMESTICLEAD;
            }
            else if ( cse.RecordTypeId == CASE_INT_ENQUIRY_RECTYPE_ID ) 
            {
                recTypeId = AFFILIATION_INT_LEAD_RECTYPE_ID;
                affRole = INTERNATIONAL_LEAD_ROLE;
            }
            else {
                recTypeId = AffiliationExternalContact;
                affRole = 'School Representative';
            }
            

            switch on cse.Origin {
                when 'Email' {
                    leadSource = 'Email';
                }
                when 'Web' {
                    leadSource = 'Web Form';
                    leadsourceSubCatagory = 'Ask a Question form';
                }
                when else {
                    leadSource = 'Live Chat';
                }
            }

            I_RM_Affiliation__c Aff = new I_RM_Affiliation__c(I_RM_Contact__c = cse.ContactID,
                                                              I_RM_Account__c = cse.AccountId,                                                             
                                                              I_RM_Enquirer_Type__c = cse.I_ST_Enquirer_Type__c,
                                                              I_RM_Lead_Source_Category__c = leadSource,
                                                              I_RM_Lead_Source_sub_category__c = leadsourceSubCatagory,
                                                              I_RM_Position_Title__c = cse.I_ST_Position_Title__c,
                                                              I_RM_Mobile_Phone__c = cse.SuppliedPhone,
                                                              RecordTypeId = recTypeId ,
                                                              I_RM_Role__c = affRole,
                                                              I_RM_Postcode__c = cse.I_ST_Postcode__c);
            
            if( IDS_THAT_REQUIRE_AFFILIATION_UPSERT.contains(cse.RecordTypeId) ){
                Aff.I_RM_Email__c = cse.SuppliedEmail;
                updateAffilationFieldsFromCase(Aff, cse);
            }else if(cse.RecordTypeId == caseActivityBooking){
                Aff.I_RM_Work_Email__c = cse.SuppliedEmail;
            }
            
            
            affList.add(Aff);
        }
        set<string> affliateSetID=new  set<string>();
        
        if(affList.size()>0){
            try{
                Database.SaveResult[] srList = Database.insert(affList, false);               
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        affliateSetID.add(sr.id);
                    }
                }
                
            }catch(exception ex){
                Apex_Debug_Log__c debugLog = new Apex_Debug_Log__c();
                debugLog.Apex_Class_Name__c = 'I_ST_CaseTriggerHelper';
                debugLog.Apex_Class_Method_Name__c = 'createAffiliationForCase';
                debugLog.Exception_message__c = ex.getMessage();
                debugLog.Log_Type__c = 'Error';
                Insert debugLog;
            } 
        }
        List<I_RM_Affiliation__c> lstAffiliation = [SELECT I_RM_Contact__c FROM I_RM_Affiliation__c WHERE id=:affliateSetID ];
        for(Case cse : caseList){
            for(I_RM_Affiliation__c aff : lstAffiliation){
                if(aff.I_RM_Contact__c == cse.ContactId){
                    cse.I_RM_Affiliation__c = aff.Id;
                }
            }
        }
    }
    
    //check if the Case records record type Id is valid for Scoring
    private static Boolean isValidISTScoringCaseRecordTypeId(Id recordTypeId) {
        Boolean validRecordType = false;
        String strRecordDevName = Schema.SObjectType.Case.getRecordTypeInfosById().get(recordTypeId).getDeveloperName();
        if(GlobalConstants.CASE_RECORD_TYPE_API_NAME_ENQUIRY == strRecordDevName) {
            validRecordType = true;
        }
        return validRecordType;
    }
    
    public static void calculateCaseScoring(){
        
        List<Case> newCaseList = new List<Case>();
        Set<Id> recordTypeIds = new Set<Id>(); 
        String caseIncrementField = GlobalConstants.CASE_INCREMENTAL_SCORE_FIELD;
        List<Apex_Debug_Log__c> insertDebugStatement = new List<Apex_Debug_Log__c>();
        for(Case newCase: (List<Case>)Trigger.New){
            
            if(isValidISTScoringCaseRecordTypeId(newCase.RecordTypeId)) {
                newCaseList.add(newCase);
                recordTypeIds.add(newCase.RecordTypeId);
            } 
        }
        if(newCaseList.size() > 0) {
            if(Trigger.isAfter && Trigger.isInsert){
                calculateIncrementalScoreOnCase(GlobalConstants.CASE_OBJECT_API_NAME,caseIncrementField,recordTypeIds,newCaseList,null);
            }
            if(Trigger.isAfter && Trigger.isUpdate){
                calculateIncrementalScoreOnCase(GlobalConstants.CASE_OBJECT_API_NAME,caseIncrementField,recordTypeIds,newCaseList,(Map<ID,Case>) Trigger.oldMap);
            }            
        }        
    }
    public static void calculateIncrementalScoreOnCase(String sobjectName, String caseIncrementField, Set<Id> recordTypeIds,List<Case> cases, Map<ID,Case> oldMap){
        I_ST_IncrementalScoreContactRelObject.calcIncrementalScoreContactRelObject(sobjectName,caseIncrementField,recordTypeIds,cases, oldMap);   
    }
    
    
}