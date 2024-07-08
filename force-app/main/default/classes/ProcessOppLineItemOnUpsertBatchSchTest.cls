@isTest
public with sharing class ProcessOppLineItemOnUpsertBatchSchTest {
    @isTest 
    static void executeTest(){
        SchedulableContext sc = null;
        ProcessOppLineItemOnUpsertBatchScheduler processOppLineItemOnUpsertBatchScheduler = new ProcessOppLineItemOnUpsertBatchScheduler();
        processOppLineItemOnUpsertBatchScheduler.execute(sc);
    }
}