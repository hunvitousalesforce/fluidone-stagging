@isTest
public with sharing class OrderTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        
        List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx',
                                              Auth_API_URL__c='xx', Dimension_API_URL__c='xx', CPQ_API_URL__c='xx', OrderManagement_API_URL__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx',
                                              Auth_API_URL__c='xx', Dimension_API_URL__c='xx', CPQ_API_URL__c='xx', OrderManagement_API_URL__c='xx')};
        insert apiCredentials; 
        
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
        
         Site__c site = new Site__c(Account__c = acc.Id,Name='Test site3vjhh');
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
            Status = 'Draft',
            EffectiveDate = System.today(),
            SBQQ__Quote__c = sbqqQuote.Id,
            OpportunityId = oppt.Id,
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
            Internal_Journey__c = 'FluidOne',
            SBQQ__QuoteLine__c = sbqqQuoteLines[1].Id,
            Site__c= site.Id
        );
        OrderItems.add(orderItem);
        insert OrderItems;
        
       
    }
    @isTest
    static void neoTestMethod1(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionOrderApiMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.CreateInNeo__c = true;
        update order;
        Test.stopTest();
    }
    @isTest
    static void xeroTestMethod1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        Account acc = [Select Id,Billing_Contact__c from Account limit 1];
        Order order = [SELECT Id,Name,Account.Billing_Contact__c FROM Order Limit 1];
        order.CreateInXero__c = true;
        update order;
        Test.stopTest();
        order = [SELECT Id,Name,XeroQuoteId__c FROM Order Limit 1];
        system.Assert(order.XeroQuoteId__c != null);
        
    }
}