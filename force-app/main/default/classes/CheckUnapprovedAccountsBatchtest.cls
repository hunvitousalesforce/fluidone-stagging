@isTest
public with sharing class CheckUnapprovedAccountsBatchtest {
    @TestSetup
    static void makeData(){
        Contact c = TestDataUtil.createContact('Test');
		insert c;          
        List<Account> accounts = new List<Account>();
        Account acc = TestDataUtil.createAccount('Test x1');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInAccessDimensions__c = true;
        acc.AccessDimensionsId__c = 'Test x1';
        acc.Division_Source__c = 'FluidOne';
        acc.VAT_number__c = 'GB';
        accounts.add(acc) ;
        Account acc1 = TestDataUtil.createAccount('x Test x2');
        acc1.CreateInAccessDimensions__c = true;
        acc1.AccessDimensionsId__c = 'Test x2';
        acc1.Division_Source__c = 'CSA';
        acc1.AccessApprovalStatus__c = 'Approved';
        acc1.VAT_number__c = 'GB';
        accounts.add(acc1) ;
        insert accounts;
        
        List<Dimensions_API_Credentials__c> apiCredentials = new List<Dimensions_API_Credentials__c>{
            new Dimensions_API_Credentials__c(Name='Sandbox',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx'),
            new Dimensions_API_Credentials__c(Name='Production',End_Point_URL__c = 'https://api.fluidone.com/',UserId__c='xx',Account_Code__c='xx',Email__c='xx@xx.com',Password__c='xx')
        };
        insert apiCredentials;    
        
    }
    @isTest
    static void testMethod1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionAccountApiMock());
        Database.executeBatch(new CheckUnapprovedAccountsBatch());
        Test.stopTest();
        List<CalloutLog__c> CalloutLogs = [SELECT Id FROM CalloutLog__c];
        system.Assert(CalloutLogs.size() == 1);
        List<Account> accounts = [SELECT ID,Name FROM Account WHERE AccessApprovalStatus__c = 'Approved'];
        system.Assert(accounts.size() == 2);

    }
    @isTest
    static void schedulerTest(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new DimensionApiMock.DimensionAccountApiMock());
        new CheckUnapprovedAccountsScheduler().execute(null);
        test.stopTest();
    }
}