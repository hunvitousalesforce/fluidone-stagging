import { LightningElement, api } from "lwc";
import fetchRecords from "@salesforce/apex/ScfInputLookup.fetchRecords";
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 500;

export default class ScfInputLookup extends LightningElement {
  @api variant;
  @api helpText = "";
  @api label = "";
  @api required;
  @api exclusiveIds = "";
  @api selectedIconName = "standard:account";
  @api objectLabel = "Account";
  recordsList = [];
  selectedRecordName;
  selectedRecordDescription;
  recordsListSuggest = [];
  @api objectApiName = "Account";
  @api fieldApiName = "Name";
  @api otherFieldApiName = "Industry";
  @api extraFieldApiName = "Description";
  @api searchString = "";
  @api selectedRecordId = "";
  @api parentRecordId;
  @api parentFieldApiName;
  @api customProductId;
  @api name; // for input field name used for event data
  preventClosingOfSearchPanel = false;

  get methodInput() {
    return {
      objectApiName: this.objectApiName,
      fieldApiName: this.fieldApiName,
      otherFieldApiName: this.otherFieldApiName,
      extraFieldApiName: this.extraFieldApiName,
      searchString: this.searchString,
      selectedRecordId: this.selectedRecordId,
      parentRecordId: this.parentRecordId,
      parentFieldApiName: this.parentFieldApiName,
      exclusiveIds: this.exclusiveIds
    };
  }

  get showRecentRecords() {
    if (!this.recordsList) {
      return false;
    }
    return this.recordsList.length > 0 && this.preventClosingOfSearchPanel;
  }

  //getting the default selected record
  connectedCallback() {
    this.fetchSobjectRecords(true);
  }

  //call the apex method
  fetchSobjectRecords(loadEvent) {
    fetchRecords({
      inputWrapper: this.methodInput,
      onLoad: loadEvent
    })
      .then((result) => {
        if (loadEvent) {
          this.recordsListSuggest = JSON.parse(JSON.stringify(result));
          this.recordsList = JSON.parse(JSON.stringify(result));
        }
        if (loadEvent && result && this.selectedRecordId) {
          this.selectedRecordName = result[0].mainField;
        } else if (result) {
          this.recordsList = JSON.parse(JSON.stringify(result));
        } else {
          this.recordsList = [];
        }
      })
      .catch((error) => {
        console.log(error);
      });
  }

  get isValueSelected() {
    return this.selectedRecordId;
  }

  //handler for calling apex when user change the value in lookup
  handleChange(event) {
    this.searchString = event.target.value;
    this.fetchSobjectRecords(false);
  }

  //handler for clicking outside the selection panel
  handleBlur() {
    this.recordsList = [];
    this.preventClosingOfSearchPanel = false;
  }

  handleInputFocus() {
    this.preventClosingOfSearchPanel = true;
  }

  //handle the click inside the search panel to prevent it getting closed
  handleDivClick() {
    this.preventClosingOfSearchPanel = true;
  }

  //handler for deselection of the selected item
  handleCommit() {
    this.selectedRecordId = "";
    this.selectedRecordName = "";
    this.recordsList = JSON.parse(JSON.stringify(this.recordsListSuggest));
  }

  //handler for selection of records from lookup result list
  handleSelect(event) {
    let selectedRecord = {
      mainField: event.currentTarget.dataset.mainfield,
      subField: event.currentTarget.dataset.subfield,
      id: event.currentTarget.dataset.id,
      customProductId: this.customProductId,
      name: this.name
    };
    this.selectedRecordId = selectedRecord.id;
    this.selectedRecordName = selectedRecord.mainField;
    this.selectedRecordDescription = selectedRecord.subField;
    this.recordsList = [];
    // Creates the event
    const selectedEvent = new CustomEvent("valueselected", {
      detail: selectedRecord
    });
    //dispatching the custom event
    this.dispatchEvent(selectedEvent);
  }

  //to close the search panel when clicked outside of search input
  handleInputBlur(event) {
    // Debouncing this method: Do not actually invoke the Apex call as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
      if (!this.preventClosingOfSearchPanel) {
        this.recordsList = [];
      }
      this.preventClosingOfSearchPanel = false;
    }, DELAY);
  }

  get placeholder() {
    return "Search " + this.objectLabel + "s...";
  }
}