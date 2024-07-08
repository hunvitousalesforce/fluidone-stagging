@isTest
public with sharing class ProcessOppLineItemOnUpsertBatchTest {
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
    static void createOppAndOLIForMatchingProductFamilyTest(){
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

        System.debug('>>>>>>>>>>>>: ' + [Select Recurring_Dealer_Commission__c,id from OpportunityLineItem WHERE Id = :opportunityLineItem.Id].Id);
        System.debug('>>>>>>>>>>>>: ' + [Select Recurring_Dealer_Commission__c,id from OpportunityLineItem WHERE Id = :opportunityLineItem2.Id].Id);

        Test.startTest();
        Database.executeBatch(new ProcessOppLineItemOnUpsertBatch(),200);
        Test.stopTest();
        List<Opportunity> childOpps = [SELECT Id FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        System.assertEquals(1, childOpps.size(), 'There should be one child opp created for the data product family');
    }

    @isTest
    static void updateChildOpportunityLineItemTest(){
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Opportunity opp = [SELECT Id,StageName FROM Opportunity where Name ='testopp2'];
        Account acc = [SELECT Id FROM Account];
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry1 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        List<OpportunityLineItem> OpportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry1.Id, OpportunityId=opp.Id, Is_Inserted_By__c = 'Batch');
        insert opportunityLineItem;

       
        opportunityLineItem.UnitPrice = 15000;
        opportunityLineItem.Recurring_Dealer_Commission__c = 10;
        update opportunityLineItem;
        
      
        Test.startTest(); 
            Database.executeBatch(new ProcessOppLineItemOnUpsertBatch(),200);
        Test.stopTest();
        opp = [SELECT Id,StageName FROM Opportunity where Name ='testopp2'];
        System.debug('>>>>>>>>>opp: ' + opp);
        List<Opportunity> childOpps = [SELECT Id,StageName FROM Opportunity WHERE Parent_Opportunity__c = :opp.Id];
        System.debug('>>>>>>>>>childOpps: ' + childOpps);
        List<OpportunityLineItem> childLIs = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE OpportunityId IN : childOpps];
        System.assertEquals(1, childOpps.size(), 'There should be one child opp created for the data product family');
        System.assertEquals(10, childLIs[0].UnitPrice, 'Line Items Unit Price has not been updated');
    }

    @isTest
    static void setOverlayFieldOnProductFor12MonthsTest(){
        new SendToCPQTrigger().clearMaxLoopCount();
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = [SELECT Id FROM Account];
        Opportunity opp = [SELECT Id FROM Opportunity where Name ='testopp'];

        Opportunity opp1 = new Opportunity(Name='testopp1', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                Data_Overlay_Type__c='Commission as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20, Rental_Overlay_Type__c = 'Sales as AGP',
                Rental_Overlay_User__c = runningUser.Id, Rental_Split_Percentage__c = 20, Parent_Opportunity__c = opp.Id,
                IT_Services_Overlay_Type__c='Commission as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
        insert opp1;
        new SendToCPQTrigger().clearMaxLoopCount();
        Product2 product1 = [SELECT Id FROM Product2 WHERE Name = 'Product 1' ];
        PriceBookEntry priceBookEntry4 = [SELECT Id FROM PriceBookEntry WHERE Product2Id = :product1.Id ];
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry4.Id, OpportunityId=opp.Id, Is_Inserted_By__c = 'Batch');
        insert opportunityLineItem;
        OpportunityLineItem opportunityLineItem1 = new OpportunityLineItem(Quantity = 1, PriceBookEntryId = priceBookEntry4.Id, OpportunityId=opp1.Id, Is_Inserted_By__c = 'Batch', Parent_Opportunity_Product__c = opportunityLineItem.Id);
        insert opportunityLineItem1;
        new SendToCPQTrigger().clearMaxLoopCount();
        opportunityLineItem.UnitPrice = 15000;
        opportunityLineItem.Recurring_Dealer_Commission__c = 10;
        update opportunityLineItem;
        opportunityLineItem1.Recurring_Dealer_Commission__c = null;
        update opportunityLineItem1;
        new SendToCPQTrigger().clearMaxLoopCount();
        Test.startTest(); 
            Database.executeBatch(new ProcessOppLineItemOnUpsertBatch(),100);
        Test.stopTest();

        List<OpportunityLineItem> childLIs = [SELECT Id, UnitPrice, Sales_AGP_QAGP_Text__c FROM OpportunityLineItem WHERE Id =: opportunityLineItem.Id];
        System.assert(childLIs[0].Sales_AGP_QAGP_Text__c != NULL, 'Sales AGP QAGP Text is NULL');
    }
}