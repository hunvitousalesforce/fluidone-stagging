@isTest
public class MidasToSalesforceSyncupSchedulableTest {
    public static testmethod void testGetMidasSuccess(){
        
        Dimensions_API_Credentials__c apiCredentials = new Dimensions_API_Credentials__c(Name='Sandbox', End_Point_URL__c = 'https://api.fluidone.com/', Access_Token__c = 'eyC3L0t0iZAwZKqA', UserId__c='268560',Account_Code__c='FLU010',Email__c='cpq-api@fluidone.com',Password__c='BwQIH!xty2DluCP2!bK1tr',
                                                                                         Refresh_Token__c = '905ad46a-82a1-4470-8348-12d63ffef63b');
        insert apiCredentials;
        
        Dimensions_API_Credentials__c apiCredentials1 = new Dimensions_API_Credentials__c(Name='Production', End_Point_URL__c = 'https://api.fluidone.com/', Access_Token__c = 'eyC3L0t0iZAwZKqA', UserId__c='268560',Account_Code__c='FLU010',Email__c='cpq-api@fluidone.com',Password__c='BwQIH!xty2DluCP2!bK1tr',
                                                                                         Refresh_Token__c = '905ad46a-82a1-4470-8348-12d63ffef63b');
        insert apiCredentials1;
        
        Contact c = TestDataUtil.createContact('Test'); 
        insert c;
        Account acc = TestDataUtil.createAccount('Test');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInXero__c = false;
        acc.Division_Source__c = 'FluidOne';
        insert acc;
        acc.Billing_Contact__c = c.Id;
        update acc;
        Product2 prod = TestDataUtil.createProduct('Test');
        insert prod;
        Opportunity oppt = TestDataUtil.createOpportunity(acc.Id,'Test');
        insert oppt;
        Site__c site = new Site__c(Account__c = acc.Id, Name='Test site3vjhh');
        insert site;
        SBQQ__Quote__c sbqqQuote = TestDataUtil.createQuote(acc.Id,oppt.Id);
        sbqqQuote.Site__c = site.Id;
        sbqqQuote.SBQQ__LineItemsGrouped__c = false;
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
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 10000,
            IsActive = true);
        insert standardPrice;
        Order order = new Order(
            AccountId = acc.Id,
            Midas_Order_Id__c = '20af6c52-9ff2-4e76-8330-dbd61e1486d3',
            Status = 'Draft',
            EffectiveDate = System.today(),
            SBQQ__Quote__c = sbqqQuote.Id,
            OpportunityId = oppt.Id,
            Create_in_Midas__c = false,
            Pricebook2Id = pricebookId
        );
        insert order;
        List<OrderItem> OrderItems = new List<OrderItem>();
        OrderItem orderItem = new OrderItem(
            Quantity = 2,
            Product2Id = prod.Id,
            OrderId = order.Id,
            PricebookEntryId = standardPrice.Id,
            UnitPrice = 20,
            Internal_Journey__c = 'SAS',
            SBQQ__QuoteLine__c = sbqqQuoteLines[0].Id,
            Site__c= site.Id
        );
        OrderItems.add(orderItem);
        orderItem = new OrderItem(
            Quantity = 2,
            Product2Id = prod.Id,
            OrderId = order.Id,
            PricebookEntryId = standardPrice.Id,
            UnitPrice = 20,
            Internal_Journey__c = 'SAS',
            SBQQ__QuoteLine__c = sbqqQuoteLines[1].Id,
            Site__c= site.Id
        );
        OrderItems.add(orderItem);
        insert OrderItems;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderMock());
        MidasToSalesforceSyncQueueable first = new MidasToSalesforceSyncQueueable();
        first.execute(null);
        System.schedule('test Schedule '+system.now().millisecond(), '0 0 * * * ?', new MidasToSalesforceSyncupSchedulable());
        Test.stopTest();
    }
    
}