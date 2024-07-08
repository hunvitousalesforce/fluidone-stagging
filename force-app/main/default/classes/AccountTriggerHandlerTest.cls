/**
* @description       : 
* @author            : matthew.rosete@pracedo.com
* @group             : 
* @last modified on  : 09-08-2023
* @last modified by  : marco.tibaldi.ext@pracedo.com
**/
@IsTest
public class AccountTriggerHandlerTest {
    
    @TestSetup
    static void makeData(){
        List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx')
        };
        insert apiCredentials; 
        Account acc = new Account(
            CreateInXero__c = false,
            Account_Number__c = 'Test',
            Name = 'Test',
            Division_Source__c = 'CSA',
            VAT_number__c = 'GB'
        );
        insert acc;
        
        Account dimensionsAccount = new Account(
            CreateInAccessDimensions__c = false, 
            Account_Number__c = '12345',
            Name = 'Dimensions Test Account',
            comp_house__Company_Number__c = '12331',
            VAT_number__c = '23131',
            BillingCity = 'London',
            BillingCountry = 'test',
            BillingState = 'TestState',
            BillingPostalCode = 'UBT TLS',            
            BillingStreet = 'Test Street',                        
            Phone = '213213',
            Fax = '213123',                        
            Type = 'Direct',
            Division_Source__c = 'CSA',
            Account_Type__c = 'Wholesale'
        );
        
        insert dimensionsAccount;
        
        Contact dimensionsContact = new Contact (
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'test@test.com',
            Account = dimensionsAccount
        );
        
        insert dimensionsContact; 
        
        dimensionsAccount.PrimaryContact__c = dimensionsContact.Id;
        dimensionsAccount.Billing_Contact__c = dimensionsContact.Id;
        update dimensionsAccount;
        
    }
    
    @isTest 
    static void createDimensionsAccountTest() {
        Account acc = [SELECT Id, CreateInAccessDimensions__c FROM Account WHERE Name = 'Dimensions Test Account' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionAccountApiMock());
        acc.CreateInAccessDimensions__c = true;
        acc.VAT_number__c = 'GB';
        update acc;
        Test.stopTest();   
        
        acc = [SELECT Id, AccessApprovalStatus__c, AccessDimensionsId__c, Account_Type__c 
               FROM Account 
               WHERE Name = 'Dimensions Test Account' LIMIT 1];
        
        system.Assert(acc.AccessApprovalStatus__c == 'Pending Approval');
        system.Assert(acc.AccessDimensionsId__c == 'TestValue');
        
        System.assert(acc.Account_Type__c == 'Wholesale');
        System.assert(AccountTriggerHandler.accountBody.contains('"RelationshipType":"Wholesale"'),
                      'Expected "RelationshipType":"Wholesale" to be in accountBody, but was not found');
    }
    
    @IsTest 
    static void createXeroContactsTest() {
        Account acc = [SELECT Id, CreateInXero__c FROM Account WHERE Name = 'Test' LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        acc.CreateInXero__c = true;
        update acc;
        Test.stopTest();
        acc = [SELECT Id, CreateInXero__c,XeroContactId__c FROM Account WHERE Name = 'Test' LIMIT 1];
        system.Assert(acc.XeroContactId__c != null);
    }
    @IsTest 
    static void createXeroContactsTests() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        Map<Id , Account>  oldMapAccount = new Map<Id , Account> ([SELECT Id, CreateInXero__c,Account_Number__c,Name FROM Account WHERE Name = 'Test' LIMIT 1]);
        system.debug('MAP--->'+oldMapAccount.values());
      
        List<Account> lstAcc = new List<Account>();
        for(Account objAcc : oldMapAccount.values()){
            Account acc = new Account();
            acc.Id = objAcc.Id;
            acc.CreateInXero__c = true;
            acc.Account_Number__c = '1234567890';
            acc.Name = 'Test';
            lstAcc.add(acc);
        }
        update lstAcc;
        system.debug('LIST--->'+lstAcc);
        
        AccountTriggerHandler.createXeroAccounts(lstAcc, oldMapAccount);
        Test.stopTest();
        Account acc = [SELECT Id, CreateInXero__c,XeroAccountId__c,Name FROM Account WHERE Name = 'Test' LIMIT 1];
        system.Assert(acc.XeroAccountId__c != null);
    }
}