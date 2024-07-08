import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api, track } from "lwc";
import { loadStyle } from 'lightning/platformResourceLoader';
import lwcDatatableStyle from '@salesforce/resourceUrl/lwcDatatableStyle';
import getProduct2List from "@salesforce/apex/CustomDatatableWithFilterController.getProduct2List";
import { columns } from "./columns";
import getChildProduct from "@salesforce/apex/CustomDatatableWithFilterController.getChildProduct";
import getProductSelections from "@salesforce/apex/CustomDatatableWithFilterController.getProductSelections";


export default class CustomDatatableWithFilterSuggestion extends LightningElement {
    columns = columns;
    @api quoteId;
    @api selectedProducts;
    @api contractReference;
    @api contractEndDate;
    @api postCode;
    @api recurring;
    @api opportunityRecordTypeName;

    searchTerm;
    showSpinner = false;

    @track selectedRecords = {};
    @track searchRender = {};
    @track productRender = {};

    get productListToRender() {
        return Object.values(this.productRender);
    }

  

    @api
    get returnedQuoteLines() {
        const result = Object.values(this.selectedRecords);
        const qouteLines = result.map((item) => {
            let quoteLine = {
                SBQQ__Quote__c: this.quoteId,
                Name: item.Name,
                SBQQ__Number__c: null,
                SBQQ__Product__c: item.Id,
                SBQQ__ProductOption__c: item.Id,
                SBQQ__Quantity__c: item.SBQQ__Quantity__c,
                Unit_Sell__c: item.Unit_Sell__c,
                SBQQ__UnitCost__c: item.SBQQ__UnitCost__c,
                SBQQ__RequiredBy__c: item.SBQQ__RequiredBy__c
            };
            // if item is a parent
            if (item.Parent_Product__c || item._children.length) {
                quoteLine = {
                    ...quoteLine,
                    SBQQ__ProductOption__c: null,
                    SBQQ__Product__c: item.Id
                };
            } else {
                if (!item.ParentId) {
                    quoteLine = {
                        ...quoteLine,
                        SBQQ__ProductOption__c: null,
                        SBQQ__Product__c: item.Id
                    };
                } else {
                    quoteLine = {
                        ...quoteLine,
                        SBQQ__ProductOption__c: item.Id,
                        SBQQ__Product__c: item.ParentId
                    };
                }
            }
            return quoteLine;
        });
        return qouteLines;
    }

    get isStrangerRenewalOpportunity() {
        return this.opportunityRecordTypeName === "Stranger Renewal";
    }

    async connectedCallback() {
        Promise.all([
            loadStyle(this, lwcDatatableStyle + '/customDatatableWithFilterSuggestion.css')
        ]).then(() => {

        });
        const result = await this.loadRelatedRecords();

        result.forEach(item => {
          this.productRender[item.Id] = item;
        })

        this.productRender = {
            ...this.productRender
        };
    }

    async toggleInput(event) {
        const parentId = event.target.dataset.id;
        const productId = event.target.name;
        let selectedProduct = {};
        // parentId = undefined meaning the selectedProduct doesn't have children product
        if (!parentId) {
            selectedProduct = this.productRender[productId];
        } else {
            const parentProduct = this.productRender[parentId];
            selectedProduct = parentProduct._children.find(
                (item) => item.Id === productId && item.ParentId === parentId
            );
        }
        // Toggle the selection state
        selectedProduct.Selected = !selectedProduct.Selected;
        // If the product is a parent, toggle all its children
        if (
            selectedProduct.Parent_Product__c &&
            !selectedProduct._children.length
        ) {
            // get children and append to seletect
            await this.appendChildRecordsToParent(selectedProduct);
            // selected = true to all the children
            selectedProduct._children = selectedProduct._children.map((child) => ({
                ...child,
                Selected: selectedProduct.Selected
            }));
        }
        // Update selected records
        if (selectedProduct.Selected) {
            if (selectedProduct.Parent_Product__c) {
                const temp = {
                    ...selectedProduct,
                    _children: []
                };
                this.selectedRecords[selectedProduct.Id] = {
                    ...temp
                };
                selectedProduct._children.forEach((child) => {
                    this.selectedRecords[child.Id] = {
                        ...child
                    };
                });
            } else {
                this.selectedRecords[selectedProduct.Id] = {
                    ...selectedProduct
                };
            }
        } else {
            if (selectedProduct.Parent_Product__c) {
                delete this.selectedRecords[selectedProduct.Id];
                // reset value
                selectedProduct.SBQQ__Quantity__c = null;
                selectedProduct.Unit_Sell__c = null;
                selectedProduct.SBQQ__UnitCost__c = null;
                selectedProduct.SBQQ__RequiredBy__c = "";

                selectedProduct._children.forEach((child) => {
                    delete this.selectedRecords[child.Id];
                    // reset child
                    child.SBQQ__Quantity__c = null;
                    child.Unit_Sell__c = null;
                    child.SBQQ__UnitCost__c = null;
                    child.SBQQ__RequiredBy__c = "";
                });
            } else {
                delete this.selectedRecords[selectedProduct.Id]; // remove from selection list
                // reset value
                selectedProduct.SBQQ__Quantity__c = null;
                selectedProduct.Unit_Sell__c = null;
                selectedProduct.SBQQ__UnitCost__c = null;
                selectedProduct.SBQQ__RequiredBy__c = "";
            }
        }
        console.log(
            "Selected Products::: " + Object.keys(this.selectedRecords).length + "\n"
        );

        // Update the productRender object immutably to ensure reactivity
        if (selectedProduct.Parent_Product__c) {
            this.productRender = {
                ...this.productRender,
                [productId]: {
                    ...selectedProduct
                }
            };
        } else {
            const parentProduct = this.productRender[parentId];
            const updatedChildren = parentProduct._children.map((child) => {
                if (child.Id === productId && child.ParentId === parentId) {
                    return {
                        ...selectedProduct
                    };
                }
                return child;
            });

            this.productRender = {
                ...this.productRender,
                [parentId]: {
                    ...parentProduct,
                    _children: updatedChildren
                }
            };
        }
    }



