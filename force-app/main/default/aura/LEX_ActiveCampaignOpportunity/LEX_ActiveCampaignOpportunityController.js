({
    doInit : function(component, event, helper) {

        helper.fetchCampaign(component);
     

    },
    filter: function(component, event, helper) {
        var data = component.get("v.data"),
            term = component.get("v.filter"),
            results = data, regex;
        try {
            regex = new RegExp(term, "i");
            // filter checks each row, constructs new array where function returns true
            results = data.filter(row=>regex.test(row.Name) || regex.test(row.ParentName) || 
                                regex.test(row.Type) || regex.test(row.StartDate) ||
                                regex.test(row.Status));
        } catch(e) {
            // invalid regex, use full list
            console.log('Error filter ',e);
        }

        console.log('results >>>> ',results);

        component.set("v.filteredData", results);
    },

    handleRowAction : function(component, event, helper) {       

        var selectedRows = event.getParam('selectedRows');
       
        var camId = (selectedRows.length>0) ? selectedRows[0].Id : '';

        component.set("v.selectedCampaignId", camId);
           
    },    
    doSave : function(component, event, helper) {

      // start spinner
      
      var camId = component.get('v.selectedCampaignId');
      if (camId=='') {
          helper.showToast('Please choose campaign', 'Error', 'Error Message');
          // close spinner
          return;
        }
        
        component.set('v.showSpinner', true);
        event.getSource().set("v.disabled", true);

      var action = component.get("c.updateCampaignOpportunity");
      var oppId = component.get('v.recordId');
        action.setParams({
            'oppId': oppId,
            'campId': camId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS"){                
            
                var status = res.getReturnValue();               
                if (status == 'success') {
                  helper.showToast('Opportunity has been updated successfully!', 'Success', 'Success Message');

                  var navEvt = $A.get("e.force:navigateToSObject");
                  navEvt.setParams({
                      "recordId": oppId,
                      "slideDevName": "detail"
                  });
                  navEvt.fire();

                } else {
                  helper.showToast(status, 'Error', 'Error Message');
                } 
                // close spinner
                component.set('v.showSpinner', false);                

            } else {
              console.log("Failed with state: " + state);
            }

            event.getSource().set("v.disabled", false);
        });
        $A.enqueueAction(action);       
    
    },
    cancel : function(component) {
		$A.get("e.force:closeQuickAction").fire() 
	}
})