public without sharing class GraduateResearchExaminationHelper {
    private static String EDIT_ACCESS = 'Edit';
    private static String READ_ACCESS = 'Read';
    
    public static void calculateAccessForAffectedThesis(Map<Id, Graduate_Research_Examination__c> newGREMap, Map<Id, Graduate_Research_Examination__c> oldGREMap){
        //insert
        if (oldGREMap == null) {
            createShareRecordsForThesis(newGREMap);
        }   

        //update
        if ((oldGREMap != null) && (newGREMap != null)){
            updateShareRecordsForThesis(newGREMap, oldGREMap);
        }
    }
    
    public static void createShareRecordsForThesis(Map<Id, Graduate_Research_Examination__c> newGREMap){
        List<Graduate_Research_Examination__share> gre_shares = new List<Graduate_Research_Examination__share>();
        Id studentUserId;
        Id psUserId;
        Id asUserId;
        Id dgrUserId;
        Id dgrsUserId;
        Id dgsUserId;
        Id dgssUserId;
        for (Graduate_Research_Examination__c gre : newGREMap.values()) {
            studentUserId = GlobalUtility.getIdValueOf(gre.I_RS_Student_User__c);
            psUserId = GlobalUtility.getIdValueOf(gre.I_RS_PS_User__c);
            asUserId = GlobalUtility.getIdValueOf(gre.I_RS_AS_User__c);
            dgrUserId = GlobalUtility.getIdValueOf(gre.I_RS_DGR_User__c);
            dgrsUserId = GlobalUtility.getIdValueOf(gre.I_RS_SDGR_User__c);
            dgsUserId = GlobalUtility.getIdValueOf(gre.I_RS_BGR_User__c);
            dgssUserId = GlobalUtility.getIdValueOf(gre.I_RS_SBGR_User__c);
            
            //Create Student Share
            if (studentUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = studentUserId,
                    AccessLevel = EDIT_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.Student__c
                ));
            }

            //Create Principle Supervisor Share
            if (psUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = psUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.Principal_Supervisor__c
                ));
                
            }
            //Create Alternate Supervisor Share
            if (asUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = asUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.Alternate_Supervisor__c
                ));
            }

            //Create DGR Share
            if (dgrUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = dgrUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.DGR__c
                ));
            }

            //Create DGR Substitute Share
            if (dgrsUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = dgrsUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.SDGR__c
                ));
            }

            //Create DGS Share
            if (dgsUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = dgsUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.DGS__c
                ));
            }

            //Create DGS Substitute Share
            if (dgssUserId != null){                 
                gre_shares.add(new Graduate_Research_Examination__share(
                	ParentId = gre.Id, UserOrGroupId = dgssUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Graduate_Research_Examination__share.rowCause.SDGS__c
                ));
            }
        }
        
        //insert all the share records created in the FOR Loop
        Database.insert(gre_shares, false);
    }
    
    private static void populate_GRE_CURD_List(List<Graduate_Research_Examination__share> gre_shares_insert,
                                              List<Graduate_Research_Examination__share> gre_shares_delete,
                                              Graduate_Research_Examination__share greShare, Graduate_Research_Examination__c gre,
                                              Id newId, Id oldId, String rowCause, String accessLevel) {
            if (newId != null) {
                if (oldId == null){
                    //insert sharing record
                    gre_shares_insert.add(new Graduate_Research_Examination__share(
                        ParentId = gre.Id, UserOrGroupId = newId,
                        AccessLevel = accessLevel, RowCause = rowCause
                    ));
                    
                } else if (newId != oldId) {
                    //update(delete old and insert new) sharing record
                    if ((oldId != null) && ((greShare != null))) {
                    	gre_shares_delete.add(greShare);
                    }
                    gre_shares_insert.add(new Graduate_Research_Examination__share(
                        ParentId = gre.Id, UserOrGroupId = newId,
                        AccessLevel = accessLevel, RowCause = rowCause
                    ));
                }    
            } else {
                if ((oldId != null) && ((greShare != null))){
                    //delete sharing record
                    gre_shares_delete.add(greShare);
                }
            }
    }
    
    private static void updateShareRecordsForThesis(Map<Id, Graduate_Research_Examination__c> newGREMap, Map<Id, Graduate_Research_Examination__c> oldGREMap){
        List<Graduate_Research_Examination__share> gre_shares_insert = new List<Graduate_Research_Examination__share>();
        List<Graduate_Research_Examination__share> gre_shares_delete = new List<Graduate_Research_Examination__share>();
        
        Map<String, Graduate_Research_Examination__share> currentGreShares = new Map<String, Graduate_Research_Examination__share>();
        
        //Get all the existing share records
        String keystr;//combination of GRE record and rowcause
        for (Graduate_Research_Examination__share greShare: [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Graduate_Research_Examination__share WHERE ParentId IN :newGREMap.keyset()]){
            keystr = greShare.ParentId + greShare.RowCause;
            currentGreShares.put(keyStr, greShare);
        }
        
        Id newstudentUserId;
        Id newpsUserId;
        Id newasUserId;
        Id newdgrUserId;
        Id newdgrsUserId;
        Id newdgsUserId;
        Id newdgssUserId;
        Id newsdgrApproverUserId;

        Id oldstudentUserId;
        Id oldpsUserId;
        Id oldasUserId;
        Id olddgrUserId;
        Id olddgrsUserId;
        Id olddgsUserId;
        Id olddgssUserId;
        Id oldsdgrApproverUserId;
        List<Id> aoeAffectingGRE = new List<Id>();
        List<Id> eoAffectingGRE = new List<Id>();
        //now loop through individual gre record
        for (Graduate_Research_Examination__c gre: newGREMap.values()){
            newstudentUserId = GlobalUtility.getIdValueOf(gre.I_RS_Student_User__c);
            newpsUserId = GlobalUtility.getIdValueOf(gre.I_RS_PS_User__c);
            newasUserId = GlobalUtility.getIdValueOf(gre.I_RS_AS_User__c);
            newdgrUserId = GlobalUtility.getIdValueOf(gre.I_RS_DGR_User__c);
            newdgrsUserId = GlobalUtility.getIdValueOf(gre.I_RS_SDGR_User__c);
            newdgsUserId = GlobalUtility.getIdValueOf(gre.I_RS_BGR_User__c);
            newdgssUserId = GlobalUtility.getIdValueOf(gre.I_RS_SBGR_User__c);
        	newsdgrApproverUserId = GlobalUtility.getIdValueOf(gre.I_RS_SDGR_Approver_User_Id__c);

            oldstudentUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_Student_User__c);
            oldpsUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_PS_User__c);
            oldasUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_AS_User__c);
            olddgrUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_DGR_User__c);
            olddgrsUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_SDGR_User__c);
            olddgsUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_BGR_User__c);
            olddgssUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_SBGR_User__c);
        	oldsdgrApproverUserId = GlobalUtility.getIdValueOf(oldGREMap.get(gre.Id).I_RS_SDGR_Approver_User_Id__c);
            //let's look at student
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.Student__c), gre, 
                                   newstudentUserId, oldstudentUserId, Schema.Graduate_Research_Examination__share.rowCause.Student__c, EDIT_ACCESS);

            //let's look at Principal Supervisor
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.Principal_Supervisor__c), gre, 
                                   newpsUserId, oldpsUserId, Schema.Graduate_Research_Examination__share.rowCause.Principal_Supervisor__c, READ_ACCESS);

            //let's look at Alternate Supervisor
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.Alternate_Supervisor__c), gre, 
                                   newasUserId, oldpsUserId, Schema.Graduate_Research_Examination__share.rowCause.Alternate_Supervisor__c, READ_ACCESS);

            //let's look at DGR
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.DGR__c), gre, 
                                   newdgrUserId, olddgrUserId, Schema.Graduate_Research_Examination__share.rowCause.DGR__c, READ_ACCESS);

            //let's look at SDGR
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.SDGR__c), gre, 
                                   newdgrsUserId, olddgrsUserId, Schema.Graduate_Research_Examination__share.rowCause.SDGR__c, READ_ACCESS);

            //let's look at BGS
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.DGS__c), gre, 
                                   newdgsUserId, olddgsUserId, Schema.Graduate_Research_Examination__share.rowCause.DGS__c, READ_ACCESS);

            //let's look at SBGS
            populate_GRE_CURD_List(gre_shares_insert, gre_shares_delete, 
                                   currentGreShares.get(gre.Id + Schema.Graduate_Research_Examination__share.rowCause.SDGS__c), gre, 
                                   newdgssUserId, olddgssUserId, Schema.Graduate_Research_Examination__share.rowCause.SDGS__c, READ_ACCESS);
            
            if ((newpsUserId != oldpsUserId) || (newasUserId != oldasUserId) || 
                (newdgrUserId != olddgrUserId) || (newdgrsUserId != olddgrsUserId)|| (newdgsUserId != olddgsUserId) || (newdgssUserId != olddgssUserId)) {
            	aoeAffectingGRE.add(gre.Id);    
            }
            
            if (newsdgrApproverUserId != oldsdgrApproverUserId){
            	eoAffectingGRE.add(gre.Id);
            }
            
        }
        
        if (gre_shares_delete.size() > 0) {
         	Database.delete(gre_shares_delete, false);
        }
        if (gre_shares_insert.size() > 0) {
            Database.insert(gre_shares_insert, false);
        }

        if (aoeAffectingGRE.size() > 0 ){
        	calculateAffectedAOEs(aoeAffectingGRE);    
        }

        if (eoAffectingGRE.size() > 0 ){
        	calculateAffectedEOs(eoAffectingGRE);    
        }
    }
    
    private static void calculateAffectedAOEs(List<Id> aoeAffectingGRE){
        Set<Id> deleteIds = new Set<Id>();
        deleteIds.addAll(aoeAffectingGRE);
        deleteChildRecordSharesOfThesis(deleteIds);
        
        List<Appointment_of_Examiner__c> affectedAOEs = new List<Appointment_of_Examiner__c>();
        for (Appointment_of_Examiner__c aoe: [SELECT Id, I_RS_PS_User__c, I_RS_AS_User__c, I_RS_DGR_User__c, I_RS_SDGR_User__c, I_RS_BGR_User__c, I_RS_SBGR_User__c FROM Appointment_of_Examiner__c WHERE I_RS_Graduate_Research_Examination__c IN :aoeAffectingGRE]) {
       		affectedAOEs.add(aoe);
        }
        if (affectedAOEs.size() > 0) {
            AppointmentOfExaminerHelper.claculateNewAOEShare(affectedAOEs);
        }
    }   

    private static void calculateAffectedEOs(List<Id> eoAffectingGRE){
        Set<Id> deleteIds = new Set<Id>();
        deleteIds.addAll(eoAffectingGRE);
        deleteChildRecordSharesOfThesis(deleteIds);
        
        /*List<Examination_Outcome__c> affectedEOs = new List<Examination_Outcome__c>();
        for (Examination_Outcome__c eo: [SELECT Id, I_RS_SDGR_Approver_User__c FROM Examination_Outcome__c WHERE I_RS_Graduate_Research_Examination__c IN :eoAffectingGRE]) {
       		affectedEOs.add(eo);
        }
        if (affectedEOs.size() > 0) {
            ExaminationOutcomeHelper.claculateNewEOShare(affectedEOs);
        }*/
    }   
    
    public static void deleteChildRecordSharesOfThesis(set<Id> oldGREIds) {
        // Delete share records of AOE
    	set<Id> affectedAOEs = new Set<Id>();
        for (Appointment_of_Examiner__c aoe: [SELECT Id FROM Appointment_of_Examiner__c WHERE I_RS_Graduate_Research_Examination__c IN :oldGREIds]) {
       		affectedAOEs.add(aoe.Id);
        }
        
        if (affectedAOEs .size() > 0) {
            List<Appointment_of_Examiner__share> aorShares = new List<Appointment_of_Examiner__share>();
            for (Appointment_of_Examiner__share aoes: [SELECT Id FROM Appointment_of_Examiner__share WHERE ParentId IN :affectedAOEs]){
            	aorShares.add(aoes);    
            }
            if (aorShares.size() > 0 ) {
                Database.delete(aorShares, false);
            }
        }
        
    }
    
}