    handleInputChange(event) {
        const parentId = event.target.dataset.parentid;
        const name = event.target.name;
        let value = event.target.value;
        let productId = event.target.dataset.id;

        let selectedProduct = null;

        if (name === "SBQQ__RequiredBy__c") {
            productId = event.detail.customProductId;
            value = event.detail.id;
        }

        if (!parentId) {
            selectedProduct =
                this.productRender[productId] || this.selectedRecords[productId];
        } else {
            let parentProduct = this.productRender[parentId];

            if (parentProduct && parentProduct._children) {
                selectedProduct = parentProduct._children.find(
                    (item) => item.Id === productId && item.ParentId === parentId
                );
            }
        }
        if (selectedProduct) {
            // Update the value for the selected product
            selectedProduct[name] = value;
            // Update in selected records
            this.selectedRecords[productId] = {
                ...selectedProduct
            };
        }
        // Update the productListToRender to trigger reactivity
        // Handle reactivity for productRender
        if (!parentId) {
            // if

            if (productId in this.productRender) {
                this.productRender = {
                    ...this.productRender,
                    [productId]: {
                        ...selectedProduct
                    }
                };
            }
        } else {
            // If the product is a child, update the parent's _children array
            const parentProduct = this.productRender[parentId];
            const updatedChildren = parentProduct._children.map((child) =>
                child.Id === productId && child.ParentId === parentId ?
                {
                    ...selectedProduct
                } :
                child
            );

            this.productRender = {
                ...this.productRender,
                [parentId]: {
                    ...parentProduct,
                    _children: updatedChildren
                }
            };
        }
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    async loadRelatedRecords() {
        let result;
        let newProductList = [];
        try {
            result = await getProductSelections({
                Ids: this.selectedProducts
            });
            newProductList = Object.values(result).map((item) => {
                const newItem = {
                    Id: item.Id,
                    Name: item.Name,
                    Description: item.Description,
                    Parent_Product__c: item.Parent_Product__c,
                    SBQQ__Quantity__c: item.SBQQ__DefaultQuantity__c,
                    Unit_Sell__c: null,
                    SBQQ__UnitCost__c: (item.SBQQ__Costs__r ? item.SBQQ__Costs__r[0].SBQQ__UnitCost__c : null),
                    SBQQ__RequiredBy__c: "",
                    Recurring: item.SBQQ__SubscriptionPricing__c === "Fixed Price",
                    Selected: false,
                    _children: []
                };
                return newItem;
            });
        } catch (error) {
            console.log("loadRelatedRecords:", JSON.stringify(error));
        }
        return newProductList;
    }

    async appendChildRecordsToParent(parentProduct) {
        const parentId = parentProduct.Id;
        const result = await getChildProduct({
            parentId: parentProduct.Id
        });
        let childRecords = result.map((item) => {
            const child = {
                ParentId: item.StockKeepingUnit, //Utilize StockKeepingUnit as parent Id
                Id: item.Id,
                Name: item.Name,
                Parent_Product__c: item.Parent_Product__c,
                Class: "level-1",
                SBQQ__Quantity__c: item.SBQQ__DefaultQuantity__c,
                Unit_Sell__c: null,
                SBQQ__UnitCost__c: (item.SBQQ__Costs__r ? item.SBQQ__Costs__r[0].SBQQ__UnitCost__c : null),
                SBQQ__RequiredBy__c: "",
                Recurring: item.SBQQ__SubscriptionPricing__c === "Fixed Price",
                Selected: false,
                _children: []
            };
            return child;
        });
        parentProduct._children = [...parentProduct._children, ...childRecords];
        this.productRender = {
            ...this.productRender,
            [parentId]: {
                ...this.productRender[parentId],
                ...parentProduct
            }
        };
    }
}