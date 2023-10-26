/**
* I_ST_FlowFindDuplicates
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @Modification logs
* 21/02/2022 - Vanita Walia - Modified the code as part of remediation and removed all the logic related to duplicate rules and instead queried affiliation to fetch duplicate contacts
*/

global  without sharing class I_ST_FlowFindDuplicates {
    
    @InvocableMethod(label='Find Duplicate Contacts')
    global static List<Contact> FindDuplicateContacts(List<ContactFields> cons) {
        
        //variable initialization
        List<Contact> returnList = new List<Contact>();
        List<I_RM_Affiliation__c> dupList1 = new List<I_RM_Affiliation__c>();
        List<I_RM_Affiliation__c> dupList2 = new List<I_RM_Affiliation__c>();
        Map<Id,Contact> contactMap = new  Map<Id,Contact>();
      
        // Find duplicate affiliations & its assiciated contact record based on the input email
        dupList1 = [Select I_RM_Contact__c from I_RM_Affiliation__c where I_RM_Email__c =: cons[0].Email OR I_RM_Work_Email__c =: cons[0].Email 
                    OR I_RM_Student_Email__c =: cons[0].Email ORDER BY createdDate DESC];
       
       
        if(!dupList1.isEmpty()){           
           
            // add all associated contacts in contactMap if its not already added
            for(I_RM_Affiliation__c affiliation : dupList1){
                if(!contactMap.containsKey(affiliation.I_RM_Contact__c))
                    contactMap.put(affiliation.I_RM_Contact__c, new Contact(Id = affiliation.I_RM_Contact__c));                
            }
        }
      
        // Find duplicate affiliations & its assiciated contact record based on the first name, lastname and phone numbers
        dupList2 = [Select I_RM_Contact__c from I_RM_Affiliation__c 
                                        where I_RM_Contact__r.FirstName = :cons[0].FirstName AND I_RM_Contact__r.LastName =: cons[0].LastName AND
                                           (I_RM_Mobile_Phone__c =: cons[0].Mobile OR I_RM_Phone__c =: cons[0].Mobile OR I_RM_Other_Phone__c =: cons[0].Mobile)
                                        ORDER BY createdDate DESC];
                                        system.debug('## dupList2' + dupList2);  
        if(!dupList2.isEmpty()){
           
            // add all associated contacts in contactMap if its not already added
            for(I_RM_Affiliation__c aff : dupList2){
                if(!contactMap.containsKey(aff.I_RM_Contact__c))
                    contactMap.put(aff.I_RM_Contact__c, new Contact(Id = aff.I_RM_Contact__c));                
            }
        }
        
        // AllOrFirst boolean true represent we need to return 1st matching record else list of all matching records
        if(!contactMap.isEmpty()){
        	if(cons[0].AllOrFirst){
            	returnList.add(contactMap.values()[0]);
        	}
        	else {
            	returnList.addAll(contactMap.values());
        	}
        }
        
        // return the duplicate contact record
        return returnList;
    }

    // Global class with invocable variables will be used to send input fields from flow to find duplicate records
    global class ContactFields {
        @InvocableVariable
        global String FirstName;

        @InvocableVariable
        global String LastName;

        @InvocableVariable
        global String Email;

        @InvocableVariable
        global String Mobile;

        @InvocableVariable
        global Boolean AllOrFirst;
    }
    
}