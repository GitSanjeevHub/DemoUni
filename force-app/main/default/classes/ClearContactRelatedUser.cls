public class ClearContactRelatedUser {
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
}