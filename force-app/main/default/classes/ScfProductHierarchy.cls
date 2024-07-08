public with sharing class ScfProductHierarchy {
    @AuraEnabled
    public static Map<String, Object> fetchRecords(SearchWrapper inputWrapper, Boolean onLoad) {
        try {
            if (inputWrapper != null) {
                String fieldsToQuery = 'SELECT Id, ';
                if (String.isNotBlank(inputWrapper.fieldApiName)) {
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                if (String.isNotBlank(inputWrapper.otherFieldApiName)) {
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                }
                String[] selectedRows = inputWrapper.selectedRows;
                String searchString = String.escapeSingleQuotes(inputWrapper.searchString.trim());
                String likeClause = inputWrapper.fieldApiName + ' LIKE ' + '\'%' + searchString + '%\'';
                likeClause = '(' + likeClause;
                if (onLoad) {
                    List<String> tokens = searchString.split(' ');
                    for (String token : tokens) {
                        if (String.isNotBlank(token.trim())) {
                            likeClause += ' OR ' + inputWrapper.otherFieldApiName + ' LIKE ' + '\'%' + token.trim() + '%\'';
                        }
                    }
                } else {
                    likeClause += ' OR ' + inputWrapper.otherFieldApiName + ' LIKE ' + '\'%' + searchString.trim() + '%\'';
                }
                likeClause += ' OR Id IN: selectedRows)';

                String filterCriteria = 'Parent_Product__c = true AND '+ likeClause + (onLoad ? ' LIMIT 10' : ' LIMIT 50') ;
                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName + ' WHERE '+ filterCriteria;
                Set<String> parentIds = new Set<String>();
                List<ResultWrapper> superParentList = new List<ResultWrapper>();
                for(SObject s : Database.query(query)) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    wrap.subField = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.id = (String)s.get('id');
                    parentIds.add(wrap.id);
                    superParentList.add(wrap);
                }

                Map<String, List<ResultWrapper>> mapObjects = new Map<String, List<ResultWrapper>>();
                for (SBQQ__ProductOption__c sRelation : [Select Id, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.Description, SBQQ__ConfiguredSKU__c From SBQQ__ProductOption__c Where SBQQ__ConfiguredSKU__c IN: parentIds OR SBQQ__ConfiguredSKU__c IN: selectedRows OR SBQQ__OptionalSKU__c IN: selectedRows]) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = sRelation.SBQQ__OptionalSKU__r.Name;
                    wrap.subField = sRelation.SBQQ__OptionalSKU__r.Description;
                    wrap.id = sRelation.SBQQ__OptionalSKU__c + '#' + sRelation.Id;
                    wrap.parentId = sRelation.SBQQ__ConfiguredSKU__c;
                    List<ResultWrapper> children = mapObjects.get(wrap.parentId);
                    if (children != null) {
                        children.add(wrap);
                    } else {
                        mapObjects.put(wrap.parentId, new List<ResultWrapper>{ wrap });
                    }
                }

                return new Map<String, Object>{
                    'superLevel' => superParentList,
                    'dto' => mapObjects
                };
            }
            return null;
        }catch (Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
    }

    public class ResultWrapper {
        @AuraEnabled public String mainField {get;set;}
        @AuraEnabled public String subField {get;set;}
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String parentId {get;set;}
        @AuraEnabled public String debug {get;set;}
    }

    public class SearchWrapper {
        @AuraEnabled public String objectApiName {get;set;}
        @AuraEnabled public String fieldApiName {get;set;}
        @AuraEnabled public String otherFieldApiName {get;set;}
        @AuraEnabled public String searchString {get;set;}
        @AuraEnabled public String[] selectedRows {get;set;}
    }
}