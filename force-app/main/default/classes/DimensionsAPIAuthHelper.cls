public with sharing class DimensionsAPIAuthHelper {
    public static String accessToken;
    public static String refreshToken;
    public static Dimensions_API_Credentials__c apiCredentials;
    public static void setApiCredentials(){
        if(apiCredentials == null){
            /*Boolean isSandbox = [Select IsSandbox From Organization].IsSandbox;
            String apiCredentialsName = 'Production';
            if(isSandbox){
                apiCredentialsName = 'Sandbox';
            }*/
            apiCredentials  = [
                    SELECT Id,End_Point_URL__c,UserId__c,Account_Code__c,Email__c,Password__c,Access_Token__c,Refresh_Token__c FROM Dimensions_API_Credentials__c /*WHERE Name =:apiCredentialsName*/ LIMIT 1
            ];
        }
        
    }
    public static String getAccessToken(){
        //String accessToken;
        setApiCredentials();
        //DimensionsAPICredentials__c apiCredentials = DimensionsAPICredentials__c.getOrgDefaults();
        
        System.debug(apiCredentials);
        Http http = new Http(); 
        HttpRequest request = new HttpRequest();  
        boolean isAccessTokenApiCall = false;
        if(String.isBlank(apiCredentials.Access_Token__c)){
        	request.setEndpoint(apiCredentials.End_Point_URL__c+'Auth/api/token/login');
            CredentialsBody body = new CredentialsBody (
                apiCredentials.Account_Code__c, 
                apiCredentials.Email__c, 
                apiCredentials.Password__c
            );
            String jsonBody = JSON.serialize(body);
            request.setBody(jsonBody);
            isAccessTokenApiCall = true;
        }else{
        	request.setEndpoint(apiCredentials.End_Point_URL__c+'Auth/api/token/refresh');
            request.setBody('{"RefreshToken": "'+apiCredentials.Refresh_Token__c+'","UserId": '+apiCredentials.UserId__c+'}');
        }
        
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json'); 
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);  
        system.debug('===response====='+ response);
        system.debug('===response.getBody()====='+ response.getBody());
        if (response.getStatusCode() == 200) {
            system.debug('===response.getBody()====='+ response.getBody());
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            system.debug('===results====='+ results);
            if(isAccessTokenApiCall){
                Map<String, Object> bearer = (Map<String, Object>) results.get('bearerToken');
                Map<String, Object> loginInfo = (Map<String, Object>) results.get('loginInfo');
                
                system.debug('===results====='+ results.keySet());
                system.debug('===results====='+ results.get('loginInfo'));
                system.debug('===bearer====='+ bearer);
                accessToken = (String) bearer.get('access_token');
                refreshToken = (String) bearer.get('refresh_token');
                apiCredentials.Access_Token__c = accessToken;
                apiCredentials.Refresh_Token__c = refreshToken;
                apiCredentials.UserId__c = (String) loginInfo.get('userId');
            }else{
                accessToken = (String) results.get('access_token');
                refreshToken = (String) results.get('refresh_token');
                apiCredentials.Access_Token__c = accessToken;
                apiCredentials.Refresh_Token__c = refreshToken;
            }
            
            //Map<String, Object> bearerToken = (Map<String, Object>) JSON.deserializeUntyped(results.get('bearerToken'));
            //System.debug(results.get('bearerToken').get('access_token'));
            //Map<String, Object> bearerToken = (Map<String, Object>) JSON.deserializeUntyped(results.get('bearerToken'));
			//accessToken = String.valueOf(bearer.get('access_token'));        
        }
        return accessToken;        
    }

    public class CredentialsBody {
        public String AccountCode; 
        public String Email; 
        public String Password;

        public credentialsBody(String accountCode, String email, String password) {
            this.AccountCode = accountCode; 
            this.Email = email; 
            this.Password = password;
        }
    }
    
}