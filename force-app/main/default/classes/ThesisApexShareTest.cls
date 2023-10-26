@isTest
public class ThesisApexShareTest {
	@testSetup
    static void setup() {
        AccountContactRelationHandler.runHierarchySharing = false;
        AccountContactRelationHandler.runPositionHistory = false;
        ContactTriggerHandler.runHierarchySharing = false;
	    ContactTriggerHandler.runProjectTeamMemberSharing = false;

        List<Contact> updateList = new List<Contact>();
        Profile researcherProfile = [SELECT Id FROM Profile WHERE Name='LTU Partner Community Login User'  LIMIT 1];
        
        //Create Account
        Account tstAccount = new Account(Name = 'La Trobe University',
        I_RS_Part_of_La_Trobe__c = true,
        I_RS_SAP_Customer_Number__c = '1234567890');
        insert tstAccount;
        tstAccount.IsPartner = True;
        update tstAccount;
        
        Contact StudentContact = new Contact(FirstName = 'Student', LastName = 'Reseracher', email = 'Student@test.edu.com');
        StudentContact.AccountId = tstAccount.Id;
        insert StudentContact;
        User StudentUser = new User(Alias = 'student', Email=StudentContact.Email, 
            EmailEncodingKey='UTF-8', LastName=StudentContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = StudentContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=StudentContact.Email);
        Insert StudentUser;
        StudentContact.I_RS_Related_User__c = StudentUser.Id;
        updateList.add(StudentContact);
        
        Contact PrincipalSupervisorContact = new Contact(FirstName = 'Principal', LastName = 'Supervisor', email = 'PrincipalSupervisor@test.edu.com');
        PrincipalSupervisorContact.AccountId = tstAccount.Id;
        insert PrincipalSupervisorContact;
        User PrincipalSupervisorUser = new User(Alias = 'PS', Email=PrincipalSupervisorContact.Email, 
            EmailEncodingKey='UTF-8', LastName=PrincipalSupervisorContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = PrincipalSupervisorContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=PrincipalSupervisorContact.Email);
        Insert PrincipalSupervisorUser;
        PrincipalSupervisorContact.I_RS_Related_User__c = PrincipalSupervisorUser.Id;
        updateList.add(PrincipalSupervisorContact);
        
        Contact AlternateSupervisorContact = new Contact(FirstName = 'Alternate', LastName = 'Supervisor', email = 'AlternateSupervisor@test.edu.com');
        AlternateSupervisorContact.AccountId = tstAccount.Id;
        insert AlternateSupervisorContact;
        User AlternateSupervisorUser = new User(Alias = 'As', Email=AlternateSupervisorContact.Email, 
            EmailEncodingKey='UTF-8', LastName=AlternateSupervisorContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = AlternateSupervisorContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=AlternateSupervisorContact.Email);
        Insert AlternateSupervisorUser;
        AlternateSupervisorContact.I_RS_Related_User__c = AlternateSupervisorUser.Id;
        updateList.add(AlternateSupervisorContact);
        
        Contact DGRContact = new Contact(FirstName = 'DGR', LastName = 'DGR', email = 'DGR@test.edu.com');
        DGRContact.AccountId = tstAccount.Id;
        insert DGRContact;
       User DGRUser = new User(Alias = 'dgr', Email=DGRContact.Email, 
            EmailEncodingKey='UTF-8', LastName=DGRContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = DGRContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=DGRContact.Email);
        Insert DGRUser;
        DGRContact.I_RS_Related_User__c = DGRUser.Id;
        updateList.add(DGRContact);
      
        Contact SubDGRContact = new Contact(FirstName = 'SubDGR', LastName = 'DGR', email = 'SubDGR@test.edu.com');
        SubDGRContact.AccountId = tstAccount.Id;
        insert SubDGRContact;
        User SubDGRUser = new User(Alias = 'sdgr', Email=SubDGRContact.Email, 
            EmailEncodingKey='UTF-8', LastName=SubDGRContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = SubDGRContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=SubDGRContact.Email);
        Insert SubDGRUser;
        SubDGRContact.I_RS_Related_User__c = SubDGRUser.Id;
        updateList.add(SubDGRContact);
        
        Contact BGRContact = new Contact(FirstName = 'BGR', LastName = 'BGR', email = 'BGR@test.edu.com');
        BGRContact.AccountId = tstAccount.Id;
        insert BGRContact;
        User BGRUser = new User(Alias = 'bgr', Email=BGRContact.Email, 
            EmailEncodingKey='UTF-8', LastName=BGRContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = BGRContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=BGRContact.Email);
        Insert BGRUser;
        BGRContact.I_RS_Related_User__c = BGRUser.Id;
        updateList.add(BGRContact);
      
        Contact SubBGRContact = new Contact(FirstName = 'SubBGR', LastName = 'BGR', email = 'SubBGR@test.edu.com');
        SubBGRContact.AccountId = tstAccount.Id;
        insert SubBGRContact;
        User SubBGRUser = new User(Alias = 'bbgr', Email=SubBGRContact.Email, 
            EmailEncodingKey='UTF-8', LastName=SubBGRContact.LastName, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = researcherProfile.Id, ContactId = SubBGRContact.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=SubBGRContact.Email);
        Insert SubBGRUser;
        SubBGRContact.I_RS_Related_User__c = SubBGRUser.Id;
        updateList.add(SubBGRContact);
        
        update updateList;
               
        
    }
    
