@isTest
private class MidasOrderApiServiceTest {
    @TestSetup
    static void makeData(){
                
        Dimensions_API_Credentials__c apiCredentials1 = new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx',
			Auth_API_URL__c='xx', Dimension_API_URL__c='xx', CPQ_API_URL__c='xx', OrderManagement_API_URL__c='xx');   
        insert apiCredentials1;        
        
        Dimensions_API_Credentials__c apiCredentials2 = new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx',
			Auth_API_URL__c='xx', Dimension_API_URL__c='xx', CPQ_API_URL__c='xx', OrderManagement_API_URL__c='xx');   
        insert apiCredentials2;        
        
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
        prod.ProductLine__c = 'CPE';
        insert prod;
        
        Opportunity oppt = TestDataUtil.createOpportunity(acc.Id,'Test');
        insert oppt;
        
        Site__c site2 = new Site__c(Account__c = acc.Id, Name='Test site2');
        insert site2;
        
        Site__c site = new Site__c(Account__c = acc.Id, Name='Test site3vjhh', Site2__c = site2.Id);
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
    }
    @isTest
    static void testMethod1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Create_in_Midas__c = true;
        update order;
        Test.stopTest();
    }
    @isTest
    static void testMethod2(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Create_in_Midas__c = true;
        update order;
        Test.stopTest();
    }
    @isTest
    static void testMethod3(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderPartialFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Create_in_Midas__c = true;
        update order;
        Test.stopTest();
    }
    @isTest
    static void testMethod4(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderMock());
        MidasOrderApiServiceHelper.getAccessToken();
        Test.stopTest();
        MidasOrderApiServiceWrappers wrapper = new MidasOrderApiServiceWrappers();
        MidasOrderApiServiceWrappers.CredentialsBody body = new MidasOrderApiServiceWrappers.CredentialsBody();
        body.AccountCode = '';
        body.Email= '';
        body.Password = '';
    }
    @isTest
    static void testMethod5(){
        Dimensions_API_Credentials__c apiCredentials = [SELECT Id,Access_Token__c FROM Dimensions_API_Credentials__c LIMIT 1];
        apiCredentials.Access_Token__c = '';
        update apiCredentials;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderMock());
        MidasOrderApiServiceHelper.getAccessToken();
        Test.stopTest();
    }
    @isTest
    static void testMethod6(){
        Dimensions_API_Credentials__c apiCredentials = [SELECT Id,Access_Token__c FROM Dimensions_API_Credentials__c LIMIT 1];
        apiCredentials.Access_Token__c = '';
        update apiCredentials;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Create_in_Midas__c = true;
        update order;
        Test.stopTest();
    }
    @isTest
    static void testMethod7(){
        Dimensions_API_Credentials__c apiCredentials = [SELECT Id,Access_Token__c FROM Dimensions_API_Credentials__c LIMIT 1];
        Test.startTest();
        System.enqueueJob(new MidasOrderApiServiceHelper.UpdateApiCredentials(apiCredentials));
        Test.stopTest();
    }
    @isTest
    static void testMethod8(){
        Dimensions_API_Credentials__c apiMidasOrderApiServiceTestCredentials = [SELECT Id,Access_Token__c FROM Dimensions_API_Credentials__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderFailedMock());
        MidasOrderApiServiceHelper.getAccessToken();
        Test.stopTest();
    }  
    
    // Reset tests
    @isTest
    static void testMethod9(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Reset_In_Midas__c = true;
        update order;
        Test.stopTest();
    }
    
    @isTest
    static void testMethod10(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderPartialFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Reset_In_Midas__c = true;
        update order;
        Test.stopTest();
    }
    
    @isTest
    static void testMethod11(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceOrderFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Reset_In_Midas__c = true;
        update order;
        Test.stopTest();      
    }
    
    @isTest
    static void testMethod12(){
        Test.startTest();
        String result = MidasOrderApiServiceHelper.convertToBase64('myTestString');
        system.Assert(result == 'bXlUZXN0U3RyaW5n');
        Test.stopTest();
    }
    
    // Reset tests
    @isTest
    static void testMethod13(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceReSendMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Reset_In_Midas__c = true;
        update order;
        Test.stopTest();
    }
    
    @isTest
    static void testMethod14(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceResetFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Reset_In_Midas__c = true;
        update order;
        Test.stopTest();
    }
    
    @isTest
    static void testMethod15(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MidasOrderApiServiceMock.MidasOrderApiServiceReSendFailedMock());
        Order order = [SELECT Id,Name FROM Order Limit 1];
        order.Reset_In_Midas__c = true;
        update order;
        Test.stopTest();      
    }         
}