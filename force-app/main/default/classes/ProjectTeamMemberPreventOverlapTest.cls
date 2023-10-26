@isTest
public class ProjectTeamMemberPreventOverlapTest {
    
    public static testmethod void checkAgainstExistingData(){
    
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        insert pp;
        
        //Contact person = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null);
        Contact person = TestUtility.createContact(null);
        insert person;
        
        //First team member
        Project_Team_Member__c existingTeamMember = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
        insert existingTeamMember;
        
        //SECTION 1 - Neither have end dates
        //
        //INVALID - Another PTM with no end date
        try {
            Project_Team_Member__c newTeamMember = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
            newTeamMember.I_RS_Date_Added__c = Date.today();
            insert newTeamMember;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member inserted when it shouldn\'t have');
            
        }
        catch (Exception e){}
        
        //SECTION 2 - One but not both have an end date
        //
        //INVALID - New PTM starts and finishes after existing PTM, but existing PTM has no end date
        //
        try {
            Project_Team_Member__c newTeamMember = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
            newTeamMember.I_RS_Date_Added__c = Date.today()+1;
            newTeamMember.I_RS_Date_Removed__c = Date.today()+2;
            insert newTeamMember;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member inserted when it shouldn\'t have');
            
        }
        catch (Exception e){}
        
        //VALID - New PTM starts and finishes before existing PTM, and there is no overlap
        //
        Project_Team_Member__c validPTM = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
        validPTM.I_RS_Date_Added__c = Date.today()-2;
        validPTM.I_RS_Date_Removed__c = Date.today()-1;
        insert validPTM;
        
        
        
        existingTeamMember.I_RS_Date_Removed__c = Date.today() + 7;
        update existingTeamMember;
        
        //INVALID - Existing PTM has start and end date, but new PTM starts before it with no end date
        try {
            Project_Team_Member__c newTeamMember = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
            newTeamMember.I_RS_Date_Added__c = Date.today()-1;
            insert newTeamMember;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member inserted when it shouldn\'t have');
            
        }
        catch (Exception e){}
        
        
        //SECTION 3 - Both have an end date
        //
        //INVALID - Overlapping end date
        try {
            Project_Team_Member__c newTeamMember = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
            newTeamMember.I_RS_Date_Added__c = Date.today()-1;
            newTeamMember.I_RS_Date_Removed__c = Date.today();
            insert newTeamMember;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member inserted when it shouldn\'t have');
            
        }
        catch (Exception e){}
        
        //INVALID - Overlapping start date
        try {
            Project_Team_Member__c teamMember2 = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
            teamMember2.I_RS_Date_Added__c = Date.today() + 1;
            teamMember2.I_RS_Date_Removed__c = Date.today() + 8;
            insert teamMember2;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member 2 inserted when it shouldn\'t have');
            
        }
        catch (Exception e){}
        
        
        //third team member - this will be invalid due to overlapping end date
        try {
            Project_Team_Member__c teamMember3 = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
            teamMember3.I_RS_Date_Added__c = Date.today() - 1;
			teamMember3.I_RS_Date_Removed__c = Date.today() + 6;
            insert teamMember3;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member 3 inserted when it shouldn\'t have');
            
        }
        catch (Exception e){}
        
        //fourth team member - this will be valid as there is no overlap        
        Project_Team_Member__c teamMember4 = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person.Id);
        teamMember4.I_RS_Date_Added__c = Date.today() + 8;
        teamMember4.I_RS_Date_Removed__c = Date.today() + 15;
        insert teamMember4;
        
        //Fourth team member again - attempt to change start date so there is overlap, this will now be invalid
		try {
	        teamMember4.I_RS_Date_Added__c = Date.today() + 7;
            teamMember4.I_RS_Date_Removed__c = Date.today() + 14;
            update teamMember4;
            
            //Exception should occur before we get to this line
            System.assert(false, 'Team Member 4 updated when it shouldn\'t have');
        }
        catch (Exception e){}
       
        //fifth team member - this will be valid as its a different person
        //Contact person2 = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null);
        Contact person2 = TestUtility.createContact(null);
        insert person2;
        
        Project_Team_Member__c teamMember5 = TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person2.Id);
        teamMember5.I_RS_Date_Added__c = Date.today() - 1;
        teamMember5.I_RS_Date_Removed__c = Date.today() + 6;
        insert teamMember5;
            
        
    }
    
    
    
    public static testmethod void checkWithinSameBatch(){
        
        Project_Proposal__c pp = TestUtility.newProjectProposal();
        insert pp;
        
        //Contact person1 = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null);
        Contact person1 = TestUtility.createContact(null);
        insert person1; 
        
        //Contact person2 = TestUtility.newContact(GlobalConstants.CONTACT_RECORD_TYPE_NAME_LTU_STAFF, null);
        Contact person2 = TestUtility.createContact(null);
        insert person2;
        
        List<Project_Team_Member__c> newPTMs = new List<Project_Team_Member__c>{
            TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person1.Id),
            TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person1.Id),
            TestUtility.newProjectTeamMember(pp.Id, 'Administrator', person2.Id)
        };
		//First PTM lasts for a week
		newPTMs[0].I_RS_Date_Removed__c = Date.today() + 7;
        //Second PTM lasts for a week but is offset by 3 days
        newPTMs[1].I_RS_Date_Added__c = Date.today() + 3;
        newPTMs[1].I_RS_Date_Removed__c = Date.today() + 10;
        
        //Check that addError was thrown
        try {
            insert newPTMs;
            System.assert(false, 'PTM list inserted successfully when it shouldnt have');
        }
        catch (Exception e){}
        
        //Check number output if allOrNothing is false when inserting
        Database.insert(newPTMs, false);
        System.assertequals(1, [SELECT COUNT() FROM Project_Team_Member__c]);
    }

}