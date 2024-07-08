/**
 * @description #FO-410
 * @date        13/08/2020
 * @author      Samnang MUONG
 */

public with sharing class LEX_ActiveCampaignOpportunityController {
    

    @AuraEnabled
    public static Map<String, Campaign> getActiveCampaign(String oppId) {

        // get Contact Ids from Opportunity contact role
        Set<String> conIds = new Set<String>();
        
        for (OpportunityContactRole conRole : [SELECT ContactId FROM OpportunityContactRole  WHERE OpportunityId = :oppId]) {
            conIds.add(conRole.ContactId);
        }

        Map<String, Campaign> mapCampaigns = new Map<String, Campaign>();
        Set<String> setCamParentIds = new Set<String>();
        
        System.debug('conIds === '+ conIds);
        if (conIds.isEmpty()) {

            // return error message
            mapCampaigns.put('Error: Please add contact role before add primary campaign', new Campaign());
            return mapCampaigns; 
         }
         // query campaign where contact equals opportunity contact role
        for (CampaignMember cm : [SELECT Id, ContactId, CampaignId, Campaign.Name, Campaign.IsActive, Campaign.Status, Campaign.ParentId FROM CampaignMember WHERE ContactId IN :conIds ORDER BY Campaign.IsActive DESC]) {
            mapCampaigns.put(cm.CampaignId, cm.Campaign);           
        }        
            
        // query more details of campaign
        for (Campaign c : [SELECT Id, Name, IsActive, Parent.Name, Status, Type, StartDate FROM Campaign WHERE Id IN :mapCampaigns.KeySet()]) {
            mapCampaigns.put(c.Id, c);
        }
        
        
        
        return mapCampaigns;
    }

    @AuraEnabled
    public static String updateCampaignOpportunity(String oppId, String campId) {
        
        String status = 'success';
        try {

            update new Opportunity(Id=oppId, CampaignId=campId);

        } catch(Exception e) {
            status = 'ERROR : ' + e.getMessage();
        }

        return status;

    }
}