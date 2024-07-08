public with sharing class MSAVersionHandlerBatchable implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, (SELECT Id, ContentDocument.Title FROM ContentDocumentLinks WHERE ContentDocument.Title LIKE \'%FluidOne MSA v%\') FROM Account WHERE Signed_MSA_attached__c = TRUE';
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Account> accountsToUpdate = new List<Account>();

        for(Sobject s : scope){
            Account account = (Account) s;
            System.debug('account: '+account);
            Decimal maxVersionNumber = MSAVersionHandler.getMaximumMSAFileVersionNumber(account.ContentDocumentLinks);
            if(maxVersionNumber != null){
                account.MSA_Version_Number__c = maxVersionNumber;
                accountsToUpdate.add(account);
            }

        }

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
   }

    public void finish(Database.BatchableContext BC){}

}