import { LightningElement, wire } from 'lwc';
import getContractsExpiringNextFYQuarter from '@salesforce/apex/ContractsExpiringNextFYQuarter.getContractsExpiringNextFYQuarter';

const columns = [
    {
        label: 'Hierarchy',
        fieldName: 'Hierarchy__c',
        type: 'text',
        cellAttributes: {
            class: { fieldName: 'parentChildClass' }
        }
    },
    { label: 'Opportunity Name', fieldName: 'Opportunity_Name__c', type: 'text' },
    {
        label: 'Contract Number',
        fieldName: 'contractUrl',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'ContractNumber'
            },
            target: '_blank'
        }
    },
    {
        label: "Expiration Date",
        fieldName: "SBQQ__ExpirationDate__c",
        type: "date-local",
        typeAttributes: {
            month: "2-digit",
            day: "2-digit"
        }
    },
    { label: 'Renewal?', fieldName: 'SBQQ__Opportunity__r.SBQQ__Renewal__c', type: 'boolean' },
];


export default class ContractDatatable extends LightningElement {
    columns = columns;
    groupedContracts = [];

    @wire(getContractsExpiringNextFYQuarter)
    contracts({ error, data }) {
        if (data) {
            this.groupContractsByOpportunity(data);
        } else if (error) {
            console.error('Error fetching contracts:', error);
        }
    }

    groupContractsByOpportunity(data) {
        const grouped = data.reduce((acc, contract) => {
            const key = contract.Opportunity_Name__c; // Use Opportunity Name as the key
            if (!acc[key]) {
                acc[key] = { key, contracts: [] };
            }
            acc[key].contracts.push({
                ...contract,
                parentChildClass: contract.Hierarchy__c === 'Child' ? 'slds-text-color_success slds-text-title_caps' : '',
                contractUrl: `/lightning/r/Contract/${contract.Id}/view` // Add the URL field
            });
            return acc;
        }, {});

        this.groupedContracts = Object.values(grouped).map(group => {
            const sortedContracts = [...group.contracts].sort((a, b) => {
                if (a.Hierarchy__c === 'Grandparent') return -1;
                if (b.Hierarchy__c === 'Parent') return 1;
                return 0;
            });
            return { ...group, contracts: sortedContracts };
        });
    }

}