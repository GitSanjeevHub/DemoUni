/**
─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_RM_AffiliationTriggerHelper
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author Teja Yenduri
* @date 2022-02-18
* 

* * @description : markCalculateAffiliationScoreToTrue method is used to set I_RM_Calculate_Affiliation_Score__c to true
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class I_RM_AffiliationTriggerHelper {
    public static boolean createLeadFirtRun = true;
    
    //set of strings that require email on affilition to be copied over to related contact's personal email
    public static final Set<String> AFFLIATIONROLENAMESET = new Set<String> {
        'Student Lead (Int)',
        'Domestic Lead'
    };
    /*** Setting CalculateContact Score to true**/
    public static void markCalculateAffiliationScoreToTrue(List<I_RM_Affiliation__c> newAffiliations,
                                                           map<Id,I_RM_Affiliation__c> oldAffiliations,
                                                           boolean isInsertAffiliation){
                                                               boolean isFieldChanged = isInsertAffiliation;
                                                               List<I_RM_Affiliation__c> listUpdateAffiliations = new List<I_RM_Affiliation__c>();
                                                               List<String> objectFields = fetchAllChangedField();
                                                               for(I_RM_Affiliation__c AffiliationRecord: newAffiliations){
                                                                   for(string affiliationField: objectFields){
                                                                       if(AffiliationRecord.get(affiliationField) != oldAffiliations.get(AffiliationRecord.id).get(affiliationField)){
                                                                           isFieldChanged = true;
                                                                           break;
                                                                       }
                                                                   }
                                                                   if(isFieldChanged){                                                                  
                                                                       I_RM_Affiliation__c affiliationToUpdate = new I_RM_Affiliation__c(Id=AffiliationRecord.Id,I_RM_Calculate_Affiliation_Score__c=true);
                                                                       listUpdateAffiliations.add(affiliationToUpdate);
                                                                       isFieldChanged = false;
                                                                   }
                                                               }
                                                               I_RM_AffiliationTriggerHandler.makeAffiliationQualified = false;
                                                               Database.update(listUpdateAffiliations,false);
                                                               I_RM_AffiliationTriggerHandler.runmarkCalculateAffiliationScoreToTrue=true;
                                                               //I_RM_AffiliationTriggerHandler.makeAffiliationQualified = true;
                                                               
                                                               
                                                           }
    
    
    //Method to get all contact field from custom metadataType
    public static List<string> fetchAllChangedField(){
        List<string> affiliationFields = new List<string>();       
        for(I_ST_Lead_Scoring__mdt leadScoreRecord : I_ST_Lead_Scoring__mdt.getAll().values()){
            if(leadScoreRecord.I_ST_Object__c == 'I_RM_Affiliation__c') {
                string affiliationFieldName = '';
                if(leadScoreRecord.I_ST_Field_API_Name__c != ''){
                    affiliationFieldName = leadScoreRecord.I_ST_Field_API_Name__c;
                    affiliationFields.add(affiliationFieldName);
                }   
            }            
        }        
        return affiliationFields;
    }    
    
  /* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
* @author Teja Yenduri
* @date 2022-02-18
    
 LTU360-1231,LTU360-1230: Updating status to Qualified for Active and In active domestic lead affiliations
                           based on applicant status

* ─────────────────────────────────────────────────────────────────────────────────────────────────┘*/

    public static void filterAffiliations(Set<Id> affiContactIds,List<I_RM_Affiliation__c> lstAffiliations, List<String> inactiveStatus){//Only Inactive Affiliations
        
        Map<Id,Integer> mapConIdVSInActivaffiCount = new Map<Id,Integer>();
        Map<Id,Integer> mapConIdVSActivaffiCount = new Map<Id,Integer>();
        Map<Id,Integer> mapConIdVSInactivApplicantCount = new Map<Id,Integer>();
        Id domesticLeadRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_LEAD).getrecordTypeId();
        Id applicantRecordtypeId =   Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_APPLICANT).getrecordTypeId();
       // List<String> inactiveStatus = inactiveStatuses;
        if(!affiContactIds.isEmpty()){
            List<AggregateResult> lstInactiveAggregateResult = [SELECT count(Id)cnt,I_RM_Contact__c
                                                                FROM I_RM_Affiliation__c 
                                                                WHERE I_RM_Contact__c IN: affiContactIds 
                                                                AND RecordTypeId =: domesticLeadRecordTypeId
                                                                AND I_RM_Role__c = 'Domestic Lead'
                                                                AND I_RM_Status__c  IN: inactiveStatus
                                                                GROUP BY I_RM_Contact__c
                                                               ];
            
            for(AggregateResult arr: lstInactiveAggregateResult){
                Integer intCount = (Integer)arr.get('cnt');                   
                Id contactId = (Id)arr.get('I_RM_Contact__c'); 
                mapConIdVSInActivaffiCount.put(contactId,intCount); //conID,1                   
            }
            
            List<AggregateResult> lstActiveAggregateResult = [SELECT count(Id)cnt,I_RM_Contact__c 
                                                              FROM I_RM_Affiliation__c 
                                                              WHERE I_RM_Contact__c IN: affiContactIds //contactIDs 
                                                              AND RecordTypeId =: domesticLeadRecordTypeId
                                                              AND I_RM_Role__c = 'Domestic Lead'
                                                              AND I_RM_Status__c NOT IN: inactiveStatus
                                                              GROUP BY I_RM_Contact__c                
                                                             ];            
           
            for(AggregateResult arr: lstActiveAggregateResult){
                Integer intCount = (Integer)arr.get('cnt');                   
                Id contactId = (Id)arr.get('I_RM_Contact__c'); //conID,1 Or conID,0
                mapConIdVSActivaffiCount.put(contactId,intCount);                    
            }
            
            
            List<AggregateResult> lstInactiveApplicantAggregateResult =[SELECT count(Id)cnt,I_RM_Contact__c 
                                                              FROM I_RM_Affiliation__c 
                                                              WHERE I_RM_Contact__c IN: affiContactIds //contactIDs 
                                                              //AND RecordTypeId =: applicantRecordtypeId
                                                              AND I_RM_Role__c IN  ('Applicant','HDR Student','Student')
                                                              AND (I_RM_EndDate__c = null
                                                              OR I_RM_Status__c NOT IN: inactiveStatus)
                                                              GROUP BY I_RM_Contact__c];
            
            
            if(lstInactiveApplicantAggregateResult.size() == 0){
                for(Id contactId : affiContactIds){
                    mapConIdVSInactivApplicantCount.put(contactId,0);
                }
            }
            else{
                for(AggregateResult arr: lstInactiveApplicantAggregateResult){
                    Integer intCount = (Integer)arr.get('cnt');                   
                    Id contactId = (Id)arr.get('I_RM_Contact__c'); //conID,1 Or conID,0
                    mapConIdVSInactivApplicantCount.put(contactId,intCount);                    
                }
            }
            //for loop on currently updated / inserted affiliation
            List<Id> lstContactForAllAffiliation = new List<Id>();
            List<Id> lstContactForActiveAffiliation = new List<Id>();
            for(I_RM_Affiliation__c newAffiliation :lstAffiliations){
                if(mapConIdVSInActivaffiCount.get(newAffiliation.I_RM_Contact__c) > 0 
                   && ( mapConIdVSActivaffiCount.isEmpty() || mapConIdVSActivaffiCount.get(newAffiliation.I_RM_Contact__c) == 0)
                  && mapConIdVSInactivApplicantCount.get(newAffiliation.I_RM_Contact__c) == 0){
                   
                    lstContactForAllAffiliation.add(newAffiliation.I_RM_Contact__c);
                }
                else if(mapConIdVSActivaffiCount.get(newAffiliation.I_RM_Contact__c) > 0  
                        && mapConIdVSInactivApplicantCount.get(newAffiliation.I_RM_Contact__c) == 0){
                  
                    lstContactForActiveAffiliation.add(newAffiliation.I_RM_Contact__c);                        
                    
                }
                else if(mapConIdVSInActivaffiCount.get(newAffiliation.I_RM_Contact__c) == 0
                        && mapConIdVSInactivApplicantCount.get(newAffiliation.I_RM_Contact__c) == 0){
                    
                }
                else if(mapConIdVSInActivaffiCount.get(newAffiliation.I_RM_Contact__c) > 0 
                        && mapConIdVSActivaffiCount.get(newAffiliation.I_RM_Contact__c) > 0
                       && mapConIdVSInactivApplicantCount.get(newAffiliation.I_RM_Contact__c) == 0){
                    
                }
            }
            
            
           
            if(!lstContactForAllAffiliation.isEmpty()){   
                
                inactiveDomesticLeadAffiliationUpdate(lstContactForAllAffiliation);
            }
            if(!lstContactForActiveAffiliation.isEmpty()){
                
                activeDomesticLeadAffiliationUpdate(lstContactForActiveAffiliation, inactiveStatus);
            }
        }        
    }
    public static void inactiveDomesticLeadAffiliationUpdate(List<Id> lstContactId){//contact found all or any one domestic lead affiliation inactive
       
        Map<Id,I_RM_Affiliation__c> mapConIdVSaffiliation = new Map<Id,I_RM_Affiliation__c>();
        List<I_RM_Affiliation__c> lstAffiliationsToupdate = new List<I_RM_Affiliation__c>();
        List<I_RM_Affiliation__c> lstLatestAffiliation = [SELECT Id,createddate,I_RM_Contact__c,I_RM_Role__c,I_RM_Status__c FROM I_RM_Affiliation__c 
                                                          WHERE I_RM_Role__c = 'Domestic Lead'
                                                          AND I_RM_Contact__c IN:lstContactId ORDER BY Createddate desc];//ConId1,Affiliation1,ContID1,Affiliation2
        
        
        for(I_RM_Affiliation__c objInstance: lstLatestAffiliation){
            if(!mapConIdVSaffiliation.containsKey(objInstance.I_RM_Contact__c)){            
            	mapConIdVSaffiliation.put(objInstance.I_RM_Contact__c,objInstance);
            }                       
        }
        lstAffiliationsToupdate.addAll(mapConIdVSaffiliation.values());
       updateLeadAffiliation(lstAffiliationsToupdate);        
    }
    public static void activeDomesticLeadAffiliationUpdate(List<Id> lstContactId, List<String> inactiveStatus){
        
        //List<String> inactiveStatus = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');
        inactiveStatus.add('Qualified');
        List<I_RM_Affiliation__c> lstactiveAffiliations = [SELECT  Id,createddate,I_RM_Contact__c,I_RM_Role__c,I_RM_Status__c FROM I_RM_Affiliation__c 
                                                           WHERE I_RM_Contact__c IN: lstContactId
                                                           AND I_RM_Role__c = 'Domestic Lead' 
                                                           AND  I_RM_Status__c NOT IN: inactiveStatus];//1 or more records with not qualified status.
      
        if(!lstactiveAffiliations.isEmpty()){
            updateLeadAffiliation(lstactiveAffiliations);
        }
    }
    public static void updateLeadAffiliation(List<I_RM_Affiliation__c> lstAffiliationsToupdate){
        List<I_RM_Affiliation__c> lstAffiToUpdate = new List<I_RM_Affiliation__c>(); 
        
        for(I_RM_Affiliation__c objupdateAffi:lstAffiliationsToupdate){
            I_RM_Affiliation__c objNewAffiliation = new I_RM_Affiliation__c(Id = objupdateAffi.Id);            
            objNewAffiliation.I_RM_Status__c = 'Qualified'; 
            lstAffiToUpdate.add(objNewAffiliation);
            
        }         
        
        if(!lstAffiToUpdate.isEmpty() && schema.SObjectType.I_RM_Affiliation__c.isCreateable() && schema.SObjectType.I_RM_Affiliation__c.isUpdateable()){
         //   I_RM_AffiliationTriggerHandler.makeAffiliationQualified = false;
            upsert lstAffiToUpdate;
            I_RM_AffiliationTriggerHandler.makeAffiliationQualified = true;            
        }
        
    }
    
 /* LTU360-1229*/
 public static void createLeadAffliations(List<I_RM_Affiliation__c> inactiveAffliationsList, List<String> inactiveStatus, String afflType){

    List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
    Set<Id> inactiveAffliationsIdList = new Set<Id>();
    Set<Id> contactIds = New Set<Id>();
    for(I_RM_Affiliation__c affl : inactiveAffliationsList){
        inactiveAffliationsIdList.add(affl.Id);
        contactIds.add(affl.I_RM_Contact__c);
    }
    
    if(inactiveAffliationsIdList.size() > 0){
        Id applicantRecordtypeId =   Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.AFFILIATION_RECORD_TYPE_NAME_APPLICANT).getrecordTypeId();
        List<AggregateResult> lstInactiveApplicantAggregateResult = New List<AggregateResult>();
        lstInactiveApplicantAggregateResult =[SELECT count(Id)cnt,I_RM_Contact__c 
                                                            FROM I_RM_Affiliation__c 
                                                            WHERE I_RM_Contact__c IN: contactIds //contactIDs 
                                                            //AND RecordTypeId =: applicantRecordtypeId
                                                            AND I_RM_Role__c IN  ('Applicant','HDR Student','Student')
                                                            AND (I_RM_EndDate__c = null
                                                            OR I_RM_Status__c NOT IN: inactiveStatus)
                                                            GROUP BY I_RM_Contact__c];
                                                                                                          
        if(lstInactiveApplicantAggregateResult.size() == 0){
            Set<Id> contactIdsWithoutLeads = New Set<Id>();
            if(afflType == 'Applicant'){
                for(Contact con: [SELECT ID, name,I_RM_Applicant__c FROM contact WHERE ID NOT IN (SELECT I_RM_Contact__c FROM I_RM_Affiliation__c WHERE I_RM_Role__c = 'Domestic Lead' AND I_RM_Contact__c IN: contactIds) AND ID IN: contactIds]){
                    contactIdsWithoutLeads.add(con.id);
                }
            }else if(afflType == 'Student' || afflType == 'HDR Student'){
                for(Contact con: [SELECT ID, name,I_RM_Applicant__c FROM contact WHERE ID NOT IN (SELECT I_RM_Contact__c FROM I_RM_Affiliation__c WHERE I_RM_Role__c = 'Domestic Lead' AND I_RM_Status__c Not IN:inactiveStatus AND I_RM_Contact__c IN: contactIds) AND ID IN: contactIds]){
                    contactIdsWithoutLeads.add(con.id);
                }
            }
            if(contactIdsWithoutLeads.size() > 0){
                List<I_RM_Affiliation__c> afflList = new List<I_RM_Affiliation__c>();
                String fieldsNames = '';

                for (Schema.SObjectField sObjectField : Schema.getGlobalDescribe().get('I_RM_Affiliation__c').getDescribe().fields.getMap().values()) {
                    fieldsNames += sObjectField.getDescribe().getName() + ',';
                }
                fieldsNames = fieldsNames.removeEnd(',');
                afflList = Database.query('SELECT ' + fieldsNames + ' ' + ' from I_RM_Affiliation__c WHERE Id IN : inactiveAffliationsIdList AND I_RM_Contact__r.I_RS_Deceased__c = False');
                Id devRecordTypeId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Lead').getrecordTypeId();
                List<I_RM_Affiliation__c> newLeadAfflsList = New List<I_RM_Affiliation__c>();

                for(I_RM_Affiliation__c affls : afflList){
                    if(affls.I_RM_Email__c != null || affls.I_RM_Mobile_Phone__c != null){
                        if(contactIdsWithoutLeads.contains(affls.I_RM_Contact__c)){
                            I_RM_Affiliation__c afflsRec = new I_RM_Affiliation__c();
                            afflsRec = affls.clone(false, true, false, false);
                            afflsRec.I_RM_Status__c = 'Qualified';
                            afflsRec.I_RM_Role__c = 'Domestic Lead';
                            afflsRec.I_RM_External_Id__c = null;
                            afflsRec.I_RM_Applicant_Id__c = null;
                            afflsRec.I_RM_EndDate__c = null;
                            afflsRec.I_RM_Email__c = affls.I_RM_Email__c;
                            afflsRec.I_RM_Data_Source__c = 'Salesforce';
                            afflsRec.I_RM_StartDate__c = System.today();
                            afflsRec.RecordTypeId = devRecordTypeId;
                            afflsRec.I_RM_Lead_Source_Category__c = 'Other system';
                            if(afflType == 'Student' || afflType == 'HDR Student' ){
                                afflsRec.I_RM_Lead_Source_sub_category__c = 'SIS';
                                afflsRec.I_RM_Enquirer_Type__c = 'Other';
                            }else if(afflType == 'Applicant'){
                                afflsRec.I_RM_Lead_Source_sub_category__c = 'FlexiDirect';
                            }
                            newLeadAfflsList.add(afflsRec);
                        }
                    }else{
                        errorLogs.add(new Apex_Debug_Log__c(
                        Apex_Class_Name__c = 'I_RM_AffiliationTriggerHelper',
                        Apex_Class_Method_Name__c = 'createLeadAffliations',
                        Exception_message__c = 'affiliation email or mobile phone is blank',
                        Exception_Stack_Trace__c = null));
                    }
                }
                if(!newLeadAfflsList.isEmpty()){
                   // I_RM_AffiliationTriggerHandler.makeAffiliationQualified = true;
                    Insert newLeadAfflsList;
                }
                if (!errorLogs.isEmpty() && errorLogs != Null)
                    insert errorLogs;  
                }
            }
        }
    }

    
     public static void updateContactEmailfields(List<I_RM_Affiliation__c> listOfAffliations, Map<Id,I_RM_Affiliation__c> oldAffliations){
        Map<Id,Contact> contactsToBeUpdated = New Map<Id,Contact>();
        for(I_RM_Affiliation__c affls :(List<I_RM_Affiliation__c>) listOfAffliations){
            I_RM_Affiliation__c oldAfl;
            oldAfl = Trigger.oldMap != null ? (I_RM_Affiliation__c)Trigger.oldMap.get(affls.Id) : null;
            String workEmail;
            String studentEmail;
            String email;
            if(oldAfl != null){
                workEmail = oldAfl.I_RM_Work_Email__c;
                studentEmail = oldAfl.I_RM_Student_Email__c;
                email = oldAfl.I_RM_Email__c;
            }else{
                workEmail = null;
                studentEmail = null;
                email = null; 
            }
            Contact cont = New Contact();
            if((affls.I_RM_Work_Email__c != null && affls.I_RM_Work_Email__c != workEmail) && (affls.I_RM_Role__c == 'La Trobe Staff' || affls.I_RM_Role__c == 'HDR Student')){
                cont.Email = affls.I_RM_Work_Email__c;
            }
            if((affls.I_RM_Student_Email__c != null && affls.I_RM_Student_Email__c != studentEmail) && (affls.I_RM_Role__c == 'Student' || affls.I_RM_Role__c == 'HDR Student')){
                cont.I_ST_Student_Email__c = affls.I_RM_Student_Email__c;
            }
            if(affls.I_RM_Email__c != null && affls.I_RM_Email__c != email) {
                if(affls.I_RM_Role__c == 'Applicant'){
                    cont.I_RM_Applicant_Email__c = affls.I_RM_Email__c;
                }else if(AFFLIATIONROLENAMESET.contains(affls.I_RM_Role__c)){
                    cont.I_ST_Personal_Email__c = affls.I_RM_Email__c;
                }
            }
            cont.Id = affls.I_RM_Contact__c;
            contactsToBeUpdated.put(cont.id,cont);
        }
        if(!contactsToBeUpdated.isEmpty()){
            update contactsToBeUpdated.values();
        }
    }
    
    /*LTU360-1232  */
    public static void updateActiveAffiliation(List<I_RM_Affiliation__c> afflist, List<String> csvaluelist){//Applicant Active only
      //  List<String> csvaluelist = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');
        Set<ID> CnctID = new Set<ID>();
        List<I_RM_Affiliation__c> updateAffRecord=new List<I_RM_Affiliation__c>();
        for(I_RM_Affiliation__c a : afflist){
            CnctID.add(a.I_RM_Contact__c);
        }
        for(I_RM_Affiliation__c af:[SELECT Id,I_RM_Status__c,I_RM_EndDate__c from I_RM_Affiliation__c WHERE I_RM_Contact__c IN: CnctID AND I_RM_Role__c = 'Domestic Lead' AND I_RM_Status__c !='Inactive']){
           af.I_RM_Status__c='Inactive';
           af.I_RM_EndDate__c =system.today();
            updateAffRecord.add(af);
        }
        if(updateAffRecord.size()>0 && schema.SObjectType.I_RM_Affiliation__c.isUpdateable()){
           // I_RM_AffiliationTriggerHandler.makeAffiliationQualified = false; //true          
            update updateAffRecord;
            I_RM_AffiliationTriggerHandler.makeLeadInactive = true;
        }
    }     

    /*
    *@author Rahul Kumar
    *@date 23/03/2022
    *@description - LTU360-1251 : Method to Update Active Applicant record when Student becomes Admitted And Enrolled 
    */
  /*  public static void updateActiveApplicant(List<I_RM_Affiliation__c> afflist, List<String> csvaluelist){
      //  List<String> csvaluelist = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');
        Set<ID> CnctID = new Set<ID>();
        List<I_RM_Affiliation__c> updateAffRecord=new List<I_RM_Affiliation__c>();
        for(I_RM_Affiliation__c a : afflist){
            CnctID.add(a.I_RM_Contact__c);
        }
        for(I_RM_Affiliation__c af:[SELECT Id,I_RM_Status__c from I_RM_Affiliation__c WHERE I_RM_Contact__c IN: CnctID AND I_RM_Role__c = 'Applicant' AND I_RM_Status__c !='Inactive']){
            af.I_RM_Status__c='Inactive';
            updateAffRecord.add(af);
        }
        if(updateAffRecord.size()>0 && schema.SObjectType.I_RM_Affiliation__c.isUpdateable()){
            update updateAffRecord;
            I_RM_AffiliationTriggerHandler.makeApplicantInactive = true;
        }
    }*/

    //LTU360-1407
    public static void updateContactExternalEmal(List<I_RM_Affiliation__c> listOfAffliations, List<String> inactiveStatus){

        List<Id> contactIds = New List<Id>();
        Map<Id, List<I_RM_Affiliation__c>> mapOfContactIdAndListOfAffls = New Map<Id, List<I_RM_Affiliation__c>>();

        for(I_RM_Affiliation__c affls:listOfAffliations){
            contactIds.add(affls.I_RM_Contact__c);
        }

        List<I_RM_Affiliation__c> afflList = New List<I_RM_Affiliation__c>();

        afflList = [Select Id, I_RM_Work_Email__c, I_RM_Contact__c From I_RM_Affiliation__c Where I_RM_Contact__c IN: contactIds AND I_RM_Role__c = 'External Contact' AND I_RM_Status__c NOT IN: inactiveStatus];

        if(afflList.size() > 0){
            for(I_RM_Affiliation__c affl : afflList){

                    if(!mapOfContactIdAndListOfAffls.isEmpty() && mapOfContactIdAndListOfAffls.containsKey(affl.I_RM_Contact__c))
                    mapOfContactIdAndListOfAffls.get(affl.I_RM_Contact__c).add(affl);
                    else
                    mapOfContactIdAndListOfAffls.put(affl.I_RM_Contact__c,new List<I_RM_Affiliation__c>{affl});
            }
        }
        List<Contact> contactsToUpdate = New List<Contact>();
        if(mapOfContactIdAndListOfAffls.size() > 0){
            List<I_RM_Affiliation__c> affslList = New List<I_RM_Affiliation__c>();
            for(Id conactId : mapOfContactIdAndListOfAffls.keySet()){
                affslList = mapOfContactIdAndListOfAffls.get(conactId);
                if(affslList.size() > 0){
                    Contact cnt = New Contact();
                    cnt.I_RM_Examiner_Email__c = concatinateEmails(affslList);
                    cnt.Id = conactId;
                    contactsToUpdate.add(cnt);
                }
            }
        }
        if(contactsToUpdate.size() >0){
            update contactsToUpdate;
        }
    }

    public static String concatinateEmails(List<I_RM_Affiliation__c> listOfAffliations){

        String emails;
        for(I_RM_Affiliation__c aff : listOfAffliations){
            if(aff.I_RM_Work_Email__c !=null && aff.I_RM_Work_Email__c!= ''){
                if(emails != null){
                    emails = emails + aff.I_RM_Work_Email__c+';';
                }                
                if(emails == null){
                    emails = aff.I_RM_Work_Email__c+';';
                }
            }
        }
        emails = emails.removeEnd(';');
        return emails;
    }

    /**
     * @description LTU360-2246 - Set the sponsored field based on 
     *                            Contact attributes in before insert/update context
     * @param triggerNewList - List of new items in trigger
     * @param triggerOldMap - map of old trigger items
    */
    public static List<I_RM_Affiliation__c> setSponsoredFieldValue( 
        List<I_RM_Affiliation__c> triggerNewList,
        Map<Id, I_RM_Affiliation__c> triggerOldMap
    ) {
        if( !GlobalConstants.INTENDEDFUNDINGSRCSET.isEmpty() && 
            !GlobalConstants.COUNTRYOFCITIZENSHIPSET.isEmpty()
        ) {
            List<I_RM_Affiliation__c> affListToUpdate = new List<I_RM_Affiliation__c>();
            Set<Id> contactIdSet = new Set<Id>();
            //create a map of affilitions that require an update on sponsored field
            for( I_RM_Affiliation__c aff : triggerNewList ) 
            {
                if( 
                    triggerOldMap.isEmpty() ||
                    ( aff.I_IL_Sponsored__c == triggerOldMap.get(aff.Id).I_IL_Sponsored__c && 
                    aff.I_IL_Intended_Funding_Source__c != triggerOldMap.get(aff.Id).I_IL_Intended_Funding_Source__c
                    )
                ) {
                    affListToUpdate.add(aff);
                    contactIdSet.add(aff.I_RM_Contact__c);
                }
            }
            if(!contactIdSet.isEmpty() && 
            Schema.SObjectType.Contact.Fields.I_RS_Citizenship__c.isAccessible()) 
            {            
                Map<Id, Contact> contactMap = new Map<Id, Contact>(
                    [SELECT Id, I_RS_Citizenship__c  
                    FROM Contact 
                    WHERE Id IN :contactIdSet 
                    WITH SECURITY_ENFORCED
                    ]
                );
                Contact con;
                for( I_RM_Affiliation__c aff : affListToUpdate ) {
                    con = contactMap.get(aff.I_RM_Contact__c);
                    if( ( String.isBlank(aff.I_IL_Intended_Funding_Source__c) ||
                          GlobalConstants.INTENDEDFUNDINGSRCSET.contains(aff.I_IL_Intended_Funding_Source__c)
                        ) && 
                        GlobalConstants.COUNTRYOFCITIZENSHIPSET.contains(con.I_RS_Citizenship__c)
                    ) {
                        aff.I_IL_Sponsored__c = 'Yes';
                    }
                    else {
                        aff.I_IL_Sponsored__c = 'No';
                    }
                }
            }
            return affListToUpdate;
        }
        return null;
    }
}