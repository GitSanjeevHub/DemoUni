/*
* @Modified by Vanita - 02/03/2022 - As part of remediation commented CTE call
*/
public class ContactTriggerHelper {
    
    @InvocableMethod(label='Clear Contact Related User' description='Cleares the "Related User" field of Contact.')
    public static void ClearContactRelatedUser(List<Id> ContactIds) {
        ClearContactRelatedUserFuture(ContactIds);
    }
    
    @future
    public static void ClearContactRelatedUserFuture(List<Id> ContactIds) {
        List<Contact> Contacts = new List<Contact>();
        for (Id i: ContactIds) {
            Contact c = new Contact(Id = i, I_RS_Related_User__c = null);
            Contacts.add(c);
        }
        update Contacts;
    }
    
    
    public static void handleBudgetRelatedFieldChanges(List<Contact> contactsAfterDML, Map<Id, contact> contactsBeforeDML){
        
        System.debug('handleBudgetRelatedFieldChanges');
        
        Set<Id> contactIdsToRecalculateBudgetsFor = new Set<Id>();
        
        for (contact contactAfterDML : contactsAfterDML){
            
            System.debug('contact changed?');
            
            contact contactBeforeDML = contactsBeforeDML.get(contactAfterDML.Id);
            
            Boolean salaryGradeChanged = 
                contactBeforeDML.I_RS_Salary_Grade__c != contactAfterDML.I_RS_Salary_Grade__c;
            System.debug('salaryGradeChanged '+salaryGradeChanged);
            
            if (salaryGradeChanged){
                contactIdsToRecalculateBudgetsFor.add(contactAfterDML.Id);
            }
            
        }
        
        System.debug(contactIdsToRecalculateBudgetsFor);
        
        if (!contactIdsToRecalculateBudgetsFor.isEmpty()){
            System.enqueueJob(new RecordMergeBudgetHandler(contactIdsToRecalculateBudgetsFor, 'contact'));
        }
        
    }
    
    public static void cleanVilomahAccounts(List<Contact> contactsOld, String updateOrDelete, Map<Id, Contact> contactsAfterDML){
        
        //Collect Ids of isolated Account candidates (Trigger.Old)
        Set<Id> deleteAccountCandidates = new Set<Id>();
        for(Contact con : contactsOld){
            if( con.AccountId != null){ 
                if(updateOrDelete == 'Delete'){
                    deleteAccountCandidates.add(con.AccountId);
                } else if(updateOrDelete == 'Update' && con.AccountId != contactsAfterDML.get(con.Id).AccountId){
                    deleteAccountCandidates.add(con.AccountId);
                } 
            }
        }
        
        //Filter only Lead Account record type without Contacts
        Set<Id> deleteAccountIds = new Set<Id>();
        for(Account acct : [Select Id, (Select Id FROM Contacts LIMIT 1) FROM Account WHERE RecordType.DeveloperName = 'I_ST_Lead_Account' AND Id IN :deleteAccountCandidates]){
            if(acct.Contacts.size() == 0){
                deleteAccountIds.add(acct.Id);
            }
        }
        
        if(deleteAccountIds.isEmpty()){
            return;
        }
        
        List<Case> caseWithDeleteAccounts = new List<Case>([Select Id, AccountID FROM Case WHERE AccountId IN :deleteAccountIds]);
        Set<Id> deleteAccountIdsWithCase = new Set<Id>();
        for(Case c : caseWithDeleteAccounts){
            deleteAccountIdsWithCase.add(c.AccountID);
        }
        
        //Do not try and delete accounts with cases still attached
        deleteAccountIds.removeAll(deleteAccountIdsWithCase);
        
        List<AccountContactRelation> indirectRelations = new List<AccountContactRelation>([Select Id, AccountID FROM AccountContactRelation WHERE IsDirect = false AND AccountID IN :deleteAccountIds]);
        
        Database.DeleteResult[] drListACR = Database.delete(indirectRelations, false);        
                
        Database.DeleteResult[] drList = Database.delete(new List<Id>(deleteAccountIds), false);
    }

