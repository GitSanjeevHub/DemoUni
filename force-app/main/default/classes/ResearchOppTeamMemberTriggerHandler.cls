/**
 * Created by burnside on 2019-05-02.
 */

public with sharing class ResearchOppTeamMemberTriggerHandler {

    public static void execute() {

        System.debug('ResearchOppTeamMemberTriggerHandler.execute');
        System.debug(Trigger.operationType);

        if (Trigger.isBefore) {

            

        }

        else if (Trigger.isAfter) {

            if (Trigger.isInsert) {
                //ResearchOppTeamMemberRecordAccess.handleUpsert(triggerNew, null);

                ResearchOppTeamMemberRecordAccess access = new ResearchOppTeamMemberRecordAccess();
                access.teamMembersAfterDML = Trigger.New;
                access.DMLOperation = 'INSERT';
                access.run();
            }

            else if (Trigger.isUpdate) {
                //ResearchOppTeamMemberRecordAccess.handleUpsert(triggerNew, triggerOldMap);

                ResearchOppTeamMemberRecordAccess access = new ResearchOppTeamMemberRecordAccess();
                access.teamMembersBeforeDML = Trigger.Old;
                access.teamMembersAfterDML = Trigger.New;
                access.DMLOperation = 'UPDATE';
                access.run();
            }


            else if (Trigger.isDelete) {
                ResearchOppTeamMemberRecordAccess access = new ResearchOppTeamMemberRecordAccess();
                access.teamMembersBeforeDML = Trigger.Old;
                access.DMLOperation = 'DELETE';
                access.run();
            }

        }

    }

}