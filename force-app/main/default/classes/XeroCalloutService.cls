//Test: XeroCalloutServiceTest
public with sharing class XeroCalloutService {

    public static final String XERO_NAMED_CREDENTIALS = System.Label.Xero_Named_Credentials;
    public static final String XERO_CALLOUT = 'callout:' + XERO_NAMED_CREDENTIALS + '/';
    public static final String XERO_CONNECTIONS = 'connections';
    public static final String XERO_API = 'api.xro/2.0/';
    public static final Integer TIMEOUT = 120000;
    
    public static HttpResponse executeCallout(String method, String resourceName) {
        return executeCallout(method, resourceName, null, null);
    }

    public static HttpResponse executeCallout(String method, String resourceName, String requestBody) {
        return executeCallout(method, resourceName, requestBody, null);
    }

    public static HttpResponse executeCallout(String method, String resourceName, String requestBody, Map<String, String> headers) {
        HttpRequest request = new HttpRequest();

        request.setMethod(method);
        request.setEndpoint(
            XERO_CALLOUT + 
            (resourceName.equalsIgnoreCase(XERO_CONNECTIONS) ? XERO_CONNECTIONS: XERO_API + resourceName)
        );
        request.setTimeout(TIMEOUT);
        //TODO: move header to named credentials
        request.setHeader('Xero-Tenant-Id', System.Label.Xero_Organization_Tenant_Id);

        if (headers != null && !headers.isEmpty()) {
            for (String headerKey :headers.keySet()) {
                request.setHeader(headerKey, headers.get(headerKey));
            }
        }

        if (!String.isBlank(requestBody)) {
            request.setBody(requestBody);
        }
		
        System.debug('===request==='+ request);
        System.debug('===request=endpoint=='+ request.getEndpoint());
        HttpResponse response = new Http().send(request);
        System.debug('===response=='+ response);
        System.debug('===response body=='+ response.getBody());
        return response;
    }  
}