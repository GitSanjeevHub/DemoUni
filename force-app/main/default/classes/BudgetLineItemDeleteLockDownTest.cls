@isTest
public class BudgetLineItemDeleteLockDownTest {
    
  
    public static testmethod void budgetLineItemDeleteLockDownTest() {

        
        Account portalAccount = TestUtility.newEmptyExternalAccount('TestAccount');
        insert portalAccount;

        //Contact portalContact = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, portalAccount.Id);
        Contact portalContact = TestUtility.createContact(portalAccount.Id);
        insert portalContact;

        User portalUser;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {

            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'LTU Partner Community Login User' Limit 1];
            //UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'Partner' LIMIT 1];
            portalUser = TestUtility.newUser('test', portalProfile.Id, null, portalContact.Id);
            
            System.debug(portalUser);

            insert portalUser;
        }

        Project_Proposal__c pp = TestUtility.newProjectProposal();
        pp.OwnerId = portalUser.Id;
        insert pp;
        
        Budget__c budget = TestUtility.newBudget(pp.Id);
        insert budget;
        
        Budget_Line_Item__c lineItem = TestUtility.newBudgetLineItem(budget.Id);
        insert lineItem;

        Object_Metadata__c deletionBlockerCustomSetting = new Object_Metadata__c(
            Name = 'Budget_Line_Item__c',
            I_RS_Enable_Deletion_Blocker__c = true,
            I_RS_Deletion_Blocker_Check_Formula__c = 'I_RS_Line_Item_Permission_Delete__c',
            I_RS_Deletion_Blocker_Error_Message__c = 'Cant delete this'
        );
        insert deletionBlockerCustomSetting;

        budget.I_RS_Status__c = 'Active';
        update budget;

        System.runAs(portalUser){

            try {

                Budget_Line_Item__c budgetLineItem = [select Id, I_RS_Line_Item_Permission_Delete__c from Budget_Line_Item__c];
                System.debug(budgetLineItem);
                delete budgetLineItem;

                System.assert(false, 'Budget Line Item has deleted when it shouldn\'t have');
            }
            catch (DMLException e){
                System.assert(
                    e.getMessage().contains('CUSTOM_VALIDATION_EXCEPTION'),
                    'On Budget Line Item delete, Exception has happened as expected but for a different reason from what is expected. Please investigate.'
                );
            }

        }

    }

}