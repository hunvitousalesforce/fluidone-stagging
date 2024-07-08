public class MidasToSalesforceSyncQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        CalloutLog__c log = new CalloutLog__c();
        List<Object> orderData = new List<Object>();
        Map<String, String> midasOrderIdWithStatus = new Map<String, String>();
        List<Order> orderToBeUpdated = new List<Order>();
        
        try{
            String dt = DateTime.now().addHours(-1)+'';
            String syncTime = dt.split(' ')[0]+'T'+dt.split(' ')[1];
         
            Dimensions_API_Credentials__c apiCredentials  = MidasOrderApiServiceHelper.getApiCredentials();
            String endPoint = apiCredentials.End_Point_URL__c+'ordermanagement/api/orders?Filters=modifiedOn>='+syncTime+'&Sorts=-modifiedOn';
            String method = 'GET';
            
            HttpResponse response = MidasOrderApiServiceHelper.callMidasApi(endPoint, method, null);
            String responseBody = (String) response.getBody();
            
            log.EndpointURL__c = endPoint;
            log.ResponseMessage__c = responseBody.length() > 32000 ? responseBody.substring(0, 32000) : responseBody;
            
            if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                orderData = (List<Object>)jsonData.get('data');
            }
            
        }catch(Exception e){
            System.debug('Exception ====='+String.valueOf(e));
            log.CalloutException__c = String.valueOf(e);
        }
        
        for(Object obj : orderData){
            Map<String, Object> wrap = (Map<String, Object>)obj;
            midasOrderIdWithStatus.put((String)wrap.get('id'), (String)wrap.get('status'));
        }
        system.debug('midasOrderIdWithStatus:: '+midasOrderIdWithStatus);
        
        for(Order orderRecord : [SELECT Id, Midas_Order_Id__c, Status FROM Order WHERE Midas_Order_Id__c IN :midasOrderIdWithStatus.keySet()]){
                    system.debug('midasOrderIdWithStatus.get(orderRecord.Midas_Order_Id__c):: '+midasOrderIdWithStatus.get(orderRecord.Midas_Order_Id__c));

            orderRecord.Status = midasOrderIdWithStatus.get(orderRecord.Midas_Order_Id__c);
            orderRecord.Midas_Last_Sync__c = DateTime.now();
            orderToBeUpdated.add(orderRecord);
        }
        
        if(!orderToBeUpdated.isEmpty()){
            try{
                update orderToBeUpdated;
                //Database.SaveResult[] results = Database.update(orderToBeUpdated, false);
            }catch(Exception e){
                log.DmlException__c = String.valueOf(e);
            } 
        }
        insert log;      
    }
}