/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_Student_Course__c Trigger Helper
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Rahul Kumar
* @version        1.0
* @created        2021-03-23
* Description     LTU360-1314 Create alumini affiliation based on student course enrolment "Stage and Status"
* @Modified by Vanita Walia on 06/04/2022 - update the code to resolve defect LTU360-1448 
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class I_ST_Student_CourseTriggerHelper {
    
    public static List<Apex_Debug_Log__c> errorLogs = new List<Apex_Debug_Log__c>();
    
    public static void createAlumni(List<I_ST_Student_Course__c> StudentCourselist){
        //variable initialization
    	set<ID> studentIdSet =new set<ID>(); //set of contacts related to student courses
        set<Id> affSet = new Set<Id>();
        List<I_RM_Affiliation__c> newAlumni = new List<I_RM_Affiliation__c>();
    
        Id alumniRecordId = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get('I_RM_Alumni').getrecordTypeId(); 
      	
      //fetch the contact Ids & affiliation Ids from studentCourse list and add it to respective sets
       for(I_ST_Student_Course__c course : StudentCourselist){
       		studentIdSet.add(course.I_ST_Student__c);
            affSet.add(course.I_RM_Affiliation__c);
      }
        
        
      // Check if the contact has any active alumni
        List<I_RM_Affiliation__c> availableAff =[select ID from I_RM_Affiliation__c where I_RM_Contact__c IN:studentIdSet AND I_RM_Role__c = 'Alumni' AND I_RM_Status__c = 'Active'];
      
        if(availableAff.isEmpty()){      	
          	for(I_RM_Affiliation__c studentAff : [select ID, I_RM_Contact__c, I_RM_Email__c, I_RM_Mobile_Phone__c, I_RM_Phone__c, I_RM_Other_Phone__c, I_RM_Street__c, I_RM_Suburb__c,
                                                  	  I_RM_State__c, I_RM_Postcode__c, I_RM_Country__c, I_RM_Mailing_Street__c, I_RM_Mailing_Suburb__c, I_RM_Mailing_State__c,
                                               		  I_RM_Mailing_Postcode__c, I_RM_Mailing_Country__c 
                                               		  from I_RM_Affiliation__c where I_RM_Contact__c IN: studentIdSet AND Id IN:affSet]){
				
                  //create new alumni affiliation with details from student affiliation
                  I_RM_Affiliation__c alumniAff = new I_RM_Affiliation__c();
                  alumniAff.RecordTypeId = alumniRecordId;
                  alumniAff.I_RM_Contact__c = studentAff.I_RM_Contact__c;
                  alumniAff.I_RM_Role__c = 'Alumni';
                  alumniAff.I_RM_StartDate__c = system.today();
                  alumniAff.I_RM_Status__c = 'Active';
                  alumniAff.I_RM_Email__c = studentAff.I_RM_Email__c;
                  alumniAff.I_RM_Mobile_Phone__c = studentAff.I_RM_Mobile_Phone__c;
                  alumniAff.I_RM_Phone__c = studentAff.I_RM_Phone__c;
                  alumniAff.I_RM_Other_Phone__c = studentAff.I_RM_Other_Phone__c;
                  alumniAff.I_RM_Street__c = studentAff.I_RM_Street__c;
                  alumniAff.I_RM_Suburb__c = studentAff.I_RM_Suburb__c;
                  alumniAff.I_RM_State__c = studentAff.I_RM_State__c;
                  alumniAff.I_RM_Postcode__c = studentAff.I_RM_Postcode__c;
                  alumniAff.I_RM_Country__c = studentAff.I_RM_Country__c;
                  alumniAff.I_RM_Mailing_Street__c = studentAff.I_RM_Mailing_Street__c;
                  alumniAff.I_RM_Mailing_Suburb__c = studentAff.I_RM_Mailing_Suburb__c;
                  alumniAff.I_RM_Mailing_State__c = studentAff.I_RM_Mailing_State__c;
                  alumniAff.I_RM_Mailing_Postcode__c = studentAff.I_RM_Mailing_Postcode__c;
                  alumniAff.I_RM_Mailing_Country__c = studentAff.I_RM_Mailing_Country__c;
                  alumniAff.I_RM_Data_Source__c = 'Salesforce'; 
              newAlumni.add(alumniAff);
          }
      }
        // Insert the alumni affiliation records and if any dml error comes add it to errorlogs
                if(newAlumni.size() >0 && schema.SObjectType.I_RM_Affiliation__c.isAccessible() && schema.SObjectType.I_RM_Affiliation__c.isCreateable()){                    
                	I_ST_Student_CourseTriggerHandler.hasFired = True; // Set hasFired to True to avoid recursion               	
                	List<Database.saveResult> saveResults = Database.Insert(newAlumni, false);
                   
                    errorLogs.addAll(GlobalUtility.constructErrorLogsForDMLErrors(saveResults, newAlumni, 'I_ST_Student_CourseTriggerHelper', 'createAlumni'));
                    insert errorLogs;  
        			errorLogs.clear();
        		}
  }
}