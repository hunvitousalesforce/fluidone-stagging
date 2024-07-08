@isTest
global class AccessDimensionsProductsBatchCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        String jsonBody = '{"data":[{"description":"test 1","code":"Test","cost":10},{"description":"test 2","cost":10}]}';
        response.setBody(jsonBody);
        response.setStatusCode(200);
        
        return response; 
    }
}