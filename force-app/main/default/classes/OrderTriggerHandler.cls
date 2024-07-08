/**
* @description       : 
* @author            : matthew.rosete@pracedo.com
* @group             : 
* @last modified on  : 28-12-2022
* @last modified by  : matthew.rosete@pracedo.com
**/
public with sharing class OrderTriggerHandler extends TriggerHandler {
    // setting the maximum loop count for this trigger
    public OrderTriggerHandler() {
        this.setMaxLoopCount(5); 
    }
    
    // context specific methods override
    public override void afterUpdate() {
        sendOrderInformation((Map<Id,Order>)Trigger.newMap, (Map<Id,Order>)Trigger.oldMap); 
    }
    
    // method to check for any changes in fields and send information to SAP using future class
    public void sendOrderInformation(Map<Id, Order> newMap, Map<Id, Order> oldMap){
        // for each order create a callout
        for(Order ord : newMap.values()){
            
            if (ord.Reset_In_Midas__c && 
                oldMap.get(ord.Id).Reset_In_Midas__c == false) 
            {
                MidasOrderApiService.ResetAndSendOrderToProvisioning(ord.OpportunityId, ord.Id);                           
            }
            
            if (ord.CreateInXero__c && oldMap.get(ord.Id).CreateInXero__c == false) {
                createXeroQuote((List<Order>) Trigger.new, (Map<Id, Order>) Trigger.oldMap);                           
            }
        }
    }
          
    public static void createXeroQuote(List<Order> newList, Map<Id, Order> oldMap) {
        List<Order> orders = new List<Order>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        for (Order order_i : newList) {
            if (order_i.AccountId != null   /*order_i.Account.Billing_Contact__c != null */                    
                && order_i.CreateInXero__c == true
                && order_i.CreateInXero__c != oldMap.get(order_i.Id).CreateInXero__c) {
                    orders.add(order_i);
                    accountMap.PUT(order_i.AccountId,NULL);
                }
        }
        accountMap = new Map<Id,Account>([SELECT ID,Billing_Contact__c FROM Account WHERE Id IN:accountMap.keySet()]);
        if (!orders.isEmpty()) {
            for (Order order_i : orders) {
                if(accountMap.containsKey(order_i.AccountId) && accountMap.get(order_i.AccountId).Billing_Contact__c != null){
                    System.enqueueJob(new CreateXeroQuoteCallout(order_i.Id));
                }
                //TODO: process orders as a batch
            }
        }
    }
    
    public class CreateXeroQuoteCallout implements Queueable, Database.AllowsCallouts  {
        private String orderId;
        public CreateXeroQuoteCallout(String orderId) {
            this.orderId = orderId;
        }
        
        public void execute(QueueableContext context) {
            Boolean isContactExists = false;
            Account accToUpdate;
            Order orderToUpdate;
            
            Order order = [SELECT Id
                           , OrderNumber
                           , PoNumber
                           , ActivatedDate
                           , EffectiveDate
                           , TotalAmount
                           , AccountId
                           , Account.XeroContactId__c
                           , Account.Billing_Contact__c,
                           Account.Billing_Contact__r.Name
                           , (SELECT Id
                              , UnitPrice
                              , TotalPrice
                              , Quantity
                              , Product2.ProductCode
                              , Product2.Name
                              , Product2.Product_Code_CSA__c
                              , SBQQ__QuoteLine__r.SBQQ__RegularPrice__c
                              , SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c 
                              , SBQQ__QuotedListPrice__c    
                              , SBQQ__QuoteLine__r.SBQQ__ListTotal__c                               
                              FROM OrderItems 
                              WHERE Product2.Product_Code_CSA__c != null /*Product2.ProductCode != null */) 
                           FROM Order
                           WHERE Id = :orderId 
                           AND Account.Billing_Contact__c != null LIMIT 1];
            //check xero contact
            if (order.Account.XeroContactId__c == null) {
                //create xero contact
                XeroApi.ContactsResponse createOrUpdateContactsResponse = XeroApi.createOrUpdateContact(XeroObjects.mapContact(order.Account.Billing_Contact__r.Name));
                if (createOrUpdateContactsResponse.isSuccess) {
                    accToUpdate = new Account(
                        Id = order.AccountId,
                        XeroContactId__c = createOrUpdateContactsResponse.Contacts.get(0).ContactID
                        //XeroContactId__c = order.Account.XeroContactId__c
                    );
                    isContactExists = true;
                }   
            } else {
                isContactExists = true;
            }
            
            if (isContactExists) {
                //check xero items
                Boolean isItemsExists = false;
                
                if (!order.OrderItems.isEmpty()) {
                    Set<String> productCodes = new Set<String>();
                    
                    for (OrderItem orderItem_i : order.OrderItems) {
                        //productCodes.add(orderItem_i.Product2.ProductCode);
                        productCodes.add(orderItem_i.Product2.Product_Code_CSA__c);
                    }
                    
                    XeroApi.ItemsResponse createOrUpdateItemsResponse = XeroAPI.createOrUpdateItems(XeroObjects.mapItems(new List<String>(productCodes), '310', '630'));
                    
                    if (createOrUpdateItemsResponse.isSuccess) {
                        isItemsExists = true;
                    }
                    
                    if (isItemsExists) {
                        //create xero order
                        XeroApi.QuotesResponse quoteResponse = XeroApi.createQuote(XeroObjects.mapQuote(order, 'GBP'));
                        
                        if (quoteResponse.isSuccess) {
                            orderToUpdate = new Order(
                                Id = order.id,
                                XeroQuoteId__c = quoteResponse.Quotes.get(0).QuoteID
                            );   
                        }
                    }
                } 
            }
            if (accToUpdate != null) {
                update accToUpdate;
            }
            if (orderToUpdate != null) {
                update orderToUpdate;
            }
        }
    }
}