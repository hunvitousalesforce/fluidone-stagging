public without sharing class RecalculateAGPForOpportunityBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private Set<String> oppIds = new Set<String>();
    public RecalculateAGPForOpportunityBatch(Set<String> oppIds) {
        this.oppIds = oppIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT AGP_CPQ_QL__c,AGP_CPQ__c,Annualised_Gross_Profit_Total__c,Annualised_Gross_Profit__c,Annual_Dealer_Commission__c,'+
                                        'Category__c,Child_Opportunity_AGP_Text__c,Child_Opportunity_AGP__c,Child_Opportunity_Commission_as_AGP__c,Competitor__c,'+
                                        'Contract_Term__c,CPQ_Line_Item__c,CreatedById,CreatedDate,Create_Overlay_Opportunity__c,Description,Opportunity.StageName,'+
                                        'Expected_Annualised_Gross_Profit__c,Gross_Upgrade_Margin__c,Id,IsDeleted,Is_Inserted_By__c,Is_Updated_By__c,'+
                                        'LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Low_Annualised_Gross_Profit__c,Name,'+
                                        'Non_Recurring_Cost__c,Non_Recurring_Dealer_Commission__c,Non_Recurring_Margin__c,Non_Recurring_Profit2__c,'+
                                        'Non_Recurring_Profit__c,OpportunityId,Overlay_Sales_AGP_QAGP__c,Overlay_Split_Percentage__c,Overlay_Type__c,'+
                                        'Overlay_User__c,Parent_Annual_Dealer_Commission__c,Parent_Bundle__c,Parent_Opportunity_Id__c,Parent_Opportunity_Product__c,'+
                                        'Pillar__c,PricebookEntryId,Product2Id,Product_Family__c,Quantity,Q_AGP_CPQ_Formula__c,Q_AGP_CPQ__c,Q_AGP__c,'+
                                        'Recalculate_Sharing__c,Record_Type__c,Recurring_Cost__c,Recurring_Dealer_Commission__c,Recurring_Margin__c,'+
                                        'Recurring_Profit2__c,Recurring_Profit__c,Recurring__c,Related_Child_Opportunity_Product__c,Related_Child_Opportunity__c,'+
                                        'Sales_AGP_QAGP_Text__c,Sales_Price_Non_Recurring__c,sbaa__ApprovalStatus__c,SBQQ__ParentID__c,SBQQ__QuoteLine__c,'+
                                        'SBQQ__SubscriptionType__c,Sell_Type__c,ServiceDate,SortOrder,SubCategory__c,Subscription_Term__c,SystemModstamp,TotalPrice,'+
                                        'Total_Cost_Formula__c,Total_Cost__c,Total_Profit__c,Total_Value__c,UnitPrice,Unit_Sell__c FROM OpportunityLineItem '+
                                        'WHERE OpportunityId IN: oppIds');
    }    


    public void execute(Database.BatchableContext bc, List<OpportunityLineItem> opportunityLineItems){
        ProcessOppLineItemOnUpsertBatch executer = new ProcessOppLineItemOnUpsertBatch();
        //mark Opportunity Line Item update by trigger
        for(OpportunityLineItem opli:opportunityLineItems){
            opli.Is_Updated_By__c = executer.UPSERTED_BY_TRIGGER;
        }
        executer.execute(bc, opportunityLineItems);

    }

    public void finish(Database.BatchableContext bc){
    }


}