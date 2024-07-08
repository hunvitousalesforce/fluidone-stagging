public class MidasOrderApiServiceHelper {
    public static String accessToken;
    public static String refreshToken;
    public static boolean doAccessToken = false;
    
    public static Dimensions_API_Credentials__c getApiCredentials(){
        // String apiCredentialsName = [Select IsSandbox From Organization].IsSandbox ? 'Sandbox' : 'Production'; removed this logic on Nov 23 based on Email from Thomas to Henry
        return [SELECT Id,End_Point_URL__c,UserId__c,Account_Code__c,Email__c,Password__c, Midas_API_URL__c , 
                Access_Token__c,Refresh_Token__c , Auth_API_URL__c , CPQ_API_URL__c , Dimension_API_URL__c , OrderManagement_API_URL__c, Opportunity_Route__c
                FROM Dimensions_API_Credentials__c  LIMIT 1]; /*WHERE Name =:apiCredentialsName*/
    }
    
    public static Dimensions_API_Credentials__c getAccessToken(){
        Dimensions_API_Credentials__c apiCredentials = getApiCredentials();
        
        String loginUrl = apiCredentials.End_Point_URL__c+ apiCredentials.Auth_API_URL__c +'token/login';
        String refreshUrl = apiCredentials.End_Point_URL__c+ apiCredentials.Auth_API_URL__c +'token/refresh';
        
        Http http = new Http(); 
        HttpRequest request = new HttpRequest();  
        boolean isAccessTokenApiCall = false;
        if(String.isBlank(apiCredentials.Access_Token__c) || doAccessToken){
            request.setEndpoint(loginUrl);
            MidasOrderApiServiceWrappers.CredentialsBody body = new MidasOrderApiServiceWrappers.CredentialsBody();
            body.AccountCode = apiCredentials.Account_Code__c;
            body.Email = apiCredentials.Email__c;
            body.Password = apiCredentials.Password__c;
            String jsonBody = JSON.serialize(body);
            request.setBody(jsonBody);
            isAccessTokenApiCall = true;
        }else{
            request.setEndpoint(refreshUrl);
            request.setBody('{"RefreshToken": "'+apiCredentials.Refresh_Token__c+'","UserId": '+apiCredentials.UserId__c+'}');
        }
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json'); 
        request.setTimeout(120000);
        
        Integer calloutAttempts = 0;
        
        HttpResponse response;
        
        do{
            Integer calloutAttempted = Limits.getCallouts(); 
            if(calloutAttempted >= 100) break;
            
            response = http.send(request); 
        } while (response.getStatusCode() != 200 && calloutAttempts++ < 10);
        
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if(isAccessTokenApiCall){
                Map<String, Object> bearer = (Map<String, Object>) results.get('bearerToken');
                Map<String, Object> loginInfo = (Map<String, Object>) results.get('loginInfo');
                Integer userIdNumber = (Integer)loginInfo.get('userId');
                accessToken = (String) bearer.get('access_token');
                refreshToken = (String) bearer.get('refresh_token');
                apiCredentials.Access_Token__c = accessToken;
                apiCredentials.Refresh_Token__c = refreshToken;
                apiCredentials.UserId__c = String.valueOf(userIdNumber);
            }else{
                accessToken = (String) results.get('access_token');
                refreshToken = (String) results.get('refresh_token');
                apiCredentials.Access_Token__c = accessToken;
                apiCredentials.Refresh_Token__c = refreshToken;
            }
        }else{
            if(!isAccessTokenApiCall && !doAccessToken){ 
                doAccessToken = true;
                apiCredentials = getAccessToken();
                doAccessToken = false;
            }
        }
        
        return apiCredentials;        
    }
    
    public static HttpResponse callMidasApi (String endpoint, String method, String jsonBody) {
        Dimensions_API_Credentials__c apiCredentials = getApiCredentials();
        String accessToken = apiCredentials.Access_Token__c;
        
        if(String.isBlank(accessToken)){
            apiCredentials = getAccessToken();
            accessToken = apiCredentials.Access_Token__c;
        }
        
        HttpResponse response = doCall(endpoint, method, jsonBody, accessToken);
        System.debug('response:: '+response);
        return response;  
    }
    
    public static HttpResponse callMidasApiBasicAuth (String endpoint, String method, String jsonBody) {        
        Dimensions_API_Credentials__c apiCredentials = getApiCredentials();        
	    HttpResponse response = doCallBasicAuth(endpoint, method, jsonBody, apiCredentials.Email__c, apiCredentials.Password__c);
        System.debug('response:: '+response);
        return response;  
    }
    
    public static HttpResponse doCall(String endpoint, String method, String jsonBody, String accessToken){
        Http http = new Http(); 
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint(endpoint);
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setMethod(method);
        request.setTimeOut(120000);
        request.setBody('');
        request.setHeader('Content-Type', 'application/json');
        
        Dimensions_API_Credentials__c updatedApiCredentials;
        Boolean invalidAccessToken = false;
        Integer calloutAttempts = 0;
        
        HttpResponse response;
        
        
        response = http.send(request);   
        
        if(response.getStatusCode() == 401 || response.getStatus() == 'Unauthorized'){
            invalidAccessToken = true;
            updatedApiCredentials = getAccessToken();
            accessToken = updatedApiCredentials.Access_Token__c;
            response = doCall(endpoint, method, jsonBody,accessToken);
        }
        
        if(invalidAccessToken){
            System.enqueueJob(new UpdateApiCredentials(updatedApiCredentials));
        }
        
        system.debug('====response=='+ response); 
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
    
    // jamesgoode@fluidone.com - HTTP call with basic auth
    public static HttpResponse doCallBasicAuth(String endpoint, String method, String jsonBody, String userName, String password) {
        
        String authentication = userName + ':' + password;
        authentication = convertToBase64(authentication);               
         
        Http http = new Http(); 
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint(endpoint);
        request.setHeader('Authorization', 'CPQAuthorization ' + authentication);  
        request.setMethod(method);
        request.setTimeOut(120000);
        request.setBody('');
        request.setHeader('Content-Type', 'application/json');
                
        HttpResponse response = http.send(request);
        
        system.debug('====response=='+ response); 
         
        return response; 
    }
    
    // jamesgoode@fluidone.com - Convert String to Base64Encoded
    public static String convertToBase64(String inputString) {
        Blob binaryData = Blob.valueOf(inputString);        
        return EncodingUtil.base64Encode(binaryData);                
    }
    
}