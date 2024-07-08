@isTest
public class CheckUnapprovedAccountBatchMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HTTpResponse response = new HTTPResponse();
                response.setStatusCode(200);
                response.setStatus('OK');
                response.setBody('{"id":61627,"code":"MAR001","approved":true,"onStop":false}');
             return response;

}
}