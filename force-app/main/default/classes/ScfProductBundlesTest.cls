/**
 * @description Test unit for cover code in scfProductBundles class
 * @createdDate 10-June-2024
 */
@isTest 
private class ScfProductBundlesTest {
    
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
    static void testMassLoad() {
        Test.startTest();
        String productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        Map<String, Object> mapResult = ScfProductBundles.massLoad(productId);       
        Test.stopTest();
        List<ScfProductBundles.LineItemRecord> items = (List<ScfProductBundles.LineItemRecord>)mapResult.get('lineItems');
        System.assertEquals(true, items.size() > 0);

    }
}