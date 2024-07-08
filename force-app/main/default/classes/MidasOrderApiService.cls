public class MidasOrderApiService {
    @future(callout=true)
    public static void sendOpportunityToMidas(Id opportunityId){
        
        Opportunity opp = [
            SELECT Id
            FROM Opportunity WHERE Id =: opportunityId
            ];
        
        List<Order> orders = [
            SELECT Id, OpportunityId, Create_in_Midas__c, Created_in_Midas__c
            FROM Order WHERE OpportunityId =: opportunityId
        	];
        
        CalloutLog__c mainLog = new CalloutLog__c();
        List<CalloutLog__c> logList = new List<CalloutLog__c>();
                
        Dimensions_API_Credentials__c apiCredentials  = MidasOrderApiServiceHelper.getApiCredentials();
        String endpoint = apiCredentials.End_Point_URL__c + apiCredentials.CPQ_API_URL__c;
        
        try
        {            
            for(Order order : orders)
            {		        
                string route = apiCredentials.Opportunity_Route__c + '/' + order.OpportunityId + '/' + order.Id;
                
                CalloutLog__c log = new CalloutLog__c();            
                log.RecordId__c = order.Id;
                log.EndpointURL__c = endpoint + route;                
                
                HttpResponse createdOrderResponse = MidasOrderApiServiceHelper.callMidasApiBasicAuth(endpoint + route, 'POST', null);
                
                log.ResponseMessage__c = createdOrderResponse.getBody();
                log.ResponseCode__c = String.valueOf(createdOrderResponse);
                log.SuccessfulCall__c = (createdOrderResponse.getStatusCode() == 200);                
                
                logList.Add(log);
                
                if (createdOrderResponse.getStatusCode() == 200)
                {
                    order.Create_in_Midas__c = true;
                    order.Created_in_Midas__c = true;                    
                    order.Midas_Order_Error__c = null;                	
                }
                else
                {
                    order.Create_in_Midas__c = false;                    
                    order.Created_in_Midas__c = false;
                    order.Midas_Order_Error__c = (String)createdOrderResponse.getBody();
                }
            }                                             
            
            // Persist the opp and the modified orders
            try
            {                
                TriggerHandler.bypass('OrderTriggerHandler');
                TriggerHandler.bypass('SendToCPQTriggerHandler');                                                              
                               
                update orders;
                
                TriggerHandler.clearBypass('OrderTriggerHandler');
                TriggerHandler.clearBypass('SendToCPQTriggerHandler');                                                              
                
                mainLog.SuccessfulCall__c = true;                              
            }
            catch (Exception e) 
            {
                mainLog.DmlException__c = String.valueOf(e);
                mainLog.CalloutException__c = String.valueOf(e);
                mainLog.SuccessfulCall__c = false;
            }
                
        }        
		catch (Exception e) 
        { 
            mainLog.DmlException__c = String.valueOf(e);
            mainLog.CalloutException__c = String.valueOf(e);
            mainLog.SuccessfulCall__c = false;
        }
        
        finally
        {
            // Insert all callout logs			
            insert logList;            
            insert mainLog;
        }    	    
    }
          
    @future(callout=true)
    public static void ResetAndSendOrdersToProvisioning(Id oppId){
                
        Opportunity opp = [
            SELECT Id, Reset_In_Midas__c
            FROM Opportunity WHERE Id =: oppId
            ];
        
        List<Order> orders = [
            SELECT Id, OpportunityId, Create_in_Midas__c, Created_in_Midas__c, Reset_In_Midas__c
            FROM Order WHERE OpportunityId =: oppId
        	];
        
        CalloutLog__c mainLog = new CalloutLog__c();
        
        List<CalloutLog__c> logsList = new List<CalloutLog__c>();                      
        
        try
        	{            
            Dimensions_API_Credentials__c apiCredentials  = MidasOrderApiServiceHelper.getApiCredentials();
            string endpoint = apiCredentials.End_Point_URL__c + apiCredentials.CPQ_API_URL__c;
            
           	// Do the reset first to midas  
            // eg: opportunities/{opId}/reset              
            string route = apiCredentials.Opportunity_Route__c + '/' + opp.Id + '/reset';
                            
            CalloutLog__c resetLog = new CalloutLog__c();
            resetLog.RecordId__c = opp.Id;
            resetLog.EndpointURL__c = endpoint + route;
            
            HttpResponse resetOrderResponse = MidasOrderApiServiceHelper.callMidasApiBasicAuth(endpoint + route, 'POST', null); 
            
            resetLog.ResponseMessage__c = resetOrderResponse.getBody();
            resetLog.ResponseCode__c = String.valueOf(resetOrderResponse);
            resetLog.SuccessfulCall__c = (resetOrderResponse.getStatusCode() == 200);
            logsList.Add(resetLog);
            
            if(resetOrderResponse.getStatusCode() == 200)
            {                                             
                opp.Reset_In_Midas__c = false;                
                
                // Reset ok so resend each order to Midas
                // eg: opportunities/{oppId}/{ordId}
                for(Order ord : orders)
                {                   
                    route = apiCredentials.Opportunity_Route__c + '/' + opp.Id + '/' + ord.Id;
                    
                    CalloutLog__c orderLog = new CalloutLog__c();
                	orderLog.RecordId__c = opp.Id;
                	orderLog.EndpointURL__c = endpoint + route;
                
                	HttpResponse createdOrderResponse = MidasOrderApiServiceHelper.callMidasApiBasicAuth(endpoint + route, 'POST', null);
                    
                	orderLog.ResponseMessage__c = createdOrderResponse.getBody();
                	orderLog.ResponseCode__c = String.valueOf(createdOrderResponse);
                    orderLog.SuccessfulCall__c = (createdOrderResponse.getStatusCode() == 200);
                    
                    logsList.Add(orderLog);
                
                    if(createdOrderResponse.getStatusCode() == 200)
                    {                        
                        ord.Create_in_Midas__c = true;
                    	ord.Created_in_Midas__c = true;                    
                        ord.Midas_Order_Error__c = null;
                    } 
                    else 
                    {
                        ord.Create_in_Midas__c = false;
                    	ord.Created_in_Midas__c = false;                                            	
                        ord.Midas_Order_Error__c = String.valueOf(createdOrderResponse);
                    }                                        
                }                    
            }
            
            // Reset the ReSend flag so it can send again
            opp.Reset_In_Midas__c = false;               
            
            // Persist the opp and the modified orders
            try
            {
                TriggerHandler.bypass('OpportunityTriggerHandler');
                TriggerHandler.bypass('OrderTriggerHandler');
                TriggerHandler.bypass('SendToCPQTriggerHandler');                                                              
                
                update opp;                                      
                update orders;
                
                TriggerHandler.clearBypass('OpportunityTriggerHandler');
                TriggerHandler.clearBypass('OrderTriggerHandler');
                TriggerHandler.clearBypass('SendToCPQTriggerHandler');                                                              
                
                mainLog.SuccessfulCall__c = true;                              
            }
            catch (Exception e) 
            {
                mainLog.DmlException__c = String.valueOf(e);
                mainLog.CalloutException__c = String.valueOf(e);
                mainLog.SuccessfulCall__c = false;
            }
                
          }        
		catch (Exception e) 
        { 
            mainLog.DmlException__c = String.valueOf(e);
            mainLog.CalloutException__c = String.valueOf(e);
            mainLog.SuccessfulCall__c = false;
        }
        
        finally
        {
            // Insert all callout logs			
            insert logsList;            
            insert mainLog;
        }    
    }
    
    @future(callout=true)
    public static void ResetAndSendOrderToProvisioning(Id oppId, Id orderId){
                        
        Order ord = [
            SELECT Id, OpportunityId, Create_in_Midas__c, Created_in_Midas__c, Reset_In_Midas__c
            FROM Order WHERE OpportunityId =: oppId
        	];
        
        CalloutLog__c mainLog = new CalloutLog__c();        
        List<CalloutLog__c> logsList = new List<CalloutLog__c>();                      
                
        try
        	{            
            Dimensions_API_Credentials__c apiCredentials  = MidasOrderApiServiceHelper.getApiCredentials();
            string endpoint = apiCredentials.End_Point_URL__c + apiCredentials.CPQ_API_URL__c;
            
           	// Do the reset first to midas  
            // eg: opportunities/{opId}/{orderId}/reset-order              
            string route = apiCredentials.Opportunity_Route__c + '/' + oppId + '/' + orderId + '/reset-order';
                            
            CalloutLog__c resetLog = new CalloutLog__c();
            resetLog.RecordId__c = orderId;
            resetLog.EndpointURL__c = endpoint + route;
            
            HttpResponse resetOrderResponse = MidasOrderApiServiceHelper.callMidasApiBasicAuth(endpoint + route, 'POST', null); 
            
            resetLog.ResponseMessage__c = resetOrderResponse.getBody();
            resetLog.ResponseCode__c = String.valueOf(resetOrderResponse);
            resetLog.SuccessfulCall__c = (resetOrderResponse.getStatusCode() == 200);
            logsList.Add(resetLog);
            
            if(resetOrderResponse.getStatusCode() == 200)
            {                                                                             
                // Reset ok so send order to Midas/Halo
                // eg: opportunities/{oppId}/{ordId}                                  
                route = apiCredentials.Opportunity_Route__c + '/' + oppId + '/' + orderId;
                    
				CalloutLog__c orderLog = new CalloutLog__c();
                orderLog.RecordId__c = orderId;
                orderLog.EndpointURL__c = endpoint + route;
                
                HttpResponse createdOrderResponse = MidasOrderApiServiceHelper.callMidasApiBasicAuth(endpoint + route, 'POST', null);
                    
                orderLog.ResponseMessage__c = createdOrderResponse.getBody();
                orderLog.ResponseCode__c = String.valueOf(createdOrderResponse);
                orderLog.SuccessfulCall__c = (createdOrderResponse.getStatusCode() == 200);
                
                logsList.Add(orderLog);
                
                if(createdOrderResponse.getStatusCode() == 200)
                {                        
                    ord.Create_in_Midas__c = true;
                    ord.Created_in_Midas__c = true;                    
                    ord.Midas_Order_Error__c = null;
                } 
                else 
                {
                    ord.Create_in_Midas__c = false;
                    ord.Created_in_Midas__c = false;                                            
                    ord.Midas_Order_Error__c = String.valueOf(createdOrderResponse);
                }
            }
            
            // Reset the ReSend flag so it can send again
            ord.Reset_In_Midas__c = false;               
            
            // Persist the opp and the modified orders
            try
            {                
                TriggerHandler.bypass('OrderTriggerHandler');                
                update ord;                
                TriggerHandler.clearBypass('OrderTriggerHandler');
                
                mainLog.SuccessfulCall__c = true;                              
            }
            catch (Exception e) 
            {
                mainLog.DmlException__c = String.valueOf(e);
                mainLog.CalloutException__c = String.valueOf(e);
                mainLog.SuccessfulCall__c = false;
            }
                
          }        
		catch (Exception e) 
        { 
            mainLog.DmlException__c = String.valueOf(e);
            mainLog.CalloutException__c = String.valueOf(e);
            mainLog.SuccessfulCall__c = false;
        }
        
        finally
        {
            // Insert all callout logs			
            insert logsList;            
            insert mainLog;
        }    
    }
}