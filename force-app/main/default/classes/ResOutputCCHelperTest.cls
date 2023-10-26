@isTest
public class ResOutputCCHelperTest {
    static Database.DMLOptions allowDuplicates = TestUtility.getAllowDuplicatesDMLOption();

    @testSetup 
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE name = 'LTU Partner Community Login User' Limit 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'LTU PRIME' Limit 1];
        
        Account testAcc = TestUtility.newEmptyExternalAccount('Test LTU Account');
        Insert testAcc;
        
        Contact testContact = TestUtility.newContact(testAcc.Id);
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'LTU';
        Database.insert(testContact, allowDuplicates);

        User testCommunityUser = TestUtility.newUser('testCommunityUser', profile.Id, null, testContact.Id);
        insert testCommunityUser;
        
        Contact testContact1 = TestUtility.newContact(testAcc.Id);
        testContact1.FirstName = 'Test Contact1';
        testContact1.LastName = 'LTU';
        Database.insert(testContact1, allowDuplicates);

        User noAuthCommunityUser = new User();
        noAuthCommunityUser.UserRoleId = null;
        noAuthCommunityUser.ProfileId = profile.Id;
        noAuthCommunityUser.contactId = testContact1.Id;
        noAuthCommunityUser.Username = 'noAuthUser' + UserInfo.getOrganizationId() + '@test.com';
        noAuthCommunityUser.Alias = 'noAuthUs';
        noAuthCommunityUser.Email='noAuthUser@test.com';
        noAuthCommunityUser.EmailEncodingKey='UTF-8';
        noAuthCommunityUser.FirstName='noAuth';
        noAuthCommunityUser.LastName='User';
        noAuthCommunityUser.LanguageLocaleKey='en_US';
        noAuthCommunityUser.LocaleSidKey='en_US';
        noAuthCommunityUser.TimeZoneSidKey='America/Chicago';
        insert noAuthCommunityUser;
        
        User testInternalUser = new User();
        //testInternalUser.UserRoleId = internalRole.Id;
        testInternalUser.UserRoleId = null;
        testInternalUser.ProfileId = internalProfile.Id;
        testInternalUser.Username = 'GrantsUser' + UserInfo.getOrganizationId() + '@test.com';
        testInternalUser.Alias = 'GrantsUs';
        testInternalUser.Email='GrantsUser@test.com';
        testInternalUser.EmailEncodingKey='UTF-8';
        testInternalUser.FirstName='Grants';
        testInternalUser.LastName='User';
        testInternalUser.LanguageLocaleKey='en_US';
        testInternalUser.LocaleSidKey='en_US';
        testInternalUser.TimeZoneSidKey='America/Chicago';
        insert testInternalUser;
    }
    
    @isTest
    public static void createRecordWithInternalUser(){
        String userName = 'GrantsUser' + UserInfo.getOrganizationId() + '@test.com';
    	User internalUser = [SELECT Id, Username FROM User WHERE Username = :userName LIMIT 1]; 
        if (internalUser == null) {
            System.assert(false, 'test user doesnot exist');
        }
		
        Contact testContact = [SELECT Id, Name FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        Research_Output__c ro = TestUtility.newResearchOutput('Test RO'); 
        insert ro;

        Authorship_Research_Output_Team_Member__c auth = TestUtility.newAuthorship('Test Author', ro.Id, testContact.Id, 'Author');
		insert auth;
        
        Classification_Master__c testClassficationMaster = TestUtility.newClassificationMaster('TestCls001','2610','Type of Activity (TOA)',true);
        insert testClassficationMaster;
        
        Test.startTest();
        System.runAs(internalUser){
            try {
                Research_Output_Classification_Code__c roCC = new Research_Output_Classification_Code__c();
                roCC.I_RS_Research_Output__c = ro.Id;
                roCC.I_RS_Classification_Master__c =  testClassficationMaster.Id;
                roCC.I_RS_Percentage__c = 100;
                insert roCC;
                System.assert(roCC.Id != null, 'internal user is unable to create RO CC');
            } catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
            	System.assert(false, 'internal user is unable to create RO CC --> exception');    
            }
        }
        
        Test.stopTest();

    }
    
    @isTest
    public static void createRecordWithCommunityUserSuccess(){
        String userName = 'testCommunityUser' + UserInfo.getOrganizationId() + '@test.com';
    	User authUser = [SELECT Id, Username FROM User WHERE Username = :userName LIMIT 1]; 
        if (authUser == null) {
            System.assert(false, 'test user doesnot exist');
        }
		
        Contact testContact = [SELECT Id, Name FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        Research_Output__c ro = TestUtility.newResearchOutput('Test RO'); 
        insert ro;
		
        Research_Output__Share roShare = new Research_Output__Share();
        roShare.ParentId = ro.Id;
        roShare.UserOrGroupId = authUser.Id;
        roShare.AccessLevel = 'Edit';
        roShare.RowCause = Schema.Research_Output__Share.RowCause.Manual;
        insert roShare;
        
        for (Research_Output__Share roS : [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Research_Output__Share WHERE ParentId = :ro.Id]){
        	System.debug('Research output Share: ' + roS);
        }
        System.debug('AuthUser: ' + authUser);
        System.debug('Research output: ' + ro);
        //System.debug('Research output Share: ' + roShare);
        
        Authorship_Research_Output_Team_Member__c auth = TestUtility.newAuthorship('Test Author', ro.Id, testContact.Id, 'Author');
		insert auth;
        
        Classification_Master__c testClassficationMaster = TestUtility.newClassificationMaster('TestCls001','2610','Type of Activity (TOA)',true);
        insert testClassficationMaster;
        
        Test.startTest();
        System.runAs(authUser){
            try {
                Research_Output_Classification_Code__c roCC = new Research_Output_Classification_Code__c();
                roCC.I_RS_Research_Output__c = ro.Id;
                roCC.I_RS_Classification_Master__c =  testClassficationMaster.Id;
                roCC.I_RS_Percentage__c = 100;
                insert roCC;
                System.assert(roCC.id != null, 'Authorship user is unable to create RO CC');
            } catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown = e.getMessage().contains('You do not have permission to create/modify codes for this research Output') ? true : false;
            	System.assert(expectedExceptionThrown, 'Authorship user is unable to create RO CC --> exception');    
            }
        }
        Test.stopTest();
    }
    
    @isTest
    public static void createRecordWithCommunityUserFail(){
        String userName = 'noAuthUser' + UserInfo.getOrganizationId() + '@test.com';
    	User noauthUser = [SELECT Id, Username FROM User WHERE Username = :userName LIMIT 1]; 
        if (noauthUser == null) {
            System.assert(false, 'test user doesnot exist');
        }
		
        Contact testContact = [SELECT Id, Name FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        Research_Output__c ro = TestUtility.newResearchOutput('Test RO'); 
        insert ro;

        Authorship_Research_Output_Team_Member__c auth = TestUtility.newAuthorship('Test Author', ro.Id, testContact.Id, 'Author');
		insert auth;
        
        Classification_Master__c testClassficationMaster = TestUtility.newClassificationMaster('TestCls001','2610','Type of Activity (TOA)',true);
        insert testClassficationMaster;
        
        Test.startTest();
        System.runAs(noauthUser){
            try {
                Research_Output_Classification_Code__c roCC = new Research_Output_Classification_Code__c();
                roCC.I_RS_Research_Output__c = ro.Id;
                roCC.I_RS_Classification_Master__c =  testClassficationMaster.Id;
                roCC.I_RS_Percentage__c = 100;
                insert roCC;
                System.assert(false, 'Authorship user is able to create RO CC');
            } catch (Exception e) {
                System.debug('--> Error Message--> '+e.getMessage());
                Boolean expectedExceptionThrown = e.getMessage().contains('You do not have permission to create/modify codes for this research Output') ? true : false;
            	System.assert(expectedExceptionThrown, 'Wrong exception message while creating RO CC --> exception');
            }
        }
        Test.stopTest();
    }
    
}