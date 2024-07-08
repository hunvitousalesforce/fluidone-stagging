/**
 * 
 */
@isTest
private class ScfInputLookupTest {
   
    @TestSetup
    static void setupData(){
        Account acc = new Account(
                                    Account_Number__c = '123', 
                                    Name = 'Test');
        
            insert acc;

        Contact c = new Contact (
                                FirstName = 'First Name', 
                                LastName = 'test Lastname', 
                                Email = 'test@test.com',
                                AccountId = acc.Id
                            );
        insert c;

    }

    @isTest
    static void testfetchRecords() {

        Test.startTest();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE LastName = 'test Lastname' LIMIT 1];
        ScfInputLookup.SearchWrapper searchWrapper = new ScfInputLookup.SearchWrapper();
        searchWrapper.objectApiName = 'Contact';
        searchWrapper.fieldApiName='Name';
        searchWrapper.otherFieldApiName = 'Email';
        searchWrapper.searchString = 'test';      
        searchWrapper.parentFieldApiName = 'AccountId';
        searchWrapper.parentRecordId = con.AccountId;       
        searchWrapper.exclusiveIds = con.AccountId;
        List<ScfInputLookup.ResultWrapper> result = ScfInputLookup.fetchRecords(searchWrapper, true);
        Test.stopTest();
        System.assertEquals('First Name test Lastname', result[0].mainField);        

    }
}