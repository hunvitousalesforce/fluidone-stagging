({
	invoke : function(component, event, helper) {        
        return new Promise(function(resolve, reject) {
            component.find("recordLoader").reloadRecord(true, $A.getCallback(function() {
                // ignore errors, we don't want to stop the flow if we cannot refresh the record
                resolve();
            }));
        });
    }
})