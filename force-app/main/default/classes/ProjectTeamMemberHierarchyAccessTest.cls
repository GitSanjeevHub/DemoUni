@isTest
public class ProjectTeamMemberHierarchyAccessTest {
	private static Map<Integer, String> numberName = new Map<Integer, String>{1=>'One', 2=>'Two', 3=>'Three', 4=>'Four', 
                                                                              5=>'Five', 6=>'Six', 7=>'Seven', 8=>'Eight', 
                                                                              9=>'Nine', 10=>'Ten', 11=>'Eleven', 12=>'Twelve'};
	private static Map<String, Integer> nameNumber = new Map<String, Integer>{'One'=>1, 'Two'=>2, 'Three'=>3, 'Four'=>4, 
                                                                              'Five'=>5, 'Six'=>6, 'Seven'=>7, 'Eight'=>8, 
                                                                              'Nine'=>9, 'Ten'=>10, 'Eleven'=>11, 'Twelve'=>12};

                                                                                  
	private static string rowCausePP = Schema.Project_Proposal__Share.rowCause.Project_Proposal_Hierarchy_User__c;
	private static string rowCauseC = Schema.Contract__Share.rowCause.Project_Proposal_Hierarchy_User__c;
                                                                                  
	private Static Map<Integer, User> researcherUsers = new Map<Integer, User>();
    private static Project_Proposal__c projProposalRec;
    private Static Project_Team_Member__c projTeamMember1;
    private Static Project_Team_Member__c projTeamMember2;
    private static Contract__c contractRec;