    @isTest
    public static void testInsertSharing(){
        Test.startTest();
        Contact StudentContact;
        Contact PrincipalSupervisorContact;
        Contact AlternateSupervisorContact;
        Contact DGRContact;
        Contact SubDGRContact;
        Contact BGRContact;
        Contact SubBGRContact;
		
        for (Contact c:[SELECT Id, FirstName, I_RS_Related_User__c FROM Contact]) {
            if (c.FirstName == 'Student') {
        		StudentContact = c;
            } else if (c.FirstName == 'Principal') {
        		PrincipalSupervisorContact = c;
            } else if (c.FirstName == 'Alternate') {
        		AlternateSupervisorContact = c;
            } else if (c.FirstName == 'DGR') {
        		DGRContact = c;
            } else if (c.FirstName == 'SubDGR') {
        		SubDGRContact = c;
            } else if (c.FirstName == 'BGR') {
        		BGRContact = c;
            } else if (c.FirstName == 'SubBGR') {
        		SubBGRContact = c;
            }
        }

        Graduate_Research_Examination__c gre = new Graduate_Research_Examination__c();
        gre.OwnerId = StudentContact.I_RS_Related_User__c;
        gre.I_RS_Student__c = StudentContact.Id;
        gre.I_RS_Principal_Supervisor__c = PrincipalSupervisorContact.Id;
        gre.I_RS_Alternate_Supervisor__c = AlternateSupervisorContact.Id;
        gre.I_RS_Director_of_Graduate_Research__c = DGRContact.Id;
        gre.I_RS_Substitute_DirectorGraduateResearch__c = SubDGRContact.Id;
        gre.I_RS_Substitute_Board_Graduate_Research__c = BGRContact.Id;
        gre.I_RS_Board_of_Graduate_Research__c = SubBGRContact.Id;
        gre.I_RS_Supervisor_Approver__c = AlternateSupervisorContact.Id;
        gre.I_RS_SDGR_Approver__c = SubDGRContact.Id;
        gre.I_RS_BGR_Approver__c = SubBGRContact.Id;
        insert gre;
        Appointment_of_Examiner__c aoe = new Appointment_of_Examiner__c(I_RS_Graduate_Research_Examination__c = gre.id);
        aoe.OwnerId = PrincipalSupervisorContact.I_RS_Related_User__c;
        aoe.I_RS_Potential_conflicts_of_interest_1st__c='Yes';
        aoe.I_RS_Potential_conflicts_of_interest_2nd__c='Yes';
        aoe.I_RS_Potential_conflicts_of_interest_3rd__c='Yes';
        insert aoe;
        
        List<String> greRowCauses = new List<String>();
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Alternate_Supervisor__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.DGR__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.DGS__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Principal_Supervisor__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.SDGR__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.SDGS__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Student__c);
        
