@isTest 
public class trgOpportunityhandlerTest {
    static testMethod void insertNewOpportunity() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = new Account(name='Test Demo');
        insert acc;
        
        
        // Do you recognize these fields?
        // create opportunity
        Opportunity opportunityToCreate = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Sales as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Sales as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
      
                
        insert opportunityToCreate;
        
        // This is how we get the Standard PriceBook Id.  Prior to Summer '14, we needed
        // to use SeeAllData=true, so this is a big improvement
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create your product
        Product2 prod = new Product2(
            Name = 'Product X',
            ProductCode = 'Pro-X',
            Family = 'Data',
            isActive = true
        );
        insert prod;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem olisalesAGP = new OpportunityLineItem(
            OpportunityId = opportunityToCreate.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 100
        );
        olisalesAGP.Overlay_Split_Percentage__c=100;
        olisalesAGP.Overlay_Type__c='Sales as AGP';
        olisalesAGP.Create_Overlay_Opportunity__c=true;
        olisalesAGP.Overlay_User__c = UserInfo.getUserId();
        olisalesAGP.Recurring_Dealer_Commission__c = 100;
        olisalesAGP.Non_Recurring_Dealer_Commission__c = 100;
        Test.startTest();
        insert olisalesAGP;

        User u = [select id,name from user where id!=:UserInfo.getUserId() limit 1];        
        olisalesAGP.Quantity=10;
        olisalesAGP.Overlay_User__c = u.Id;
        update olisalesAGP;
        Test.stopTest();
    }
    
    static testMethod void insertNewOpportunitySub() {
        
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = new Account(name='Test Demo');
        insert acc;
        
        
        // Do you recognize these fields?
        // create opportunity
        Opportunity opportunityToCreate = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Sales as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Sales as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
                
        insert opportunityToCreate;
        
        // This is how we get the Standard PriceBook Id.  Prior to Summer '14, we needed
        // to use SeeAllData=true, so this is a big improvement
        Id pricebookId = Test.getStandardPricebookId();        
        
        Product2 prod1 = new Product2(
            Name = 'Product 1',
            ProductCode = 'Pro-1',
            Family = 'Data',
            isActive = true
        );
        insert prod1;
        
        //Create your pricebook entry
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry1;        
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunityToCreate.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry1.Id,
            TotalPrice = 100
        );
        oli.Overlay_Split_Percentage__c=100;
        oli.Overlay_Type__c='Commission as AGP';
        oli.Create_Overlay_Opportunity__c=true;
        oli.Overlay_User__c = UserInfo.getUserId();
        oli.Recurring_Dealer_Commission__c = 100;
        oli.Non_Recurring_Dealer_Commission__c = 100;
        oli.Related_Child_Opportunity__c = opportunityToCreate.Id;
        Test.startTest();
        insert oli;
        
        User u = [select id,name from user where id!=:UserInfo.getUserId() limit 1];        
        oli.Quantity=10;
        oli.Overlay_User__c = u.Id;
        update oli;
        Test.stopTest();
    }
    
    static testMethod void updateNewOpportunity() {
        
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = new Account(name='Test Demo');
        insert acc;
        
        
        // Do you recognize these fields?
        // create opportunity
        Opportunity opportunityToCreate = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Sales as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Sales as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
                
        insert opportunityToCreate;
        
        // This is how we get the Standard PriceBook Id.  Prior to Summer '14, we needed
        // to use SeeAllData=true, so this is a big improvement
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create your product
        Product2 prod = new Product2(
            Name = 'Product X',
            ProductCode = 'Pro-X',
            Family = 'Data',
            isActive = true
        );
        insert prod;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem olisalesAGP = new OpportunityLineItem(
            OpportunityId = opportunityToCreate.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 100
        );
        olisalesAGP.Overlay_Split_Percentage__c=100;
        olisalesAGP.Overlay_Type__c='Sales as AGP';
        olisalesAGP.Overlay_User__c = UserInfo.getUserId();
        olisalesAGP.Recurring_Dealer_Commission__c = 100;
        olisalesAGP.Non_Recurring_Dealer_Commission__c = 100;
        
        olisalesAGP.Create_Overlay_Opportunity__c=true;
        insert olisalesAGP;
        
        olisalesAGP.Quantity=10;
        olisalesAGP.Create_Overlay_Opportunity__c=true;
        olisalesAGP.Related_Child_Opportunity__c= opportunityToCreate.Id;
        update olisalesAGP;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunityToCreate.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 100
        );
        oli.Overlay_Split_Percentage__c=100;
        oli.Overlay_Type__c='Commission as AGP';
        oli.Overlay_User__c = UserInfo.getUserId();
        oli.Recurring_Dealer_Commission__c = 100;
        oli.Non_Recurring_Dealer_Commission__c = 100;
        
        insert oli;
        
        Test.startTest();
        oli.Create_Overlay_Opportunity__c=true;
        update oli;        
        
        delete oli;
        
        List<Opportunity> lstop = [select id,name from opportunity where recordtype.DeveloperName='Child_Opportunity'];
        delete lstop;
        Test.stopTest();
     } 
    
    static testMethod void createNewOpportunity() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc = new Account(name='Test Demo');
        insert acc;
        
        
        // Do you recognize these fields?
        // create opportunity
        Opportunity opportunityToCreate = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase',
                                         Data_Overlay_Type__c='Sales as AGP',Data_Overlay_User__c=runningUser.Id,Data_Split_Percentage__c=20,
                                         IT_Services_Overlay_Type__c='Sales as AGP', IT_Services_Overlay_User__c=runningUser.Id, IT_Services_Split_Percentage__c=40);
        
        insert opportunityToCreate;
        
        RecordType  rt = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive, 
                          CreatedDate, CreatedById, LastModifiedById, LastModifiedDate, SystemModstamp FROM RecordType WHERE DeveloperName='Child_Opportunity' LIMIT 1];
        
        
        Opportunity opportunityChild = new Opportunity();
        
        // Do you recognize these fields?
        opportunityChild.StageName = 'Discovery Phase';
        opportunityChild.CloseDate = Date.valueOf('2016-01-01');
        opportunityChild.AccountId = acc.Id;
        opportunityChild.Name = 'Test Opportunity Triggers';
        opportunityChild.Parent_Opportunity__c=opportunityToCreate.Id;
        opportunityChild.RecordTypeId =rt.Id;
        
        
        Test.startTest();
        Insert opportunityChild;

        //update child with error Restricted
        try{
            OpportunityTriggerHandler.createsharerecord(opportunityChild.Id, runningUser.Id);
            opportunityChild.StageName = 'Closed Lost';
            opportunityChild.LostReason__c = 'No Opportunity';
            update opportunityChild;
            OpportunityTriggerHandler.runOnce = true;
            //cannot update from closed lost to open
            opportunityChild.StageName = 'Discovery Phase';
            update opportunityChild;
            System.assert(false,'should throw an error');
        }catch(Exception e){
            system.assert(true,'cannot update from closed lost to open');
        }

        try{
             OpportunityTriggerHandler.runOnce = true;
            opportunityChild.CloseDate = System.today();
            update opportunityChild;
            System.assert(false,'should throw an error');
        }catch(Exception e){
            system.assert(true,'cannot update CloseDate');
        }



        try{
             OpportunityTriggerHandler.runOnce = true;
            opportunityChild.name = 'Test Opportunity update';
            update opportunityChild;
            System.assert(false,'should throw an error');
        }catch(Exception e){
            system.assert(true,'cannot update opportunity name');
        }

        opportunityToCreate.Description='Test';
        update opportunityToCreate;
        try{
            delete opportunityToCreate;
            System.assert(false,'should throw an error');
        }catch(Exception e){
            system.assert(true,'we need to delete child opportunity first');
        }
        try{
            OpportunityTriggerHandler.ChildOpportunity chilOpp = new OpportunityTriggerHandler.ChildOpportunity();
            chilOpp.lstChild = new List<Opportunity>();
            chilOpp.parentOpp = opportunityChild;
            chilOpp.del();
        }catch(Exception e){
            //always get error validation when try to delete record
            system.assert(true,'we need to delete child opportunity first');
        }
       

        Test.stopTest();
     } 
}