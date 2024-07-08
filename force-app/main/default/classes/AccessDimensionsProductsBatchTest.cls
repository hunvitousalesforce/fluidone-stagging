@isTest
public class AccessDimensionsProductsBatchTest {

    @TestSetup
    static void makeData(){
        List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx')
        };
        insert apiCredentials;     
        Contact c = TestDataUtil.createContact('Test');
		insert c;          
        
        Account acc = TestDataUtil.createAccount('Test');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInXero__c = false;
        acc.VAT_number__c = 'GB';
        acc.Division_Source__c = 'FluidOne';
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

        SBQQ__QuoteLine__c sbqqQuoteLine = new SBQQ__QuoteLine__c();

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id =pricebookId,
            IsActive = true
        );
        Update standardPricebook;
        Pricebook2 customPricebook = new Pricebook2(
            IsActive = true,Name = 'custom price book'
        );
        insert customPricebook;
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id,
            UnitPrice = 10000, 
            IsActive = true);
        insert standardPrice;
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPricebook.Id, 
            Product2Id = prod.Id,
            UnitPrice = 10000, 
            IsActive = true);
        insert customPrice;
        

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
            NeoOrderStatus__c = 'Queueing'
        );
        OrderItems.add(orderItem);
         orderItem = new OrderItem(
            Quantity = 2,
            Product2Id = prod.Id,
            OrderId = order.Id,
            PricebookEntryId = standardPrice.Id,
            UnitPrice = 20,
            Internal_Journey__c = 'FluidOne',
            NeoOrderId__c = 'x2',
            NeoOrderStatus__c = 'Queueing'
        );
        OrderItems.add(orderItem);
        insert OrderItems;  
        SBQQ__Cost__c cost = new SBQQ__Cost__c(
        	SBQQ__Product__c= prod.Id, SBQQ__UnitCost__c=10
        );
        insert cost;
    }
    @isTest
    static void dimensionProductTestMethod(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionStockApiMock());
        Database.executeBatch(new AccessDimensionsProductsBatch());
        Test.stopTest();
        List<Product2> products = [SELECT Id,Name FROM Product2];
        system.AssertEquals(products.size() ,1);
    }
    @isTest
    static void schedulerMethod(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionStockApiMock());
        new AccessDimensionsProductsScheduler().execute(null);
        test.stopTest();
    }
}