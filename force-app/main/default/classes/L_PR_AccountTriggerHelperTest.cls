@isTest 
public class L_PR_AccountTriggerHelperTest{

    @TestSetup
    static void makeData(){
        
        List<L_PR_Country_Reference__c> crList = new List<L_PR_Country_Reference__c>();
        L_PR_Country_Reference__c cr1 = new L_PR_Country_Reference__c();
        cr1.Name ='UNITED STATES OF AMERICA';
        cr1.L_PR_Portfolio__c = 'North America';
        cr1.L_PR_Country_Alias__c = 'UNITED STATES OF AMERICA;United States of America (the); USA; America';
        crList.add(cr1);
        L_PR_Country_Reference__c cr2 = new L_PR_Country_Reference__c();
        cr2.Name ='UNITED KINGDOM';
        cr2.L_PR_Portfolio__c = 'Europe';
        cr2.L_PR_Country_Alias__c = 'UNITED KINGDOM';
        crList.add(cr2);
        L_PR_Country_Reference__c cr3 = new L_PR_Country_Reference__c();
        cr3.Name ='UNITED ARAB EMIRATES';
        cr3.L_PR_Portfolio__c = 'Middle East';
        cr3.L_PR_Country_Alias__c = 'UNITED ARAB EMIRATES';
        crList.add(cr3);
        L_PR_Country_Reference__c cr4 = new L_PR_Country_Reference__c();
        cr4.Name ='UZBEKISTAN';
        cr4.L_PR_Portfolio__c = 'Middle East';
        cr4.L_PR_Country_Alias__c = 'UZBEKISTAN';
        crList.add(cr4);
        Insert crList;

        List<Account> accList = new List<Account>();
        accList.add(TestUtility.newEmptyExternalAccount('testAccount1'));
        accList.add(TestUtility.newEmptyExternalAccount('testAccount2'));
        accList.add(TestUtility.newEmptyExternalAccount('testAccount3'));
        insert accList;
    }

    @isTest 
    public static void countryAliasMatchingOneValue(){

        Test.startTest();
        List<Account> accountList = new List<Account>();
        accountList = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account];
        accountList[0].ShippingCountry = 'USA';
        update accountList[0];
        List<Account> accountListUpdated = new List<Account>();
        accountListUpdated = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account where name = 'testAccount1'];
        system.assertEquals('North America', accountListUpdated[0].L_PR_Portfolio__c);
        Test.stopTest();
    }

    @isTest 
    public static void countryAliasMatchingMultipleValues(){

        Test.startTest();
        List<Account> accountList = new List<Account>();
        accountList = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account];
        accountList[0].ShippingCountry = 'UNITED';
        update accountList[0];
        accountList[1].ShippingCountry = 'UsA';
        update accountList[1];
        accountList[2].ShippingCountry = 'USA';
        update accountList[2];
        List<Account> accountListUpdated = new List<Account>();
        accountListUpdated = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account];
        system.assertEquals(null, accountListUpdated[0].L_PR_Portfolio__c);
        system.assertEquals('North America', accountListUpdated[1].L_PR_Portfolio__c);
        system.assertEquals('North America', accountListUpdated[2].L_PR_Portfolio__c);
        Test.stopTest();
    }

    @isTest 
    public static void countryAliasMatchingNull(){

        Test.startTest();
        List<Account> accountList = new List<Account>();
        accountList = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account];
        accountList[0].ShippingCountry = 'ABC';
        update accountList[0];
        List<Account> accountListUpdated = new List<Account>();
        accountListUpdated = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account where name = 'testAccount1'];
        system.assertEquals(null, accountListUpdated[0].L_PR_Portfolio__c);
        Test.stopTest();
    }

    @isTest 
    public static void countryAliasMatchingException(){

        Test.startTest();
        List<Account> accountList = new List<Account>();
        accountList = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account];
        accountList[0].ShippingCountry = 'ABC';
        update accountList[0];
        List<Account> accountListUpdated = new List<Account>();
        accountListUpdated = [SELECT id, Name, L_PR_Portfolio__c, ShippingCountry FROM Account where name = 'testAccount1'];
        system.assertEquals(null, accountListUpdated[0].L_PR_Portfolio__c);
        Test.stopTest();
    }

}