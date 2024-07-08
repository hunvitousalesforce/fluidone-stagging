@isTest
private class RecalculateAGPForOpportunityBatchTest {
    @testSetup
    static void setup(){
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = new Account(Name='test acc', Type='End User', Status__c = 'Active');
        insert acc;

        // create opportunity
        Opportunity opp = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Sales as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Sales as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
        insert opp;

        Opportunity opp2 = new Opportunity(Name='testopp2', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Commission as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Commission as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
        insert opp2;
        
        Product2 product1 = new Product2(Name='Product 1', Family = 'Data');
        Product2 product2 = new Product2(Name='Product 2', Family = 'IT Services');
        Product2 product3 = new Product2(Name='Product 3', Family = 'Data');
        insert new List<Product2>{product1, product2, product3}; 
            
        PriceBookEntry pbe1 = new PriceBookEntry(IsActive = true, Product2Id=product1.Id, PriceBook2Id=Test.getStandardPricebookId(), UnitPrice=100);
        PriceBookEntry pbe2 = new PriceBookEntry(IsActive = true, Product2Id=product2.Id, PriceBook2Id=Test.getStandardPricebookId(), UnitPrice=1000);
        PriceBookEntry pbe3 = new PriceBookEntry(IsActive = true, Product2Id=product3.Id, PriceBook2Id=Test.getStandardPricebookId(), UnitPrice=1010);
        insert new List<PriceBookEntry>{pbe1, pbe2, pbe3}; 

        
    }
    
    @isTest
    static void testExecuteBatch(){
        Opportunity opp = [SELECT Id FROM Opportunity where Name ='testopp'];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id);
        
        Opportunity oppCommissionAsAGP = [SELECT Id FROM Opportunity where Name ='testopp2'];
        OpportunityLineItem opportunityLineItem2 = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId = oppCommissionAsAGP.Id);
        insert new List<OpportunityLineItem>{ opportunityLineItem,opportunityLineItem2};
        opportunityLineItem2.Non_Recurring_Dealer_Commission__c = null;
        opportunityLineItem.Non_Recurring_Dealer_Commission__c = null;
        update new List<OpportunityLineItem>{ opportunityLineItem,opportunityLineItem2};
        Test.startTest();
        Database.executeBatch(new RecalculateAGPForOpportunityBatch(new Set<String>{opp.Id}),200);
        Test.stopTest();
    }
}