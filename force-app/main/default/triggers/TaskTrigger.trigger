/*
 * Created Date: 26 Dec 2019
 * Author   Mony Nou
 * Description: Trigger for Task object
 * History:
 *      - MN-26122019 - FO-153 
 *      - MN-30012020 - FO-186
*/
trigger TaskTrigger on Task (before insert, before update, after insert, after update) {
    
    //MN-30122019 - Whenever Lead's task is created without Activity_Type__c & Activity_Sub_Type__c => prepopulate it with picklist value "Task"
    if (trigger.isBefore) {
        if (trigger.isInsert) {
            TaskTriggerHandler.initRecord(trigger.new);    
            TaskTriggerHandler.populateUTM(trigger.new, null);
        }
        else if (trigger.isUpdate) {
            TaskTriggerHandler.populateUTM(trigger.new, trigger.oldMap);
            
        }
        
    }
    //MN-30012020
    if (trigger.isAfter) {
        if (trigger.isInsert) {
            TaskTriggerHandler.populateNextClosestActivityToOpportunity(trigger.newMap, null);
        }
        else if(trigger.isUpdate){
            TaskTriggerHandler.populateNextClosestActivityToOpportunity(trigger.newMap, trigger.oldMap);
        }
    }
}