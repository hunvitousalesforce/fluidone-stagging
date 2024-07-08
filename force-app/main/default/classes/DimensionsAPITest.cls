@isTest
public class DimensionsAPITest {
	@testSetup
    static void loadData(){
        List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx',
                                              Auth_API_URL__c='xx', Dimension_API_URL__c='xx', CPQ_API_URL__c='xx', OrderManagement_API_URL__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx',
                                              Auth_API_URL__c='xx', Dimension_API_URL__c='xx', CPQ_API_URL__c='xx', OrderManagement_API_URL__c='xx')
        };
        insert apiCredentials;                    
        Contact c = TestDataUtil.createContact('Test');
		insert c;          
        
        Account acc = TestDataUtil.createAccount('Test');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInXero__c = false;
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
        
        //oppt.Contracting_Account__c = 'Testing Contracting Account';
        //oppt.Billing_Account__c = 'Testing Billing Account';
        //update oppt;

        oppt = [SELECT Id, SBQQ__PrimaryQuote__r.SBQQ__Primary__c FROM Opportunity WHERE SBQQ__PrimaryQuote__c = :sbqqQuote.Id LIMIT 1];
        System.assert(oppt.SBQQ__PrimaryQuote__r.SBQQ__Primary__c);

        SBQQ__QuoteLine__c sbqqQuoteLine = new SBQQ__QuoteLine__c();

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
            UnitPrice = 20
        );
        OrderItems.add(orderItem);
         orderItem = new OrderItem(
            Quantity = 2,
            Product2Id = prod.Id,
            OrderId = order.Id,
            PricebookEntryId = standardPrice.Id,
            UnitPrice = 20,
            Internal_Journey__c = 'FluidOne'
        );
        OrderItems.add(orderItem);
        insert OrderItems;
    }
    @isTest
    static void orderApiTestMethod(){
        
        DimensionsOrderAPI orderApi = new DimensionsOrderAPI();
        
        Order order = [SELECT Id,Account.Account_Number__c,PoNumber, OrderFormSignedOn__c, Type,ActivatedDate, 
                       Opportunity.Contracting_Account__c, Opportunity.Billing_Account__c, OpportunityId FROM Order LIMIT 1];
        
        OrderItem oi = [SELECT Id,SBQQ__QuoteLine__r.SBQQ__SubscriptionPricing__c,SBQQ__QuotedListPrice__c,UnitPrice,Product2.ProductCode,Quantity,SBQQ__QuoteLine__r.RecurringCost__c,SBQQ__QuoteLine__r.OneOffCost__c FROM OrderItem LIMIT 1];
        DimensionsOrderAPI.DimensionsOrder dimentionOrder = DimensionsOrderAPI.mapNeoOrder(order,'site');
        dimentionOrder.getBillingFrequency();
        dimentionOrder.setBillingFrequency('');
        dimentionOrder.setBillingFrequency('Monthly');
        dimentionOrder.setBillingFrequency('Quarterly');
        dimentionOrder.setBillingFrequency('Semiannual');
        dimentionOrder.setBillingFrequency('Annual');
        DimensionsOrderAPI.ContractPart contractPart = DimensionsOrderAPI.mapNeoContractPart('xx', 'xx');
        DimensionsOrderAPI.mapNeoAddressFromSite(new Site__c());
        DimensionsOrderAPI.OrderContact orderContact = DimensionsOrderAPI.mapNeoContact('title', 'firstName', 'lastName', 'email', 'phoneNumber');
        DimensionsOrderAPI.ProductLine productLine = DimensionsOrderAPI.mapNeoProductLine(oi);
        DimensionsOrderAPI.parseOrderStatus(-1);
        DimensionsOrderAPI.parseOrderStatus(0);
        DimensionsOrderAPI.parseOrderStatus(1);
        DimensionsOrderAPI.parseOrderStatus(2);
        DimensionsOrderAPI.parseOrderStatus(3);
        DimensionsOrderAPI.parseOrderStatus(4);
        DimensionsOrderAPI.parseOrderStatus(5);

        String orderJsonBody = JSON.serialize(dimentionOrder);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionOrderApiMock());
        DimensionsOrderAPI.createOrderInDimensions(orderJsonBody);
        Test.stopTest();
        DimensionsOrderAPI.getOrderStatus('xx');
    }
    @isTest
    static void accountApiTestMethod(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionAccountApiMock());
        DimensionsAccountAPI.Account acc = new DimensionsAccountAPI.Account();
        String accountJson = JSON.serialize(acc);
        DimensionsAccountAPI.getAccountInDimensionsById('dimensionId');
        Test.stopTest();
    }
    @isTest
    static void accountApiTestMethod1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionAccountApiMock());
        DimensionsAccountAPI.Account acc = new DimensionsAccountAPI.Account();
        String accountJson = JSON.serialize(acc);
        DimensionsAccountAPI.createAccountInDimensions(accountJson);
        Test.stopTest();
    }
    @isTest
    static void stockApiTestMethod(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionStockApiMock());
		DimensionsStockAPI.getDimensionsStock();
        test.stopTest();
    }
}