public class DimensionOrderApiMockInvalid {
   
    public class DimensionOrderApiMockInvalidTest implements HttpCalloutMock {
         Boolean  isMockResponseSuccessful;  // set by constructor, used to vary the mockresponse

    public DimensionOrderApiMockInvalidTest(Boolean isMockResponseSuccessful) {
    this.isMockResponseSuccessful  = isMockResponseSuccessful;
  }
        public HTTPResponse respond(HTTPRequest request){
            HTTpResponse response = new HTTPResponse();
            if(this.isMockResponseSuccessful){
                if(request.getEndpoint().contains('https://api.fluidone.com/Auth/api/token/login')){
                    response.setStatusCode(200);
                    response.setStatus('OK');
                    response.setBody('{"bearerToken":{"access_token":""}}');
                }else if(request.getEndpoint().contains('https://api.fluidone.com/Dimensions/api/orders')){
                    response.setStatusCode(200);
                    response.setStatus('OK');
                    response.setBody('{"linkedContractNumber":"test","status":4}');
                }
                else{
                    response.setStatusCode(400);
                    response.setStatus('Bad request');
                }
            }
            return response;
        }
    }

}