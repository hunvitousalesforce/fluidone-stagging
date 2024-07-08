@IsTest
public class CheckXeroAccountBatchTest {

    private static final String XERO_ACCOUNT_ID = 'd1c54f04-6fc7-4f39-9d86-0f5049d2bb03';

    @TestSetup
    static void makeData(){
        Account acc = new Account(
            Name = 'Test',
            ApprovedInXero__c = false,
            XeroAccountId__c = XERO_ACCOUNT_ID,
            Division_Source__c = 'CSA',
            VAT_number__c = 'GB'

        );

        insert acc;
    }
    
    @IsTest 
    static void test() {
        Test.startTest();
        XeroCalloutMock mock = new XeroCalloutMock();
        mock.setXeroObjectId(XERO_ACCOUNT_ID);
        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new CheckXeroAccountBatch(), 1);
        Test.stopTest();
    }
    @isTest
    static void schedulerMethod(){
        test.startTest();
        XeroCalloutMock mock = new XeroCalloutMock();
        mock.setXeroObjectId(XERO_ACCOUNT_ID);
        Test.setMock(HttpCalloutMock.class, mock);
        new CheckXeroAccountScheduler().execute(null);
        test.stopTest();
        
    }
}