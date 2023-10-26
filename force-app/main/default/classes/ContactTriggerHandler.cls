/*
* @Modified by Vanita - 02/03/2022 - As part of remediation commented CTE call
  @Modified by Subbiah - 29/07/2022 - SB-81 Enddate issue fix
*/
public with sharing class ContactTriggerHandler {
    public static Boolean runHierarchySharing = true;
    public static Boolean runProjectTeamMemberSharing = true;
    public static Boolean runResearchPersonnelSharing = true; 
    public static Boolean runPositionHistory = true; // SB-81 End Date update
    public static Boolean runDirectManagerSharing = true;
    public static Boolean runEndDatePositionHistory = false;
    //public static Boolean runmarkCalculateContactScoreToTrue = false;
    public static Boolean runBudget = true;
    Private Static String contactObjectName = 'Contact';
    public static Boolean firstRun = true;
    public static Boolean firstRunInactive = true;
    public static Boolean createLeadAccount = true;

    //Added by JTan IBM on 16 Feb 2021 for Apex test class fix
    //Flag default to false to avoid running CTE (Contact Transition Engine) multiple times in a single transaction
    //public static Boolean runCTEAlways = false;
    //Flag for skipping Lead Account cleanup in ProjectTeamMemberRecordAccessTest
    public static Boolean runLeadAccountCleanup = true;
    public static List<String> ContactRecordTypes = new List<String>{'I_ST_Domestic_Lead'};
    
    public static void execute(){ 
        if(Trigger.isBefore && Trigger.isInsert){

            if(firstRun){
                ContactTriggerHelper.updateConfidentialfield(Trigger.New);                
            }
        }

        if (Trigger.isAfter){
            if (Trigger.isInsert){      
                
                ContactTriggerHelper.updateSponsoredFieldOnAffiliations(
                    new Map<Id, Contact>(),
                    (Map<Id, Contact>) Trigger.newMap
                );
               
                //Added by JTan IBM on 27 Jan 2021 for IST-256    
                            
                if(
                    //Scenario 1: If not running tests, run CTE only once
                    (!ContactTriggerHelper.hasFired() && !Test.isRunningTest())
                    ||
                    //Scenario 2: If running CTE tests, run CTE always
                    (Test.isRunningTest())
                    //Scenario 3: If running other tests, never run CTE
                ) {
                    system.debug('In contact after insert');                
                    
                    if (createLeadAccount) {
                    	ContactTriggerHelper.createLeadOrganization((Map<Id, Contact>)Trigger.newMap);    
                    }
                    // @Modified by Vanita - 02/03/2022 - As part of remediation commented CTE call                
                 //   ContactTriggerHelper.runContactTransitionEngine(new List<Contact>(), Trigger.New);                    
                    ContactTriggerHelper.setFired();
                }
                
                              
            }

            if (Trigger.isUpdate){    
                
                ContactTriggerHelper.updateSponsoredFieldOnAffiliations(
                    (Map<Id, Contact>) Trigger.oldMap,
                    (Map<Id, Contact>) Trigger.newMap
                );
                if (runResearchPersonnelSharing) {
                    ResearchPersonnelTriggerHelper.updateRPSharesWithNewUserId((Map<Id, Contact>) Trigger.OldMap, (Map<Id, Contact>) Trigger.newMap);
                }
                if (runPositionHistory) { // SB-81 END date update to position history
                    List<Contact> newContactList = new List<Contact>();
                   map<Id, contact> oldMap = (Map<Id, Contact>) Trigger.OldMap;
                   for(Contact newContact :(List<Contact>)Trigger.New){              
                       if(newContact.I_RS_Employment_End_Date__c != null && 
                          newContact.I_RS_Employment_End_Date__c != oldMap.get(newContact.Id).I_RS_Employment_End_Date__c) {
                           newContactList.add(newContact);
                           system.debug('newContact>>>>>' + newContact);
                       }
                   }
                   if(newContactList.size() > 0) {
                   PositionHistoryHandler.enddateLastPostionHistoryRecForContact((set<Id>) Trigger.newMap.keyset());
               }
               }

                if (runDirectManagerSharing) {
                    ContactManagerPTMAccess.checkThenExecute(Trigger.New, (Map<Id, Contact>) Trigger.OldMap);
                }

                if (runHierarchySharing) {
                    updateACRActiveState((Map<Id, Contact>) Trigger.newMap, (Map<Id, Contact>) Trigger.OldMap);                
                    calculateHierarchySharingForRelatedUserChange((Map<Id, Contact>) Trigger.newMap, (Map<Id, Contact>) Trigger.OldMap);
                }

                if (runBudget) {
                	ContactTriggerHelper.handleBudgetRelatedFieldChanges(Trigger.New, (Map<Id, Contact>) Trigger.OldMap);
                }
                
                //Conor Langan IBM, Bluewolf 06 Nov 2020
                if (runLeadAccountCleanup) {
                    ContactTriggerHelper.cleanVilomahAccounts(Trigger.Old, 'Update' ,(Map<Id, Contact>) Trigger.NewMap);
                }

                //Added by JTan IBM on 27 Jan 2021 for IST-256
                if(
                    //Scenario 1: If not running tests, run CTE only once
                    (!ContactTriggerHelper.hasFired() && !Test.isRunningTest())
                    ||
                    //Scenario 2: If running CTE tests, run CTE always
                    (Test.isRunningTest())
                    //Scenario 3: If running other tests, never run CTE
                ) {
                    // @Modified by Vanita - 02/03/2022 - As part of remediation commented CTE call
                  //  ContactTriggerHelper.runContactTransitionEngine(Trigger.Old, Trigger.New);
                    ContactTriggerHelper.setFired();
                }

                    //LTU360-1247 Set Affiliations to Inactive if Contact is Deceased

                                    ContactTriggerHelper.setAffliationsToInactive((Map<Id,Contact>)Trigger.OldMap, Trigger.New);
                

                
            }   

            if (Trigger.isDelete){

                //Conor Langan IBM, Bluewolf 06 Nov 2020
                if (runLeadAccountCleanup) {
                    ContactTriggerHelper.cleanVilomahAccounts(Trigger.Old, 'Delete', null);
                }
                
                if (runBudget){
                    Set<Id> masterContactIds = GlobalUtility.getParentIds(Trigger.Old, 'MasterRecordId');
                    System.debug('masterContactIds '+masterContactIds);
                    if (masterContactIds != null){
                        System.enqueueJob(new RecordMergeBudgetHandler(masterContactIds, 'Contact'));
                    }
				}
            }

        }
        
        
        //--------****Created for validating contact delete******-----------
        if (Trigger.isBefore){
            if (Trigger.isUpdate){
                if(firstRun){
                    ContactTriggerHelper.updateConfidentialfield(Trigger.New);                
                }
            }
            if (Trigger.isDelete){
                checkDelete((Map<Id, Contact>) Trigger.oldMap, (Map<Id, Contact>) Trigger.OldMap);
            }
        }
        //--------****END******-----------
    }

    private static void updateACRActiveState(Map<Id, Contact> triggerNewMap, Map<Id, Contact> triggerOldMap){
        set<Id> cIds = new set<Id>();
        set<Id> aIds = new set<Id>();
        List<AccountContactRelation> acrs = new List<AccountContactRelation>();
        Contact oldC, newC;
        
        for (Contact c: triggerNewMap.Values()) {
            oldC = triggerOldMap.get(c.Id);
            if (c.AccountId != oldC.AccountId) {
                cIds.add(c.Id);
                aIds.add(c.AccountId);
                aIds.add(oldC.AccountId);
            }
        }
        
        for (AccountContactRelation acr: [SELECT Id, AccountId, ContactId, IsDirect, IsActive, I_RS_Manual__c FROM AccountContactRelation WHERE ContactId in :cIds and AccountID in :aIds]) {
            newC = triggerNewMap.get(acr.ContactId);
            oldC = triggerOldMap.get(acr.ContactId);
            if (acr.AccountId == newC.AccountId) {
                acr.IsActive = TRUE;
                acrs.add(acr);
            }
            if ((acr.AccountId == oldC.AccountId) && (acr.I_RS_Manual__c == FALSE)) {
                acr.IsActive = FALSE;
                acrs.add(acr);
            }
        }
        if (acrs.size() > 0) {
            Database.Update(acrs, false);
            System.debug('Contact trigger acr update: ' + acrs);
        }
    }
    
    private static void calculateHierarchySharingForRelatedUserChange(Map<Id, Contact> newContactsMap, Map<Id, Contact> OldContactsMap){
        set<Id> contactIds = new set<Id>();
        Contact oldC;
        for (Contact newC: newContactsMap.values()) {
            oldC = OldContactsMap.get(newC.Id);
            if (newC.I_RS_Related_User__c != oldC.I_RS_Related_User__c) {
                contactIds.add(newC.Id);    
            }
        }
        if (contactIds.size() > 0) {
            System.enqueueJob(new HierarchySharesForContactsQueueable(contactIds, null, false, false));
        }
    }
    
    //newMethod to verify the custom permission and field
    private static void checkDelete(Map<Id, Contact> triggeroldMap, Map<Id, Contact> triggerNewMap){
        Boolean hasPermission = FeatureManagement.checkPermission('I_ST_Merge_Contacts_From_Chat');
        for(Contact cont : triggeroldMap.Values()){
            if(!cont.I_ST_Deletion_Allowed__c && hasPermission){
                cont.addError('Insufficient privileges to complete the operation');
            }
        }
    }
    
    //check if the Contact records record type Id is valid for Scoring
   /* private static Boolean isValidISTScoringContactRecordTypeId(Id recordTypeId) {
        Boolean validRecordType = false;
        String strRecordDevName = Schema.SObjectType.Contact.getRecordTypeInfosById().get(recordTypeId).getDeveloperName();
        if(GlobalConstants.CONTACT_RECORD_TYPE_API_NAME_DOMESTIC_LEAD == strRecordDevName) {
            validRecordType = true;
        }
        return validRecordType;
    }*/
    
}