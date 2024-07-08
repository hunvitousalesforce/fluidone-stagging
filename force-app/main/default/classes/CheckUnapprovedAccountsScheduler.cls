global class CheckUnapprovedAccountsScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      CheckUnapprovedAccountsBatch batchable = new CheckUnapprovedAccountsBatch(); 
      Database.executeBatch(batchable,50);
   }
}