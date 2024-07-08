global class GetNeoOrderStatusScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      GetNeoOrderStatusBatch batchable = new GetNeoOrderStatusBatch(); 
      Database.executeBatch(batchable,50);
   }
}