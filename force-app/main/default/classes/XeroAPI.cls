//Test: XeroAPITest
public with sharing class XeroAPI {

    public static final String HTTP_METHOD_PUT = 'PUT';
    public static final String HTTP_METHOD_POST = 'POST';
    public static final String HTTP_METHOD_GET = 'GET';
    public static final String HTTP_METHOD_DELETE = 'DELETE';

    public static final String RESOURCE_ACCOUNTS = 'Accounts';
    public static final String RESOURCE_CONTACTS = 'Contacts';
    public static final String RESOURCE_ITEMS = 'Items';
    public static final String RESOURCE_QUOTES = 'Quotes';

    public static final String FIELD_NAME = 'Name';
    public static final String FIELD_CODE = 'Code';

    //Accounts
    public static AccountsResponse createAccount(XeroObjects.XeroAccount account) {
        String body = XeroUtils.generateJsonBodyStringWihoutNull(account);
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_PUT, RESOURCE_ACCOUNTS, body);

        XeroObjects.XeroAccountsApiResponse apiResponse = (XeroObjects.XeroAccountsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroAccountsApiResponse.class);

        AccountsResponse response = mapAccountsResponse(apiResponse);
        return response;
    }
    
    public static AccountsResponse getAccount(String xeroAccountId) {
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_GET, XeroUtils.buildPathById(RESOURCE_ACCOUNTS, xeroAccountId));

        XeroObjects.XeroAccountsApiResponse apiResponse = (XeroObjects.XeroAccountsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroAccountsApiResponse.class);

        AccountsResponse response = mapAccountsResponse(apiResponse);
        return response;
    }

    public static ContactsResponse getContactNew(String xeroContactId) {
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_GET, XeroUtils.buildPathById(RESOURCE_CONTACTS, xeroContactId));

        XeroObjects.XeroContactsApiResponse apiResponse = (XeroObjects.XeroContactsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroContactsApiResponse.class);

        ContactsResponse response = mapContactsResponse(apiResponse);
        return response;
    }

    //Contacts
    public static ContactsResponse createContact(XeroObjects.XeroContact contact) {
        String body = XeroUtils.generateJsonBodyStringWihoutNull(contact);
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_PUT, RESOURCE_CONTACTS, body); 

        XeroObjects.XeroContactsApiResponse apiResponse = (XeroObjects.XeroContactsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroContactsApiResponse.class);

        ContactsResponse response = mapContactsResponse(apiResponse);
        return response;
    }

    public static ContactsResponse createOrUpdateContact(XeroObjects.XeroContact contact) {
        String body = XeroUtils.generateJsonBodyStringWihoutNull(contact);
        system.debug('==body==='+ body);
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_POST, RESOURCE_CONTACTS, body); 
		system.debug('==httpResponse==='+ httpResponse);
        XeroObjects.XeroContactsApiResponse apiResponse = (XeroObjects.XeroContactsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroContactsApiResponse.class);
		system.debug('==apiResponse==='+ apiResponse);
        ContactsResponse response = mapContactsResponse(apiResponse);
        return response;
    }

    public static ContactsResponse getContactByName(String name) {
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_GET, XeroUtils.buildWhere(RESOURCE_CONTACTS, XeroUtils.buildWhereParams(FIELD_NAME, name))); 

        XeroObjects.XeroContactsApiResponse apiResponse = (XeroObjects.XeroContactsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroContactsApiResponse.class);

        ContactsResponse response = mapContactsResponse(apiResponse);
        return response;
    }

    //Items
    public static ItemsResponse getItemsByCode(List<String> codes) {
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_GET, XeroUtils.buildWhere(RESOURCE_ITEMS, XeroUtils.buildWhereParams(FIELD_CODE, '||', codes))); 

        XeroObjects.XeroItemsApiResponse apiResponse = (XeroObjects.XeroItemsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroItemsApiResponse.class);

        ItemsResponse response = mapItemsResponse(apiResponse);
        return response;
    }

    public static ItemsResponse createItems(List<XeroObjects.XeroItem> items) {
        String body = XeroUtils.generateJsonBodyStringWihoutNull(XeroObjects.mapCreataXeroItemRequest(items));
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_PUT, RESOURCE_ITEMS, body); 

        XeroObjects.XeroItemsApiResponse apiResponse = (XeroObjects.XeroItemsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroItemsApiResponse.class);

        ItemsResponse response = mapItemsResponse(apiResponse);
        return response;
    }

    public static ItemsResponse createOrUpdateItems(List<XeroObjects.XeroItem> items) { 
        String body = XeroUtils.generateJsonBodyStringWihoutNull(XeroObjects.mapCreataXeroItemRequest(items));
        system.debug('=====body===='+ body);
        system.debug('=====HTTP_METHOD_POST===='+ HTTP_METHOD_POST);
        system.debug('=====RESOURCE_ITEMS===='+ RESOURCE_ITEMS);
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_POST, RESOURCE_ITEMS, body); 
        system.debug('=====httpResponse===='+ httpResponse);
		system.debug('=====httpResponse===='+ httpResponse.getBody());
        XeroObjects.XeroItemsApiResponse apiResponse = (XeroObjects.XeroItemsApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroItemsApiResponse.class);
		system.debug('=====apiResponse===='+ apiResponse);
        ItemsResponse response = mapItemsResponse(apiResponse);
        system.debug('=====ItemsResponse===='+ response);
        return response;
    }

    //Quotes
    public static QuotesResponse createQuote(XeroObjects.XeroQuote quote) {
        String body = XeroUtils.generateJsonBodyStringWihoutNull(XeroObjects.mapCreataXeroQuotesRequest(quote));
        HttpResponse httpResponse = XeroCalloutService.executeCallout(HTTP_METHOD_PUT, RESOURCE_QUOTES, body); 

        XeroObjects.XeroQuotesApiResponse apiResponse = (XeroObjects.XeroQuotesApiResponse) XeroUtils.parseBody(httpResponse, XeroObjects.XeroQuotesApiResponse.class);
     
        QuotesResponse response = mapQuotesResponse(apiResponse);
        return response;
    }

    private static AccountsResponse mapAccountsResponse(XeroObjects.XeroAccountsApiResponse apiResponse) {
        AccountsResponse response = new AccountsResponse();

        mapResponse(response, apiResponse);
        response.accounts = apiResponse.Accounts;
        return response;
    }

    private static ContactsResponse mapContactsResponse(XeroObjects.XeroContactsApiResponse apiResponse) {
        ContactsResponse response = new ContactsResponse();

        mapResponse(response, apiResponse);
        response.contacts = apiResponse.Contacts;
        return response;
    }

    private static ItemsResponse mapItemsResponse(XeroObjects.XeroItemsApiResponse apiResponse) {
        ItemsResponse response = new ItemsResponse();

        mapResponse(response, apiResponse);
        response.items = apiResponse.Items;
        return response;
    }

    private static QuotesResponse mapQuotesResponse(XeroObjects.XeroQuotesApiResponse apiResponse) {
        QuotesResponse response = new QuotesResponse();

        mapResponse(response, apiResponse);
        response.quotes = apiResponse.Quotes;
        return response;
    }

    private static void mapResponse(Response response, XeroObjects.ApiResponse apiResponse) {
        if (apiResponse.ErrorNumber == null) {
            response.isSuccess = true;
        } else {
            response.isSuccess = false;
            response.message = apiResponse.Message;
            if (apiResponse.Elements != null && !apiResponse.Elements.isEmpty()) {
                for (XeroObjects.Element element_i : apiResponse.Elements ) {
                    if (element_i.ValidationErrors != null && !element_i.ValidationErrors.isEmpty()) {
                        response.errors = new List<String>();

                        for (XeroObjects.ValidationError error_i : element_i.ValidationErrors) {
                            response.errors.add(error_i.Message);
                        }
                    }
                }
            }
        }
    }

    public virtual class Response {
        public Boolean isSuccess {set;get;}
        public String message {set;get;}
        public List<String> errors {set;get;}
    }

    public class AccountsResponse extends Response {
        public List<XeroObjects.XeroAccount> accounts {set;get;}
    }

    public class ContactsResponse extends Response {
        public List<XeroObjects.XeroContact> contacts {set;get;}
    }
 
    public class ItemsResponse extends Response {
        public List<XeroObjects.XeroItem> items {set;get;}
    }

    public class QuotesResponse extends Response {
        public List<XeroObjects.XeroQuote> quotes {set;get;}
    }
}