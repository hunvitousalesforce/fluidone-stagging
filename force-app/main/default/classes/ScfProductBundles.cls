public with sharing class ScfProductBundles {

    public static String mainName = 'Product2';
    public static String relatedName = 'SBQQ__ProductOption__c';

    public static List<String> mainFields = new List<String>{ 
        'Name' 
    };

    public static List<String> relatedFields = new List<String>{ 
        'SBQQ__ConfiguredSKU__c',
        'SBQQ__OptionalSKU__c',
        'SBQQ__OptionalSKU__r.Name',
        'SBQQ__OptionalSKU__r.Description'
    };

    @AuraEnabled
    public static Map<String, Object> massLoad(String recordId) {

        String query = 'SELECT Id';
        for (String field : relatedFields) {
            query += ', ' + field ;
        }
        query += ' FROM ' + relatedName;
        query += ' WHERE SBQQ__ConfiguredSKU__c =: recordId'; 
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        try {
            productOptions = (List<SBQQ__ProductOption__c>)Database.query(query);
        } catch (Exception e) { 
            throw new AuraException('Exception in queryRecords: ' + e.getMessage() + '[' + query + ']');
        }

        Map<Id, LineItemRecord> lineItemRecords = new Map<Id, LineItemRecord>();
        for (SBQQ__ProductOption__c productOption : productOptions) {
            LineItemRecord lineItemRecord = new LineItemRecord(mainName);
            if (!lineItemRecords.containsKey(productOption.SBQQ__OptionalSKU__c)) {
                lineItemRecord.item = productOption.SBQQ__OptionalSKU__r;
                lineItemRecords.put(productOption.SBQQ__OptionalSKU__c, lineItemRecord);
            }
        }
        return new Map<String, Object> {
            'lineItems' => lineItemRecords.values()
        };
    }

    public class LineItemRecord {
        @AuraEnabled
        public sObject item { get; set; }
        
        public LineItemRecord(String sobjectName) {
            item = (SObject) Type.forName('Schema', sobjectName).newInstance();
        }
    }
}