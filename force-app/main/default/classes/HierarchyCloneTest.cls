/**
 * @description Test unit for cover code in HierachyClone class
 * @createdDate 25/June/2024
 */
@isTest
private class HierarchyCloneTest {
   
    @TestSetup
    static void setupData(){

        // create an account
        Account acc = new Account(Name='test parent Acc', Type='Dealer', Status__c='Client', Division_Source__c='CSA', VAT_number__c = 'GB');
        insert acc;      

        // create contracts
        Contract c = new Contract(
            AccountId = acc.id, 
            Status = 'Draft', 
            StartDate = Date.today(), 
            ContractTerm = 12);
        insert c;
        
        Contract con1 = new Contract(
        	AccountId=acc.id, 
            Status='Draft', 
            StartDate=Date.today(), 
            ContractTerm = 12,
        	Parent_Contract__c = c.Id);
        insert con1;
        
        Contract con2 = new Contract(
        	AccountId = acc.id, 
            Status = 'Draft', 
            StartDate = Date.today(), 
            ContractTerm = 12,
        	Parent_Contract__c = con1.Id);
        insert con2;
        
    } 

    @isTest 
    static void testHierarchyClone() {
        Test.startTest();

        String[] objIds = new String[]{};
        for (Contract obj : [SELECT Id FROM Contract]) {
            objIds.add(obj.Id);
        }
        HierarchyClone.Request req = new HierarchyClone.Request();
        req.objIdsToProcess = objIds;
        req.fieldRef = 'Parent_Contract__c';
        req.objTypeName = 'Contract';

        HierarchyClone.Response[] responses = HierarchyClone.process(new List<HierarchyClone.Request>{req});
        System.assertEquals(true, responses[0].objIdsClone.size() > 0);
        
        Test.stopTest();
    }
}