/**
 * Created by burnside on 2019-05-03.
 */

public with sharing class GlobalConstants {

    //Contact record type names
  //  public static String CONTACT_RECORD_TYPE_NAME_LTU_STAFF = 'I_RS_La_Trobe_Staff';
 //   public static String CONTACT_RECORD_TYPE_NAME_LTU_STUDENT = 'I_RS_La_Trobe_Student';
   // public static String CONTACT_RECORD_TYPE_NAME_EXTERNAL_CONTACT = 'I_RS_External_Contact';
    
    //set of strings that require Sponsored flag on Affiliation to be set Yes
    public static final List<String> COUNTRYOFCITIZENSHIPSET = ( I_RM_Affiliation_Settings__c.getInstance('I_IL_Sponsored_by_Citizenship') != null )
                                                               ? I_RM_Affiliation_Settings__c.getInstance('I_IL_Sponsored_by_Citizenship').Value__c.split(';')
                                                               : new List<String>();
    //set of strings that require Sponsored flag on Affiliation to be set Yes
    public static final List<String> INTENDEDFUNDINGSRCSET = ( I_RM_Affiliation_Settings__c.getInstance('I_IL_Sponsored_by_Citizenship') != null )
                                                             ? I_RM_Affiliation_Settings__c.getInstance('I_IL_Sponsored_by_Citizenship').I_RM_Status__c.split(';')
                                                             : new List<String>();
    
    //sObject API Names
    public static String AFFILIATION_OBJECT_API_NAME = 'I_RM_Affiliation__c';
    public static String CONTACT_OBJECT_API_NAME = 'Contact';
    public static String CASE_OBJECT_API_NAME = 'Case';
    public static String INTERACTION_OBJECT_API_NAME = 'I_ST_Interaction__c';
    
    
    //Custom Setting Records
    public static String I_RM_AFFILIATIONSCORING ='I_RM_AffiliationScoring';
    public static String I_ST_CONTACTSCORING = 'I_ST_ContactScoring';
    public static String I_ST_CASESCORING = 'I_ST_CaseScoring';
    public static String I_ST_INTERACTIONSCORING = 'I_ST_InteractionScoring';
    public static String I_RM_AFFILIATION_SETTINGS = 'I_RM_Inactive_Status';
    public static String I_RM_INACTIVE_APPLICATION_SETTINGS = 'I_RM_Inactive_Application_Status';
    public static String I_RM_Early_Entry_Courses = 'I_RM_Early_Entry_Courses';
    //IST Contact record type API names
  //  public static String CONTACT_RECORD_TYPE_API_NAME_DOMESTIC_LEAD = 'I_ST_Domestic_Lead';
    
    //IST Case record type API names
    public static String CASE_RECORD_TYPE_API_NAME_ENQUIRY = 'I_ST_Enquiry';
    
    //Case record type names
    public static String CASE_RECORD_TYPE_NAME_ENQUIRY = 'Enquiry';
    public static String CASE_RECORD_TYPE_NAME_INT_ENQUIRY = 'I_IL_LTU_INT_Enquiry';
    
    
    //Affiliation record type names
     public static String AFFILIATION_RECORD_TYPE_NAME_LEAD ='I_RM_Lead'; 
     public static String AFFILIATION_RECORD_TYPE_NAME_APPLICANT = 'I_RM_Applicant';
     public static String AFFILIATION_RECORD_TYPE_NAME_INT_LEAD = 'I_IL_Student_Lead_Int';
    
     //Affiliation record type Ids
     public static Id AFFILIATION_RECORD_TYPE_ID_INT_LEAD = Schema.SObjectType.I_RM_Affiliation__c.getRecordTypeInfosByDeveloperName().get(AFFILIATION_RECORD_TYPE_NAME_INT_LEAD).getRecordTypeId();
    
     //Case Incremental score field namee
    public static String CASE_INCREMENTAL_SCORE_FIELD = 'I_ST_Incremental_Score__c';
    
    //Interaction RecordType API Names
    public static String INTERACTION_RECORD_TYPE_API_NAME_LEAD_INTERACTION = 'I_ST_Lead_Interaction';
    
    //Interaction Incremental score field namee
    public static String INTERACTION_INCREMENTAL_SCORE_FIELD = 'I_ST_Incremental_Score__c';

    //Organisation record type names
    public static String ACCOUNT_RECORD_TYPE_NAME_LTU_ORG_UNIT = 'I_RS_La_Trobe_Organisation_Unit';
    public static String ACCOUNT_RECORD_TYPE_NAME_EXTERNAL_ORG = 'I_RS_External_Organisation';
    public static String ACCOUNT_RECORD_TYPE_NAME_Admin_Account = 'I_ST_Lead_Account';

    //Project Team Member Status Values
    public static String PROJECT_TEAM_MEMBER_STATUS_ACCEPTED = 'Accepted';
    public static String PROJECT_TEAM_MEMBER_STATUS_REJECTED = 'Rejected';
    
    //Project Team Member Role Values 
    public static String PROJECT_TEAM_MEMBER_ROLE_LEAD_CI = 'Lead Chief Investigator';
    
    //Project Proposal Status Values
    public static String PROJECT_PROPOSAL_STATUS_REVIEW_BY_RESEARCH_OFFICE = 'Review by Research Office';
    public static String PROJECT_PROPOSAL_STATUS_APPROVALS = 'Approvals';
    public static String PROJECT_PROPOSAL_STATUS_SUCCESSFUL = 'Successful';
    public static String PROJECT_PROPOSAL_STATUS_UNSUCCESSFUL = 'Unsuccessful';

    //Project Team Member share access constants
    public static String PROJECT_TEAM_MEMBER_SHARING_PROJ_PROP_ACCESS = 'Edit';
    public static String PROJECT_TEAM_MEMBER_SHARING_PROJ_TEAM_MEMBER_ACCESS = 'Read';
    public static String PROJECT_TEAM_MEMBER_SHARING_CONTRACT_ACCESS = 'Read';
    public static String PROJECT_TEAM_MEMBER_SHARING_RELATED_CONTRACT_ACCESS = 'Read';
    public static String PROJECT_TEAM_MEMBER_SHARING_WBS_ACCESS = 'Edit';
    public static String PROJECT_TEAM_MEMBER_SHARING_CLASSIF_CODE_ACCESS = 'Edit';
    public static String PROJECT_TEAM_MEMBER_SHARING_JUNCTION_ACCESS = 'Read';

    //Project Hierarchy share access constants
    public static String PROJECT_HIERARCHY_SHARING_PROJ_PROP_ACCESS = 'Edit';
    public static String PROJECT_HIERARCHY_SHARING_PROJ_TEAM_MEMBER_ACCESS = 'Edit';
    public static String PROJECT_HIERARCHY_SHARING_CONTRACT_ACCESS = 'Edit';
    public static String PROJECT_HIERARCHY_SHARING_RELATED_CONTRACT_ACCESS = 'Edit';
    public static String PROJECT_HIERARCHY_SHARING_WBS_ACCESS = 'Edit';
    public static String PROJECT_HIERARCHY_SHARING_CLASSIF_CODE_ACCESS = 'Edit';
    public static String PROJECT_HIERARCHY_SHARING_JUNCTION_ACCESS = 'Edit';

    //Classification Master Types
    public static string CLASSIFICATION_MASTER_TYPE_FOR = 'Fields of Research (FOR)';
    public static string CLASSIFICATION_MASTER_TYPE_FOR_2008 = 'Fields of Research - 2008 (FOR - 08)';
    public static string CLASSIFICATION_MASTER_TYPE_SEO = 'Socio-Economic Objective (SEO)';
    public static string CLASSIFICATION_MASTER_TYPE_SEO_2008 = 'Socio-economic Objective - 2008 (SEO - 08)';
    public static string CLASSIFICATION_MASTER_TYPE_TOA = 'Type of Activity (TOA)';
    
    //Ethics Team Member share access constants
    public static String ETHICS_TEAM_MEMBER_SHARING_ACCESS = 'Edit';
    
    public static String RES_OPP_TEAM_MEMBER_STATUS_ACCEPTED = 'Accepted';
    public static String RES_OPP_TEAM_MEMBER_STATUS_REJECTED = 'Rejected';

    public static String RES_OPP_TEAM_MEMBER_SHARING_OPP_ACCESS = 'Edit';
    public static String RES_OPP_TEAM_MEMBER_SHARING_OPP_TEAM_MEMBER_ACCESS = 'Edit';
    //public static String RES_OPP_TEAM_MEMBER_SHARING_MILESTONE_ACCESS = 'Edit';
    //public static String RES_OPP_TEAM_MEMBER_SHARING_CLASSIF_CODE_ACCESS = 'Edit';
    
    //Trigger error description
    public static String ADDED_ERROR_ATTACHMENT_UPLOAD_PROECT_IN_REVIEW = 'Project proposal is currently locked down until Research Office has approved. You cannot upload/modify any attachments';
    public static String RESTRICT_DOCUMENT_UPLOAD_BY_RESEARCHER = 'You cannot upload/modify any attachments';
    public static String ADDED_ERROR_LEAD_CI_HAS_VALID_EMAIL_ADDRESS = 'Please ensure the Lead Chief Investigator has a valid email address';
    
    //Profile Names
    public static String PROFILE_NAME_LTU_PARTNER_COMMUNITY_USER = 'LTU Partner Community User';
    public static List<String> COMMUNITYPROFILENAMES = System.Label.Partner_Community_Profile_Label.split(',');

    public static String COMMA = ',';
    
    //Thesis
    public static String THESIS_GRADUATE_RESEARCHER = 'GR';
    public static String THESIS_PRINCIPLE_SUPERVISOR = 'PS';
    public static String THESIS_PRINCIPLE_SUPERVISOR_SUB = 'PSS';
    public static String THESIS_DGR = 'DGR';
    public static String THESIS_DGR_SUB = 'DGRS';
    public static String THESIS_DGS = 'DGS';
    public static String THESIS_DGS_SUB = 'DGSS';

}