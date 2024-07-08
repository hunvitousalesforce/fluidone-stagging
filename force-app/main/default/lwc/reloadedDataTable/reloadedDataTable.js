import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getProduct2List from "@salesforce/apex/CustomDatatableWithFilterController.getProduct2List";

const COLUMNS = [
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
  },
  {
    label: "Quantity",
    fieldName: "SBQQ__Quantity__c",
    type: "number",
    editable: true
  },
  {
    label: "Unit Sell",
    fieldName: "Unit_Sell__c",
    type: "number",
    editable: true
  },
  {
    label: "Unit Cost",
    fieldName: "SBQQ__NetPrice__c",
    type: "number",
    editable: true
  },
  {
    label: "Required By",
    fieldName: "SBQQ__RequiredBy__c",
    type: "lookup",
    typeAttributes: {
      placeholder: "Choose Quote Line",
      object: "SBQQ__QuoteLine__c",
      fieldName: "SBQQ__RequiredBy__c",
      label: "Required By",
      value: { fieldName: "SBQQ__RequiredBy__c" },
      context: { fieldName: "Id" },
      variant: "label-hidden",
      name: "Required By",
      fields: ["SBQQ__QuoteLine__c.SBQQ__RequiredBy__c"],
      target: "_self"
    },
    editable: false,
    cellAttributes: {
      class: { fieldName: "requireByClass" }
    }
  }
];

export default class ReloadedDatatable extends LightningElement {
  columns = COLUMNS;
  records;
  lastSavedData;
  error;
  searchTerm;
  wiredRecords;
  showSpinner = false;
  showTable = false;
  draftValues = [];
  defaultRecordTypeId;
  stagePicklistValues;
  //used to obtain the picklist as private children of datatable
  privateChildren = {};

  @api quoteId;
  @track productListToRender = [];

  // mockList = [
  //   {
  //     productId: "a0A0u000002OjynEAC",
  //     name: "Cisco",
  //     description: "this is a description for Cisco",
  //     parentProduct: false,
  //     SBQQ__Quantity__c: 1,
  //     Unit_Sell__c: 100,
  //     SBQQ__NetPrice__c: 100,
  //     SBQQ__RequiredBy__c: ""
  //   },
  //   {
  //     productId: "a0A0u000002OjynEAG",
  //     name: "cisco 3",
  //     description: "this is description",
  //     parentProduct: true,
  //     SBQQ__Quantity__c: 1,
  //     Unit_Sell__c: 100,
  //     SBQQ__NetPrice__c: 100,
  //     SBQQ__RequiredBy__c: ""
  //   }
  // ];

  async connectedCallback() {
    await this.loadRelatedRecords(this.searchTerm);
    // try {
    //   const data = await getProduct2List({ keyword: this.searchTerm }); // js array
    //   const newProductList = data.map((item) => {
    //     const newItem = {
    //       Id: item.Id,
    //       Name: item.Name,
    //       Description: item.Description,
    //       Parent_Product__c: item.Parent_Product__c,
    //       SBQQ__Quantity__c: 1,
    //       Unit_Sell__c: 100,
    //       SBQQ__NetPrice__c: 100,
    //       SBQQ__RequiredBy__c: ""
    //     };
    //     return newItem;
    //   });

    //   this.productListToRender = newProductList;
    // } catch (e) {
    //   console.log(e);
    // }
  }

  // @wire(getProduct2List)
  // wiredProducts({ error, data }) {
  //   if (data) {
  //     const newProductList = data.map((item) => {
  //       const newItem = {
  //         Name: item.Name,
  //         Description: item.Description,
  //         Parent_Product__c: item.Parent_Product__c,
  //         SBQQ__Quantity__c: 1,
  //         Unit_Sell__c: 100,
  //         SBQQ__NetPrice__c: 100,
  //         SBQQ__RequiredBy__c: ""
  //       };
  //       return newItem;
  //     });

  //     this.productListToRender = [
  //       ...this.productListToRender,
  //       ...newProductList
  //     ];
  //   } else if (error) {
  //     console.log(error);
  //   }
  // }

  renderedCallback() {
    if (!this.isComponentLoaded) {
      window.addEventListener("click", (evt) => {
        this.handleClickOnWindow(evt);
      });
      this.isComponentLoaded = true;
    }
  }

  disconnectedCallback() {
    window.removeEventListener("click", () => {});
  }

  handleClickOnWindow(context) {
    this.resetPopups("c-datatable-lookup", context);
  }

  resetPopups(markup, context) {
    let elementMarkup = this.privateChildren[markup];
    if (elementMarkup) {
      Object.values(elementMarkup).forEach((element) => {
        element.callbacks.reset(context);
      });
    }
  }

