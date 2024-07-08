/**
 * Created by abhyashtimsina on 03/06/2024.
 */

// File: ContractDataController.cls
    public with sharing class ContractsExpiringNextFYQuarter {
        @AuraEnabled(cacheable=true)
        public static List<Contract> getContractsExpiringNextFYQuarter() {
            return [
                    SELECT Account.name, Opportunity_Name__c, ContractNumber, Hierarchy__c, SBQQ__ExpirationDate__c, SBQQ__Opportunity__r.SBQQ__Renewal__c
                    FROM Contract
                    WHERE Expiring_in_Next_FY_Quarter__c = TRUE
            ];
        }
    }