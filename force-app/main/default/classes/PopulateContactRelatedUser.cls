public class PopulateContactRelatedUser {

    @InvocableMethod(label='Populate Contact Related User' description='Populates the "Related User" field of Contact.')
    public static void PopulateContactRelatedUser(List<User> users) {
         System.enqueueJob(new PopulateRelatedUserQueueable(users));
    }
    
}