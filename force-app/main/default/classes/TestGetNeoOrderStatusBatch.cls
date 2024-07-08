@isTest
public class TestGetNeoOrderStatusBatch {
    
    static testMethod void getNeoOrderStatusBatchTest(){
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
        OrderItem orderItemRecord = new OrderItem();
        orderItemRecord.Product2Id = prod.Id;
        orderItemRecord.OrderId = order.Id;
        orderItemRecord.UnitPrice = 20;
        orderItemRecord.Quantity = 2;
        orderItemRecord.PricebookEntryId = standardPrice.Id;
        orderItemRecord.NeoOrderStatus__c = 'Queueing';
        orderItemRecord.NeoOrderId__c = 'ttestid';
        orderItemRecord.LinkedContractNumber__c = 'ContractNumbertest';
        
        insert orderItemRecord;
        
         List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx')
        };
        insert apiCredentials;  
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionOrderApiMock());
        GetNeoOrderStatusBatch obj = new GetNeoOrderStatusBatch();
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
        
    }
}