global class RefreshSellPriceScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      RefreshSellPriceBatch batchable = new RefreshSellPriceBatch(); 
      Database.executeBatch(batchable,50);
   }
}