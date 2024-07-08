import { LightningElement, api, wire, track } from 'lwc';
import getContractsForOpportunity from '@salesforce/apex/StrangerRenewalCostSellController.getContractsForOpportunity';

const columns = [
    {
        label: 'Contract Number',
        fieldName: 'contractUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'ContractNumber' },
            target: '_blank'
        }
    },
    {
        label: 'Cost',
        fieldName: 'TotalContractCost__c',
        type: 'currency',
        cellAttributes: { alignment: 'center' }
    },
    {
        label: 'Sell',
        fieldName: 'TotalContractProfit__c',
        type: 'currency',
        cellAttributes: { alignment: 'center' }
    },
];

export default class StrangerRenewalCostSell extends LightningElement {
    @api recordId;  // Opportunity Id
    @track columns = columns;
    @track contracts = {};
    @track totalContractValue = '0.00';
    @track totalContractCost = '0.00';
    @track totalContractSell = '0.00';

    @wire(getContractsForOpportunity, { opportunityId: '$recordId' })
    wiredContracts(result) {
        if (result.data) {
            let totalValue = 0;
            let totalCost = 0;
            let totalSell = 0;
            this.contracts.data = result.data.map(contract => {
                let value = contract.SBQQ__Opportunity__r?.Total_Contract_Value__c || 0;
                let cost = contract.SBQQ__Quote__r?.TotalContractCost__c || 0;
                let sell = contract.SBQQ__Quote__r?.TotalContractProfit__c || 0;
                totalValue += value;
                totalCost += cost;
                totalSell += sell;
                return {
                    ...contract,
                    contractUrl: `/lightning/r/Contract/${contract.Id}/view`,
                    ContractNumber: contract.ContractNumber,
                    Total_Contract_Value__c: value,
                    TotalContractCost__c: cost,
                    TotalContractProfit__c: sell,
                };
            });
            this.totalContractValue = totalValue.toFixed(2);
            this.totalContractCost = totalCost.toFixed(2);
            this.totalContractSell = totalSell.toFixed(2);
            this.contracts.error = undefined;
        } else if (result.error) {
            this.contracts.error = result.error;
            this.contracts.data = undefined;
        }
    }
}