/**
 * Created by abhyashtimsina on 23/06/2024.
 */

public with sharing class StrangerRenewalCostSellController {
    @AuraEnabled(cacheable=true)
    public static List<Contract> getContractsForOpportunity(Id opportunityId) {
        return [SELECT Id, ContractNumber, SBQQ__Opportunity__r.Total_Contract_Value__c,SBQQ__Quote__r.TotalContractCost__c, SBQQ__Quote__r.TotalContractProfit__c
        FROM Contract
        WHERE SBQQ__Opportunity__c = :opportunityId];
    }
}