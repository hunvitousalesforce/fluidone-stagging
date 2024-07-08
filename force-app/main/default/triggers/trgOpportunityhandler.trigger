trigger trgOpportunityhandler on Opportunity (before insert,before update,after insert,after update,before delete, after delete) {


    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
           System.debug('Trigger is after insert');
            OpportunityTriggerHandler.shareParentLI(Trigger.newMap,Trigger.oldMap);
            OpportunityTriggerHandler.updateparentCount(Trigger.newMap);
        }
        else if(Trigger.isUpdate){
            OpportunityTriggerHandler.shareParentLI(Trigger.newMap,Trigger.oldMap);
            OpportunityTriggerHandler.updateOpportunity(Trigger.newMap,Trigger.oldMap);
            OpportunityProductHandler.handleAfterUpdate(Trigger.newMap,Trigger.oldMap);

            OpportunityTriggerHandler.updateparentCount(Trigger.newMap);
        }

    }else{ // isbefore
        if(Trigger.isDelete){ // delete
            OpportunityTriggerHandler.deleteOpportunity(Trigger.oldMap);
        }

    }
    
    if (Trigger.isbefore) {
        if(Trigger.isdelete){
            OpportunityTriggerHandler.restrictdeleteOpportunity(Trigger.new,Trigger.old);
        }
        
        if(Trigger.isUpdate){
            OpportunityTriggerHandler.restrictChildOpportunity(Trigger.newMap,Trigger.oldMap);
        }

    }
    
}