    //Added by JTan IBM on 27 Jan 2021 for IST-256 - starts
    // @Modified by Vanita - 02/03/2022 - As part of remediation commented CTE call
    /*public static void runContactTransitionEngine(List<Contact> triggerOld, List<Contact> triggerNew) {
        I_ST_CTE_ContactTransitionEngine cte = new I_ST_CTE_ContactTransitionEngine(triggerOld, triggerNew);
        cte.run();
    }*/ 
    
    //Added by Teja IBM on 30 August 2021 for LTU360-68 - starts
    /*** Setting CalculateContact Score to true**/
   /* public static void markCalculateContactScoreToTrue(List<Contact> newContacts,
                                                       map<Id,contact> oldContacts,
                                                       boolean isInsertContact){
                                                           boolean isFieldChanged = isInsertContact;
                                                           List<Contact> listUpdateContacts = new List<Contact>();
                                                           List<String> objectFields = fetchAllChangedField();
                                                           for(contact contactRecord: newContacts){
                                                               for(string contactField: objectFields){
                                                                   if(contactRecord.get(contactField) != oldContacts.get(contactRecord.id).get(contactField)){
                                                                       isFieldChanged = true;
                                                                       break;
                                                                   }
                                                               }
                                                               if(isFieldChanged){
                                                                   //system.debug('Is calling.');
                                                                   contact contactToUpdate = new contact(Id=contactRecord.Id,I_ST_Calculate_Contact_Score__c=true);
                                                                   listUpdateContacts.add(contactToUpdate);
                                                                   isFieldChanged = false;
                                                               }
                                                           }
                                                           Database.update(listUpdateContacts,false);
                                                           ContactTriggerHandler.runmarkCalculateContactScoreToTrue=true;
                                                       }
    
    //Method to get all contact field from custom metadataType
    public static List<string> fetchAllChangedField(){
        List<string> contactFields = new List<string>();
        //for(I_ST_Lead_Scoring__mdt leadScoreRecord : [SELECT I_ST_Field_API_Name__c FROM I_ST_Lead_Scoring__mdt WHERE I_ST_Object__c = 'Contact']){
        for(I_ST_Lead_Scoring__mdt leadScoreRecord : I_ST_Lead_Scoring__mdt.getAll().values()){
            if(leadScoreRecord.I_ST_Object__c == 'Contact') {
                string contactFieldName = '';
                if(leadScoreRecord.I_ST_Field_API_Name__c != ''){
                    contactFieldName = leadScoreRecord.I_ST_Field_API_Name__c;
                    contactFields.add(contactFieldName);
                }   
            }            
        }
        return contactFields;
    }*/
    
