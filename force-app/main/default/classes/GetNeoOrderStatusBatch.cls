/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 01-03-24
 * @last modified by  : jamesgoode@fluidone.com
**/
global class GetNeoOrderStatusBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts{
    
    global Iterable<String> start(Database.BatchableContext BC){
        //Get unique order ids
        List<AggregateResult> uniqueNeoOrderIds = [
            SELECT NeoOrderId__c neoId
            FROM OrderItem 
            WHERE  NeoOrderId__c <> '' AND 
                (NOT(
                    NeoOrderStatus__c = 'Completed' OR 
                    NeoOrderStatus__c = 'Rejected')
                ) 
            GROUP BY NeoOrderId__c 
        ];

        List<String> neoOrderIdList = new List<String>();
        for (AggregateResult ar: uniqueNeoOrderIds) {
            neoOrderIdList.add((String) ar.get('neoId'));
        }

        return neoOrderIdList;
    }
     
    global void execute(Database.BatchableContext BC, List<String> scope){ 
        List<OrderItem> orderProductsByNeoId = [
            SELECT Id,OrderId,
                    NeoOrderStatus__c,
                    NeoOrderId__c
            FROM OrderItem
            WHERE NeoOrderId__c IN :scope
        ];
        Map<Id,Order> ordersByNeoIdMap = new Map<Id,Order>();

        Map<String,List<OrderItem>> orderProductsByNeoIdMap = new Map<String,List<OrderItem>>();
        for (OrderItem oi : orderProductsByNeoId) {
            
            List<OrderItem> orderProductsForNeoId = orderProductsByNeoIdMap.get(oi.NeoOrderId__c); 
            if (orderProductsForNeoId == null) {
                orderProductsForNeoId = new List<OrderItem>();        
            }
            orderProductsForNeoId.add(oi);            
            orderProductsByNeoIdMap.put(oi.NeoOrderId__c,orderProductsForNeoId);
        }

        List<CalloutLog__c> logsToCreate  = new List<CalloutLog__c>();   
        List<OrderItem> orderProductsToUpdate = new List<OrderItem>();
        for (String neoOrderId : scope) { 
            CalloutLog__c log = new CalloutLog__c();                        		            
            log.EndpointURL__c = 'https://api.fluidone.com/Dimensions/api/orders/' + neoOrderId;
            try {  
                system.debug('=====neoOrderId.===='+ neoOrderId);
                HttpResponse orderStatusResponse = DimensionsOrderAPI.getOrderStatus(neoOrderId);
                system.debug('=====orderStatusResponse.===='+ orderStatusResponse);
                system.debug('=====orderStatusResponse.===='+ orderStatusResponse.getStatus());
                
                system.debug('=====orderStatusResponse.===='+ orderStatusResponse.getStatusCode() );
                system.debug('=====orderStatusResponse.===='+ orderStatusResponse);
                log.ResponseMessage__c = orderStatusResponse.getBody();     
                system.debug('=====orderStatusResponse.getBody()===='+ orderStatusResponse.getBody());
                
                if (orderStatusResponse.getStatusCode() == 200) {
                	Map<String, Object> orderStatusResponseBody = (Map<String, Object>) JSON.deserializeUntyped(orderStatusResponse.getBody());
                    log.SuccessfulCall__c = true;                                   
                    for (OrderItem oi : orderProductsByNeoIdMap.get(neoOrderId)) {                        
                        oi.LinkedContractNumber__c = (String) orderStatusResponseBody.get('linkedContractNumber');          
                        orderProductsToUpdate.add(oi);                            
                    }  
                    String neoOrderStatus =  DimensionsOrderApi.parseOrderStatus((Integer) orderStatusResponseBody.get('status'));                 

                    /*  REMOVED - OrderForms will never be Rejected from Neo - jamesgoode@fluidone.com                   		
                    if (neoOrderStatus == 'Rejected') {
                        String orderId = orderProductsByNeoIdMap.get(neoOrderId)[0].OrderId;
                        Order order = new Order(Id = orderId);
						order.SendCancelledOrderProductsEmail__c = true;
                        ordersByNeoIdMap.put(order.Id,order);  
                        for (OrderItem oi : orderProductsByNeoIdMap.get(neoOrderId)) {
                            oi.SBQQ__QuoteLine__c = null; 
                            oi.NeoOrderStatus__c = neoOrderStatus; 
                            if (orderProductsToUpdate.contains(oi)) {
                                continue;
                            }
                            orderProductsToUpdate.add(oi);                            
                        }                        
                    }else
					*/
                    
					if(neoOrderStatus == 'Completed'){ // previously it was 'Accepted'
                        String orderId = orderProductsByNeoIdMap.get(neoOrderId)[0].OrderId;
                        String activatedOn = (String) orderStatusResponseBody.get('activatedOn');
                        System.debug('===activatedOn===='+ activatedOn);
                        if(!ordersByNeoIdMap.containsKey(orderId) && activatedOn != null){
                            Order order = new Order(Id = orderId);
                            order.Status = 'Activated';
                            //order.ActivatedDate = Date.valueOf(activatedOn);
                            order.EffectiveDate = Date.valueOf(activatedOn);//Updated Order Start Date with activatedOn date value
                            order.SBQQ__Contracted__c = true;
                            ordersByNeoIdMap.put(order.Id,order);
                            for (OrderItem oi : orderProductsByNeoIdMap.get(neoOrderId)) {
                                oi.SBQQ__Status__c = 'Activated';
                                oi.NeoOrderStatus__c = neoOrderStatus;
                                if (orderProductsToUpdate.contains(oi)) {
                                continue;
                            	}
                                orderProductsToUpdate.add(oi);                            
                            }
                        }
                        
                    }                               
                }
            } catch (CalloutException e) {
                System.debug(e);
                log.CalloutException__c = String.valueOf(e);                
            } catch (DmlException e) { 
                System.debug(e);
                log.DmlException__c = String.valueOf(e);
            }
            logsToCreate.add(log);
        }
		Database.update(ordersByNeoIdMap.values(), false);
        Database.update(orderProductsToUpdate, false);  
        Database.insert(logsToCreate, false);      
    }
  
    global void finish(Database.BatchableContext BC){
    }
}
/*
//At order level
//When Rejected
order.SendCancelledOrderProductsEmail__c = true;
// When Completed
order.Status = 'Activated';
order.ActivatedDate = Date.valueOf(activatedOn);
order.SBQQ__Contracted__c = true;

//At Order product 
oi.LinkedContractNumber__c = (String) orderStatusResponseBody.get('linkedContractNumber');  
oi.SBQQ__Status__c = 'Activated';
oi.NeoOrderStatus__c = neoOrderStatus;
*/