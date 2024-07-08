/**
 * @description       : Provides generic methods to call the dimensions API 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 27-10-2022
 * @last modified by  : matthew.rosete@pracedo.com
**/
public with sharing class DimensionsAPIHelper { 

    /*public static HttpResponse callDimensionsApi (String endpoint, String method, String jsonBody) {
        
        System.debug('Endpoint ==> ' + endpoint);
        System.debug('Method ==> ' + method);
        System.debug('JSON ==> ' + jsonBody);

        //Replace with getting refresh token instead of getting an access token every single time
        String accessToken = DimensionsAPIAuthHelper.getAccessToken();
        System.debug('Access Token ==> ' + accessToken);
        
        Http http = new Http(); 
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint(endpoint);
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setMethod(method);
        if (method == 'POST') {
            request.setBody(jsonBody);
        }
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        HttpResponse response = http.send(request);         
        System.debug(response);
        System.debug('response body:: '+response.getBody());
        if (response.getStatusCode() == 200) {
            
            return response; 
        } 
        return response;            
    }*/
    public static HttpResponse callDimensionsApi (String endpoint, String method, String jsonBody) {
        
        System.debug('Endpoint ==> ' + endpoint);
        System.debug('Method ==> ' + method);
        System.debug('JSON ==> ' + jsonBody);
        DimensionsAPIAuthHelper.setApiCredentials();
        //Replace with getting refresh token instead of getting an access token every single time
        String accessToken = DimensionsAPIAuthHelper.apiCredentials.Access_Token__c;
        if(String.isBlank(accessToken)){
            accessToken = DimensionsAPIAuthHelper.getAccessToken();
        }
        HttpResponse response = DimensionsAPIHelper.doCall(endpoint, method, jsonBody,accessToken,0);
        System.enqueueJob(new UpdateApiCredentials(DimensionsAPIAuthHelper.apiCredentials));
        return response;  
        
    }
    public static HttpResponse doCall(String endpoint, String method, String jsonBody, String accessToken,Integer count){
        System.debug('Access Token ==> ' + accessToken);
        Http http = new Http(); 
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint(endpoint);
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setMethod(method);
        if (method == 'POST') {
            request.setBody(jsonBody);
        }
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        HttpResponse response = http.send(request);         
        System.debug(response);
        System.debug('response body:: '+response.getBody());
        System.debug('response STATUS:: '+response.getStatusCode());
        if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
            return response; 
        }else if(response.getStatusCode() == 401 || response.getStatus() == 'Unauthorized' || (String.isBlank(response.getBody()) && count == 0)){
            accessToken = DimensionsAPIAuthHelper.getAccessToken();
            //update CS with access and refresh token
            response = DimensionsAPIHelper.doCall(endpoint, method, jsonBody,accessToken,1);
        } 
        return response; 
    }
    public class UpdateApiCredentials implements Queueable, Database.AllowsCallouts {
        public Dimensions_API_Credentials__c apiCredentials;
        public UpdateApiCredentials(Dimensions_API_Credentials__c apiCredentials){
            this.apiCredentials = apiCredentials;
        }
        public void execute(QueueableContext context) {
            update apiCredentials;
        }
    }
}