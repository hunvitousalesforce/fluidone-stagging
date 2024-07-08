global class AccessDimensionsProductsScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      AccessDimensionsProductsBatch batchable = new AccessDimensionsProductsBatch(); 
      Database.executeBatch(batchable,50);
   }
}