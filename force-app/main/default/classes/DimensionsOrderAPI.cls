/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 28-12-2022
 * @last modified by  : matthew.rosete@pracedo.com
**/
public with sharing class DimensionsOrderAPI {   
    
    // Added ContractAccountCode and BillingAccountCode to DimensionsOrderApi - jamesgoode@fluidone.com 231123
    public class DimensionsOrder {
        public String AccountCode;
        public String ContractAccountCode;
        public String BillingAccountCode;
        public String BillingReference; 
        public String SiteReference;
        public OrderContact EndUserContact;
        public OrderContact TechnicalContact;
        public OrderAddress InstallationAddress;
        public OrderAddress P2PInstallationAddress;
        public OrderAddress DeliveryAddress;
        public DateTime OrderFormSignedOn;
        private Decimal BillingFrequency;
        public Decimal ContractLength;
        public String OrderType;
        public List<ContractPart> ContractParts;
        public String SalesForceOpportunityId;           
        
        public Decimal getBillingFrequency () { 
            return BillingFrequency;
        }

        public void setBillingFrequency (String oiBillingFrequency) {
            switch on oiBillingFrequency { 
                when 'Monthly' { 
                    BillingFrequency = 1; 
                }
                when 'Quarterly' { 
                    BillingFrequency = 3;
                }
                when 'Semiannual' {
                    BillingFrequency = 3;
                }
                when 'Annual' {
                    BillingFrequency = 12;
                }
                when else { 
                    BillingFrequency = 0;
                }
            }            
        }
    }

    public class OrderAddress {
        public String City;
        public String CountryCode;        
        public String Postcode;                  
        public String StreetName; 
        public String County;
    }

    public class ContractPart {
        public String Type; 
        public String LinkedContractNumber;
        public List<ProductLine> ProductLines;
    }

    public class ProductLine {
        public Decimal SellPrice;
        public String StockCode; 
        public Decimal Quantity;
        public Decimal CostOverride;
        public Decimal Cost;
    }

    public class OrderContact { 
        public String Title;
        public String FirstName;
        public String LastName;
        public String Email;
        public String PhoneNumber;
    }

    public static DimensionsOrder mapNeoOrder (Order ord, String siteName) {
        DimensionsOrderAPI.DimensionsOrder orderModel = new DimensionsOrderAPI.DimensionsOrder();
        orderModel.AccountCode = ord.Account.Account_Number__c;
        orderModel.ContractAccountCode = ord.Opportunity.Contracting_Account__c;
        orderModel.BillingAccountCode = ord.Opportunity.Billing_Account__c;
        orderModel.BillingReference = ord.PoNumber;             
        orderModel.SiteReference = siteName;            
        orderModel.OrderType = ord.Type;                
        orderModel.OrderFormSignedOn = ord.OrderFormSignedOn__c ;// ord.ActivatedDate;      updated on Nov 8, 2023 based on the request to have Opp created date as  ActivatedDate might be null in some cases                                    
        return orderModel;
    }

    public static ContractPart mapNeoContractPart(String contractType, String linkedContractNumber) {
        ContractPart contractPart = new ContractPart();
        contractPart.LinkedContractNumber = linkedContractNumber;
        contractPart.Type = contractType;
        contractPart.ProductLines = new List<ProductLine>();
        return contractPart; 
    }

    public static OrderContact mapNeoContact (
        String title, 
        String firstName, 
        String lastName, 
        String email, 
        String phoneNumber
    ) {
        OrderContact neoContact = new OrderContact();
        neoContact.Title = title;            
        neoContact.FirstName = firstName;
        neoContact.LastName = lastName;
        neoContact.Email = email;
        neoContact.PhoneNumber = phoneNumber;
        return neoContact;
    }

    public static ProductLine mapNeoProductLine (OrderItem oi) {
        ProductLine pl = new ProductLine(); 
        if(oi.SBQQ__QuoteLine__r.BLine__c ){
       		 pl.Cost = oi.SBQQ__QuoteLine__r.SBQQ__SubscriptionPricing__c == 'Fixed Price' ? oi.SBQQ__QuoteLine__r.RecurringCost__c : oi.SBQQ__QuoteLine__r.OneOffCost__c;            
        }else{
        	pl.CostOverride = oi.SBQQ__QuoteLine__r.SBQQ__SubscriptionPricing__c == 'Fixed Price' ? oi.SBQQ__QuoteLine__r.RecurringCost__c : oi.SBQQ__QuoteLine__r.OneOffCost__c;            
        }
        pl.SellPrice = oi.SBQQ__QuotedListPrice__c;//oi.UnitPrice;     updated on Feb 3        
        pl.StockCode = oi.Product2.ProductCode;
        pl.Quantity = oi.Quantity;          
        return pl;
    }

    public static OrderAddress mapNeoAddressFromSite (Site__c site) {
        OrderAddress address = new OrderAddress();
        address.City = site.LocationAddress__City__s;            
        address.CountryCode = site.LocationAddress__CountryCode__s;
        address.Postcode = site.LocationAddress__PostalCode__s;
        address.StreetName = site.LocationAddress__Street__s;
        address.County = site.LocationAddress__City__s;
        return address;
    }

    //returns response given an endpoint and which API to call.
    public static HttpResponse createOrderInDimensions (String orderJson) {        
        HttpResponse response = DimensionsAPIHelper.callDimensionsApi(
            'https://api.fluidone.com:8443/Dimensions-UAT/api/orders', 
            'POST', 
            orderJson
        );                        
        return response;
    }

    public static HttpResponse getOrderStatus (String neoOrderId) {
        HttpResponse response = DimensionsAPIHelper.callDimensionsApi(
            'https://api.fluidone.com:8443/Dimensions-UAT/api/orders/' + neoOrderId, 
            'GET',
            ''
        );                        
        return response;
    }

    public static string parseOrderStatus (Integer orderStatusNumber) {
        switch on orderStatusNumber {
            when -1 {
                return 'Error';
            }
            when 0 {
                return 'Queueing';
            }
            when 1 {
                return 'Accepted';
            }
            when 2 {
                return 'Processing';
            }
            when 3 {
                return 'Completed';
            }
            when 4 {
                return 'Rejected';
            }
            when else {
                return 'Error';
            }
        }
    }
}