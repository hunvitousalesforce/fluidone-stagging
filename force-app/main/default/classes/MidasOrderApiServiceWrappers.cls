public class MidasOrderApiServiceWrappers {
    public MidasOrderApiServiceWrappers(){
        
    }
    public class CredentialsBody {
        public String AccountCode; 
        public String Email; 
        public String Password;
    }
    
    /*public class MidasOrder{
        public String sourceOrderId;
        public String salesForceOpportunityId;
        public String customerCode;
        public String projectName;
        public String billingReference;
        public String specialTerms;
        public List<Sites> sites;
    }
    
    public class Sites {
        public String id;
        public String p2pId;
        public String name;
        public String timeZone;
        public Integer contractLength;
        public OrderAddress installationAddress;
        public OrderAddress deliveryAddress;
        public OrderContact technicalContact;
        public OrderContact siteContact;
        public OrderContact endUserContact;
        public List<LineItems> lineItems;
    }
    
    public class OrderAddress {
        public String city;
        public String county;
        public String postcode;
        public String countryCode;
        public String streetNumber;
        public String streetName;
        public String buildingName;
        public String subBuilding;
        public String floor;
        public String roomUnit;
        public String rackLocation;
        public String accessInformation;
    }
    
    public class OrderContact {
        public String title;
        public String firstName;
        public String lastName;
        public String email;
        public String phoneNumber;
    }
    
    public class LineItems{
        public String id;
        public String stockCode;
        public Decimal sellPrice;
        public Integer billingFrequency;
        public String feature;
        public String productLine;
        public Integer contractLength;
        public LineItems[] lineItems;
        
        LineItems(OrderItem oi){
            Map<String, Integer> frequencyMap = new Map<String, Integer>();
            frequencyMap.put('Monthly', 1);
            frequencyMap.put('Quarterly', 3);
            frequencyMap.put('Semiannual', 6);
            frequencyMap.put('Annual', 12);
            frequencyMap.put('Invoice Plan', 0);
            
            id = oi.Id;
            contractLength = Integer.valueOf(oi.SBQQ__SubscriptionTerm__c) != null ? Integer.valueOf(oi.SBQQ__SubscriptionTerm__c) : 0;
            StockCode = oi.Product2.ProductCode;
            productLine = oi.Product2.ProductLine__c;
            SellPrice = oi.SBQQ__QuotedListPrice__c != null ? oi.SBQQ__QuotedListPrice__c : 0;
            billingFrequency = frequencyMap.get(oi.SBQQ__QuoteLine__r.SBQQ__BillingFrequency__c) == null ? 0 : frequencyMap.get(oi.SBQQ__QuoteLine__r.SBQQ__BillingFrequency__c);
            feature = oi.Feature_Name__c;
            lineItems = new List<LineItems>();
        }
    }
    
    public static OrderAddress mapMidasAddressFromSite (Site__c site) {
        OrderAddress address = new OrderAddress();
        address.City = site.LocationAddress__City__s;            
        address.CountryCode = site.LocationAddress__CountryCode__s;
        address.Postcode = site.LocationAddress__PostalCode__s;
        address.StreetName = site.LocationAddress__Street__s;
        address.County = site.LocationAddress__City__s;
        return address;
    }
    
    public static OrderContact mapTechnicalContact (Order ord) {
        OrderContact midascontact = new OrderContact();
        midascontact.Title = ord.TechnicalContact__r.Title;            
        midascontact.FirstName = ord.TechnicalContact__r.FirstName;
        midascontact.LastName = ord.TechnicalContact__r.LastName;
        midascontact.Email = ord.TechnicalContact__r.Email;
        midascontact.PhoneNumber = ord.TechnicalContact__r.Phone;
        return midascontact;
    }
    
    public static OrderContact mapEndUserContact (Order ord) {
        OrderContact midascontact = new OrderContact();
        midascontact.Title = ord.EndUserContact__r.Title;            
        midascontact.FirstName = ord.EndUserContact__r.FirstName;
        midascontact.LastName = ord.EndUserContact__r.LastName;
        midascontact.Email = ord.EndUserContact__r.Email;
        midascontact.PhoneNumber = ord.EndUserContact__r.Phone;
        return midascontact;
    }
    
    public static OrderContact mapSiteContact (Site__c site) {
        OrderContact midascontact = new OrderContact();
        midascontact.Title = site.SiteContact__r.Title;            
        midascontact.FirstName = site.SiteContact__r.FirstName;
        midascontact.LastName = site.SiteContact__r.LastName;
        midascontact.Email = site.SiteContact__r.Email;
        midascontact.PhoneNumber = site.SiteContact__r.Phone;
        return midascontact;
    }
    
    public static List<LineItems> mapLineItems (List<OrderItem> oiList) {
        system.debug('oiList::'+oiList.size());
        List<LineItems> orderItemJson = new List<LineItems>();
        for(OrderItem oi : oiList) {
            if (oi.Product2.ProductLine__c == 'Circuit' || oi.Product2.ProductLine__c == '' || oi.Product2.ProductLine__c == null) {
                orderItemJson.add(new LineItems(oi));
            }
        }
        
        for(OrderItem oi : oiList) {
            if (oi.Product2.ProductLine__c == 'Circuit Component') {
                addOnParent(orderItemJson, oi, 'Circuit');
            }
        }
        
        Set<Id> childItemIds = new Set<Id>();
        Map<String,List<LineItems>> groupedItems = new Map<String,List<LineItems>>();
        for(OrderItem oi : oiList) {
            if (oi.Product2.ProductLine__c == 'CPE' || oi.Product2.ProductLine__c == 'CPE Component') {
                if(!groupedItems.containsKey(oi.SBQQ__RequiredBy__c)){
                    groupedItems.put(oi.SBQQ__RequiredBy__c,new List<LineItems>());
                }
                groupedItems.get(oi.SBQQ__RequiredBy__c).add(new LineItems(oi));
            }
            
        }
        
        List<LineItems> cpeData = new List<LineItems>();
        Integer i = 0;
        for(OrderItem oi : oiList) {
            if (oi.Product2.ProductLine__c == 'CPE') {
                LineItems lineItem = new LineItems(oi);
                if(groupedItems.containsKey(oi.Id)){
                    List<LineItems> childItems = groupedItems.get(oi.Id);
                    List<LineItems> grandChildItems = new List<LineItems>();
                    for(LineItems childItem:childItems){
                        List<LineItems> items = addChildItems(childItem,groupedItems);
                        if(items != null && items.size()>0)grandChildItems.addAll(items);
                    }
                    childItems.addAll(grandChildItems);
                    lineItem.lineItems = childItems;
                }
                cpeData.add(lineItem);
            }
        }
        
        Boolean hasCircuit = false;
        for(LineItems cpe : cpeData) {
            for(LineItems parent : orderItemJson) {
                if (parent.productLine == 'Circuit' && parent.feature == cpe.feature) {
                    hasCircuit = true;
                    parent.lineItems.add(cpe);
                    break;
                }
            }
        }
        
        if(!hasCircuit){
            orderItemJson.addAll(cpeData);
        }
        
        return orderItemJson;
    }
    
    public static List<LineItems> addChildItems(LineItems childItem,Map<String,List<LineItems>> groupedItems){
        if(groupedItems.containsKey(childItem.Id)){
            List<LineItems> grandChildItems = groupedItems.get(childItem.Id);
            for(LineItems grandchildItem:grandChildItems){
                List<lineItems> grandGrandChildItems = addChildItems(grandchildItem,groupedItems);
                if(grandGrandChildItems != null && grandGrandChildItems.size()>0)grandChildItems.addAll(grandGrandChildItems);
            }
            return grandChildItems;
        }
        return null;
    }
    
    public static void addOnParent(List<LineItems> request, OrderItem oi, String parentline) {
        for(LineItems parent : request) {
            if (parent.productLine == parentline && parent.feature == oi.Feature_Name__c) {
                parent.lineItems.add(new LineItems(oi));
                break;
            }else{
                for(LineItems childli : parent.lineItems){
                    if (childli.productLine == parentline && childli.feature == oi.Feature_Name__c) {
                        childli.lineItems.add(new LineItems(oi));
                        break;
                    }
                }
            }
        }
    }*/
}