@isTest
public class OpportunityProductHandlerTest {
    
	@testSetup
    static void setup(){
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = new Account(Name='test acc', Type='End User', Status__c = 'Active');
        insert acc;

        // create opportunity
        Opportunity opp = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Commission as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Commission as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40,
                                         Contracting_Account__c='test', Billing_Account__c ='test');
        insert opp;
        
        Product2 product1 = new Product2(Name='Product 1', Family = 'Data');
        Product2 product2 = new Product2(Name='Product 2', Family = 'IT Services');
        Product2 product3 = new Product2(Name='Product 3', Family = 'Data');
        insert new List<Product2>{product1, product2, product3}; 
            
        PriceBookEntry pbe1 = new PriceBookEntry(IsActive = true, Product2Id=product1.Id, PriceBook2Id=Test.getStandardPricebookId(), UnitPrice=100);
        PriceBookEntry pbe2 = new PriceBookEntry(IsActive = true, Product2Id=product2.Id, PriceBook2Id=Test.getStandardPricebookId(), UnitPrice=1000);
        PriceBookEntry pbe3 = new PriceBookEntry(IsActive = true, Product2Id=product3.Id, PriceBook2Id=Test.getStandardPricebookId(), UnitPrice=1010);
        insert new List<PriceBookEntry>{pbe1, pbe2, pbe3}; 

        
    }
    /*
    @isTest
    static void testInsertNewFamily(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id);
        insert opportunityLineItem;
        List<Opportunity> childOpps = [SELECT Id FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        System.assertEquals(1, childOpps.size(), 'There should be one child opp created for the data product family');
    }

    @isTest
    static void testUpdateFamily(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id);
        insert opportunityLineItem;


        Test.startTest();
            opportunityLineItem.UnitPrice = 15000;
            opportunityLineItem.Recurring_Dealer_Commission__c = 10;
            update opportunityLineItem;
        Test.stopTest();

        List<Opportunity> childOpps = [SELECT Id FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        List<OpportunityLineItem> childLIs = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE OpportunityId IN : childOpps];
        System.assertEquals(1, childOpps.size(), 'There should be one child opp created for the data product family');
        System.assertEquals(10, childLIs[0].UnitPrice, 'Line Items Unit Price has not been updated');
    }

    @isTest
    static void testDeleteNoOtherProducts(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id);
        insert opportunityLineItem;

        List<Opportunity> childOppsBefore = [SELECT Id, StageName FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        //System.assertEquals(1, childOppsBefore.size(), 'There should be one child opp created for the data product family');

        Test.startTest();
            delete opportunityLineItem;
        Test.stopTest();

        List<Opportunity> childOpps = [SELECT Id, StageName FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        //System.assertEquals(1, childOpps.size(), 'There should be one child opp created for the data product family');
        //System.assertEquals('Closed Lost', childOpps[0].StageName, 'Opp has not been closed Lost');
    }


    @isTest
    static void testDeleteOtherProducts(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        Product2 product3 = [SELECT Id FROM Product2 WHERE Name = 'Product 3' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        PriceBookEntry priceBookEntry3 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product3.Id ];
        OpportunityLineItem opportunityLineItem1 = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id);
        OpportunityLineItem opportunityLineItem2 = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry3.Id, OpportunityId=opp.Id);
        insert new List<OpportunityLineItem>{opportunityLineItem1, opportunityLineItem2};

        Test.startTest();
            delete opportunityLineItem1;
        Test.stopTest();

        List<Opportunity> childOpps = [SELECT Id, StageName FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        //System.assertEquals(1, childOpps.size(), 'There should be one child opp created for the data product family');
       // System.assertEquals('Discovery Phase', childOpps[0].StageName, 'Opp has been closed Lost whilst still having a line item');
        List<OpportunityLineItem> childLIs = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN : childOpps];
        //System.assertEquals(1, childLIs.size(), 'Line Item 2 doesnt exist');

    }*/

    @isTest
    static void handleAfterDeleteTest(){
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = [SELECT Id FROM Account];
        Opportunity opp = [SELECT Id FROM Opportunity];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id);
        insert opportunityLineItem;

        Opportunity childOpp = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Commission as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Commission as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40, Parent_Opportunity__c = opp.Id,
                                         Contracting_Account__c='test', Billing_Account__c='test');
        insert childOpp;

        OpportunityLineItem childOpportunityLineItem = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId=childOpp.Id, Parent_Opportunity_Product__c = opportunityLineItem.Id);
        insert childOpportunityLineItem;
        
        Test.startTest();
            new SendToCPQTrigger().clearMaxLoopCount();
            delete opportunityLineItem;
        Test.stopTest();
        List<Opportunity> childOpps = [SELECT Id, StageName FROM Opportunity where Id =: childOpp.Id];
        List<OpportunityLineItem> childLIs = [SELECT Id FROM OpportunityLineItem ];
        System.debug('***childOpps****'+childOpps);
        System.debug('***childLIs****'+childLIs);
        System.assertEquals('Closed Lost', childOpps[0].StageName, 'Opp has not been closed Lost');
        System.assertEquals(0, childLIs.size(), 'Line Item exist');
    }
    
}