    @TestSetup
    static void setup() {
        //Test.startTest();
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        
        
    	ContactTriggerHandler.runResearchPersonnelSharing = false;
        ContactTriggerHandler.runLeadAccountCleanup = false;
        ContactTriggerHandler.runBudget = false;
        ContactTriggerHandler.createLeadAccount = false;
        //GrantACRHierarchyAccess.doChain = false;
        ProjectProposalHandler.executeInTest = false;
        
        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community Login User'];

        //Create Account
        Map<integer, Account> accounts = new Map<integer, Account>();
        Account a = TestUtility.newEmptyLTUAccount(System.Label.Top_Org_Name_LaTrobe);
        a.I_RS_SAP_Customer_Number__c = '0000000000';
        //insert a;
        Database.insert(a, dml);
        String SAPNumber;
        for (Integer i = 1; i <6; i++) {
            SAPNumber = '000000000' + i;
            Account acct = TestUtility.newEmptyLTUAccount('Account' + i);
            acct.ParentId = a.Id;
            acct.I_RS_SAP_Customer_Number__c = SAPNumber;
            
            accounts.put(i,acct);
        }
        //insert accounts.values();
        Database.insert(accounts.values(), dml);
        for(Account acc555: accounts.values()){
	        
            
        }
        
        accounts.get(1).ParentId = a.Id;
        accounts.get(1).IsPartner = True;
        accounts.get(2).ParentId = accounts.get(1).Id;
        accounts.get(2).IsPartner = True;
        accounts.get(3).ParentId = accounts.get(1).Id;
        accounts.get(3).IsPartner = True;
        accounts.get(4).ParentId = accounts.get(3).Id;
        accounts.get(4).IsPartner = True;
        accounts.get(5).ParentId = accounts.get(3).Id;
        accounts.get(5).IsPartner = True;
        //update accounts.Values();
        Database.update(accounts.values(), dml);
        
        set<Id> acrContacts = new set<Id>();
        set<Id> acrAccounts = new set<Id>();
        Map<Integer, Contact> researcherContacts = new Map<Integer, Contact>();
        Contact researcherContact;
        for (integer i = 1; i<12; i++) {
            researcherContact = new Contact(FirstName = numberName.get(i), LastName = 'Researcher', email = numberName.get(i)+'@researcher.test.com.au');
            switch on i {
                when 1, 2 { researcherContact.AccountId = accounts.get(1).Id; acrAccounts.add(accounts.get(1).Id);}
                when 3, 4 { researcherContact.AccountId = accounts.get(2).Id;acrAccounts.add(accounts.get(2).Id);}
                when 5, 6 { researcherContact.AccountId = accounts.get(3).Id;acrAccounts.add(accounts.get(3).Id);}
                when 7, 8, 9 { researcherContact.AccountId = accounts.get(4).Id;acrAccounts.add(accounts.get(4).Id);}
                when 10, 11 { researcherContact.AccountId = accounts.get(5).Id;acrAccounts.add(accounts.get(5).Id);}
            }
           
            researcherContacts.put(i, researcherContact);
        }
        

        Database.insert(researcherContacts.values(), dml);
        for (Contact c: researcherContacts.values()) {
        	acrContacts.add(c.Id);  
            
        }
        
        User researcherUser;
        for (integer i = 1; i<12; i++) {
            researcherUser = new User(Alias = numberName.get(i), Email=numberName.get(i)+'@researcher.test.com.au', 
                                      EmailEncodingKey='UTF-8', LastName='Researcher', LanguageLocaleKey='en_US', 
                                      LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = researcherContacts.get(i).Id,
                                      TimeZoneSidKey='Australia/Sydney', UserName=numberName.get(i)+'@researcher.test.com.au');
            researcherUsers.put(i, researcherUser);
        }
        insert researcherUsers.values();
        
        for (Contact c: researcherContacts.values()) {
			c.I_RS_Related_User__c = researcherUsers.get(nameNumber.get(c.FirstName)).Id;            
        }
        //update researcherContacts.values();
        Database.update(researcherContacts.values(), dml);
        
     

        List<AccountContactRelation> acrList = [SELECT Id, AccountId, ContactId, I_RS_Grant_Project_Proposal_Access__c FROM AccountContactRelation WHERE IsActive = True];
        for (AccountContactRelation acr : acrList) {
            if ((acrContacts.contains(acr.ContactId)) && (acrAccounts.contains(acr.AccountId))) {
                acr.I_RS_Grant_Project_Proposal_Access__c = True;
            }
        }
         

        //update acrList;
        upsert acrList;
        
        projProposalRec = new Project_Proposal__c();
        projProposalRec.Name = 'Sample Project Proposal';
        projProposalRec.RecordTypeId = Schema.SObjectType.Project_Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        projProposalRec.I_RS_Peer_Review_Status__c = 'Exempt';
        projProposalRec.I_RS_Status__c = 'Successful';
        projProposalRec.I_RS_Theme__c = 'No theme alignment';
        projProposalRec.I_RS_Submission_Date__c = System.today();
        projProposalRec.I_RS_Project_Type__c = 'Grant';
        projProposalRec.I_RS_Project_Start_Date__c = System.today() - 10;
        projProposalRec.I_RS_Project_End_Date__c = System.today() + 10;
        projProposalRec.I_RS_IP_Position__c = 'Owned by La Trobe';
        projProposalRec.I_RS_Administring_Organisation__c=accounts.get(4).Id;
        projProposalRec.I_RS_Proposal_Submission_Date__c = System.today();
		insert projProposalRec;
        
        Account extOrgAcc = TestUtility.newEmptyAccount('test ExtOrg1','I_RS_External_Organisation');
        Insert extOrgAcc;
        contractRec = new Contract__c();
        contractRec.Name = 'Sample Contract';
        contractRec.I_RS_Organisation__c = extOrgAcc.Id;
        contractRec.I_RS_Project_Proposal__c = projProposalRec.Id;
        insert contractRec;
		
        List<Project_Team_Member__c> projTeamMembers = new List<Project_Team_Member__c>();
        projTeamMember1 = new Project_Team_Member__c();
        projTeamMember1.I_RS_Project_Proposal__c = projProposalRec.Id;
        //projTeamMember1.Name = researcherContacts.get(8).FirstName;
        projTeamMember1.I_RS_Project_Team_Member__c = researcherContacts.get(8).Id;        
        projTeamMember1.I_RS_Team_Member_User__c = researcherUsers.get(8).Id;
        projTeamMember1.I_RS_Active__c = True;
        projTeamMember1.I_RS_Status__c = 'Accepted';
        projTeamMember1.I_RS_Invitation_Status__c = 'Accepted';
        projTeamMembers.add(projTeamMember1);
        //insert projTeamMember1;
        

        projTeamMember2 = new Project_Team_Member__c();
        projTeamMember2.I_RS_Project_Proposal__c = projProposalRec.Id;
        //projTeamMember2.Name = researcherContacts.get(4).FirstName;
        projTeamMember2.I_RS_Project_Team_Member__c = researcherContacts.get(4).Id;        
        projTeamMember2.I_RS_Team_Member_User__c = researcherUsers.get(4).Id;
        projTeamMember2.I_RS_Active__c = False;
        projTeamMember2.I_RS_Status__c = 'Accepted';
        projTeamMember2.I_RS_Invitation_Status__c = '';
         projTeamMembers.add(projTeamMember2);
        //insert projTeamMember2;
        insert projTeamMembers;        
        //Test.stopTest();

    }
    
