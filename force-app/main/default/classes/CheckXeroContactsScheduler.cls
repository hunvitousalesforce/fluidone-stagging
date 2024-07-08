global class CheckXeroContactsScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      CheckXeroContactsBatch batchable = new CheckXeroContactsBatch(); 
      Database.executeBatch(batchable,50);
   }
}