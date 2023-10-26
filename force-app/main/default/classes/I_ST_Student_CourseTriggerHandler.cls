/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_Student_Course__c Trigger Handler
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Rahul Kumar
* @version        1.0
* @created        2021-03-23
* Description     LTU360-1314 Create alumini affiliation based on student course enrolment "Stage and Status"
* ─────────────────────────────────────────────────────────────────────────────────────────────────
*/
public with sharing class I_ST_Student_CourseTriggerHandler {
    public static Boolean hasFired = false;
     public static List<String> earlyEntryCourses = [SELECT Value__c FROM I_RM_Affiliation_Settings__c WHERE Name =:GlobalConstants.I_RM_Early_Entry_Courses].Value__c.split(',');    
   
  
    public static void execute() {
        List<I_ST_Student_Course__c> studentcourse = new List<I_ST_Student_Course__c>();
         map<Id,I_ST_Student_Course__c> mapOldCourses = (map<Id,I_ST_Student_Course__c>)Trigger.oldMap;
        if (Trigger.isAfter) {
           List<I_ST_Student_Course__c> stdCourse = [SELECT Id,I_ST_CourseAvailability__c,I_ST_Student__c,I_RM_Affiliation__c,I_ST_Course_Admission_Stage_Code__c,I_ST_Course_Admission_Status_Code__c,I_ST_CourseAvailability__r.L_AD_CourseInstance__r.L_AD_CourseParent__r.L_AD_Course_Type_Name__c 
                                                     FROM I_ST_Student_Course__c 
                                                     WHERE id IN: (List<I_ST_Student_Course__c>)trigger.New 
                                                     AND I_ST_CourseAvailability__r.L_AD_CourseInstance__r.L_AD_CourseParent__r.L_AD_Course_Type_Name__c NOT IN :earlyEntryCourses];
           
            if(Trigger.isInsert || Trigger.isUpdate){
                if(!hasFired){                	
                    for(I_ST_Student_Course__c st :stdCourse){ 
                    	if(st.I_ST_Student__c != NULL && st.I_RM_Affiliation__c != Null
                           && (Trigger.isInsert  ||  (Trigger.isUpdate 
                            && (st.I_ST_Course_Admission_Stage_Code__c != mapOldCourses.get(st.Id).I_ST_Course_Admission_Stage_Code__c 
                               || st.I_ST_Course_Admission_Status_Code__c != mapOldCourses.get(st.Id).I_ST_Course_Admission_Status_Code__c)))
                           && st.I_ST_Course_Admission_Stage_Code__c == 'COMP' && st.I_ST_Course_Admission_Status_Code__c== 'PASS'){
                        	studentcourse.add(st);
                    	}
                	}	
                    
                 	if(studentcourse.size() > 0){
              	   		I_ST_Student_CourseTriggerHelper.createAlumni(studentcourse);  
                 	}
                }
            }           
        }
    }
}