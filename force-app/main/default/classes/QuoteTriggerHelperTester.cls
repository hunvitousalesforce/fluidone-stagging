@isTest (seealldata=false)
public class QuoteTriggerHelperTester {
    @testSetup static void methodName() {
        // set up foundation.
        Product2 sp = new Product2(Name='Test Subscription', Family='Mobile', IsActive=true, SBQQ__PricingMethod__c='List', SBQQ__SubscriptionPricing__c='Fixed Price', SBQQ__SubscriptionType__c='Renewable', SBQQ__SubscriptionTerm__c=12);
        insert sp;
        
        Id pbid = Test.getStandardPricebookId();
        PricebookEntry spbe = new PricebookEntry(Product2Id=sp.id, Pricebook2Id=pbid, UnitPrice=1, IsActive=true);
        insert spbe;
        
        Account a = new Account(Name='Test');
        insert a;
        
        // set up first opp and quote scenario.
        Opportunity o = new Opportunity(AccountId=a.id, Name='Test', StageName='Prospecting', CloseDate=Date.today(), Pricebook2Id=pbid);
        insert o;
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Account__c=a.id, SBQQ__Opportunity2__c=o.id, SBQQ__Type__c='Quote', SBQQ__Primary__c=true, SBQQ__Pricebook__c=pbid, SBQQ__StartDate__c=Date.today(), SBQQ__SubscriptionTerm__c=12);
        insert q;
        
        SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c(SBQQ__Account__c=a.id, SBQQ__Quote__c=q.id, Name='Test');
        insert qlg;
        
        SBQQ__QuoteLine__c sql = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.id, SBQQ__Group__c=qlg.id, SBQQ__Product__c=sp.id, SBQQ__Quantity__c=1, SBQQ__SubscriptionPricing__c='Fixed Price', SBQQ__ProductSubscriptionType__c='Renewable', SBQQ__SubscriptionType__c='Renewable', SBQQ__DefaultSubscriptionTerm__c=12, SBQQ__SubscriptionTerm__c=12, SBQQ__StartDate__c=Date.today());
        insert new List<SBQQ__QuoteLine__c>{sql};
        
        // set up contract and subscriptions.
        Contract c = new Contract(AccountId=a.id, SBQQ__Opportunity__c=o.id, SBQQ__Quote__c=q.id, Status='Draft', StartDate=Date.today(), ContractTerm=12, SBQQ__PreserveBundleStructureUponRenewals__c=true);
        insert c;
        
        SBQQ__Subscription__c s = new SBQQ__Subscription__c(SBQQ__Account__c=a.id, SBQQ__Contract__c=c.id, SBQQ__Product__c=sp.id, SBQQ__QuoteLine__c=sql.id, SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1, SBQQ__NetPrice__c=1, SBQQ__CustomerPrice__c=1, SBQQ__RenewalQuantity__c=1);
        insert s;
    }
    static testMethod void doInsertMissingRenewalLineGroups() {
        List<Product2> ps = [select id from Product2 order by Name];
        Id pbid = Test.getStandardPricebookId();
        Account a = [select id from Account where Name='Test'];
        Contract c = [select id from Contract where AccountId = :a.id];
        SBQQ__Subscription__c s = [select id from SBQQ__Subscription__c where SBQQ__Account__c = :a.id];
        
        // ********* Starting Test **********
        
        
        Opportunity ro = new Opportunity(AccountId=a.id, Name='Renewal Test', StageName='Prospecting', CloseDate=Date.today(), SBQQ__RenewedContract__c=c.id, Pricebook2Id=pbid);
        insert ro;
        
        SBQQ__Quote__c rq = new SBQQ__Quote__c(SBQQ__Account__c=a.id, SBQQ__Opportunity2__c=ro.id, SBQQ__Type__c='Renewal', SBQQ__Primary__c=true, SBQQ__Pricebook__c=pbid, SBQQ__StartDate__c=Date.today(), SBQQ__SubscriptionTerm__c=12);
        insert rq;
        
        Test.startTest();
        SBQQ__QuoteLine__c srql = new SBQQ__QuoteLine__c(SBQQ__Quote__c=rq.id, SBQQ__Group__c=null, SBQQ__Product__c=ps[0].id, SBQQ__Quantity__c=1, SBQQ__SubscriptionPricing__c='Fixed Price', SBQQ__ProductSubscriptionType__c='Renewable', SBQQ__SubscriptionType__c='Renewable', SBQQ__DefaultSubscriptionTerm__c=12, SBQQ__SubscriptionTerm__c=12, SBQQ__StartDate__c=Date.today(),
                                                       SBQQ__RenewedSubscription__c=s.id);
        insert new List<SBQQ__QuoteLine__c>{srql};
        
        QuoteTriggerHelper.insertMissingAmendmentRenewalLineGroupsRun = false;
        update rq;
        
        Test.stopTest();
    }
    static testMethod void doInsertMissingAmendmentLineGroups() {
        List<Product2> ps = [select id from Product2 order by Name];
        Id pbid = Test.getStandardPricebookId();
        Account a = [select id from Account where Name='Test'];
        SBQQ__Quote__c q = [select id from SBQQ__Quote__c where SBQQ__Opportunity2__r.Name='Test'];
        Contract c = [select id from Contract where AccountId = :a.id];
        SBQQ__Subscription__c s = [select id from SBQQ__Subscription__c where SBQQ__Account__c = :a.id];
        
        // ********* Starting Test **********
        
        
        Opportunity ao = new Opportunity(AccountId=a.id, Name='Amendment Test', StageName='Prospecting', CloseDate=Date.today(), SBQQ__AmendedContract__c=c.id, Pricebook2Id=pbid);
        insert ao;
        
        SBQQ__Quote__c aq = new SBQQ__Quote__c(SBQQ__Account__c=a.id, SBQQ__Opportunity2__c=ao.id, SBQQ__Type__c='Amendment', SBQQ__Primary__c=true, SBQQ__Pricebook__c=pbid, SBQQ__StartDate__c=Date.today(), SBQQ__SubscriptionTerm__c=12);
        insert aq;
        
        Test.startTest();
        SBQQ__QuoteLine__c srql = new SBQQ__QuoteLine__c(SBQQ__Quote__c=aq.id, SBQQ__Group__c=null, SBQQ__Product__c=ps[0].id, SBQQ__Quantity__c=1, SBQQ__SubscriptionPricing__c='Fixed Price', SBQQ__ProductSubscriptionType__c='Renewable', SBQQ__SubscriptionType__c='Renewable', SBQQ__DefaultSubscriptionTerm__c=12, SBQQ__SubscriptionTerm__c=12, SBQQ__StartDate__c=Date.today(),
                                                       SBQQ__UpgradedSubscription__c=s.id);
        insert new List<SBQQ__QuoteLine__c>{srql};
        
		
        QuoteTriggerHelper.insertMissingAmendmentRenewalLineGroupsRun = false;
        //update aq;
        Test.stopTest();
    }
}