    @isTest
    public static void validateHierarchySharing() {
        Test.startTest();

        //private Static Map<Integer, User> researcherUsers = new Map<Integer, User>();
        Map<Id, User> UserIdMap = new Map<Id, User>();
        for (User usr: [Select Alias, Email, FirstName, LastName, ProfileId, ContactId, UserName FROM User]) {
            if (nameNumber.containsKey(usr.Alias)) {
                researcherUsers.put(nameNumber.get(usr.Alias), usr);
                UserIdMap.put(usr.Id, usr);
            }
        }
        projProposalRec = [SELECT Id, Name, RecordTypeId, I_RS_Peer_Review_Status__c, I_RS_Status__c FROM Project_Proposal__c WHERE Name = 'Sample Project Proposal' LIMIT 1];
        contractRec = [Select Id, Name, I_RS_Project_proposal__c FROM Contract__c WHERE I_RS_Project_proposal__c = :projProposalRec.Id LIMIT 1];


		
        List<Id> ptmIDs = new List<Id>();
        List<Project_Team_Member__c> ptmRecList = [Select Id, I_RS_Project_Proposal__c, I_RS_Team_Member_User__c, I_RS_Active__c, I_RS_Status__c, I_RS_Invitation_Status__c FROM Project_Team_Member__c WHERE I_RS_Project_proposal__c = :projProposalRec.Id];
        for (Project_Team_Member__c ptm: ptmRecList) {
		
            if (UserIdMap.get(ptm.I_RS_Team_Member_User__c).alias == 'Four'){
           		ptmIDs.add(ptm.Id);
            }
            if (UserIdMap.get(ptm.I_RS_Team_Member_User__c).alias == 'Eight'){
           		ptmIDs.add(ptm.Id);
            }
        }
        
        validateProposalHierarchyShare(new List<Id> {projProposalRec.Id}, True, False);
        validateContractHierarchyShare(new List<Id> {contractRec.Id}, True, False);
                
        contractRec.I_RS_Project_Proposal__c = null;
        update contractRec;
        validateContractHierarchyShare(new List<Id> {contractRec.Id}, False, False);

        contractRec.I_RS_Project_Proposal__c = projProposalRec.Id;
        update contractRec;
        validateContractHierarchyShare(new List<Id> {contractRec.Id}, True, False);
        
        delete contractRec;
        validateContractHierarchyShare(new List<Id> {contractRec.Id}, False, False);

        delete ptmRecList;
        validateProposalHierarchyShare(new List<Id> {projProposalRec.Id}, False, False);
        
        Test.stopTest();
    }
    
