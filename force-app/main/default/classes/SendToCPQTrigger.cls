/**
* @description       : 
* @author            : jamesgoode@fluidone.com
* @group             : 
* @last modified on  : 18/06/2024
* @last modified by  : jamesgoode@fluidone.com
**/
public with sharing class SendToCPQTrigger extends TriggerHandler {
    
    private static Set<Id> oppIdExecuteds = new Set<Id>();
    
    // Setting the maximum loop count for this trigger
    public SendToCPQTrigger() {
        this.setMaxLoopCount(5); 
    }
        
     // context specific methods override
    public override void afterUpdate() {
        sendOpportunity((Map<Id,Opportunity>)Trigger.newMap, (Map<Id,Opportunity>)Trigger.oldMap); 
    }
    
    //  Send Opportunity to CPQ API
    public void sendOpportunity(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){		

        Opportunity newOpp = newMap.values().get(0);
        Opportunity oldOpp = oldMap.values().get(0);
        
        if (newOpp.Reset_In_Midas__c 
            && !oldOpp.Reset_In_Midas__c)
        {           
            oppIdExecuteds.add(newOpp.Id);
            MidasOrderApiService.ResetAndSendOrdersToProvisioning(newOpp.Id);
            oppIdExecuteds.remove(newOpp.Id);
        }
        else if (newOpp.Send_To_Provisioning__c 
                 && !oldOpp.Send_To_Provisioning__c)
        {            
	 		oppIdExecuteds.add(newOpp.Id);
            MidasOrderApiService.sendOpportunityToMidas(newOpp.Id);            
            oppIdExecuteds.remove(newOpp.Id);
        }
    }          
}