     //Added by Teja IBM on 21 January 2022 for LTU360-995 
    //Create ' Admin Account' whenever contact inserts.
    public static void createLeadOrganization(Map<Id,Contact> mapNewContact){        
        Map<Id,Account> mapContactVSAccount = new Map<Id,Account>();
        //List<Account> lstExistingAccount = new List<Account>();
        List<Account> lstNewLeadAccount = new List<Account>();
        Set<String> setContactName = new Set<String>();
       
        //Verify Account duplication if no duplicates create new account.
        for(Contact existingContact: mapNewContact.values()){
            if (existingContact.AccountId == null) {
                Account objOrganization = new Account();
                Database.DMLOptions dbDML = new Database.DMLOptions(); 
                dbDML.DuplicateRuleHeader.allowSave = true;
                dbDML.DuplicateRuleHeader.runAsCurrentUser = false;
                String contactName = existingContact.FirstName +' '+ existingContact.LastName;
           
                    objOrganization.Name = contactName;
                    objOrganization.RecordTypeId = AdminAccountRecordType;	
            		objOrganization.setOptions(dbDML);
                    mapContactVSAccount.put(existingContact.id,objOrganization);                
            }
               
        }
        //Create Account and link to contact.
        linkNewLeadAccountToContact(mapContactVSAccount);        
    }
    //Create Account and update contact.
    public static void linkNewLeadAccountToContact(Map<Id,Account> mapContactVSAccount){
        Map<String,Id> mapNewAccount = new Map<String,Id>();
        List<Account> lstnewLeadAccount = new List<Account>();
        List<Account> lstNewAccount = new List<Account>();
        List<Contact> lstUpdateContact = new List<Contact>();
        set<String> accountName = new set<String>();
        
        
        //Get Account Name
        for(Account newLeadAccount :mapContactVSAccount.values()){            
            lstnewLeadAccount.add(newLeadAccount);
            accountName.add(newLeadAccount.Name);
        }       
        //Insert Lead Account
        if(!lstnewLeadAccount.isEmpty()){
            // Adding this code to bypass Account Duplicate Rules
            Database.DMLOptions dbDML = new Database.DMLOptions(); 
            dbDML.DuplicateRuleHeader.allowSave = true;           
            List<Database.SaveResult> sr = Database.insert(lstnewLeadAccount, dbDML);
			
        }
        //Get account details
        for(Account objAccount : [SELECT Id,Name FROM Account WHERE Name =: accountName WITH SECURITY_ENFORCED]){
            mapNewAccount.put(objAccount.Name,objAccount.Id);
        }
        //Get latest contact details
        for(Contact objContact : [SELECT Id,FirstName,LastName,AccountId FROM Contact WHERE Id =:mapContactVSAccount.keySet()]){
            Contact objUpdateContact = objContact;
            String contactName = objContact.FirstName +' '+ objContact.LastName;
            //link account to contact
            objUpdateContact.AccountId = mapNewAccount.get(contactName);
            lstUpdateContact.add(objUpdateContact);
        }
        //update contact.
        if(!lstUpdateContact.isEmpty()){
            ContactTriggerHandler.runResearchPersonnelSharing = false;
            ContactTriggerHandler.runDirectManagerSharing = false;
            ContactTriggerHandler.runHierarchySharing = false;
            ContactTriggerHandler.runLeadAccountCleanup = false;
            hasFired();
            if(schema.SObjectType.contact.isUpdateable()){
                // Adding this code to bypass Contact Duplicate Rules
                Database.DMLOptions dbDML = new Database.DMLOptions(); 
            	dbDML.DuplicateRuleHeader.allowSave = true;
            	dbDML.DuplicateRuleHeader.runAsCurrentUser = false;
            	Database.SaveResult[] sr = Database.update(lstUpdateContact, dbDML);
            
            }
        } 
    }
    public static Id AdminAccountRecordType = [SELECT Id FROM recordType WHERE developername =: GlobalConstants.ACCOUNT_RECORD_TYPE_NAME_Admin_Account AND sObjectType = 'Account' LIMIT 1].id;
    private static Boolean hasFired = false;
    
    public static Boolean hasFired() {
        return hasFired;
    }
    
    public static void setFired() {
        hasFired = true;
    }
    
    public static void setNotFired() {
        hasFired = false;
    }
    //Added by JTan IBM on 27 Jan 2021 for IST-256 - ends