    @isTest
    public static void validatePTMUpdate() {
        Test.startTest();

        //private Static Map<Integer, User> researcherUsers = new Map<Integer, User>();
        Map<Id, User> UserIdMap = new Map<Id, User>();
        for (User usr: [Select Alias, Email, FirstName, LastName, ProfileId, ContactId, UserName FROM User]) {
            if (nameNumber.containsKey(usr.Alias)) {
                researcherUsers.put(nameNumber.get(usr.Alias), usr);
                UserIdMap.put(usr.Id, usr);
            }
        }
        projProposalRec = [SELECT Id, Name, RecordTypeId, I_RS_Peer_Review_Status__c, I_RS_Status__c FROM Project_Proposal__c WHERE Name = 'Sample Project Proposal' LIMIT 1];
        contractRec = [Select Id, Name FROM Contract__c WHERE I_RS_Project_proposal__c = :projProposalRec.Id LIMIT 1];


		
        List<Id> ptmIDs = new List<Id>();
        Project_Team_Member__c ptm2;
        List<Project_Team_Member__c> ptmRecList = [Select Id, I_RS_Project_Proposal__c, I_RS_Team_Member_User__c, I_RS_Active__c, I_RS_Status__c, I_RS_Invitation_Status__c FROM Project_Team_Member__c WHERE I_RS_Project_proposal__c = :projProposalRec.Id];
        for (Project_Team_Member__c ptm: ptmRecList) {
			
            if (UserIdMap.get(ptm.I_RS_Team_Member_User__c).alias == 'Four'){
				
           		ptmIDs.add(ptm.Id);
                ptm2 = ptm;
            }
            if (UserIdMap.get(ptm.I_RS_Team_Member_User__c).alias == 'Eight'){
				
           		ptmIDs.add(ptm.Id);
            }
        }
        
        ptm2.I_RS_Active__c = True;
        update ptm2;
        
        validateProposalHierarchyShare(new List<Id> {projProposalRec.Id}, True, True);
        validateContractHierarchyShare(new List<Id> {contractRec.Id}, True, True);
        Test.stopTest();
    }
    
    private static void validateProposalHierarchyShare(List<Id> PPIds, boolean firstTM, boolean secondTM ) {
         //Test.startTest();
    	Map <Id, Project_Proposal__Share> ppShareMap = new Map <Id, Project_Proposal__Share>();  

        for (Project_Proposal__Share pps: [SELECT UserOrGroupId, RowCause FROM Project_Proposal__Share WHERE (ParentId IN : PPIds) AND (RowCause = :rowCausePP)] ) {
            ppShareMap.put(pps.UserOrGroupId, pps);    
        }  
	

        if (firstTM) {
			System.assert(ppShareMap.get(researcherUsers.get(7).Id) != null, 'Project_Proposal__Share user 7 Failed');
			System.assert(ppShareMap.get(researcherUsers.get(5).Id) != null, 'Project_Proposal__Share user 5 Failed');
        } else {
			System.assert(ppShareMap.get(researcherUsers.get(7).Id) == null, 'Project_Proposal__Share user 7 Failed');
			System.assert(ppShareMap.get(researcherUsers.get(5).Id) == null, 'Project_Proposal__Share user 5 Failed');
        }
        
        if (secondTM) {
			System.assert(ppShareMap.get(researcherUsers.get(3).Id) != null, 'Project_Proposal__Share user 3 Failed');
        } else {
			System.assert(ppShareMap.get(researcherUsers.get(3).Id) == null, 'Project_Proposal__Share user 3 Failed');
        }
        
        if ((firstTM) || (secondTM)) {
			System.assert(ppShareMap.get(researcherUsers.get(1).Id) != null, 'Project_Proposal__Share user 1 Failed');
        } else {
			System.assert(ppShareMap.get(researcherUsers.get(1).Id) == null, 'Project_Proposal__Share user 1 Failed');
        }
        //Test.stopTest();
    }
 

    
    private static void validateContractHierarchyShare(List<Id> cIds, boolean firstTM, boolean secondTM ) {
        //Test.startTest();
    	Map <Id, Contract__Share> ppShareMap = new Map <Id, Contract__Share>();  
        for (Contract__Share c: [SELECT UserOrGroupId, RowCause FROM Contract__Share WHERE (ParentId IN : cIds) AND (RowCause = :rowCauseC)] ) {
            ppShareMap.put(c.UserOrGroupId, c);    
        }  
		

        if (firstTM) {
			System.assert(ppShareMap.get(researcherUsers.get(7).Id) != null, 'Contract__Share user 7 Failed');
			System.assert(ppShareMap.get(researcherUsers.get(5).Id) != null, 'Contract__Share user 5 Failed');
        } else {
			System.assert(ppShareMap.get(researcherUsers.get(7).Id) == null, 'Contract__Share user 7 Failed');
			System.assert(ppShareMap.get(researcherUsers.get(5).Id) == null, 'Contract__Share user 5 Failed');
        }
        
        if (secondTM) {
			System.assert(ppShareMap.get(researcherUsers.get(3).Id) != null, 'Contract__Share user 3 Failed');
        } else {
			System.assert(ppShareMap.get(researcherUsers.get(3).Id) == null, 'Contract__Share user 3 Failed');
        }
        
        if ((firstTM) || (secondTM)) {
			System.assert(ppShareMap.get(researcherUsers.get(1).Id) != null, 'Contract__Share user 1 Failed');
        } else {
			System.assert(ppShareMap.get(researcherUsers.get(1).Id) == null, 'Contract__Share user 1 Failed');
        }
        //Test.stopTest();
    }
        
