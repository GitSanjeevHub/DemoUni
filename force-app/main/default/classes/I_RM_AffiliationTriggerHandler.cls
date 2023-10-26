/**
─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_RM_AffiliationTriggerHandler
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author Teja Yenduri
* @date 2022-02-18
* 

* * @description : This class is used For Affiliation trigger helper methods
** @Modified : LTU360-2031 Vanita Walia - Update the L_PR_Contact_Name__c field on Affiliation  with Contact Name 
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class I_RM_AffiliationTriggerHandler {
    
    public static Boolean runmarkCalculateAffiliationScoreToTrue = false;
    public static Boolean makeAffiliationQualified = false;
    public static Boolean makeLeadInactive = false;
   // public static Boolean makeApplicantInactive = false;
    
    public static void execute(){ 
        map<Id,I_RM_Affiliation__c> mapOldAffiliations = (map<Id,I_RM_Affiliation__c>)Trigger.oldMap;
        map<Id,I_RM_Affiliation__c> mapNewAffiliations = (map<Id,I_RM_Affiliation__c>)Trigger.newMap;
        List<I_RM_Affiliation__c> lstNewAffiliation = new List<I_RM_Affiliation__c>();
        List<Contact> lstExistingContact = new List<Contact>();
        List<I_RM_Affiliation__c> newaffiliations = new List<I_RM_Affiliation__c>();
        Set<Id> relContactIds = new Set<Id>();
        Map<Id,String> conDetails = new Map<Id,String>();
        
        List<String> inactiveStatus = [SELECT I_RM_Status__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_AFFILIATION_SETTINGS].I_RM_Status__c.split(',');
        
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){

            I_RM_AffiliationTriggerHelper.setSponsoredFieldValue( 
                (List<I_RM_Affiliation__c>)Trigger.New, 
                (Trigger.isInsert == true) ? new Map<Id, I_RM_Affiliation__c>() 
                                           : (Map<Id, I_RM_Affiliation__c>)Trigger.oldMap 
            );

            map<Id,I_RM_Affiliation__c> mapOldAff = (map<Id,I_RM_Affiliation__c>)Trigger.oldMap;
            for(I_RM_Affiliation__c newAffiliation :(List<I_RM_Affiliation__c>)Trigger.New){
                if(Trigger.isInsert){
                    //Set the Affiliation for Score calculation if it is a new Domestic Lead
                    if(isValidISTScoringAffiliationRecordTypeId(newAffiliation.RecordTypeId))
                        newAffiliation.I_RM_Calculate_Affiliation_Score__c = true;
                }
                //created as per userstory LTU360-976
                if(inactiveStatus.contains(newAffiliation.I_RM_Status__c) && newAffiliation.I_RM_EndDate__c== null){
                    newAffiliation.I_RM_EndDate__c = system.today();
                    
                   if (newAffiliation.I_RM_Active__c == 'True') {
                        newAffiliation.I_RM_Active__c = 'False';
                    }   
                }
                else if((!inactiveStatus.contains(newAffiliation.I_RM_Status__c)) && (newAffiliation.I_RM_EndDate__c!=null)){
                    newAffiliation.I_RM_EndDate__c= null;
                    
                     if (newAffiliation.I_RM_Active__c == 'False') {
                        newAffiliation.I_RM_Active__c = 'True';
                    }   
                }
               
                //  LTU360-2031 Vanita Walia - Update the L_PR_Contact_Name__c field on Affiliation  with Contact Name 
                // check if Affiliation is inserted or contact Id is updated
                if(newAffiliation.I_RM_Contact__c != Null && (Trigger.isInsert || (Trigger.isUpdate && newAffiliation.I_RM_Contact__c != mapOldAff.get(newAffiliation.Id).I_RM_Contact__c))){
                    relContactIds.add(newAffiliation.I_RM_Contact__c);
                } 
            }
            // fetch the contact name from related contacts
            if(!relContactIds.isEmpty()){
                for(Contact con : [Select Id, Name from Contact where Id in: relContactIds]){
                    conDetails.put(con.Id,con.Name);
                }
            }
            //update the L_PR_Contact_Name__c field with updated contact name
            if(!conDetails.isEmpty()){
            	for(I_RM_Affiliation__c newAff :(List<I_RM_Affiliation__c>)Trigger.New){
                	if(conDetails.get(newAff.I_RM_Contact__c) != Null)
                        newAff.L_PR_Contact_Name__c = conDetails.get(newAff.I_RM_Contact__c);
            	}
            }
        }        
       
      /*  if(Trigger.isBefore && Trigger.isInsert){
            for(I_RM_Affiliation__c newAffiliation :(List<I_RM_Affiliation__c>)Trigger.New){
                //Set the Affiliation for Score calculation if it is a new Domestic Lead
                if(isValidISTScoringAffiliationRecordTypeId(newAffiliation.RecordTypeId)) {
                    newAffiliation.I_RM_Calculate_Affiliation_Score__c = true;
                }
            }
        }
        //created as per userstory LTU360-976
        if((Trigger.isBefore && (Trigger.isInsert || Trigger.Update){
           
            if(!makeAffiliationQualified){
            list<I_RM_Affiliation__c> AffiliationRecord=new list<I_RM_Affiliation__c>();
            for(I_RM_Affiliation__c newAffiliation :(List<I_RM_Affiliation__c>)Trigger.New){
                if((inactiveStatus.contains(newAffiliation.I_RM_Status__c)) && (newAffiliation.I_RM_EndDate__c==null)){
                    newAffiliation.I_RM_EndDate__c=system.today();
                    AffiliationRecord.add(newAffiliation);
                                           
                }
                else if((!inactiveStatus.contains(newAffiliation.I_RM_Status__c)) && (newAffiliation.I_RM_EndDate__c!=null)){
                    newAffiliation.I_RM_EndDate__c= null;
                } 
            }
        }
        } */
        if(Trigger.isAfter){
            lstExistingContact = null;
            set<Id> contactIDs = new set<Id>();
            set<Id> nonActiveContactIDs = new set<Id>();
            set<Id> affiContactIds = new set<Id>(); 
            set<Id> parentContactId = new set<Id>();
            Map<Id,List<I_RM_Affiliation__c>> mapConIdVSffiliation = new Map<Id,List<I_RM_Affiliation__c>>();
            Map<Id,List<I_RM_Affiliation__c>> mapConIdVSInActivaffiation = new Map<Id,List<I_RM_Affiliation__c>>();
            Map<Id,Decimal> mapContactIdVSCount = new Map<Id,Decimal>();
            set<Id> setDomesticLeadContact = new set<Id>();            
            List<I_RM_Affiliation__c> lstAffiToProcess = new List<I_RM_Affiliation__c>();
             //update Domestic Lead Affiliation status as per LTU360-1232
            if(Trigger.isDelete){
                List<I_RM_Affiliation__c> listOfOldAfls = New List<I_RM_Affiliation__c>();
                listOfOldAfls = getUpdatedExternalContactAffliations(Trigger.Old, inactiveStatus);
                if(listOfOldAfls.size() > 0){
                    I_RM_AffiliationTriggerHelper.updateContactExternalEmal(listOfOldAfls, inactiveStatus);
                }
            }
             //update Domestic Lead Affiliation status as per LTU360-1572
            if(Trigger.isInsert){
                
                //LTU360-1300 Create “sync” functionality between Affiliation Email Fields and Contact Email Fields V2
                I_RM_AffiliationTriggerHelper.updateContactEmailfields(Trigger.New, (Map<Id,I_RM_Affiliation__c>)Trigger.OldMap);

                List<I_RM_Affiliation__c> listOfAflls = New List<I_RM_Affiliation__c>();
                listOfAflls = getUpdatedExternalContactAffliations(Trigger.New, inactiveStatus);
                if(listOfAflls.size() > 0){
                    I_RM_AffiliationTriggerHelper.updateContactExternalEmal(listOfAflls, inactiveStatus);
                }
            }                
            
            if(Trigger.isUpdate){
                if(!makeLeadInactive){                
                    for(I_RM_Affiliation__c aff:(List<I_RM_Affiliation__c>)Trigger.New){ 
                            //if(aff.I_RM_Contact__c!= NULL && (aff.I_RM_Role__c=='Applicant') && (!inactiveStatus.contains(aff.I_RM_Status__c) || a.I_RM_Status__c == 'NULL' || a.I_RM_Status__c == 'Unknown Status')){//&& I_RM_Domestic_Lead__c > 0
                                
                        if(aff.I_RM_Contact__c!= NULL && aff.I_RM_Role__c=='Applicant' 
                          && (!inactiveStatus.contains(aff.I_RM_Status__c) && aff.I_RM_Status__c != 'Unknown Status' && aff.I_RM_Status__c != NULL)
                           && (mapOldAffiliations.get(aff.Id).I_RM_Status__c == NULL ||mapOldAffiliations.get(aff.Id).I_RM_Status__c == 'Unknown Status') ){
                               newaffiliations.add(aff);
                               parentContactId.add(aff.I_RM_Contact__c);
                           }
                    }
                    
                    //Query for contact related active affiliation is found 1 or more then 1 add contact in set.
                    //this is same as domestic lead count on contact.
                    for(I_RM_Affiliation__c objAffiliation :[SELECT Id,Name,RecordTypeId,I_RM_Contact__c,I_RM_Status__c,Createddate FROM I_RM_Affiliation__c WHERE I_RM_Status__c NOT IN: inactiveStatus AND I_RM_Contact__c IN:parentContactId AND I_RM_Role__c ='Domestic Lead']){
                        setDomesticLeadContact.add(objAffiliation.I_RM_Contact__c);
                    }
                    /*for(Contact objContact :[SELECT Id,I_RM_Domestic_Lead__c FROM Contact WHERE I_RM_Domestic_Lead__c > 0 AND Id IN:parentContactId]){
                        mapContactIdVSCount.put(objContact.Id,objContact.I_RM_Domestic_Lead__c);
                    }*/
                    for(I_RM_Affiliation__c objAff: newaffiliations){                        
                        //if(mapContactIdVSCount.containsKey(objAff.I_RM_Contact__c)){
                        if(setDomesticLeadContact.contains(objAff.I_RM_Contact__c)){
                            lstAffiToProcess.add(objAff);
                        }
                    }
                    if(lstAffiToProcess.size()>0){                  
                        I_RM_AffiliationTriggerHelper.updateActiveAffiliation(lstAffiToProcess, inactiveStatus);//Active affiliations only.
                    }
                }
                if(!runmarkCalculateAffiliationScoreToTrue) {                    
                    List<I_RM_Affiliation__c> newAffiliationList = new List<I_RM_Affiliation__c>();
                    for(I_RM_Affiliation__c newAffiliation :(List<I_RM_Affiliation__c>)Trigger.New){              
                        if(isValidISTScoringAffiliationRecordTypeId(newAffiliation.RecordTypeId)) {
                            newAffiliationList.add(newAffiliation);
                        }
                    }
                    if(newAffiliationList.size() > 0) {
                        //call this method only for Domestic Lead Affiliations
                        I_RM_AffiliationTriggerHelper.markCalculateAffiliationScoreToTrue(newAffiliationList,(Map<Id,I_RM_Affiliation__c>)Trigger.OldMap,false);                 
                    }
                   
                }

                //LTU360-1300 Create “sync” functionality between Affiliation Email Fields and Contact Email Fields V2
                I_RM_AffiliationTriggerHelper.updateContactEmailfields(Trigger.New, (Map<Id,I_RM_Affiliation__c>)Trigger.OldMap);  

                List<I_RM_Affiliation__c> listOfUpdatedAffls = New List<I_RM_Affiliation__c>();
                Map<Id,I_RM_Affiliation__c> oldMap = New Map<Id,I_RM_Affiliation__c>();
                oldMap = (Map<Id,I_RM_Affiliation__c>)Trigger.OldMap;
                for(I_RM_Affiliation__c afl :(List<I_RM_Affiliation__c>) Trigger.New){
                    if(afl.I_RM_Work_Email__c != null && (afl.I_RM_Work_Email__c != OldMap.get(afl.Id).I_RM_Work_Email__c) && afl.I_RM_Role__c == 'External Contact' && afl.I_RM_Contact__c != null && !inactiveStatus.contains(afl.I_RM_Status__c)){
                        listOfUpdatedAffls.add(afl);
                    }
                }
                if(listOfUpdatedAffls.size() >0 ){
                I_RM_AffiliationTriggerHelper.updateContactExternalEmal(listOfUpdatedAffls, inactiveStatus);
                }
                    
            }
            
            /* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
* @author Teja Yenduri
* @date 2022-02-18

LTU360-1231,LTU360-1230 Getting aggregate list of active and inactive domestic lead affilaitions from here and calling in helper

* ─────────────────────────────────────────────────────────────────────────────────────────────────┘*/
        if(Trigger.isInsert || Trigger.isUpdate ) {

            List<I_RM_Affiliation__c> listOfInactiveAppAffliations = New List<I_RM_Affiliation__c>();
            listOfInactiveAppAffliations = getListOfInactiveAffliations(mapOldAffiliations, 'Applicant', inactiveStatus);        
            if(listOfInactiveAppAffliations.size() > 0){
                I_RM_AffiliationTriggerHelper.createLeadAffliations(listOfInactiveAppAffliations, inactiveStatus, 'Applicant');
            }

            List<I_RM_Affiliation__c> listOfInactiveStudentAffliations = New List<I_RM_Affiliation__c>();
            listOfInactiveStudentAffliations = getListOfInactiveAffliations(mapOldAffiliations, 'Student', inactiveStatus);  
            if(listOfInactiveStudentAffliations.size() > 0){
                I_RM_AffiliationTriggerHelper.createLeadAffliations(listOfInactiveStudentAffliations, inactiveStatus, 'Student');
            }
            
			//LTU360-1492 create lead for inactive HDR Student affiliation
            List<I_RM_Affiliation__c> listOfInactiveHDRStudentAffliations = New List<I_RM_Affiliation__c>();
            listOfInactiveHDRStudentAffliations = getListOfInactiveAffliations(mapOldAffiliations, 'HDR Student', inactiveStatus);        
            if(listOfInactiveHDRStudentAffliations.size() > 0){
                I_RM_AffiliationTriggerHelper.createLeadAffliations(listOfInactiveHDRStudentAffliations, inactiveStatus, 'HDR Student');
            }
            
            if(!makeAffiliationQualified){
                for(I_RM_Affiliation__c newAffiliation : (List<I_RM_Affiliation__c>)Trigger.new){
                                               
                    if(Trigger.isInsert || (Trigger.isUpdate && newAffiliation.I_RM_Status__c != mapOldAffiliations.get(newAffiliation.id).I_RM_Status__c ) 
                        && (newAffiliation.I_RM_Role__c == 'Applicant' || newAffiliation.I_RM_Role__c == 'Student' || newAffiliation.I_RM_Role__c == 'HDR Student') && inactiveStatus.contains(newAffiliation.I_RM_Status__c)){
                                               lstNewAffiliation.add(mapNewAffiliations.get(newAffiliation.Id)); 
                                                   
                         /*   if(newAffiliation.I_RM_Contact__c != null && newAffiliation.I_RM_Role__c == 'Applicant'){
                                contactIDs.add(newAffiliation.I_RM_Contact__c);//Only Inactive Applicant A1 c1                                              
                            }    */ // same logic repeated                                      
                            if(newAffiliation.I_RM_Contact__c != null && (newAffiliation.I_RM_Role__c == 'Student' || newAffiliation.I_RM_Role__c == 'Applicant' || newAffiliation.I_RM_Role__c == 'HDR Student')){ // HDR Student added as part of LTU360-1527
                               //nonActiveContactIDs.add(newAffiliation.I_RM_Contact__c);//inactive student and inactive applicant A2 c2
                                contactIDs.add(newAffiliation.I_RM_Contact__c);//inactive student and inactive applicant A2 c2
                                               }                        
                                           }
                }
                if(!contactIDs.isEmpty()){
                   // List<contact> test = [Select I_RM_Applicant__c from contact where id=:contactIDs limit 1];
                
                    for(Contact objContact : [SELECT Id,I_RS_Deceased__c FROM Contact WHERE  I_RS_Deceased__c = false AND Id IN:contactIDs ]){
                                                  affiContactIds.add(objContact.id);
                                              }
                }
            
            if(!affiContactIds.isEmpty() || !lstNewAffiliation.isEmpty()){
                
                I_RM_AffiliationTriggerHelper.filterAffiliations(affiContactIds,lstNewAffiliation, inactiveStatus);//only Inactive Applicant/Student Affiliation
            }
            }
        } 
        }
        
    }       
        
    
    //check if the Affiliation records record type Id is valid for Scoring
    private static Boolean isValidISTScoringAffiliationRecordTypeId(Id recordTypeId) {
        Boolean validRecordType = false;
        I_ST_BatchScoring__c batchScoringCustomSetting = I_ST_BatchScoring__c.getValues(GlobalConstants.I_RM_AFFILIATIONSCORING);
        Set<Id> validRecordTypeIds = GlobalUtility.convertCommaSeparatedStringsToSetIds(batchScoringCustomSetting.I_ST_RecordType_SFIDs__c);
        if(validRecordTypeIds.contains(recordTypeId)) {
            validRecordType = true;
        }
        return validRecordType;
    }
    
    //return the list of affliations where affliation status is changed to inactive
    public static List<I_RM_Affiliation__c> getListOfInactiveAffliations(map<Id,I_RM_Affiliation__c> mapOldAffiliations, String afflType, List<String> inactiveStatus){
    String oldStatus;
    List<I_RM_Affiliation__c> inactiveAffliationsList = new List<I_RM_Affiliation__c>();
        for(I_RM_Affiliation__c affl : (List<I_RM_Affiliation__c>)Trigger.New){
            oldStatus = mapOldAffiliations != null ? mapOldAffiliations.get(affl.Id).I_RM_Status__c : null;
            if(inactiveStatus.contains(affl.I_RM_Status__c) && !inactiveStatus.contains(oldStatus) && affl.I_RM_Role__c == afflType){
                inactiveAffliationsList.add(affl);
            }
        }
        return inactiveAffliationsList;
    }

    // return the list of updated affliations based on the condition.
    public static List<I_RM_Affiliation__c> getUpdatedExternalContactAffliations(List<I_RM_Affiliation__c> listOfAffliations, List<String> inactiveStatus){
        List<I_RM_Affiliation__c> listOfUpdatedAflls = New List<I_RM_Affiliation__c>();
        for(I_RM_Affiliation__c afs : (List<I_RM_Affiliation__c>) listOfAffliations){
            if(afs.I_RM_Work_Email__c != null && afs.I_RM_Role__c == 'External Contact' && afs.I_RM_Contact__c != null && (!inactiveStatus.contains(afs.I_RM_Status__c))){
                listOfUpdatedAflls.add(afs);
            }
        }
        return listOfUpdatedAflls;
    }
    
}