    //LTU360-1247 Set Affiliations to Inactive if Contact is Deceased
    //LTU360-2031 Populate contact name on affiliation if first name or last name changes 
    public static void setAffliationsToInactive(Map<Id,Contact> oldContactMap, List<Contact> contactList){		
        List<Id> updatedContactIds = new List<Id>();
        Map<Id,String> contactNameMap = new Map<Id,String>();
        for(Contact con : contactList){
            if(oldContactMap.get(con.Id).I_RS_Deceased__c != True && con.I_RS_Deceased__c == True){
                updatedContactIds.add(con.Id);
            }
            // filter out the contacts where name is changed           
            if(oldContactMap.get(con.Id).FirstName != con.FirstName || oldContactMap.get(con.Id).LastName != con.LastName){
                String name = con.FirstName + ' ' + con.LastName;
                contactNameMap.put(con.Id,name.trim());
            }
        }

        List<I_RM_Affiliation__c> affliationsToUpdate = New List<I_RM_Affiliation__c>();
        if(updatedContactIds.size() > 0){
        	for(Contact cont :[SELECT Id, Name, (SELECT Id, I_RM_Status__c, I_RM_EndDate__c from Affiliations__r WHERE I_RM_Status__c !='Inactive') 
        			FROM Contact WHERE Id IN : updatedContactIds WITH SECURITY_ENFORCED]){

            	for(I_RM_Affiliation__c affli : cont.Affiliations__r){
                	I_RM_Affiliation__c affliationRec = new I_RM_Affiliation__c();
                	affliationRec.I_RM_Status__c = 'Inactive';
                	affliationRec.I_RM_EndDate__c = System.today();
                	affliationRec.Id = affli.Id;
                	affliationsToUpdate.add(affliationRec);
            	}
        	}
        }
     // find all affiliations related to contact where name is changed and update those affiliations
        if(!contactNameMap.isEmpty()){
            //find all affiliations related to current contact
            for(I_RM_Affiliation__c relatedAff : [Select Id, L_PR_Contact_Name__c, I_RM_Contact__c from I_RM_Affiliation__c where I_RM_Contact__c in: contactNameMap.keyset()]){
               
                if(contactNameMap.get(relatedAff.I_RM_Contact__c) != Null && relatedAff.L_PR_Contact_Name__c!= contactNameMap.get(relatedAff.I_RM_Contact__c) ){
                    I_RM_Affiliation__c aff = new I_RM_Affiliation__c();
                	aff.Id = relatedAff.Id;
                    aff.L_PR_Contact_Name__c = contactNameMap.get(relatedAff.I_RM_Contact__c);
                	affliationsToUpdate.add(aff);
                }
            }            
        }
        if(!affliationsToUpdate.isEmpty()){
            update affliationsToUpdate;
        }

    }

    //LTU-360-1123
    public static void updateConfidentialfield(List<Contact> contactList){
        ContactTriggerHandler.firstRun = false;
        Set<Id> accountIds = New Set<Id>();
        for(Contact con : contactList){
            accountIds.add(con.AccountId);
        }
        Map<Id, Boolean> accountIdConfidentialValue = new Map<Id, Boolean>();
        for(Account acc : [Select Id, I_RS_Confidential__c From Account where Id IN : accountIds]){
            accountIdConfidentialValue.put(acc.Id, acc.I_RS_Confidential__c);
        }
        Boolean accountConfidential;
        for(Contact con : contactList){
            if(con.AccountId != null){
            accountConfidential = accountIdConfidentialValue.size() > 0 ? accountIdConfidentialValue.get(con.AccountId) : null;
            	if(accountConfidential !=null && accountConfidential != con.I_RS_Is_Organisation_Confidential__c){
                    con.I_RS_Is_Organisation_Confidential__c = accountConfidential;
            	}
            }
        }
    }

    /**
     * @description LTU360-2807 - Set the sponsored field based on 
     *                            Contact attributes in before insert/update context
     * @param newContactMap - map of new trigger items
     * @param oldContactMap - map of old trigger items
    */
    public static void updateSponsoredFieldOnAffiliations(
        Map<Id, Contact> oldContactMap,
        Map<Id, Contact> newContactMap
    ) {
        //set of Ids that need affiliations to be updated
        Set<Id> contactIdSet = new Set<Id>();

        for(Id conId : newContactMap.keySet()) {
            if( oldContactMap.isEmpty() || 
                ( newContactMap.get(conId).I_RS_Citizenship__c != oldContactMap.get(conId).I_RS_Citizenship__c )
            ) {
                contactIdSet.add(conId);
            }
        }

        if(!contactIdSet.isEmpty()) {

            List<I_RM_Affiliation__c> affList = new List<I_RM_Affiliation__c>(
                [SELECT Id, I_IL_Sponsored__c, I_IL_Intended_Funding_Source__c, I_RM_Contact__c 
                 FROM I_RM_Affiliation__c                   
                 WHERE I_RM_Contact__c IN :contactIdSet 
                 AND RecordTypeId = :GlobalConstants.AFFILIATION_RECORD_TYPE_ID_INT_LEAD 
                 AND I_RM_Active__c = :'True'
                ]
            );

            if(!affList.isEmpty()) {
                affList = I_RM_AffiliationTriggerHelper.setSponsoredFieldValue( 
                    affList,
                    new Map<Id, I_RM_Affiliation__c>()
                );
                Database.update(affList);
            }
        }
        
    }
}