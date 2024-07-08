@isTest
public class CheckXeroContactsBatchTest {
	@TestSetup
    static void makeData(){
        Contact c = TestDataUtil.createContact('Test');
		insert c;          
        
        Account acc = TestDataUtil.createAccount('Test');
        acc.Billing_Contact__c = c.Id;
        acc.CreateInXero__c = false;
        acc.VAT_number__c = 'GB';
        acc.Division_Source__c = 'FluidOne';
        acc.XeroContactId__c = '33ff2e28-e816-4a4c-811d-444fd971d34f';
        insert acc;
    }
    @isTest
    static void schedulerMethod(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        new CheckXeroContactsScheduler().execute(null);
        test.stopTest();
        
    }
}