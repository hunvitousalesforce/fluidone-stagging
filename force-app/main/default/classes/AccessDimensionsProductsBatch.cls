/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 04-01-2023
 * @last modified by  : matthew.rosete@pracedo.com
**/
global class AccessDimensionsProductsBatch implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts{

	global Iterable<Object> start(Database.BatchableContext BC){
                
        //Do logging 
        HttpResponse response = DimensionsStockAPI.getDimensionsStock();
        Map<String,Object> initialResponse = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> stockCodes = (List<Object>) initialResponse.get('data');
        return stockCodes;

    }
     
    global void execute(Database.BatchableContext BC, List<Object> scope){
        List<Product2> products = [
            SELECT 
                ProductCode,
                Id
            FROM 
                Product2 
            WHERE 
                ProductCode <> null            
        ];

        Map<String,Product2> productCodeMap = new Map<String,Product2>();
        for (Product2 p : products) {
            productCodeMap.put(p.ProductCode, p);
        }

        //Map of all existing costs in case it needs upating 
        List<SBQQ__Cost__c> costs = [
            SELECT Id,
                SBQQ__Product__r.ProductCode,
                SBQQ__UnitCost__c
            FROM SBQQ__Cost__c 
            WHERE SBQQ__Product__r.ProductCode <> null
        ];

        //Map of all existing open quote lines in case costs need upating 
        

        Map<String, SBQQ__Cost__c> productCodeCostMap = new Map<String, SBQQ__Cost__c>();
        for (SBQQ__Cost__c c : costs) {
            productCodeCostMap.put(c.SBQQ__Product__r.ProductCode, c);
        }
        
        Id stdPricebook = [select id, name from Pricebook2 where isStandard = true limit 1].Id;                

        List<Product2> newProducts = new List<Product2>();
        List<Product2> productsToUpdate = new List<Product2>();

        Map<String,SBQQ__Cost__c> newCosts = new Map<String,SBQQ__Cost__c>();
        //List<PricebookEntry> newStandardPbes = new List<PricebookEntry>();
        Map<String,List<PricebookEntry>> customPbesMap = new Map<String,List<PricebookEntry>>();
        List<SBQQ__Cost__c> costsToUpdate = new List<SBQQ__Cost__c>();
        List<Id> productsWithUpdatedCosts  = new List<Id>();

        Map<Id, Decimal> newProductCostMap = new Map<Id,Decimal>();
        Map<String,PricebookEntry> standardPBEMap = new Map<String,PricebookEntry>();
        List<Pricebook2> customPricebooks = [
            SELECT Id
            FROM Pricebook2 
            WHERE isActive = TRUE AND 
            isStandard = FALSE
        ];
        //Loop around all the stock codes retrieved through the API 
        for (Object sc : scope) {
            system.debug('sc:::'+sc);
            Map<String,Object> scMap = (Map<String,Object>) sc;
            /*system.debug('scMap:::'+scMap.keySet());
            for(String scKey:scMap.keySet()){
                system.debug('key:::'+scKey);
            }*/
            //If the product does not yet exist, create it along with the cost.
            String code = (String)scMap.get('code');
            code = code != null? code.trim():code;
            
            if ((!productCodeMap.containsKey(code) || productCodeMap.get(code) == null)) {
                system.debug('code:::'+code);
                Product2 newProduct = new Product2(
                    Name = (String) scMap.get('description'), 
                    ProductCode = code,
                    ADId__c = code,
                    NewFromAccessDimensions__c = true ,
                    Category__c = (String) scMap.get('category'),
                    Pillar__c = (String) scMap.get('pillar'),
                    SubCategory__c = (String) scMap.get('subcategory'),
                    isActive = (Boolean)scMap.get('isActive')
                );
                newProducts.add(newProduct);

                SBQQ__Cost__c newCost = new SBQQ__Cost__c (
                    //SBQQ__Product__r = new Product2(ADId__c = code),
                    SBQQ__UnitCost__c = (Decimal) scMap.get('cost')                    
                );
                // Prabhakar On Jan 23, 2023: The code is missing…. so updating it 
                newCosts.put(newProduct.ADId__c,newCost);

                PricebookEntry pbe = new PricebookEntry (
                    //Product2 = newProduct, 
                    UnitPrice = 0, 
                    IsActive = true,                     
                    Pricebook2Id = stdPricebook
                );
                // Prabhakar On Jan 11, 2023: The code is missing…. so updating it 
                standardPBEMap.put(newProduct.ProductCode,pbe);
                //Get all active non standard PBs so can create them in those price books also 
				List<PricebookEntry> pricebookEntrys = new List<PricebookEntry>();
                for (Pricebook2 pb : customPricebooks) {
                    PricebookEntry customPbe = new PricebookEntry(IsActive = true,UnitPrice = 0); 
                    customPbe.Pricebook2Id = pb.Id;
                    pricebookEntrys.add(customPbe);
                } 
                customPbesMap.put(newProduct.ProductCode, pricebookEntrys);
            } else {                
                //Add to list so can later use to query all open quote lines with same product and upate the costs
                Product2 currentProduct = productCodeMap.get(code);
                currentProduct.Name = (String) scMap.get('description');
               	currentProduct.ADId__c = code;
                currentProduct.Category__c = (String) scMap.get('category');
                currentProduct.Pillar__c = (String) scMap.get('pillar');
                currentProduct.SubCategory__c = (String) scMap.get('subcategory');
                currentProduct.isActive = (Boolean)scMap.get('isActive');
                productsToUpdate.add(currentProduct);
                productsWithUpdatedCosts.add(currentProduct.Id);
                //If product does exist, get corresponding cost - update it 
                SBQQ__Cost__c currentCost = productCodeCostMap.get(code.trim());
                Decimal cost = scMap.get('cost') != null ? (DECIMAL)scMap.get('cost'):Null;
                if (currentCost != null && currentCost.SBQQ__UnitCost__c != cost) {
                    newProductCostMap.put(currentProduct.Id,cost);
                    currentCost.SBQQ__UnitCost__c = cost;
                    costsToUpdate.add(currentCost);
                }

                
            }
            
        }


        //Get all quote lines related to quotes with open opps - update them to the new updated costs if any.
        List<SBQQ__QuoteLine__c> quoteLinesToUpdateCost = new List<SBQQ__QuoteLine__c>();

        /*for (SBQQ__QuoteLine__c ql : [
            SELECT Id,SBQQ__Product__c,SBQQ__UnitCost__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != 'Lost' AND 
                SBQQ__Product__c IN :productsWithUpdatedCosts
        ]) {
            if(ql.SBQQ__UnitCost__c != newProductCostMap.get(ql.SBQQ__Product__c)){
            	ql.SBQQ__UnitCost__c = newProductCostMap.get(ql.SBQQ__Product__c);
                quoteLinesToUpdateCost.add(ql);
            }
        }*/
        for (SBQQ__QuoteLine__c ql : [
            SELECT Id,SBQQ__Product__c,SBQQ__UnitCost__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != 'Closed Won' AND 
                SBQQ__Product__c IN :productsWithUpdatedCosts AND SBQQ__Quote__r.SBQQ__ExpirationDate__c< TODAY
        ]) {
            if(ql.SBQQ__UnitCost__c != newProductCostMap.get(ql.SBQQ__Product__c)){
            	ql.SBQQ__UnitCost__c = newProductCostMap.get(ql.SBQQ__Product__c);
                quoteLinesToUpdateCost.add(ql);
            }
        }
        system.debug('newProducts::::'+newProducts);   
        database.insert(newProducts,false);
        database.update(productsToUpdate, false);
        // Prabhakar On Jan 11, 2023: The code is missing…. so updating it 
        List<PricebookEntry>  customPriceBookEntries = new List<PricebookEntry>();
        for(Product2 product:newProducts){
            PricebookEntry pbe = standardPBEMap.get(product.ProductCode);
            pbe.product2Id = product.Id;
            standardPBEMap.put(product.ProductCode,pbe);
            List<PricebookEntry> customPBEs = customPbesMap.get(product.ProductCode);
            for(PricebookEntry entry:customPBEs){
                entry.product2Id = product.Id;
            }
            customPriceBookEntries.addAll(customPBEs);
            SBQQ__Cost__c cost = newCosts.get(product.ProductCode);
            cost.SBQQ__Product__c = product.Id;
            newCosts.put(product.ProductCode,cost);
        }
        database.insert( standardPBEMap.values(),false);  
        database.insert( customPriceBookEntries,false); 
        database.insert( newCosts.values(),false);
        system.debug('standardPBEMap:::'+standardPBEMap);
        if(costsToUpdate.size()>0)database.update( costsToUpdate,false);
        if(quoteLinesToUpdateCost.size()>0)database.update( quoteLinesToUpdateCost,false);  
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}