global with sharing class XeroCalloutMock implements HttpCalloutMock {
    
    private Boolean isSuccess;
    private String xeroObjectId;

    public XeroCalloutMock() {
        this(true);
    }

    public XeroCalloutMock(Boolean isSuccess) {
        this.isSuccess = isSuccess;
    }

    public void setXeroObjectId(String id) {
        this.xeroObjectId = id;
    }

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Accept', 'application/json');
        response.setHeader('Content-Type', 'application/json');
        if (isSuccess) {
            response.setBody(getBodyForEndpoint(request.getEndpoint()));
            response.setStatusCode(200);
        } else {
            response.setBody(getErrorBodyForEndpoint(request.getEndpoint()));
            response.setStatusCode(401);
        }
        return response; 
    }

    private String getBodyForEndpoint(String endpoint) {
        if (endpoint.contains('TestResource')) {
            return '{}';
        } else if (endpoint.contains(XeroAPI.RESOURCE_ACCOUNTS)) {
            return '{"Id":"6d5ae18b-1325-4859-8a46-757cda54408e","Status":"OK","ProviderName":"API Explorer","DateTimeUTC":"/Date(1669204318108)/","Accounts":[{"AccountID":"' + xeroObjectId + '","Code":"123456","Name":"Foobar","Status":"ACTIVE","Type":"EXPENSE","TaxType":"INPUT","Description":"Hello World","Class":"EXPENSE","EnablePaymentsToAccount":false,"ShowInExpenseClaims":false,"ReportingCode":"EXP","ReportingCodeName":"Expense","UpdatedDateUTC":"/Date(1669204318107+0000)/","AddToWatchlist":false}]}';
        } else if (endpoint.contains(XeroAPI.RESOURCE_CONTACTS)) {
            return '{"Id":"6601bd11-631a-4265-bfc6-b931403c9735","Status":"OK","ProviderName":"API Explorer","DateTimeUTC":"/Date(1669204754044)/","Contacts":[{"ContactID":"33ff2e28-e816-4a4c-811d-444fd971d34f","ContactStatus":"ACTIVE","Name":"Foo9987","EmailAddress":"sid32476@blah.com","BankAccountDetails":"","Addresses":[{"AddressType":"STREET","City":"","Region":"","PostalCode":"","Country":""},{"AddressType":"POBOX","City":"","Region":"","PostalCode":"","Country":""}],"Phones":[{"PhoneType":"DEFAULT","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""},{"PhoneType":"DDI","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""},{"PhoneType":"FAX","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""},{"PhoneType":"MOBILE","PhoneNumber":"555-1212","PhoneAreaCode":"415","PhoneCountryCode":""}],"UpdatedDateUTC":"/Date(1669204753967+0000)/","ContactGroups":[],"IsSupplier":false,"IsCustomer":false,"SalesTrackingCategories":[],"PurchasesTrackingCategories":[],"PaymentTerms":{"Bills":{"Day":15,"Type":"OFCURRENTMONTH"},"Sales":{"Day":10,"Type":"DAYSAFTERBILLMONTH"}},"ContactPersons":[],"HasValidationErrors":false}]}';
        } else if (endpoint.contains(XeroAPI.RESOURCE_ITEMS)) {
            return '{"Id":"bcf279f4-ecea-4059-aea4-87c9e38d88ed","Status":"OK","ProviderName":"API Explorer","DateTimeUTC":"/Date(1669205547763)/","Items":[{"ItemID":"61c36ef2-0f39-4a67-8d9f-3117ff7a452c","Code":"I-BTOR-LES-1G","UpdatedDateUTC":"/Date(1668682891093+0000)/","PurchaseDetails":{"UnitPrice":0,"COGSAccountCode":"300","TaxType":"OUTPUT"},"SalesDetails":{},"IsTrackedAsInventory":true,"InventoryAssetAccountCode":"630","TotalCostPool":0,"QuantityOnHand":0,"IsSold":true,"IsPurchased":true},{"ItemID":"808cd64d-e5e7-4785-9dfb-8ddac6658175","Code":"I-BTW-LES-1G","UpdatedDateUTC":"/Date(1668682891093+0000)/","PurchaseDetails":{"UnitPrice":0,"COGSAccountCode":"300","TaxType":"OUTPUT"},"SalesDetails":{},"IsTrackedAsInventory":true,"InventoryAssetAccountCode":"630","TotalCostPool":0,"QuantityOnHand":0,"IsSold":true,"IsPurchased":true},{"ItemID":"d42f2dee-69ac-4d68-a93f-d2e7457d33f0","Code":"I-CITY-LES-1G","UpdatedDateUTC":"/Date(1668681934087+0000)/","PurchaseDetails":{"UnitPrice":0,"COGSAccountCode":"300","TaxType":"OUTPUT"},"SalesDetails":{},"IsTrackedAsInventory":true,"InventoryAssetAccountCode":"630","TotalCostPool":0,"QuantityOnHand":0,"IsSold":true,"IsPurchased":true},{"ItemID":"163924f3-66ce-40ba-ae81-b87e01f33490","Code":"I-COLT-LES-1G","UpdatedDateUTC":"/Date(1668681934067+0000)/","PurchaseDetails":{"UnitPrice":0,"COGSAccountCode":"300","TaxType":"OUTPUT"},"SalesDetails":{},"IsTrackedAsInventory":true,"InventoryAssetAccountCode":"630","TotalCostPool":0,"QuantityOnHand":0,"IsSold":true,"IsPurchased":true},{"ItemID":"5fde1d98-4d99-43e6-b87a-1f065c1c474d","Code":"I-EXPE-LES-1G","UpdatedDateUTC":"/Date(1668681934067+0000)/","PurchaseDetails":{"UnitPrice":0,"COGSAccountCode":"300","TaxType":"OUTPUT"},"SalesDetails":{},"IsTrackedAsInventory":true,"InventoryAssetAccountCode":"630","TotalCostPool":0,"QuantityOnHand":0,"IsSold":true,"IsPurchased":true}]}';
        } else if (endpoint.contains(XeroAPI.RESOURCE_QUOTES)) {
            return '{"Id":"607c1c81-5f82-4b70-a88b-1942c1b583c2","Status":"OK","ProviderName":"API Explorer","DateTimeUTC":"/Date(1669206233294)/","Quotes":[{"QuoteID":"de4fd772-41cc-451b-b076-fbb1e4cd0392","QuoteNumber":"00000227","Reference":"12345","Contact":{"ContactID":"58d3d575-61d3-46c3-8fb2-a3a57c83d95f","Name":"Test Billing 8","EmailAddress":""},"LineItems":[{"LineItemID":"cbf34a42-84bd-45fb-9fd5-66721ae0d34d","Description":"1 Gb/s Leased Line Bearer /BTOR","UnitAmount":0,"DiscountAmount":0,"LineAmount":0,"ItemCode":"I-BTOR-LES-1G","Quantity":2,"TaxAmount":0,"Tracking":[]},{"LineItemID":"4c9a6c6f-ca03-4ab1-8346-2828b5787bfc","Description":"1 Gb/s Leased Line Bearer /BTW","UnitAmount":0,"DiscountAmount":0,"LineAmount":0,"ItemCode":"I-BTW-LES-1G","Quantity":2,"TaxAmount":0,"Tracking":[]}],"Date":"/Date(1668643200000)/","DateString":"2022-11-17T00:00:00","Status":"DRAFT","CurrencyRate":0.022698,"CurrencyCode":"GBP","SubTotal":0,"TotalTax":0,"Total":0,"TotalDiscount":0,"BrandingThemeID":"95c5334d-33e4-41bb-a92e-89c8c7b8f08f","UpdatedDateUTC":"/Date(1668682891590)/","LineAmountTypes":"EXCLUSIVE"}]}';
        } else {
            return '{}';
        }
    }

    private String getErrorBodyForEndpoint(String endpoint) {
        if (endpoint.contains('TestResource')) {
            return '{}';
        } else if (endpoint.contains(XeroAPI.RESOURCE_ACCOUNTS)) {
            return '{"ErrorNumber":10,"Type":"ValidationException","Message":"A validation exception occurred","Elements":[{"AccountID":"00000000-0000-0000-0000-000000000000","Code":"123456","Name":"Foobar","Type":"EXPENSE","Description":"Hello World","ValidationErrors":[{"Message":"Please enter a unique Code."},{"Message":"Please enter a unique Name."}]}]}';
        } else {
            return '{}';   
        }
    }
}