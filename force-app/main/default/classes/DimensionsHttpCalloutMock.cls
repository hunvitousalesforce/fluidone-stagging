/**
 * @description       : mock class for dimensions api 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 28-12-2022
 * @last modified by  : matthew.rosete@pracedo.com
**/
global class DimensionsHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Accept', 'application/json');
        response.setHeader('Content-Type', 'application/json');        
        response.setBody(getBodyForEndpoint(req.getEndpoint(), req.getMethod()));
        response.setStatusCode(200);        
        return response; 
    }

    private string getBodyForEndpoint(String endpoint, String method){
        if (endpoint.contains('accounts') && method == 'GET') {
            return '{}';
        } else if (endpoint.contains('accounts') && method == 'POST') {
            return '{"id":61618,"code":"PRA001","registeredCompanyName":"PRACEDO TEST TEST NIGHT","companyRegistrationNumber":"2231","vatNumber":"820 7250 50","address":"Selfie Wealth Ltd\r\n17 Carlisle Street","town":"London","county":"London","postcode":"W1X VMG","countryCode":"GB","telephone":"","fax":"","contactFullName":"Matt Rosete","invoiceEmail":"luca.anzaghi@pracedo.com","accountManager":null,"relationshipType":"DIRECT","approved":false,"msaSigned":false,"stepInRights":false,"createdOn":"2022-11-02T23:46:58.307","modifiedOn":"0001-01-01T00:00:00"}';
        } else if (endpoint.contains('stocks') && method == 'GET') {
            return '{}';
        } else if (endpoint.contains('orders') && method == 'POST') {
            return '{}';
        } else if (endpoint.contains('orders') && method == 'GET') {
            return '{}';
        } else if (endpoint.contains('token') && method == 'POST') {
            return '{}';
        } else {
            return '{}';
        } 
     }


}