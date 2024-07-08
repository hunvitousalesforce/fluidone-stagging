import { LightningElement, api } from 'lwc';
import massLoad from '@salesforce/apex/ScfProductBundles.massLoad';

export default class ScfProductBundles extends LightningElement {
    @api recordId;
    @api quoteRecordId;
    records = [];
    searchTerm = "";

    connectedCallback() {
        massLoad({ 
            recordId: this.recordId
        }).then(result => {
            if (result != null) {
                this.records = this.defaultFields(result.lineItems);
            }
        }).catch(error => {
            console.log("error", JSON.stringify(error));
        });
    }

    defaultFields(lineItems) {
        lineItems = JSON.parse(JSON.stringify(lineItems));
        for (var i = 0; i < lineItems.length; i++) {
            lineItems[i].item.SBQQ__Quantity__c = 1;
            lineItems[i].item.UnitPrice__c = 0;
            lineItems[i].item.Unit_Sell__c = 0;
        }
        return lineItems;
    }

    handleLineChange(event) {
        let data = {
            "name": event.target.fieldName ? event.target.fieldName : event.target.name,
            "value": event.detail.value,
            "index": event.currentTarget.dataset.index
        };
        var lineItems = JSON.parse(JSON.stringify(this.records));
        lineItems[data.index].item[data.name] = data.value;
        this.records = lineItems;
    }

    @api 
    get lineItems() {
        var lineItems = [];
        for (var i = 0; i < this.records.length; i++) {
            var item = this.records[i].item;
            item.SBQQ__Quote__c = this.quoteRecordId;
            item.SBQQ__Product__c = item.Id;
            if (!item.SBQQ__Quantity__c) {
                item.SBQQ__Quantity__c = 1;
            }
            if (!item.UnitPrice__c) {
                item.UnitPrice__c = 0;
            }
            if (!item.Unit_Sell__c) {
                item.Unit_Sell__c = 0;
            }
            if (!item.SBQQ__UnitCost__c) {
                item.SBQQ__UnitCost__c = 0;
            } 
            lineItems.push(item);
        }
        return lineItems;
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value
        console.log(event.target.detail)
    }
}