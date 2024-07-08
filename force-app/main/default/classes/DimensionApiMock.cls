@isTest
public class DimensionApiMock {
    
    /*
    public class DimensionOrderApiRejectMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HTTpResponse response = new HTTPResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{}');
            if(request.getEndpoint().contains('https://api.fluidone.com/Auth/api/token/login')){
                response.setBody('{"bearerToken":{"access_token":"","refresh_token":""},"loginInfo":{}}');
            }else if(request.getEndpoint().contains('https://api.fluidone.com/Dimensions/api/orders')){
                response.setBody('{"linkedContractNumber":"test","status":4}');
            }
            return response;
        }
    }
	*/
    
    public class DimensionOrderApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HTTpResponse response = new HTTPResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{}');
            if(request.getEndpoint().contains('token/login')){
                response.setBody('{"bearerToken":{"access_token":"","refresh_token":""},"loginInfo":{}}');
            }else if(request.getEndpoint().contains('orders')){
                response.setBody('{"linkedContractNumber":"test","status":3,"activatedOn":"2023-01-01 01:01:00"}');
            }
            return response;
        }
    }
    public class DimensionAccountApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HTTpResponse response = new HTTPResponse();
            if(request.getEndpoint().contains('token/login')){
                response.setStatusCode(200);
                response.setStatus('OK');
                response.setBody('{"bearerToken":{"access_token":"","refresh_token":""},"loginInfo":{}}');
            }else if(request.getEndpoint().contains('accounts')){
                response.setStatusCode(200);
                response.setStatus('OK');
                response.setBody('{"id":"TestValue","approved":true,"onStop":true,"code":"test"}');
            }
            return response;
        }
    }
    public class DimensionStockApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HTTpResponse response = new HTTPResponse();
            if(request.getEndpoint().contains('token/login')){
                response.setStatusCode(200);
                response.setStatus('OK');
                response.setBody('{"bearerToken":{"access_token":"","refresh_token":""},"loginInfo":{}}');
            }else if(request.getEndpoint().contains('stocks')){
                response.setStatusCode(200);
                response.setStatus('OK');
                response.setBody('{"data":[{"description":"test 1","code":"Test","cost":10},{"description":"test 2","cost":10}]}');
            }
            return response;
        }
    }
}