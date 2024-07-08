@isTest
public class TestDataUtil {
    public static Contact createContact(String name){
        Contact c = new Contact (
        	FirstName = name+' First Name', 
            LastName = name+' Last Name', 
            Email = 'test@test.com'
        );
        return c;
    }
    public static Account createAccount(String name){
        Account acc = new Account(
            Name = name
        );
        return acc;
    }
    public static Opportunity createOpportunity(String accountId,String name){
        Opportunity oppt = new Opportunity(
            AccountId = accountId,
            Name = name,
            Forecast_Status__c = 'Closed',
            StageName = 'Closed Won',
            CloseDate = System.today() + 3,
            SBQQ__Contracted__c = true,
            N_A_Billing_Account__c = true,
            N_A_Contract_Account__c = true
        );
        return oppt;
    }
    public static Product2 createProduct(String productName){
        Product2 prod = new Product2(
            Name = productName,
            ProductCode = 'Test',
            Product_Code_CSA__c = 'Test'
        );
        return prod;
    }
    public static SBQQ__Quote__c createQuote(Id accountId,Id OpportunityId){
        SBQQ__Quote__c sbqqQuote = new SBQQ__Quote__c(
            SBQQ__LineItemsGrouped__c = true,
            SBQQ__Primary__c = true,
            SBQQ__Account__c = accountId,
            SBQQ__BillingCity__c = 'Hyderabad',
            SBQQ__BillingCountry__c = 'India',
            SBQQ__Key__c = '1233',
            ApprovalStatus__c = 'Approved',
            SBQQ__Ordered__c = true,
            SBQQ__Type__c = 'Qoute',
            SBQQ__Opportunity2__c = OpportunityId,
            Order_Form_Signed__c =true
        );
        return sbqqQuote;
    }
}