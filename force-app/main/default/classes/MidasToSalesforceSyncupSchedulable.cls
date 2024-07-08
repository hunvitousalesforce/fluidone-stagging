/*
 Script to Schedule job
System.schedule('Midas To Salesforce Sync Job', '0 0 * * * ?', new MidasToSalesforceSyncupSchedulable());

 */

global class MidasToSalesforceSyncupSchedulable implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext SC) {
        System.enqueueJob(new MidasToSalesforceSyncQueueable());
    }
}