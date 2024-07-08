import { LightningElement } from 'lwc';
import getProduct2List from "@salesforce/apex/CustomDatatableWithFilterController.getProduct2List";
import { track, api } from 'lwc';
import lwcDatatableStyle from '@salesforce/resourceUrl/lwcDatatableStyle';

const columns = [
    {
      label: "Product Name",
      fieldName: "Name",
      type: "text"
    },
    {
      label: "Service Description",
      fieldName: "Description",
      type: "text"
    },
    {
      label: "Parent Product",
      fieldName: "Parent_Product__c",
      type: "boolean"
    }
  ];



export default class CustomDatatableSearch extends LightningElement {
    columns = columns;
    searchTerm;
    @track data = [];
    @track selectedRecords = []

    @api
    get returnProducts() {
        return this.selectedRecords.map(item => item.Id);
    }

    async loadRelatedRecords(keyword) {
        let result;
        let newProductList = [];
        try {
            result = await getProduct2List({
                keyword: keyword
            });
            newProductList = result.map((item) => {
                const newItem = {
                    Id: item.Id,
                    Name: item.Name,
                    Description: item.Description,
                    Parent_Product__c: item.Parent_Product__c
                };
                return newItem;
            });
        } catch (error) {
            console.log("loadRelatedRecords:", JSON.stringify(error));
        }
        return newProductList;
    }

    async handleSearchChange(event) {
        this.searchTerm = event.target.value;
        const searchProducts = await this.loadRelatedRecords(this.searchTerm);
        this.data = [...searchProducts]
    }

    async connectedCallback() { 
        const searchProducts = await this.loadRelatedRecords(this.searchTerm);
        this.data = [...searchProducts]
    }


    async getSelectedRecord(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRecords = [...selectedRows]
    }
}