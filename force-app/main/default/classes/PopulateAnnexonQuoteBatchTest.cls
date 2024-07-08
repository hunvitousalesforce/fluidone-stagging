@isTest
private class PopulateAnnexonQuoteBatchTest {
    
    @isTest
    static void testPopulateAnnexonQuote(){
        Contact c = TestDataUtil.createContact('Test');
        insert c;          
        
        Account acc = TestDataUtil.createAccount('Test');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInXero__c = false;
        acc.Division_Source__c = 'FluidOne';
        acc.VAT_number__c = 'GB'; 
        insert acc;
        acc.Billing_Contact__c = c.Id;
        update acc;
        Product2 prod = TestDataUtil.createProduct('Test');
        prod.Product_Annex_Direct__c='https/test.com';
        prod.Product_Annex_Reseller__c='https/test.com';
        prod.Parent_Product__c =true;
        insert prod;
        
        Opportunity oppt = TestDataUtil.createOpportunity(acc.Id,'Test');
        oppt.StageName = 'Closed Lost';
        insert oppt;
        Site__c site = new Site__c(Account__c = acc.Id,Name='Test site');
        insert site;
        SBQQ__Quote__c sbqqQuote = TestDataUtil.createQuote(acc.Id,oppt.Id);
        sbqqQuote.Site__c = site.Id;
        sbqqQuote.SBQQ__LineItemsGrouped__c = false;
        sbqqQuote.SBQQ__Opportunity2__c = oppt.Id;
        insert sbqqQuote;
        
        oppt.SBQQ__PrimaryQuote__c = sbqqQuote.Id;
        update oppt;
        
        oppt = [SELECT Id, SBQQ__PrimaryQuote__r.SBQQ__Primary__c FROM Opportunity WHERE SBQQ__PrimaryQuote__c = :sbqqQuote.Id LIMIT 1];
        System.assert(oppt.SBQQ__PrimaryQuote__r.SBQQ__Primary__c);
        List<SBQQ__QuoteLine__c> sbqqQuoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c sbqqQuoteLine = new SBQQ__QuoteLine__c(
            ContractType__c = 'test',SBQQ__Quote__c=sbqqQuote.Id,SBQQ__Product__c =prod.Id,SBQQ__BillingFrequency__c='Monthly',
            SBQQ__SubscriptionTerm__c = 1,BelongsToPrimaryFeature__c=true,BelongsToSecondaryFeature__c=true,BelongsToAdvanceFeature__c=true
            
        );
        sbqqQuoteLines.add(sbqqQuoteLine);
        sbqqQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=sbqqQuote.Id,SBQQ__Product__c =prod.Id,SBQQ__BillingFrequency__c='Monthly'
        );
        sbqqQuoteLines.add(sbqqQuoteLine);
        insert sbqqQuoteLines;


        test.startTest();
            PopulateAnnexonQuoteBatch pab = new PopulateAnnexonQuoteBatch();
            Database.executeBatch(pab);
        test.stopTest();
        SBQQ__Quote__c updateQuote =  [SELECT Id, Product_Annex_Direct__c, Product_Annex_Reseller__c FROM SBQQ__Quote__c WHERE Id = :sbqqQuote.Id];
        System.assertEquals(updateQuote.Product_Annex_Direct__c, prod.Product_Annex_Direct__c);
        System.assertEquals(updateQuote.Product_Annex_Reseller__c, prod.Product_Annex_Reseller__c);
    }
}