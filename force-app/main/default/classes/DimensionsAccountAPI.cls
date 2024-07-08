/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 27-10-2022
 * @last modified by  : matthew.rosete@pracedo.com
**/
public with sharing class DimensionsAccountAPI {                
    public class Account {
        public String Code;
        public String HeadOfficeAccountCode; 
        public String RegisteredCompanyName;
        public String CompanyRegistrationNumber; 
        public String VATNumber;
        public AccountAddress Address;        
        public String ContactFullName; 
        public String PhoneNumber;
        public String MobileNumber; 
        public String Fax;
        public String InvoiceEmail; 
        public String AccountManagerEmail; 
        public String RelationshipType;        
    }

    public class AccountAddress {
        public String City;
        public String Country;
        public String County;
        public String Postcode; 
        public String CountryCode; 
        public String StreetNumber; 
        public String StreetName; 
        public String BuildingName; 
        public String SubBuilding;
    }

        //returns response given an endpoint and which API to call.
    public static HttpResponse createAccountInDimensions (String accountJson) {
        //CHANGE
        HttpResponse response = DimensionsAPIHelper.callDimensionsApi('https://api.fluidone.com:8443/Dimensions/api/accounts/', 'POST', accountJSON);                        
        return response;
    }
    
    public static HttpResponse getAccountInDimensionsById (String dimensionsId) {
        HttpResponse response = DimensionsAPIHelper.callDimensionsAPI('https://api.fluidone.com:8443/Dimensions/api/accounts/' + dimensionsId ,'GET', '');
        return response;
    }
    
}