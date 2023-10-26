/**
 * Created by burnside on 2019-04-24.
 */

trigger TaskTrigger on Task (before insert, before update, after insert, after update, before delete) {

    if (!GlobalUtility.isTriggerDisabled('Task')){

        TaskTriggerHandler.execute();
        
    }

}