  async loadRelatedRecords(keyword) {
    let result;
    try {
      result = await getProduct2List({ keyword: keyword });
      // this.productListToRender = JSON.parse(JSON.stringify(result));
      const newProductList = result.map((item) => {
        const newItem = {
          Id: item.Id,
          Name: item.Name,
          Description: item.Description,
          Parent_Product__c: item.Parent_Product__c,
          SBQQ__Quantity__c: 1,
          Unit_Sell__c: 100,
          SBQQ__NetPrice__c: 100,
          SBQQ__RequiredBy__c: ""
        };
        return newItem;
      });

      this.productListToRender = newProductList;
    } catch (error) {
      console.log("loadRelatedRecords:", JSON.stringify(error));
    }
  }

  // Event to register the datatable picklist and the lookup mark up.
  handleRegisterItem(event) {
    console.log("handleRegisterItem:::", JSON.stringify(event.detail));
    event.stopPropagation();
    const item = event.detail;
    if (!this.privateChildren.hasOwnProperty(item.name))
      this.privateChildren[item.name] = {};
    this.privateChildren[item.name][item.guid] = item;
  }

  async handleChange(event) {
    event.preventDefault();
    this.searchTerm = event.target.value;
    console.log("this.searchTerm::", this.searchTerm);
    this.showSpinner = true;

    await this.loadRelatedRecords(this.searchTerm);

    this.showSpinner = false;
    this.showTable = true;
    this.lastSavedData = this.productListToRender;
  }

  handleCancel(event) {
    event.preventDefault();
    this.records = JSON.parse(JSON.stringify(this.lastSavedData));
    this.handleClickOnWindow("reset");
    this.draftValues = [];
  }

  handleCellChange(event) {
    event.preventDefault();
    this.updateDraftValues(event.detail.draftValues[0]);
  }

  handleValueChange(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let updatedItem;
    if (dataRecieved.label === "Required By") {
      updatedItem = {
        Id: dataRecieved.context,
        SBQQ__RequiredBy__c: dataRecieved.value
      };
      this.setClasses(
        dataRecieved.context,
        "requiredByClass",
        "slds-cell-edit slds-is-edited"
      );
    } else {
      this.setClasses(dataRecieved.context, "", "");
    }
    console.log("updatedItem::", updatedItem);
    this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);
  }

  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.productListToRender));
    copyData.forEach((item) => {
      if (item.Id === updateItem.Id) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });
    this.productListToRender = [...copyData];
  }

  updateDraftValues(updateItem) {
    let draftValueChanged = false;
    let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
    copyDraftValues.forEach((item) => {
      if (item.Id === updateItem.Id) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
        draftValueChanged = true;
      }
    });
    if (draftValueChanged) {
      this.draftValues = [...copyDraftValues];
    } else {
      this.draftValues = [...copyDraftValues, updateItem];
    }
  }

  handleEdit(event) {
    console.log("handleEdit dataRecieved:::", event.detail.data);
    event.preventDefault();
    let dataRecieved = event.detail.data;
    this.handleClickOnWindow(dataRecieved.context);
    if (dataRecieved.label === "Required By") {
      this.setClasses(
        dataRecieved.context,
        "requiredByClass",
        "slds-cell-edit"
      );
    } else {
      this.setClasses(dataRecieved.context, "", "");
    }
  }

  setClasses(id, fieldName, fieldValue) {
    this.productListToRender = JSON.parse(
      JSON.stringify(this.productListToRender)
    );
    this.productListToRender.forEach((detail) => {
      if (detail.Id === id) {
        detail[fieldName] = fieldValue;
      }
    });
  }

  async handleSave(event) {
    event.preventDefault();
    this.showSpinner = true;
    this.showTable = false;
    const updatedFields = event.detail.draftValues;
    this.draftValues = [];

    try {
      // Pass edited fields to the updateOpportunities Apex controller
      console.log("updated draft value:::" + JSON.stringify(updatedFields));

      this.showToast(
        "Success",
        "Opportunities updated successfully",
        "success"
      );
    } catch (error) {
      this.showToast(
        "Error while updating or refreshing records",
        error.body.message,
        "error"
      );
      console.log("error:", error);
      this.showSpinner = false;
    }
    // finally {
    //   //reload Opportunities after updating fields
    //   this.records = await this.loadRelatedRecords(this.accountId);
    //   this.showSpinner = false;
    //   this.showTable = true;
    // }
  }

  rowSelectionHandler(event) {
    const selectedRows = event.detail.selectedRows;

    for (let i = 0; i < selectedRows.length; i++) {
      console.log(selectedRows[i]);
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
}