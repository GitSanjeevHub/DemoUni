/**
 * Created by burnside on 2019-05-02.
 */


public without sharing class ResearchOppTeamMemberRecordAccess {

        public List<Research_Opportunity_Team_Member__c> teamMembersBeforeDML = new List<Research_Opportunity_Team_Member__c>();
        public List<Research_Opportunity_Team_Member__c> teamMembersAfterDML = new List<Research_Opportunity_Team_Member__c>();

        public String DMLOperation;


        public void run(){

                System.debug('ResearchOppTeamMemberRecordAccess.run: '+DMLOperation);
                
                Set<Id> fundingOpportunityIds = getFundingOppIDsForAllTeamMembersInvolved();

                List<Research_Opportunity__Share> allFundingOpportunitySharesList = 
                        getAllShareRecordsInDbForTheseFundingOpps_List(fundingOpportunityIds);

                 Map<String, Research_Opportunity__Share> allFundingOpportunitySharesMap = 
                        getAllShareRecordsInDbForTheseFundingOpps_Map(allFundingOpportunitySharesList);
                
                Map<String, Research_Opportunity__share> validSharesBasedOnCurrentDB = new Map<String, Research_Opportunity__share>();
                Set<Research_Opportunity__share> sharesToInsert = new Set<Research_Opportunity__share>();
                Set<Research_Opportunity__share> sharesToDelete = new Set<Research_Opportunity__share>();


                //Handle upsert
                if (DMLOperation == 'INSERT' || DMLOperation == 'UPDATE' || DMLOperation == 'REFRESH'){

                        for(Research_Opportunity_Team_Member__c teamMemberAfterOperation : teamMembersAfterDML){

                                Boolean isValidTeamMember = checkTeamMemberDataIntegrity(teamMemberAfterOperation);
                                
                                if (isValidTeamMember){

                                        String keyToQueryExistingShare = 
                                                createKeyForShareRecord_QueryingByTeamMember(teamMemberAfterOperation);
                                        
                                        Research_Opportunity__share preExistingShare = allFundingOpportunitySharesMap.get(keyToQueryExistingShare);
                                        Boolean preExistingShareFound = preExistingShare != null;
                                        Boolean teamMemberShouldHaveAccessToOpp = teamMemberAfterOperation.I_RS_Status__c == 'Accepted';

                                        System.debug('preExistingShare '+preExistingShare);
                                        System.debug('preExistingShareFound '+preExistingShareFound);
                                        System.debug('teamMemberShouldHaveAccessToOpp '+teamMemberShouldHaveAccessToOpp);

                                        if (teamMemberShouldHaveAccessToOpp){

                                                if (preExistingShareFound){
                                                        
                                                        validSharesBasedOnCurrentDB.put(
                                                                createKeyForShareRecord_SavingToMap(preExistingShare),
                                                                preExistingShare);

                                                }
                                                else {
                                                        Research_Opportunity__share newShare = new 
                                                                Research_Opportunity__share(
                                                                        UserOrGroupId = teamMemberAfterOperation.I_RS_Internal_Team_Member__c,
                                                                        ParentId = teamMemberAfterOperation.I_RS_Research_Opportunity__c,
                                                                        RowCause = Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c,
                                                                        AccessLevel = 'Edit'
                                                                );
                                                        sharesToInsert.add(newShare);

                                                        validSharesBasedOnCurrentDB.put(
                                                                createKeyForShareRecord_SavingToMap(newShare),
                                                                newShare);

                                                }
                                        }
                                        else {

                                                if (preExistingShareFound){
                                                        sharesToDelete.add(preExistingShare);
                                                }
                                                else {
                                                        //Do Nothing
                                                }       

                                        }

                                }

                        }

                        if (!sharesToInsert.isEmpty()){
                                System.debug('sharesToInsert '+sharesToInsert);
                                Database.insert(new List<Research_Opportunity__share>(sharesToInsert), false);
                        }

                        System.debug('Shares to delete in NEW data '+sharesToDelete);

                }
                
                if (DMLOperation == 'UPDATE' || DMLOperation == 'DELETE' || DMLOperation == 'REFRESH'){

                        Boolean previousDataPassedIn = teamMembersBeforeDML != null && !teamMembersBeforeDML.isEmpty();
                        if (previousDataPassedIn){

                                System.debug('Previous data has been passed in - check for deletions');

                                for(Research_Opportunity_Team_Member__c teamMemberBeforeOperation : teamMembersBeforeDML){

                                        Boolean isValidTeamMember = checkTeamMemberDataIntegrity(teamMemberBeforeOperation);
                                        if (isValidTeamMember){
                                        
                                                String keyToQueryExistingShare = 
                                                        createKeyForShareRecord_QueryingByTeamMember(teamMemberBeforeOperation);

                                                Research_Opportunity__Share preExistingShare = allFundingOpportunitySharesMap.get(keyToQueryExistingShare);
                                                
                                                System.debug('teamMemberBeforeOperation '+teamMemberBeforeOperation);
                                                System.debug('keyToQueryExistingShare '+keyToQueryExistingShare);
                                                System.debug('preExistingShare '+preExistingShare);

                                                Boolean preExistingShareFound = preExistingShare != null;
                                                if (preExistingShareFound){
                                                        
                                                        Boolean isValidShare = validSharesBasedOnCurrentDB.get(keyToQueryExistingShare) != null;
                                                        if (isValidShare){
                                                                //Share is valid, so we don't want to touch it
                                                        }
                                                        else {
                                                                sharesToDelete.add(preExistingShare);
                                                        }

                                                }
                                                else {
                                                        //No existing share - so we don't need to do anything right now
                                                }
                                        }
                                }

                                if (!sharesToDelete.isEmpty()){

                                        System.debug('sharesToDelete '+sharesToDelete);
                                        Database.delete(new List<Research_Opportunity__share>(sharesToDelete), false);
                                }

                        }
                }
        }



        Set<Id> getFundingOppIDsForAllTeamMembersInvolved(){

                Set<Id> fundingOpportunityIds = new Set<Id>();

                System.debug('Adding Ids from BEFORE trigger');
                for (Research_Opportunity_Team_Member__c fotm : teamMembersBeforeDML){
                        fundingOpportunityIds.add(fotm.I_RS_Research_Opportunity__c);
                }
                System.debug('Adding Ids from AFTER trigger/operation');
                for (Research_Opportunity_Team_Member__c fotm : teamMembersAfterDML){
                        fundingOpportunityIds.add(fotm.I_RS_Research_Opportunity__c);
                }
                System.debug('fundingOpportunityIds '+fundingOpportunityIds);

                return fundingOpportunityIds;

        }


        List<Research_Opportunity__Share> getAllShareRecordsInDbForTheseFundingOpps_List(Set<Id> fundingOpportunityIds){
                List<Research_Opportunity__Share> allFundingOpportunitySharesList = [
                        select UserOrGroupId, ParentId from Research_Opportunity__Share where ParentId
                        in :fundingOpportunityIds and 
                        RowCause = :Schema.Research_Opportunity__Share.rowCause.Research_Opportunity_Team_Member__c
                ];
                System.debug('allFundingOpportunitySharesList '+allFundingOpportunitySharesList);

                return allFundingOpportunitySharesList;
        }

        Map<String, Research_Opportunity__Share> getAllShareRecordsInDbForTheseFundingOpps_Map(
                List<Research_Opportunity__Share> allFundingOpportunitySharesList){

                Map<String, Research_Opportunity__Share> allFundingOpportunitySharesMap = new Map<String, Research_Opportunity__Share>();
                for (Research_Opportunity__Share fundingOpportunityShare : allFundingOpportunitySharesList){
                        allFundingOpportunitySharesMap.put(
                                createKeyForShareRecord_SavingToMap(fundingOpportunityShare),
                                fundingOpportunityShare
                        );
                }
                System.debug('allFundingOpportunitySharesMap '+allFundingOpportunitySharesMap);

                return allFundingOpportunitySharesMap;
        }

        Boolean checkTeamMemberDataIntegrity(Research_Opportunity_Team_Member__c teamMember){
                Boolean isValidTeamMember = teamMember.I_RS_Internal_Team_Member__c != null;
                System.debug('Evaluating data integrity of Team Member '+teamMember);
                System.debug('Team Member valid? '+isValidTeamMember);
                return isValidTeamMember;
        }


        String createKeyForShareRecord_SavingToMap(Research_Opportunity__Share fundingOpportunityShare){
                String key = fundingOpportunityShare.ParentId + '' + fundingOpportunityShare.UserOrGroupId;
                System.debug('createKeyForShareRecord_SavingToMap '+key);
                return key;
        }

        String createKeyForShareRecord_QueryingByTeamMember(Research_Opportunity_Team_Member__c teamMember){
                
                String key = teamMember.I_RS_Research_Opportunity__c + '' + teamMember.I_RS_Internal_Team_Member__c;
                System.debug('createKeyForShareRecord_QueryingByTeamMember '+key);
                return key;
        }
    
}