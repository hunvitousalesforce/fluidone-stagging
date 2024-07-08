trigger trgOpportunityProducthandler on OpportunityLineItem (before insert,before update, after insert , after update,before delete, after delete) {

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            /***Moved to ProcessOppLineItemOnUpsertBatch***/
            //OpportunityProductHandler.shareParentLI(Trigger.newMap, Trigger.oldMap);

            //  OpprtunityProductTriggerHandlerClone.OpportunityProductCreation(Trigger.newMap,Trigger.oldMap);
            OpportunityProductHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            /***Moved to ProcessOppLineItemOnUpsertBatch***/
            //OpportunityProductHandler.shareParentLI(Trigger.newMap, Trigger.oldMap);

            // OpprtunityProductTriggerHandlerClone.OpportunityProductCreation(Trigger.newMap,Trigger.oldMap);
            // OpprtunityProductTriggerHandlerClone.OpportunityProductOverlyUserUpdate(Trigger.newMap,Trigger.oldMap);
            OpportunityProductHandler.handleAfterUpdate(Trigger.new);

        }
        
        /*if(Trigger.isUpdate || Trigger.isInsert){
            OpprtunityProductTriggerHandler.overlayOpportunityProductCreation(Trigger.newMap, Trigger.oldMap);
            OpprtunityProductTriggerHandler.shareParentLI(Trigger.newMap, Trigger.oldMap);
        }*/
        else if(Trigger.isDelete){// delete 
            //OpprtunityProductTriggerHandlerClone.deleteParentLI(Trigger.oldMap);
            OpportunityProductHandler.handleAfterDelete(Trigger.old);

        }
    }else{ // isbefore 
        // if(Trigger.isUpdate){
        //     OpprtunityProductTriggerHandler.beforeUpdateParentOppLi(Trigger.newMap);
        // }

    }
    
    if(Trigger.isbefore){
        if(Trigger.isDelete){// delete 
            //OpprtunityProductTriggerHandlerClone.deleteChildLI(Trigger.newMap,Trigger.oldMap);
            OpportunityProductHandler.handleBeforeDelete(Trigger.old);

        }
        if(Trigger.isInsert){// delete 
            //OpprtunityProductTriggerHandlerClone.deleteChildLI(Trigger.newMap,Trigger.oldMap);
            OpportunityProductHandler.handleBeforeInsert(Trigger.new);

        }

        if(Trigger.isUpdate){
            OpportunityProductHandler.handleBeforeUpdate(Trigger.newMap, Trigger.oldMap);

        }
    }

    //new OpportunityProductHandlerClone2().run();
}