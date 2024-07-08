global class RefreshSellPriceBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT 
                Id, 
                RecurringSell__c,
                OneOffSell__c,
                SBQQ__ListPrice__c, 
                SBQQ__PricebookEntryId__c
            FROM 
                SBQQ__QuoteLine__c  
            WHERE 
                SBQQ__Quote__r.SBQQ__Opportunity2__r.IsWon = false              
        ]);
    }
     
    global void execute(Database.BatchableContext BC, List<SBQQ__QuoteLine__c> scope){
        
        SBQQ.TriggerControl.disable();

        Map<Id,Decimal> priceMap = RefreshSellPriceHelper.getUnitPriceMap();
        
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c ql : scope) { 
            if (ql.OneOffSell__c <> null) {
                ql.OneOffSell__c = priceMap.get(ql.SBQQ__PricebookEntryId__c);                 
            } else if (ql.RecurringSell__c <> null) { 
                ql.RecurringSell__c = priceMap.get(ql.SBQQ__PricebookEntryId__c);                 
            }
            ql.SBQQ__ListPrice__c = priceMap.get(ql.SBQQ__PricebookEntryId__c);
            quoteLinesToUpdate.add(ql);
        }
        
        update quoteLinesToUpdate;
    }
    
    global void finish(Database.BatchableContext BC){
    SBQQ.TriggerControl.enable();
    }
}