@isTest
private with sharing class LEX_ActiveCampaignOpportunityTest {
    
    @testSetup
    private static void testSetup() {

        // create a account

        Account acc = new Account(Name='test acc', Type='End User', Status__c = 'Active');
        insert acc;
        
        // create a contact
        Contact con = new Contact(LastName='testcontact', AccountId=acc.Id);
        insert con;        
       
        // create campaign
        Campaign cam = new Campaign(Name='cam01', IsActive=true, Status='Planned');
        insert cam;

        // create campaign contact
        CampaignMember cm = new CampaignMember();
		cm.ContactId = con.Id; 
		cm.CampaignId = cam.Id;
		cm.Status ='Sent'; 
        insert cm;

        // create opportunity
        Opportunity opp = new Opportunity(Name='testopp', Type='New Business', AccountId=acc.Id, CloseDate=System.today().adddays(5), StageName='Discovery Phase');
        insert opp;

        // create opportunity contact role
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = con.Id;
        ocr.OpportunityId = opp.Id;
        ocr.IsPrimary = TRUE;
        ocr.Role = 'Primary Contact';

        insert ocr;
        

    }

    @isTest
    private static void testSetPrimaryCampaignOnOpportunity() {
        Test.startTest();
        LEX_ActiveCampaignOpportunityController.getActiveCampaign([SELECT Id FROM Opportunity LIMIT 1].Id);
        String status = LEX_ActiveCampaignOpportunityController.updateCampaignOpportunity([SELECT Id FROM Opportunity LIMIT 1].Id, [SELECT Id FROM Campaign LIMIT 1].Id);
        Test.stopTest();

        System.assertEquals('success', status);
    }

    @isTest
    private static void testERRORSetPrimaryCampaignOnOpportunity() {
        Test.startTest();       
        String status = LEX_ActiveCampaignOpportunityController.updateCampaignOpportunity(null, [SELECT Id FROM Campaign LIMIT 1].Id);
        Test.stopTest();

        System.assert('success' != status);
    }

}