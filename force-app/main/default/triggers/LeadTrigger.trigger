/*
 * Created Date: 25 Feb 2020
 * Author   Branda
 * Description: Trigger for Lead object
 * History:
 *      - BD-30012020 - FO-193
*/
trigger LeadTrigger on Lead (before insert, before update) {
    
    // FO-193
    if (trigger.isBefore) {
        if (trigger.isInsert) {
            LeadTriggerHandler.populateFirstUTM(trigger.new, null);
        }
        if (trigger.isUpdate) {
            LeadTriggerHandler.populateFirstUTM(trigger.new, trigger.oldMap);
            LeadTriggerHandler.UpdateFirstSuccessfulOrAttemptedCall(trigger.new, trigger.oldMap);
        }
        
    }
   
}