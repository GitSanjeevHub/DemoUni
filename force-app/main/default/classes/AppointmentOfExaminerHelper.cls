public class AppointmentOfExaminerHelper {
    private static String EDIT_ACCESS = 'Edit';
    private static String READ_ACCESS = 'Read';
    public static void calculateSharingForAOE(Map<Id, Appointment_of_Examiner__c> newAOEMap, Map<Id, Appointment_of_Examiner__c> oldAOEMap){
        List<Appointment_of_Examiner__c> newAOEs = new List<Appointment_of_Examiner__c>();
        List<Id> oldAOEIds = new List<Id>();
        for (Appointment_of_Examiner__c aoeNew: newAOEMap.values()){
            if (aoeNew.I_RS_Graduate_Research_Examination__c != null) {
            	newAOEs.add(aoeNew);    
            }
            if ((oldAOEMap != null) && (oldAOEMap.get(aoeNew.Id).I_RS_Graduate_Research_Examination__c != null)){
                oldAOEIds.add(aoeNew.Id);
            }
        } 
        
        //delete the old sharings of AOE records
        deleteAOEShares(oldAOEIds);
        
        //Insert new AOE shares
        claculateNewAOEShare(newAOEs);
    }
    
    public static void deleteAOEShares(List<Id> aoeIds){
        List<Appointment_of_Examiner__share> oldAOEShares = new List<Appointment_of_Examiner__share>();
        for (Appointment_of_Examiner__share aoeShare: [SELECT Id FROM Appointment_of_Examiner__share WHERE ParentId IN :aoeIds]){
            oldAOEShares.add(aoeShare);
		}
        if(oldAOEShares.size() > 0) {
        	Database.delete(oldAOEShares, false);
        }
    }
    
    public static void claculateNewAOEShare(List<Appointment_of_Examiner__c> newAOEs){
        Id psUserId;
        Id asUserId;
        Id dgrUserId;
        Id dgrsUserId;
        Id dgsUserId;
        Id dgssUserId;
        List<Appointment_of_Examiner__share> aoeShares = new List<Appointment_of_Examiner__share>();
        for (Appointment_of_Examiner__c aoe: newAOEs) {
            psUserId = GlobalUtility.getIdValueOf(aoe.I_RS_PS_User__c);
            asUserId = GlobalUtility.getIdValueOf(aoe.I_RS_AS_User__c);
            dgrUserId = GlobalUtility.getIdValueOf(aoe.I_RS_DGR_User__c);
            dgrsUserId = GlobalUtility.getIdValueOf(aoe.I_RS_SDGR_User__c);
            dgsUserId = GlobalUtility.getIdValueOf(aoe.I_RS_BGR_User__c);
            dgssUserId = GlobalUtility.getIdValueOf(aoe.I_RS_SBGR_User__c);            
            //Create Principle Supervisor Share
            if (psUserId != null){                 
                aoeShares.add(new Appointment_of_Examiner__share(
                	ParentId = aoe.Id, UserOrGroupId = psUserId,
                    AccessLevel = EDIT_ACCESS, RowCause = Schema.Appointment_of_Examiner__share.rowCause.Principal_Supervisor__c
                ));
            }
            
            //Create Alternate Supervisor Share
            if (asUserId != null){                 
                aoeShares.add(new Appointment_of_Examiner__share(
                	ParentId = aoe.Id, UserOrGroupId = asUserId,
                    AccessLevel = EDIT_ACCESS, RowCause = Schema.Appointment_of_Examiner__share.rowCause.Alternate_Supervisor__c
                ));
            }

            //Create DGR Share
            if (dgrUserId != null){                 
                aoeShares.add(new Appointment_of_Examiner__share(
                	ParentId = aoe.Id, UserOrGroupId = dgrUserId,
                    AccessLevel = EDIT_ACCESS, RowCause = Schema.Appointment_of_Examiner__share.rowCause.DGR__c
                ));
            }

            //Create DGR Substitute Share
            if (dgrsUserId != null){                 
                aoeShares.add(new Appointment_of_Examiner__share(
                	ParentId = aoe.Id, UserOrGroupId = dgrsUserId,
                    AccessLevel = EDIT_ACCESS, RowCause = Schema.Appointment_of_Examiner__share.rowCause.SDGR__c
                ));
            }

            //Create DGS Share
            if (dgsUserId != null){                 
                aoeShares.add(new Appointment_of_Examiner__share(
                	ParentId = aoe.Id, UserOrGroupId = dgsUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Appointment_of_Examiner__share.rowCause.DGS__c
                ));
            }

            //Create DGS Substitute Share
            if (dgssUserId != null){                 
                aoeShares.add(new Appointment_of_Examiner__share(
                	ParentId = aoe.Id, UserOrGroupId = dgssUserId,
                    AccessLevel = READ_ACCESS, RowCause = Schema.Appointment_of_Examiner__share.rowCause.SDGS__c
                ));
            }
        }
        if (aoeShares.size() > 0) {
            Database.insert(aoeShares, false);
        }
    }
}