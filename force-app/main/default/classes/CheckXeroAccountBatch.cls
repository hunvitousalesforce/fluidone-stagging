//Test: CheckXeroAccountBatchTest
public class CheckXeroAccountBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private static String query = 'SELECT Id, XeroAccountId__c FROM Account WHERE ApprovedInXero__c = false AND XeroAccountId__c != null';
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
     
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc_i : scope) {
            XeroAPI.AccountsResponse response = XeroAPI.getAccount(acc_i.XeroAccountId__c);
            System.debug('response: ' + response);

            if (response.isSuccess) {
                XeroObjects.XeroAccount xeroAccount = response.accounts.get(0);

                accountsToUpdate.add(
                    new Account(
                        XeroAccountId__c = xeroAccount.AccountID,
                        XeroAccountType__c = xeroAccount.Type,
                        XeroTaxType__c = xeroAccount.TaxType, 
                        XeroEnablePaymentsToAccount__c = xeroAccount.EnablePaymentsToAccount,
                        XeroBankAccountNumber__c = xeroAccount.BankAccountNumber,
                        XeroBankAccountType__c = xeroAccount.BankAccountType,
                        ApprovedInXero__c = !String.isBlank(xeroAccount.BankAccountNumber))
                );
            }      
        }

        System.debug('accountsToUpdate: size: ' + accountsToUpdate.size() + ' values: ' + accountsToUpdate);
        if (!accountsToUpdate.isEmpty()) {
            upsert accountsToUpdate Account.Fields.XeroAccountId__c;
        }
    }
  
    public void finish(Database.BatchableContext BC) {}
}