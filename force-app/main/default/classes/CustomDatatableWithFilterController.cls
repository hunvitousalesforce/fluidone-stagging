public with sharing class CustomDatatableWithFilterController {
	private static String queryWhere = 'SELECT Id, Name, Description, Parent_Product__c, SBQQ__DefaultQuantity__c, SBQQ__SubscriptionPricing__c, (Select Id, SBQQ__UnitCost__c From SBQQ__Costs__r Where SBQQ__Active__c = true Limit 1) FROM Product2 Where';
	public CustomDatatableWithFilterController() {}

    @AuraEnabled
    public static Map<Id, Product2> getProductSelections(List<Id> Ids){

      String query = '';
      Map<Id, Product2> result = new Map<Id, Product2>();
      try {
        List<Product2> products = Database.query(queryWhere + ' Id IN :Ids And IsActive = true');

        for (Product2 product : products ) {
          result.put(product.Id, product);
        }
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
      System.debug(result);
      return result;
    }

    @AuraEnabled(cacheable = true)
    public static List<Product2> getProduct2List(String keyword) {
		
        if (String.isNotBlank(keyword)) {
            List<String> keywordList = keyword.split(' ');
            String query = '';
            for (String word: keywordList) {
                query += word + '* OR ';
            }
            query = query.substring(0, query.length() - 4); // Remove the trailing ' OR '
            List<List<SObject>> searchList = [
                FIND: query
                IN NAME FIELDS
                RETURNING
                Product2(Id)
            ];
			Set<String> prodIds = new Map<String, Product2>(((List<Product2>) searchList[0])).keySet();
            return Database.query(queryWhere + ' Id IN :prodIds And IsActive = true LIMIT 400');
        } else {
            return Database.query(queryWhere + ' IsActive = true And SBQQ__DefaultQuantity__c <> null And Parent_Product__c = true LIMIT 100');
        }
    }

    @AuraEnabled
    public static List<Product2> getChildProduct(String parentId) {
        Map<String, String> prodIds = new Map<String, String>();
		for (SBQQ__ProductOption__c prodOpt : [ SELECT Id, SBQQ__OptionalSKU__c, SBQQ__ConfiguredSKU__c FROM SBQQ__ProductOption__c WHERE SBQQ__ConfiguredSKU__c =: parentId And SBQQ__OptionalSKU__r.IsActive = true]) {
			prodIds.put(prodOpt.SBQQ__OptionalSKU__c, prodOpt.SBQQ__ConfiguredSKU__c);
		}
		Set<String> prodIdSet = prodIds.keySet();
		List<Product2> prods = Database.query(queryWhere + ' Id IN :prodIdSet And IsActive = true');
		//Utilize StockKeepingUnit as parent Id
		for (Product2 prod : prods) {
			prod.StockKeepingUnit = prodIds.get(prod.Id);
		}
        return prods;
    }
}