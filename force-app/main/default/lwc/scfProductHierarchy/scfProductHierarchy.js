import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import fetchRecords from '@salesforce/apex/ScfProductHierarchy.fetchRecords';
const DELAY = 800;

export default class ScfProductHierarchy extends LightningElement {
    @api colNameApi;
    @api helpText = "custom search lookup";
    @api label = "Parent Account";
    @api searchString = "";
    objectLabel = "Product";
    objectApiName = "Product2";
    fieldApiName = "Name";
    otherFieldApiName = "Description";
    searchString = "";
    records = [];
    recordsSuggest = [];
    delayTimeout;
    @track selectedRows = [];
    @track gridExpandedRows = [];
    @track selectedRowsStored = [];
    @track bypassOnRowSelection = false;
    @track expandedRowsCount = 0;
    gridColumns = [];
    currentExpandedRows=[];
    loading = false;

    @wire(getObjectInfo, { objectApiName: "$objectApiName" })
    objectInformation({ data, error }) {
        if (data) {
            this.colNameApi.split(",").map((item) => {
                let fieldName = item.trim();
                this.gridColumns.push({
                    label: data.fields[fieldName].label,
                    fieldName: fieldName,
                    type: "text",
                });
            });
            this.gridColumns = JSON.parse(JSON.stringify(this.gridColumns));
        }
    }

    //getting the default selected record
    connectedCallback() {
        this.fetchSobjectRecords(true);
    }

    //call the apex method
    fetchSobjectRecords(loadEvent) {
        this.loading = true;
        fetchRecords({
            inputWrapper: this.methodInput,
            onLoad: loadEvent
        }).then(result => {
            this.bypassOnRowSelection = true;
            var gridData = [];
            if (result) {
                let superLevels = JSON.parse(JSON.stringify(result.superLevel));
                let treeLevelDTO = JSON.parse(JSON.stringify(result.dto));
                superLevels.forEach(element => {
                    this.findChildrenNode(element, treeLevelDTO);
                });
                gridData = JSON.parse(JSON.stringify(superLevels));
            }
            if (loadEvent) { 
                this.recordsSuggest = JSON.parse(JSON.stringify(gridData));
                this.records = JSON.parse(JSON.stringify(gridData));
            } else if (gridData.length > 0) {
                this.records = JSON.parse(JSON.stringify(gridData));
            } else {
                this.records = [];
            }
            this.delayTimeout = setTimeout(() => {
                this.bypassOnRowSelection = false;
                this.loading = false;
            }, DELAY);   
        }).catch(error => {
            console.log(error);
        })
    }

    //handler for calling apex when user change the value in lookup
    handleChange(event) {
        this.loading = true;
        this.searchString = event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.fetchSobjectRecords(false);
        }, DELAY);   
    }

    handleRowSelection(event) {
        const treeGridComponent = this.template.querySelector('lightning-tree-grid');
        const currentExpandedRows = treeGridComponent.getCurrentExpandedRows();
        const rowIds = this.rowIds;
        const selectedRowsStored = JSON.parse(JSON.stringify(this.selectedRowsStored));

        if (!this.bypassOnRowSelection) {
            //retains what was selected and not in view for now
            var selectedRowsRetained = [];
            selectedRowsStored.forEach(element => {
                if (
                    (element.parentId && currentExpandedRows.indexOf(element.parentId) === -1) || // Keep when parent not expended
                    (rowIds && rowIds.indexOf(element.id) === -1) // Keep when row not in current result list
                ) {
                    selectedRowsRetained.push(element);
                }
            });
            this.selectedRowsStored = selectedRowsRetained.concat(event.detail.selectedRows);
        }
        this.bypassOnRowSelection = false;
    }

    handleRowToggle(event) {
        this.loading = true;
        const treeGridComponent = this.template.querySelector('lightning-tree-grid');
        if (treeGridComponent) {
            const currentExpandedRows = treeGridComponent.getCurrentExpandedRows();
            if (currentExpandedRows && currentExpandedRows.length !== null && currentExpandedRows.length !== undefined) {
                if (currentExpandedRows.length >= this.expandedRowsCount) {
                    this.selectedRows = this.selectedRowIds;
                }
                this.expandedRowsCount = currentExpandedRows.length;
            }
        }
        this.delayTimeout = setTimeout(() => {
            this.loading = false;
        }, DELAY); 
    }

    findChildrenNode(element, treeLevelDTO) {
        element[this.fieldApiName] = element.mainField;
        element[this.otherFieldApiName] = element.subField;
        for (var key in treeLevelDTO) {
            if (key === element.id) {
                element["_children"] = treeLevelDTO[key];
                element["_children"].forEach(child => {
                    this.findChildrenNode(child, treeLevelDTO);
                });
            }
        }
    }

    noteSelectedRowAttr(element, selectedRowVals, attr) {
        selectedRowVals.push(element[attr]);
        if (element["_children"] === undefined) return;
        element["_children"].forEach(child => {
            this.noteSelectedRowAttr(child, selectedRowVals, attr);
        });
    }

    @api 
    get selectedRecords() {
        var ids = [];
        for (var i = 0; i < this.selectedRowIds.length; i++) {
            var id = this.selectedRowIds[i].split("#")[0];
            if (ids.indexOf(id) === -1) {
                ids.push(id);
            }
        }
        var items = [];
        for (var i = 0; i < ids.length; i++) {
            items.push({ "Id" : ids[i] });
        }
        return items;
    }

    get methodInput() {
        return {
            objectApiName: this.objectApiName,
            fieldApiName: this.fieldApiName,
            otherFieldApiName: this.otherFieldApiName,
            searchString: this.searchString,
            selectedRows: this.selectedRowIds
        };
    }

    get selectedRowIds() {
        const selectedRowsStoredIds = [];
        const selectedRowsStored = this.selectedRowsStored;
        if (selectedRowsStored && selectedRowsStored.length > 0) {
            selectedRowsStored.forEach(element => {
                this.noteSelectedRowAttr(element, selectedRowsStoredIds, "id");
            });
        }
        return selectedRowsStoredIds;
    }

    get rowIds() {
        const rowIds = [];
        const records = this.records;
        if (records && records.length > 0) {
            records.forEach(element => {
                this.noteSelectedRowAttr(element, rowIds, "id");
            });
        }
        return rowIds;
    }

    get selectedRowsCount() {
        return this.selectedRowsStored && this.selectedRowsStored.length > 2 ? this.selectedRowsStored.length + " " : "";
    }

    get selectedRowNames() {
        var selectedRowsStoredName = "";
        const selectedRowsStoredNames = [];
        const selectedRowsStored = this.selectedRowsStored;
        if (selectedRowsStored && selectedRowsStored.length > 0) {
            selectedRowsStored.forEach(element => {
                this.noteSelectedRowAttr(element, selectedRowsStoredNames, this.fieldApiName);
            });
        } else {
            return selectedRowsStoredName;
        }
        for (let i = 0; i < selectedRowsStoredNames.length; i++) {
            selectedRowsStoredName += selectedRowsStoredNames[i] + ", ";
        }
        return selectedRowsStoredName.slice(0, -2);
    }

    get placeholder() {
        return "Search " + this.objectLabel + "s...";
    }
}