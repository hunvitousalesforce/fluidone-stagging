/**
 * @description Unit test cover code in scfProductHierarchy class
 * @createdDate 10-June-2024
 */
@isTest
private class ScfProductHierarchyTest {
   

    @TestSetup
    static void setupData(){
        // create product
        Product2 prod = new Product2(
            Name = 'Product1',
            ProductCode = 'Test',
            Product_Code_CSA__c = 'Test',
            Parent_Product__c = true,
            IsActive=true
        );
        insert prod;

        // create product option
        SBQQ__ProductOption__c productOpt = new SBQQ__ProductOption__c();
        productOpt.SBQQ__ConfiguredSKU__c = prod.Id;
        productOpt.SBQQ__Number__c = 123;
        productOpt.SBQQ__OptionalSKU__c = prod.Id;
        insert productOpt;
        
    }

    @isTest 
    static void testFetchRecords() {
        Test.startTest();
        SBQQ__ProductOption__c productOpt = [SELECT Id, SBQQ__ConfiguredSKU__c FROM SBQQ__ProductOption__c LIMIT 1];
        ScfProductHierarchy.SearchWrapper searchWrapper = new ScfProductHierarchy.SearchWrapper();
        searchWrapper.objectApiName = 'Product2';
        searchWrapper.fieldApiName='Name';
        searchWrapper.otherFieldApiName = 'ProductCode'; 
        searchWrapper.searchString = 'test';        
        searchWrapper.selectedRows = new String[]{productOpt.Id};      

        Map<String, Object> mapResult = ScfProductHierarchy.fetchRecords(searchWrapper, true);       
        Map<String, Object> dto = (Map<String, Object>) mapResult.get('dto');
        Set<String> productIds = dto.keySet();           
        Test.stopTest();
        System.assertEquals(true, productIds.contains(productOpt.SBQQ__ConfiguredSKU__c));

    }
}