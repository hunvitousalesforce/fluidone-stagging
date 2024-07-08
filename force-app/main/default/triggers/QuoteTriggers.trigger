trigger QuoteTriggers on SBQQ__Quote__c (after update) {
    QuoteTriggerHelper.runTriggers(Trigger.newMap);
}