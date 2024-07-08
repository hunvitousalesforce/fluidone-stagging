@IsTest
public class XeroObjectsTest {
    
    @IsTest 
    static void objectsTest() {
        XeroObjects.ApiResponse apiResponse = new XeroObjects.ApiResponse();
        apiResponse.Id = null;
        apiResponse.Status = null;
        apiResponse.ProviderName = null;
        apiResponse.DateTimeUTC = null;
        apiResponse.ErrorNumber = 0;
        apiResponse.Type = null;
        apiResponse.Message = null;
        apiResponse.Elements = null;

        XeroObjects.Element element = new XeroObjects.Element();
        element.ValidationErrors = null;

        XeroObjects.ValidationError validationError = new XeroObjects.ValidationError();
        validationError.Message = null;

        XeroObjects.XeroAccountsApiResponse xeroAccountsApiResponse = new XeroObjects.XeroAccountsApiResponse();
        xeroAccountsApiResponse.Accounts = null;

        XeroObjects.XeroAccount xeroAccount = new XeroObjects.XeroAccount();
        xeroAccount.AccountID = null;
        xeroAccount.Code = null;
        xeroAccount.Name = null;
        xeroAccount.Type = null;
        xeroAccount.TaxType = null;
        xeroAccount.BankAccountNumber = null;
        xeroAccount.BankAccountType = null;
        xeroAccount.EnablePaymentsToAccount = false;

        XeroObjects.XeroContactsApiResponse xeroContactsApiResponse = new XeroObjects.XeroContactsApiResponse();
        xeroContactsApiResponse.Contacts = null;

        XeroObjects.XeroContact xeroContact = new XeroObjects.XeroContact();
        xeroContact.ContactID = null;
        xeroContact.ContactStatus = null;
        xeroContact.Name = null;
        xeroContact.FirstName = null;
        xeroContact.LastName = null;
        xeroContact.EmailAddress = null;
        xeroContact.Addresses = null;
        xeroContact.CompanyNumber = null;
        xeroContact.TaxNumber = null;
        xeroContact.DefaultCurrency = null;
        xeroContact.Website = null;
        xeroContact.AccountNumber = null;

        XeroObjects.XeroAddress xeroAddress = new XeroObjects.XeroAddress();
        xeroAddress.AddressType = null;
        xeroAddress.AddressLine1 = null;
        xeroAddress.City = null;
        xeroAddress.PostalCode = null;

        XeroObjects.XeroItem xeroItems = new XeroObjects.XeroItem();
        xeroItems.ItemID = null;
        xeroItems.Code = null;
        xeroItems.Description = null;
        xeroItems.InventoryAssetAccountCode = null;
        xeroItems.PurchaseDetails = null;

        XeroObjects.XeroItemsApiResponse xeroItemsApiResponse = new XeroObjects.XeroItemsApiResponse();
        xeroItemsApiResponse.Items = null;

        XeroObjects.CreataXeroItemRequest creataXeroItemRequest = new XeroObjects.CreataXeroItemRequest();
        creataXeroItemRequest.Items = null;

        XeroObjects.XeroItemPurchaseDetails xeroItemPurchaseDetails = new XeroObjects.XeroItemPurchaseDetails();
        xeroItemPurchaseDetails.UnitPrice = 0;
        xeroItemPurchaseDetails.AccountCode = null;
        xeroItemPurchaseDetails.COGSAccountCode = null;

        XeroObjects.XeroQuote xeroQuote = new XeroObjects.XeroQuote();
        xeroQuote.QuoteID = null;
        xeroQuote.QuoteNumber = null;
        xeroQuote.Reference = null;
        xeroQuote.Contact = null;
        xeroQuote.LineItems = null;
        xeroQuote.XeroDate = null;
        xeroQuote.CurrencyCode = null;
        xeroQuote.Total = 0;
        xeroQuote.Status = null;

        XeroObjects.XeroQuoteLineItems xeroQuoteLineItems = new XeroObjects.XeroQuoteLineItems();
        xeroQuoteLineItems.Description = null;
        xeroQuoteLineItems.UnitAmount = 0;
        xeroQuoteLineItems.LineAmount = 0;
        xeroQuoteLineItems.ItemCode = null;
        xeroQuoteLineItems.Quantity = 0;
        xeroQuoteLineItems.DiscountRate = 0;

        XeroObjects.XeroQuotesApiResponse xeroQuotesApiResponse = new XeroObjects.XeroQuotesApiResponse();
        xeroQuotesApiResponse.Quotes = null;

        XeroObjects.CreataXeroQuotesRequest creataXeroQuotesRequest = new XeroObjects.CreataXeroQuotesRequest();
        creataXeroQuotesRequest.Quotes = null;
    }

    @IsTest 
    static void mapErrorResponseTest() {
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setBody('Test');
        httpResponse.setStatus('Error');
        httpResponse.setStatusCode(500);

        XeroObjects.mapErrorResponse(httpResponse);
    }

    @IsTest 
    static void mapAccountTest() {
        Account acc = new Account(
            Account_Number__c = 'Test',
            Name = 'Test');

        XeroObjects.mapAccount(acc, 'Test');
    }

    @IsTest 
    static void mapContactTest1() {
        XeroObjects.mapContact('Test');
    }

    @IsTest 
    static void mapContactTest2() {
        Account acc = new Account(
            Name = 'Test',
            BillingStreet = 'Test',
            BillingCity = 'Test',
            BillingPostalCode = 'Test',
            comp_house__Company_Number__c = '101',
            VAT_number__c = 'Test',
            Website = 'Test'
        );
        
        Contact primaryCont = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'Test'
        ); 
        acc.putSObject('PrimaryContact__r', primaryCont);

        XeroObjects.mapContact(acc);
    }

    @IsTest 
    static void mapItemTest() {
        Product2 prod = new Product2(
            ProductCode = 'test'
        );

        XeroObjects.mapItem(prod, '300', '301');
    }

    @IsTest 
    static void mapCreataXeroItemRequestTest() {
        Product2 prod = new Product2(
            ProductCode = 'test'
        );

        XeroObjects.XeroItem xeroItem = XeroObjects.mapItem(prod, '300', '301');

        XeroObjects.mapCreataXeroItemRequest(new List<XeroObjects.XeroItem>{xeroItem});
    }

    @IsTest 
    static void mapQuoteTest() {
        Order order = new Order(
            PoNumber = 'Test',
            EffectiveDate = System.today()
        );
        Account acc = new Account(
            XeroContactId__c = 'Test'
        );

        order.putSObject('Account', acc);
        XeroObjects.mapQuote(order, 'GBP');
    }

    @IsTest 
    static void mapXeroQuoteLineItemTest() {
        Product2 prod = new Product2(
            Name = 'Test',
            ProductCode = 'Test'
        );
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
          
        );

        OrderItem orderItem = new OrderItem(
            Quantity = 2
        );

        orderItem.putSObject('Product2', prod);
        orderItem.putSObject('SBQQ__QuoteLine__r', quoteLine);

        XeroObjects.mapXeroQuoteLineItem(orderItem);
    }

    @IsTest 
    static void mapCreataXeroQuotesRequestTest() {
        Order order = new Order(
            PoNumber = 'Test',
            EffectiveDate = System.today()
        );
        Account acc = new Account(
            XeroContactId__c = 'Test'
        );

        order.putSObject('Account', acc);
        XeroObjects.XeroQuote xeroQuote = XeroObjects.mapQuote(order, 'GBP');

        XeroObjects.mapCreataXeroQuotesRequest(xeroQuote);
    }
}