        List<Graduate_Research_Examination__share> greShares = [SELECT Id FROM Graduate_Research_Examination__share WHERE RowCause IN :greRowCauses ];
        List<Appointment_of_Examiner__share> aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        
        System.assertEquals(7, greShares.size(), 'GRE shares mismatch');
        System.assertEquals(6, aoeShares.size(), 'AOE shares mismatch');
        Test.stopTest();
        
    }
    
    @isTest
    public static void testUpdateSharing(){
        Test.startTest();
        Contact StudentContact;
        Contact PrincipalSupervisorContact;
        Contact AlternateSupervisorContact;
        Contact DGRContact;
        Contact SubDGRContact;
        Contact BGRContact;
        Contact SubBGRContact;
		
        for (Contact c:[SELECT Id, FirstName, I_RS_Related_User__c FROM Contact]) {
            if (c.FirstName == 'Student') {
        		StudentContact = c;
            } else if (c.FirstName == 'Principal') {
        		PrincipalSupervisorContact = c;
            } else if (c.FirstName == 'Alternate') {
        		AlternateSupervisorContact = c;
            } else if (c.FirstName == 'DGR') {
        		DGRContact = c;
            } else if (c.FirstName == 'SubDGR') {
        		SubDGRContact = c;
            } else if (c.FirstName == 'BGR') {
        		BGRContact = c;
            } else if (c.FirstName == 'SubBGR') {
        		SubBGRContact = c;
            }
        }

        Graduate_Research_Examination__c gre = new Graduate_Research_Examination__c();
        gre.OwnerId = StudentContact.I_RS_Related_User__c;
        gre.I_RS_Supervisor_Approver__c = AlternateSupervisorContact.Id;
        gre.I_RS_SDGR_Approver__c = SubDGRContact.Id;
        gre.I_RS_BGR_Approver__c = SubBGRContact.Id;
        insert gre;
        
        Appointment_of_Examiner__c aoe = new Appointment_of_Examiner__c();
        aoe.I_RS_Graduate_Research_Examination__c = gre.id;
        aoe.OwnerId = PrincipalSupervisorContact.I_RS_Related_User__c;
        aoe.I_RS_Potential_conflicts_of_interest_1st__c='Yes';
        aoe.I_RS_Potential_conflicts_of_interest_2nd__c='Yes';
        aoe.I_RS_Potential_conflicts_of_interest_3rd__c='Yes';
        insert aoe;

        gre.I_RS_Student__c = StudentContact.Id;
        gre.I_RS_Principal_Supervisor__c = PrincipalSupervisorContact.Id;
        gre.I_RS_Alternate_Supervisor__c = AlternateSupervisorContact.Id;
        gre.I_RS_Director_of_Graduate_Research__c = DGRContact.Id;
        gre.I_RS_Substitute_DirectorGraduateResearch__c = SubDGRContact.Id;
        gre.I_RS_Substitute_Board_Graduate_Research__c = BGRContact.Id;
        gre.I_RS_Board_of_Graduate_Research__c = SubBGRContact.Id;
        gre.I_RS_Supervisor_Approver__c = AlternateSupervisorContact.Id;
        gre.I_RS_SDGR_Approver__c = SubDGRContact.Id;
        gre.I_RS_BGR_Approver__c = SubBGRContact.Id;
        update gre;
        
        aoe.I_RS_Graduate_Research_Examination__c = gre.id;
        update aoe;
        
               
        List<String> greRowCauses = new List<String>();
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Alternate_Supervisor__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.DGR__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.DGS__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Principal_Supervisor__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.SDGR__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.SDGS__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Student__c);
        
        List<Graduate_Research_Examination__share> greShares = [SELECT Id FROM Graduate_Research_Examination__share WHERE RowCause IN :greRowCauses ];
        List<Appointment_of_Examiner__share> aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        
        System.assertEquals(7, greShares.size(), 'GRE shares mismatch');
        System.assertEquals(6, aoeShares.size(), 'AOE shares mismatch');
        
        //clear one field
        gre.I_RS_Board_of_Graduate_Research__c = null;
        gre.I_RS_SDGR_Approver__c = null;
        update gre;

        greShares = [SELECT Id FROM Graduate_Research_Examination__share WHERE RowCause IN :greRowCauses ];
        aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        
        System.assertEquals(6, greShares.size(), 'GRE shares mismatch');
        System.assertEquals(5, aoeShares.size(), 'GRE shares mismatch');
        
        Test.stopTest();

        /*gre.I_RS_SDGR_Approver__c = SubDGRContact.Id;
        update gre;

        aoe.I_RS_Graduate_Research_Examination__c = null;
        update aoe;
        aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        System.assertEquals(0, aoeShares.size(), 'AOE shares mismatch');
        
        delete gre;
        delete aoe;
        greShares = [SELECT Id FROM Graduate_Research_Examination__share WHERE RowCause IN :greRowCauses ];
        aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        
        System.assertEquals(0, greShares.size(), 'GRE shares mismatch');
        System.assertEquals(0, aoeShares.size(), 'GRE shares mismatch');*/
        
    }
    @isTest
    public static void testUpdateSharing2(){
        Test.startTest();
        Contact StudentContact;
        Contact PrincipalSupervisorContact;
        Contact AlternateSupervisorContact;
        Contact DGRContact;
        Contact SubDGRContact;
        Contact BGRContact;
        Contact SubBGRContact;
		
        for (Contact c:[SELECT Id, FirstName, I_RS_Related_User__c FROM Contact]) {
            if (c.FirstName == 'Student') {
        		StudentContact = c;
            } else if (c.FirstName == 'Principal') {
        		PrincipalSupervisorContact = c;
            } else if (c.FirstName == 'Alternate') {
        		AlternateSupervisorContact = c;
            } else if (c.FirstName == 'DGR') {
        		DGRContact = c;
            } else if (c.FirstName == 'SubDGR') {
        		SubDGRContact = c;
            } else if (c.FirstName == 'BGR') {
        		BGRContact = c;
            } else if (c.FirstName == 'SubBGR') {
        		SubBGRContact = c;
            }
        }

        Graduate_Research_Examination__c gre = new Graduate_Research_Examination__c();
        gre.OwnerId = StudentContact.I_RS_Related_User__c;
        gre.I_RS_Student__c = StudentContact.Id;
        gre.I_RS_Principal_Supervisor__c = PrincipalSupervisorContact.Id;
        gre.I_RS_Alternate_Supervisor__c = AlternateSupervisorContact.Id;
        gre.I_RS_Director_of_Graduate_Research__c = DGRContact.Id;
        gre.I_RS_Substitute_DirectorGraduateResearch__c = SubDGRContact.Id;
        gre.I_RS_Substitute_Board_Graduate_Research__c = BGRContact.Id;
        gre.I_RS_Board_of_Graduate_Research__c = SubBGRContact.Id;
        gre.I_RS_Supervisor_Approver__c = AlternateSupervisorContact.Id;
        gre.I_RS_SDGR_Approver__c = SubDGRContact.Id;
        gre.I_RS_BGR_Approver__c = SubBGRContact.Id;
        insert gre;
        
        Appointment_of_Examiner__c aoe = new Appointment_of_Examiner__c();
        aoe.I_RS_Graduate_Research_Examination__c = gre.id;
        aoe.OwnerId = PrincipalSupervisorContact.I_RS_Related_User__c;
        aoe.I_RS_Graduate_Research_Examination__c = gre.id;
        aoe.I_RS_Potential_conflicts_of_interest_1st__c='Yes';
        aoe.I_RS_Potential_conflicts_of_interest_2nd__c='Yes';
        aoe.I_RS_Potential_conflicts_of_interest_3rd__c='Yes';
        insert aoe;

        List<String> greRowCauses = new List<String>();
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Alternate_Supervisor__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.DGR__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.DGS__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Principal_Supervisor__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.SDGR__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.SDGS__c);
        greRowCauses.add(Schema.Graduate_Research_Examination__share.rowCause.Student__c);
        
        aoe.I_RS_Graduate_Research_Examination__c = null;
        update aoe;
        List<Appointment_of_Examiner__share> aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        System.assertEquals(0, aoeShares.size(), 'AOE shares mismatch');
        
        delete gre;
        delete aoe;
        List<Graduate_Research_Examination__share> greShares = [SELECT Id FROM Graduate_Research_Examination__share WHERE RowCause IN :greRowCauses ];
        aoeShares = [SELECT Id FROM Appointment_of_Examiner__share WHERE RowCause IN :greRowCauses ];
        
        System.assertEquals(0, greShares.size(), 'GRE shares mismatch');
        System.assertEquals(0, aoeShares.size(), 'GRE shares mismatch');
        Test.stopTest();
        
    }
}