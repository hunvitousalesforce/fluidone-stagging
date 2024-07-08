public class RefreshSellPriceHelper {
    //Get map of pricebook entry ids against unit prices
    public static Map<Id, Decimal> getUnitPriceMap(){
        List<PricebookEntry> pricebookEntries = [
            SELECT 
            	Id,
            	UnitPrice
            FROM 	
            	PricebookEntry 
			WHERE 
				IsActive = true                        
        ];
        
        Map<Id, Decimal> priceMap = new Map<Id, Decimal>();
        for (PricebookEntry pbe : pricebookEntries) { 
        	priceMap.put(pbe.Id, pbe.UnitPrice);
        }
        
        return priceMap;
    }
}