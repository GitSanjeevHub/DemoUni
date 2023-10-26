@isTest
public class PositionHistoryHandlerTest {
    private static List<Position_History__c> getPositionHistoryRecords(){
        return [SELECT I_RS_Contact__c,
                            I_RS_Organisation__c,
                            I_RS_Position_Description__c,
                            I_RS_Campus__c,
                            I_RS_Campus_Code__c,
                            I_RS_Start_Date__c,
                            I_RS_End_Date__c,
                            I_RS_Salary_Grade_level__c,
                            I_RS_Employment_Type__c,
                            I_RS_FTE__c,
                            I_RS_Staff_Group_Code__c,
                            I_RS_Staff_Group_Desc__c,
                            Staff_Sub_Group_Code__c,
                            I_RS_Staff_SubGroup_Desc__c,
                            I_RS_Organisation_Code__c,
                            I_RS_Organisation_Name__c,
                            I_RS_Department_Code__c,
                            I_RS_Department_Name__c,
                            I_RS_School_Code__c,
                            I_RS_School_Name__c,
                            I_RS_College_Code__c,
                            I_RS_College_Name__c FROM Position_History__c];    
    }
    
    @istest 
    static void validatePositionHistoryHandler() {
        ContactTriggerHandler.runHierarchySharing = false;
        ContactTriggerHandler.runProjectTeamMemberSharing = false;
        ContactTriggerHandler.runResearchPersonnelSharing = false;
        ContactTriggerHandler.runDirectManagerSharing = false;
        ContactTriggerHandler.runEndDatePositionHistory = true;

        Database.DMLOptions allowDuplicates = TestUtility.getAllowDuplicatesDMLOption();
        AccountContactRelationHandler.runHierarchySharing = false;

        Account acc1, acc2, accParent;
        Contact cont1, cont2;
        System.debug('Label.Top_Org_Name_LaTrobe: ' + Label.Top_Org_Name_LaTrobe);
        accParent= TestUtility.newEmptyLTUAccount(Label.Top_Org_Name_LaTrobe);
        //accParent.I_RS_Part_of_La_Trobe__c = true;
        Database.insert(accParent, allowDuplicates);
        
        acc1= TestUtility.newEmptyLTUAccount('Account1');
        acc2= TestUtility.newEmptyLTUAccount('Account2');
        //acc1.I_RS_Part_of_La_Trobe__c = true;
        acc1.ParentId = accParent.Id;
        //acc2.I_RS_Part_of_La_Trobe__c = true;
        acc2.ParentId = accParent.Id;

        Database.insert(acc1, allowDuplicates);
        Database.insert(acc2, allowDuplicates);

        cont1 = new Contact (FirstName = 'ContactF1', LastName='ContactL1',MobilePhone= '0415 822 605', AccountId = acc1.Id);
        cont2 = new Contact (FirstName = 'ContactF2', LastName='ContactL2',MobilePhone= '0415 822 705', AccountId = acc2.Id);
        
        
        Database.insert(cont1, allowDuplicates);
        Database.insert(cont2, allowDuplicates);

        Test.startTest();
        List<Position_History__c> phList = getPositionHistoryRecords();
        for (Position_History__c ph:phList ){
            system.debug('PHrec1: ' + ph);
        }
        System.assertEquals(0,phList.size(), 'PH records created (when it should not be)');
        
        AccountContactRelation acr1 = [SELECT Id, I_RS_Position_Description__c
                                       FROM AccountContactRelation 
                                       WHERE ContactId = :cont1.Id AND AccountId =:acc1.Id LIMIT 1];
        acr1.I_RS_Position_Description__c = 'Test Position A1C1';
        Database.update(acr1, allowDuplicates) ;

        phList = getPositionHistoryRecords();
        System.assertEquals(1,phList.size(), 'PH should have created one new record (count should be 1) ');
        
        acr1.I_RS_Position_Description__c = 'Test Position A1C1';
        cont2.AccountId = acc1.Id;
        Database.update(cont2, allowDuplicates);
        phList = getPositionHistoryRecords();
        
        System.assertEquals(1,phList.size(), 'PH should not create new record as this is only org change, middleware will update PH fields later (count should be 1)');
        
        AccountContactRelation acr = [SELECT ID, I_RS_User_Name__c FROM AccountContactRelation WHERE ContactId = :cont2.Id AND AccountId = :cont2.AccountId];
        acr.I_RS_User_Name__c = 'test';
        Database.update(acr, allowDuplicates);
        phList = getPositionHistoryRecords();
        for (Position_History__c ph:phList ){
            system.debug('PHrec4: ' + ph);
        }        
        System.assertEquals(1,phList.size(), 'PH record should not be created for changing a non PH field in ACR');
        
        acr = [SELECT ID, I_RS_User_Name__c FROM AccountContactRelation WHERE ContactId = :cont1.Id AND AccountId = :cont2.AccountId];
        acr.I_RS_Staff_Group_Desc__c = 'some change';
        Database.update(acr, allowDuplicates);
        phList = getPositionHistoryRecords();
        for (Position_History__c ph:phList ){
            system.debug('PHrec5: ' + ph);
        }        
        System.assertEquals(2,phList.size(), 'PH record should be created for changing a PH field in ACR');
        
        cont1.AccountId = acc2.Id;
        Database.update(cont1, allowDuplicates);
        Test.stopTest();
        
        phList = getPositionHistoryRecords();
        for (Position_History__c ph:phList ){
            system.debug('PHrec6: ' + ph);
        }        
        
    }

}