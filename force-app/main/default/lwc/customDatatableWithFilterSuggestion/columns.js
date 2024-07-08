export const columns = [
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
    fieldName: "SBQQ__UnitCost__c",
    type: "number",
    editable: true
  },
  {
    label: "Required By",
    fieldName: "SBQQ__RequiredBy__c",
    type: "text",
    editable: true
  }
];