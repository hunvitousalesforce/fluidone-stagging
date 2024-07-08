public class PopulateAnnexonQuoteBatch implements Database.Batchable<sObject>, Database.Stateful{
    public PopulateAnnexonQuoteBatch() {

    }

    public Database.QueryLocator start(Database.BatchableContext bc){
                
        String strQuery ='SELECT Id,SBQQ__Quote__c,SBQQ__Product__r.Product_Annex_Reseller__c, SBQQ__Product__r.Product_Annex_Direct__c, SBQQ__Product__r.Parent_Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Parent_Product__c=TRUE';
        return Database.getQueryLocator(strQuery);
    }
    public void execute(Database.BatchableContext BC, List<SBQQ__QuoteLine__c> scope){

        Map<Id,SBQQ__Quote__c> id2Quote = new Map<Id,SBQQ__Quote__c>();
        for(SBQQ__QuoteLine__c ql_i : scope){
            //normal one quote have only one parent product
            if(id2Quote.containsKey(ql_i.SBQQ__Quote__c)) continue;

            Product2 prod = ql_i.SBQQ__Product__r;
            if(prod!=null && prod.Product_Annex_Reseller__c!=null && prod.Product_Annex_Direct__c!=null){
                SBQQ__Quote__c quote = new SBQQ__Quote__c();
                quote.Id = ql_i.SBQQ__Quote__c;                
                quote.Product_Annex_Direct__c = prod.Product_Annex_Reseller__c;
                quote.Product_Annex_Reseller__c = prod.Product_Annex_Direct__c;
                id2Quote.put(quote.Id,quote);
            }
            

        }
        if(!id2Quote.isEmpty()){
            Database.update(id2Quote.values(),false);
        }

    }

    public void finish(Database.BatchableContext BC){
        
    }

}