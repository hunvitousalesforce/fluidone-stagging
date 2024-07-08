@isTest
public with sharing class GetNeoOrderStatusBatchTest {
    @TestSetup
    static void makeData(){
        Contact c = TestDataUtil.createContact('Test');
		insert c;          
        
        Account acc = TestDataUtil.createAccount('Test');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInXero__c = false;
        acc.Division_Source__c = 'FluidOne';
        acc.VAT_number__c = 'GB';
        insert acc;

        Product2 prod = TestDataUtil.createProduct('Test');
        insert prod;
    
        Opportunity oppt = TestDataUtil.createOpportunity(acc.Id,'Test');
        insert oppt;

        SBQQ__Quote__c sbqqQuote = TestDataUtil.createQuote(acc.Id,oppt.Id);
        insert sbqqQuote;

        oppt.SBQQ__PrimaryQuote__c = sbqqQuote.Id;
        update oppt;

        oppt = [SELECT Id, SBQQ__PrimaryQuote__r.SBQQ__Primary__c FROM Opportunity WHERE SBQQ__PrimaryQuote__c = :sbqqQuote.Id LIMIT 1];
        System.assert(oppt.SBQQ__PrimaryQuote__r.SBQQ__Primary__c);


        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id,
            UnitPrice = 10000, 
            IsActive = true);
        insert standardPrice;

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
            NeoOrderId__c = 'x1',
            NeoOrderStatus__c = 'Queueing',
            SBQQ__QuoteLine__c = sbqqQuoteLines[0].Id
        );
        OrderItems.add(orderItem);
       OrderItem  orderItem1 = new OrderItem(
            Quantity = 2,
            Product2Id = prod.Id,
            OrderId = order.Id,
            PricebookEntryId = standardPrice.Id,
            UnitPrice = 20,
            Internal_Journey__c = 'FluidOne',
            NeoOrderId__c = 'x2',
            NeoOrderStatus__c = 'Queueing',
           SBQQ__QuoteLine__c = sbqqQuoteLines[1].Id
        );
        OrderItems.add(orderItem1);
        insert OrderItems;
        
        List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx')
        };
        insert apiCredentials;  
    }
    @isTest
    static void neoOrderTestMethod(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionOrderApiMock());
        Database.executeBatch(new GetNeoOrderStatusBatch());
        Test.stopTest();
        List<OrderItem> orderItems = [SELECT Id,NeoOrderStatus__c FROM OrderItem WHERE NeoOrderStatus__c = 'Completed'];
        system.AssertEquals(orderItems.size() , 1);
    }
    
    /* Removed, no longer a valid test case - jamesgoode@fluidone.com
    @isTest
    static void neoOrderRejectTestMethod(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionOrderApiRejectMock());
        Database.executeBatch(new GetNeoOrderStatusBatch());
        Test.stopTest();
        List<OrderItem> orderItems = [SELECT Id,NeoOrderStatus__c FROM OrderItem WHERE NeoOrderStatus__c='Rejected'];
        system.Assert(orderItems.size() == 1);

    }
	*/
    
    @isTest
    static void schedulerTest(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionOrderApiMock());
        new GetNeoOrderStatusScheduler().execute(null);
        test.stopTest();
    }
 }