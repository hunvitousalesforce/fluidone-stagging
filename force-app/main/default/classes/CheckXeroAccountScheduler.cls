global class CheckXeroAccountScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      CheckXeroAccountBatch batchable = new CheckXeroAccountBatch(); 
      Database.executeBatch(batchable,50);
   }
}