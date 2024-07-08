@IsTest
public  class XeroAPITest {
    
    @IsTest 
    static void createAccountTest() {
        Account acc = new Account(
            Account_Number__c = 'Test',
            Name = 'Test');

        XeroObjects.XeroAccount xeroAcc = XeroObjects.mapAccount(acc, 'Test');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.AccountsResponse reponses = XeroAPI.createAccount(xeroAcc);
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }  

    @IsTest 
    static void createAccountErrorTest() {
        Account acc = new Account(
            Account_Number__c = 'Test',
            Name = 'Test');

        XeroObjects.XeroAccount xeroAcc = XeroObjects.mapAccount(acc, 'Test');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock(false));
        XeroApi.AccountsResponse reponses = XeroAPI.createAccount(xeroAcc);
        Test.stopTest();
        System.assert(!reponses.isSuccess);
    }  

    @IsTest 
    static void getAccountTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.AccountsResponse reponses = XeroAPI.getAccount('test');
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void createContactTest() {
        XeroObjects.XeroContact xeroCont = XeroObjects.mapContact('Test');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.ContactsResponse reponses = XeroAPI.createContact(xeroCont);
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void createOrUpdateContactTest() {
        XeroObjects.XeroContact xeroCont = XeroObjects.mapContact('Test');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.ContactsResponse reponses = XeroAPI.createOrUpdateContact(xeroCont);
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void getContactByNameTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.ContactsResponse reponses = XeroAPI.getContactByName('Test');
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void getItemsByCodeTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.ItemsResponse reponses = XeroAPI.getItemsByCode(new List<String>{'Test'});
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void createItemsTest() {
        Product2 prod = new Product2(
            ProductCode = 'test'
        );

        XeroObjects.XeroItem xeroItem = XeroObjects.mapItem(prod, '300', '301');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.ItemsResponse reponses = XeroAPI.createItems(new List<XeroObjects.XeroItem>{xeroItem});
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void createOrUpdateItemsTest() {
        Product2 prod = new Product2(
            ProductCode = 'test'
        );

        XeroObjects.XeroItem xeroItem = XeroObjects.mapItem(prod, '300', '301');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.ItemsResponse reponses = XeroAPI.createOrUpdateItems(new List<XeroObjects.XeroItem>{xeroItem});
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }

    @IsTest 
    static void createQuoteTest() {
        Order order = new Order(
            PoNumber = 'Test',
            EffectiveDate = System.today()
        );
        Account acc = new Account(
            XeroContactId__c = 'Test'
        );

        order.putSObject('Account', acc);
        XeroObjects.XeroQuote xeroQuote = XeroObjects.mapQuote(order, 'GBP');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroApi.QuotesResponse reponses = XeroAPI.createQuote(xeroQuote);
        Test.stopTest();
        System.assert(reponses.isSuccess);
    }
}