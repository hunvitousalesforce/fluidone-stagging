public with sharing class ContentDocumentLinkTriggerHandler {

    public static void handleAfterInsert(List<ContentDocumentLink> newList){
        MSAVersionHandler.updateAccountMSAVersionNumber(newList);
    }
}