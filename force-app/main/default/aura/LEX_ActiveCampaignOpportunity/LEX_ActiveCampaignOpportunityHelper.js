({   
    fetchCampaign : function(component) {
           // initialize data
           component.set("v.columns", [
                    {type:"text",label:"Campaign Name",fieldName:"Name"},
                    {type:"text",label:"Parent Campaign Name",fieldName:"ParentName"},
                    {type:"text",label:"Status",fieldName:"Status"},
                    {type:"text",label:"",fieldName:"camStatus1",initialWidth: 30, cellAttributes: { class: { fieldName: "camStatus" } }}]);            

            var action = component.get("c.getActiveCampaign");
            var oppId = component.get('v.recordId');
            action.setParams({
            'oppId': oppId
            });
            action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS"){
            var camRes = res.getReturnValue();

            console.log('key >>> ', camRes);                

            component.set("v.mapActiveCampaigns", camRes);  

            var campaings = [];               
            for (var key in camRes) {

                // popup error message when opportunity contact role not exist
                if (key.includes("Error:")) {

                    this.showToast(key.replace('Error:', ''), 'Error', 'Error Message');
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                    "recordId": oppId,
                    "slideDevName": "detail"
                    });
                    navEvt.fire();                
                }

                if (camRes[key].Parent) camRes[key].ParentName = camRes[key].Parent.Name; 
                
                camRes[key].camStatus = camRes[key].IsActive == true ? 'Active' :'Inactive';
                // add data
                campaings.push(camRes[key]);                
            } 

            component.set("v.data", campaings);
            component.set("v.filteredData", campaings);            

            // close spinner
            component.set('v.showSpinner', false);

            } else {
            console.log("Failed with state: " + state);
            }
            });
            $A.enqueueAction(action);
    },
    showToast : function(msg,type,title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: msg, //'We were not able to create/update'+  oppId + ' records, please review the Logs to see why this request failed' + msg,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:'5000',
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
})