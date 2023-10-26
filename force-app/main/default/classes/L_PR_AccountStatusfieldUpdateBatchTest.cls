/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* L_PR_AccountStatusfieldUpdateBatchTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Kishore Reddy Basani
* @version        1.0
* @created        05-08-2022
* @Description	  This is test class for L_PR_AccountStatusfieldUpdateBatch
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public class L_PR_AccountStatusfieldUpdateBatchTest{

    @TestSetup
    static void makeData(){
        
        List<Account> accountsToBeCreated = New List<Account>();

        for(Integer i=0; i<10; i++){
            Account acc = New Account();
            acc.Name = 'Test' + i;
            acc.I_RS_Status__c = 'Active';
            accountsToBeCreated.add(acc);
        }

        Insert accountsToBeCreated;
    }

    @isTest 
    public static void accountStatusFieldUpdatedPositive(){

        Test.startTest();
        Database.executeBatch(new L_PR_AccountStatusfieldUpdateBatch(), 200);
        Test.stopTest();
    }
}