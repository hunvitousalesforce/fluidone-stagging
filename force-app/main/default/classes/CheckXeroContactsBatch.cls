public class CheckXeroContactsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private static String query = 'SELECT Id, XeroContactId__c FROM Account WHERE ApprovedInXero__c = false AND XeroContactId__c != null';
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
     
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc_i : scope) {
            XeroAPI.ContactsResponse response = XeroAPI.getContactNew(acc_i.XeroContactId__c);
            System.debug('response: ' + response);

            if (response.isSuccess) {
                XeroObjects.XeroContact xeroContact = response.Contacts.get(0);

                accountsToUpdate.add(
                    new Account(
                        XeroContactId__c = xeroContact.ContactID,                        
                        ApprovedInXero__c = !String.isBlank(xeroContact.AccountNumber), 
                    	XeroAccountCode__c = xeroContact.AccountNumber
                    )
                    
                );
            }      
        }

        System.debug('accountsToUpdate: size: ' + accountsToUpdate.size() + ' values: ' + accountsToUpdate);
        if (!accountsToUpdate.isEmpty()) {
            upsert accountsToUpdate Account.Fields.XeroContactId__c;
        }
    }
  
    public void finish(Database.BatchableContext BC) {}
}