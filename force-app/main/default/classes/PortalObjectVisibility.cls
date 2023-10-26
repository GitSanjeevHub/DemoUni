public class PortalObjectVisibility {

    public static void enableVisibleInSelfService(List<Task> tasks){
        
        for (Task task : tasks){
            /*if (
                task.I_RS_Parent_Object_Name__c == 'Project_Proposal__c' || 
                task.I_RS_Parent_Object_Name__c == 'Ethics_Request__c' ||
               	task.I_RS_Parent_Object_Name__c == 'Ethics_Post_Approval__c'
               )*/
                task.IsVisibleInSelfService = true;
        }
        
    }
    
}