    @isTest
    public static void disableGrantToUser(){
        //private Static Map<Integer, User> researcherUsers = new Map<Integer, User>();
        Test.startTest();
        Map<Id, User> UserIdMap = new Map<Id, User>();
        for (User usr: [Select Alias, Email, FirstName, LastName, ProfileId, ContactId, UserName FROM User]) {
            if (nameNumber.containsKey(usr.Alias)) {
                researcherUsers.put(nameNumber.get(usr.Alias), usr);
                UserIdMap.put(usr.Id, usr);
            }
        }

        Contact c5 = [SELECT Id FROM Contact WHERE FirstName = 'Five' Limit 1];
        
        AccountContactRelation acr5 = [SELECT Id, I_RS_Grant_Project_Proposal_Access__c FROM AccountContactRelation WHERE ContactId = :c5.Id AND  Account.Name = 'Account3' LIMIT 1];
       
        acr5.I_RS_Grant_Project_Proposal_Access__c = False;
        update acr5;
        Test.stopTest(); 
      
        

        projProposalRec = [SELECT Id, Name, RecordTypeId, I_RS_Peer_Review_Status__c, I_RS_Status__c FROM Project_Proposal__c WHERE Name = 'Sample Project Proposal' LIMIT 1];
        
        Map <Id, Project_Proposal__Share> ppShareMap = new Map <Id, Project_Proposal__Share>();  
        
        for (Project_Proposal__Share pp: [SELECT UserOrGroupId, RowCause FROM Project_Proposal__Share WHERE (ParentId = :projProposalRec.Id) AND (RowCause = :rowCausePP)] ) {
            ppShareMap.put(pp.UserOrGroupId, pp);    
        }  
		

        System.assert(ppShareMap.get(researcherUsers.get(1).Id) != null, 'disableGrantToUser user 1 Failed');
        System.assert(ppShareMap.get(researcherUsers.get(3).Id) == null, 'disableGrantToUser user 3 Failed');
        System.assert(ppShareMap.get(researcherUsers.get(5).Id) == null, 'disableGrantToUser user 5 Failed');
        System.assert(ppShareMap.get(researcherUsers.get(7).Id) != null, 'disableGrantToUser user 7 Failed');
 
        
    }

 
    @isTest
    public static void disableUser() {
        
        Test.startTest();
        List<Id> cIds = new List<Id>();
		Contact c1 = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE FirstName = :numberName.get(1) LIMIT 1];
        cIds.Add(c1.Id);
		ClearContactRelatedUser.ClearContactRelatedUser(cIds);
        Test.stopTest();        
        
        
        c1 = [SELECT Id, Name, I_RS_Related_User__c FROM Contact WHERE FirstName = :numberName.get(1) LIMIT 1];
       
        System.assert(c1.I_RS_Related_User__c == null, 'Related user test 2 Failed');

    }
    
}