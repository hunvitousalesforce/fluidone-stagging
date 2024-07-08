global class ProcessOppLineItemOnUpsertBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        ProcessOppLineItemOnUpsertBatch batchable = new ProcessOppLineItemOnUpsertBatch(); 
       Database.executeBatch(batchable,50);
    }
 }