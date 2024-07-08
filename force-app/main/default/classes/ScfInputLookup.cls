public with sharing class ScfInputLookup {
    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper, Boolean onLoad) {
        try {
            if (inputWrapper != null) {
                String fieldsToQuery = 'SELECT Id, ';
                if (String.isNotBlank(inputWrapper.fieldApiName)) {
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                if (String.isNotBlank(inputWrapper.otherFieldApiName)) {
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                }
                if (String.isNotBlank(inputWrapper.extraFieldApiName)) {
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.extraFieldApiName;
                }
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
                likeClause += ')';

                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName;
                String filterCriteria = likeClause + (onLoad ? ' LIMIT 10' : ' LIMIT 50') ;
                if (String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ inputWrapper.selectedRecordId + '\'';
                } else if (String.isNotBlank(inputWrapper.parentFieldApiName) && String.isNotBlank(inputWrapper.parentRecordId)) {
                    query += ' WHERE '+ inputWrapper.parentFieldApiName+ ' = \''+ inputWrapper.parentRecordId + '\'';
                    query += ' AND ' + filterCriteria;
                } else {
                    query += ' WHERE '+ filterCriteria;
                }
                List<String> exIds = inputWrapper.exclusiveIds.split(',');
                Set<Id> exclusiveIds = new Set<Id>();
                for (String exId : exIds) {
                    if (String.isNotBlank(exId.trim())) {
                        exclusiveIds.add(exId);
                    }
                }
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                for(SObject s : Database.query(query)) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    wrap.subField = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.extraField = (String)s.get(inputWrapper.extraFieldApiName);
                    wrap.id = (String)s.get('id');
                    if (!exclusiveIds.contains(wrap.id)) {
                        returnWrapperList.add(wrap);
                    }
                }
                return returnWrapperList;
            }
            return null;
        }catch (Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
    }

    public class ResultWrapper {
        @AuraEnabled public String mainField {get;set;}
        @AuraEnabled public String subField {get;set;}
        @AuraEnabled public String extraField {get;set;}
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String debug {get;set;}
    }

    public class SearchWrapper {
        @AuraEnabled public String objectApiName {get;set;}
        @AuraEnabled public String fieldApiName {get;set;}
        @AuraEnabled public String otherFieldApiName {get;set;}
        @AuraEnabled public String extraFieldApiName {get;set;}
        @AuraEnabled public String searchString {get;set;}
        @AuraEnabled public String selectedRecordId {get;set;}
        @AuraEnabled public String parentRecordId {get;set;}
        @AuraEnabled public String parentFieldApiName {get;set;}
        @AuraEnabled public String exclusiveIds {get;set;}
    }
}