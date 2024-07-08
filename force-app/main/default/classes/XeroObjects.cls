//Test: XeroObjectsTest
public with sharing class XeroObjects {

    public static final String ACCOUNT_TYPE_SALES = 'SALES';
    public static final String ACCOUNT_TYPE_INVENTORY = 'INVENTORY';

    public static final Map<String, String> XERO_TO_SF_KEYS = new Map<String, String> {
        '"Date"' => '"XeroDate"'
    };

    public static final Map<String, String> SF_TO_XERO_KEYS = new Map<String, String> {
        '"XeroDate"' => '"Date"'
    };

    public virtual class ApiResponse {
        public String Id {set;get;}
        public String Status {set;get;}
        public String ProviderName {set;get;}
        public String DateTimeUTC {set;get;}
        public Integer ErrorNumber {set;get;}
        public String Type {set;get;}
        public String Message {set;get;}
        public List<Element> Elements {set;get;}
    }

    public class Element {
        public List<ValidationError> ValidationErrors {set;get;}
    }

    public class ValidationError {
        public String Message {set;get;}
    }

    public class XeroAccountsApiResponse extends ApiResponse {
        public List<XeroAccount> Accounts {set;get;}
    }
    
    //Account
    public class XeroAccount {
        public String AccountID {set;get;}
        public String Code {set;get;}
        public String Name {set;get;}
        public String Type {set;get;}
        public String TaxType {set;get;}
        public String BankAccountNumber {set;get;}
        public String BankAccountType {set;get;}
        public Boolean EnablePaymentsToAccount {set;get;}
    }

    public class XeroContactsApiResponse extends ApiResponse {
        public List<XeroContact> Contacts {set;get;}
    }

    //Contacts
    public class XeroContact {
        public String ContactID {set;get;}
        public String ContactStatus {set;get;}
        public String Name {set;get;}
        public String FirstName {set;get;}
        public String LastName {set;get;}
        public String EmailAddress {set;get;}
        public List<XeroAddress> Addresses {set;get;}
        public String CompanyNumber {set;get;}
        public String TaxNumber {set;get;}
        public String DefaultCurrency {set;get;}
        public String Website {set;get;}
        public String AccountNumber {set;get;}
    }

    public class XeroAddress { 
        public String AddressType {set;get;}
        public String AddressLine1 {set;get;}
        public String City {set;get;}
        public String PostalCode {set;get;}
    }

    //Items
    public class XeroItem {
        public String ItemID {set;get;}
        public String Code {set;get;}
        public String Description {set;get;}
        public String InventoryAssetAccountCode {set;get;}
        public XeroItemPurchaseDetails PurchaseDetails {set;get;}
    }

    public class XeroItemsApiResponse extends ApiResponse {
        public List<XeroItem> Items {set;get;}
    }

    public class CreataXeroItemRequest {
        public List<XeroItem> Items {set;get;}
    }

    public class XeroItemPurchaseDetails {
        public Decimal UnitPrice {set;get;}
        public String AccountCode {set;get;}
        public String COGSAccountCode {set;get;}
    }

    //Quotes
    public class XeroQuote {
        public String QuoteID {set;get;}
        public String QuoteNumber {set;get;}
        public String Reference {set;get;}
        public XeroContact Contact {set;get;}
        public List<XeroQuoteLineItems> LineItems {set;get;}
        public String XeroDate {set;get;}
        public String CurrencyCode {set;get;}
        public Decimal Total {set;get;}
        public String Status {set;get;}        
    }

    public class XeroQuoteLineItems {
        public String Description {set;get;}
        public Decimal UnitAmount {set;get;}
        public Decimal LineAmount {set;get;}
        public String ItemCode {set;get;}
        public Decimal Quantity {set;get;}
        public Decimal DiscountRate {set;get;}
    }

    public class XeroQuotesApiResponse extends ApiResponse {
        public List<XeroQuote> Quotes {set;get;}
    }

    public class CreataXeroQuotesRequest {
        public List<XeroQuote> Quotes {set;get;}
    }

    public static ApiResponse mapErrorResponse(HttpResponse httpResponse) {
        ApiResponse response = new ApiResponse();

        response.ErrorNumber = httpResponse.getStatusCode();
        response.Type = httpResponse.getStatus();
        response.Message = httpResponse.getBody();
        return response;
    }

    //Accounts
    public static XeroAccount mapAccount(Account acc, String type) {
        XeroAccount xeroAcc = new XeroAccount();

        xeroAcc.Code = acc.Account_Number__c;
        xeroAcc.Name = acc.Name;
        xeroAcc.Type = type;
        return xeroAcc;
    }

    //Contacts
    public static XeroContact mapContact(String name) {
        XeroContact xeroCont = new XeroContact();

        xeroCont.Name = name;
        return xeroCont;
    }

    public static XeroContact mapContact(Account acc) { 
        XeroContact xeroCont = new XeroContact(); 

        xeroCont.Name = acc.Name;
        xeroCont.FirstName = acc.PrimaryContact__r.FirstName;
        xeroCont.LastName = acc.PrimaryContact__r.LastName;
        xeroCont.EmailAddress = acc.PrimaryContact__r.Email;
        xeroCont.Addresses = new List<XeroAddress>();

        XeroAddress billingAddress = new XeroAddress(); 
        billingAddress.AddressType = 'POBOX';
        billingAddress.AddressLine1 = acc.BillingStreet; 
        billingAddress.City = acc.BillingCity; 
        billingAddress.PostalCode = acc.BillingPostalCode; 
        xeroCont.Addresses.add(billingAddress);

        xeroCont.CompanyNumber = acc.comp_house__Company_Number__c; 
        xeroCont.TaxNumber = acc.VAT_number__c;
        xeroCont.DefaultCurrency = 'GBP';
        xeroCont.Website = acc.Website;

        return XeroCont;
        
    }

    //Items
    public static XeroItem mapItem(Product2 prod, String COGSAccountCode, String inventoryAssetAccountCode) {
        return mapItem(prod.ProductCode, COGSAccountCode, inventoryAssetAccountCode);
    }

    public static XeroItem mapItem(String code, String COGSAccountCode, String inventoryAssetAccountCode) {
        XeroItem xeroItem = new XeroItem();
        XeroItemPurchaseDetails purchaseDetails = new XeroItemPurchaseDetails();

        xeroItem.Code = code;
        xeroItem.purchaseDetails = purchaseDetails;
        xeroItem.InventoryAssetAccountCode = InventoryAssetAccountCode;
        purchaseDetails.COGSAccountCode = COGSAccountCode;
        return xeroItem;
    }

    public static List<XeroItem> mapItems(List<String> codes, String COGSAccountCode, String inventoryAssetAccountCode) {
        List<XeroItem> result = new List<XeroItem>();

        for (String code_i : codes) {
            result.add(mapItem(code_i, COGSAccountCode, inventoryAssetAccountCode));
        }
        return result;
    }

    public static CreataXeroItemRequest mapCreataXeroItemRequest(List<XeroItem> xeroItems) {
        CreataXeroItemRequest result = new CreataXeroItemRequest();
        
        result.Items = xeroItems;
        return result;
    }

    //Quotes
    public static XeroQuote mapQuote(Order order, String currencyCode) {
        XeroQuote xeroQuote = new XeroQuote();
        XeroContact xeroContact = new XeroContact();

        xeroQuote.QuoteNumber = order.OrderNumber;
        xeroQuote.Reference = order.PoNumber; 
        xeroQuote.Contact = xeroContact;
        xeroContact.ContactID = order.Account.XeroContactId__c;        
        xeroQuote.LineItems = mapXeroQuoteLineItems(order.OrderItems);
        xeroQuote.XeroDate = mapDate(order.EffectiveDate);
        xeroQuote.CurrencyCode = currencyCode;
        xeroQuote.Total = order.TotalAmount;
        xeroQuote.Status = 'ACCEPTED';
        return xeroQuote;
    }

    public static List<XeroQuoteLineItems> mapXeroQuoteLineItems(List<OrderItem> items) {
        List<XeroQuoteLineItems> xeroItems = new List<XeroQuoteLineItems>();

        for (OrderItem item_i : items) {
            xeroItems.add(mapXeroQuoteLineItem(item_i));
        }
        return xeroItems;
    }

    public static XeroQuoteLineItems mapXeroQuoteLineItem(OrderItem orderItem) {
        XeroQuoteLineItems xeroItem = new XeroQuoteLineItems();
        
        xeroItem.Description = orderItem.Product2.Name; 
        //xeroItem.ItemCode = orderItem.Product2.ProductCode;
        xeroItem.ItemCode = orderItem.Product2.Product_Code_CSA__c;
        xeroItem.Quantity = orderItem.Quantity;
        xeroItem.UnitAmount = orderItem.SBQQ__QuotedListPrice__c ; //orderItem.SBQQ__QuoteLine__r.SBQQ__ListTotal__c;
        xeroItem.DiscountRate = orderItem.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c;

        return xeroItem;
    }

    public static CreataXeroQuotesRequest mapCreataXeroQuotesRequest(XeroQuote quote) {
        return mapCreataXeroQuotesRequest(new List<XeroQuote>{quote});
    }

    public static CreataXeroQuotesRequest mapCreataXeroQuotesRequest(List<XeroQuote> quotes) {
        CreataXeroQuotesRequest request = new CreataXeroQuotesRequest();

        request.Quotes = quotes;
        return request;
    }

    //Other
    public static String mapDate(DateTime dateTime1) {
        return dateTime1.format('yyyy-MM-dd');
    }
}