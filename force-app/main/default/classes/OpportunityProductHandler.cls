public without sharing class OpportunityProductHandler {

    public static RecordType  rt = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive, CreatedDate, CreatedById, LastModifiedById, LastModifiedDate, SystemModstamp FROM RecordType WHERE DeveloperName='Child_Opportunity' LIMIT 1];
    public static final String SALES_AGP = 'Sales as AGP';
    public static final String COMMISSION_AS_AGP = 'Commission as AGP';
    public static Boolean runShareOnce = true;
    public static Boolean hasCloned = false;
    public static Map<String,Set<Id>> mapExecutedRecord = new Map<String,Set<Id>>();

    public static Set<String> opportunityFieldNames {
        get {
            if (opportunityFieldNames == null) {
                String lowerCase = JSON.serialize(Schema.SObjectType.Opportunity.Fields.getMap().keySet()).toLowerCase();
                opportunityFieldNames = (Set<String>)JSON.deserialize(lowerCase, Set<String>.class);
            }
            return opportunityFieldNames;
        } 
        private set;
    }

    public static void handleBeforeInsert(List<OpportunityLineItem> opportunityLineItems){
        System.debug('***handleBeforeInsert***');
        /***Moved to ProcessOppLineItemOnUpsertBatch***/
        //setOverlayFieldOnProduct(opportunityLineItems);
        Set<Id> oppIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
            if(opportunityLineItem.Is_Inserted_By__c != 'Batch'){
                opportunityLineItem.Is_Inserted_By__c = 'Trigger';
            }
            //Copied over from Flow
            updateContractTerm(opportunityLineItem);

            oppIds.add(opportunityLineItem.OpportunityId);
            prodIds.add(OpportunityLineItem.Product2Id);
        }
        //we poppulate the overlay field for parent opportunity only
        Map<Id,Opportunity> id2Opp = getOpportunityMap(oppIds);
        Map<Id,Product2> id2Prod = new Map<Id,Product2>([Select Id,Family FROM Product2 WHERE Id IN :prodIds]);
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
            Opportunity opp = id2Opp.get(opportunityLineItem.OpportunityId);
            if(opp!=null){
                Product2 p = id2Prod.get(opportunityLineItem.Product2Id);
                populateProductOverlayFields(opportunityLineItem, p.Family, opp);
            }
        }


    }

    public static void handleBeforeUpdate(Map<Id, OpportunityLineItem> newOpportunityLineItemMap, Map<Id, OpportunityLineItem> oldOpportunityLineItemMap){
        System.debug('***handleBeforeUpdate***');
        /***Moved to ProcessOppLineItemOnUpsertBatch***/
        //setOverlayFieldOnProduct(opportunityLineItems);
        Set<Id> lstExecuted  = mapExecutedRecord.get('beforeUpdate');
        if(lstExecuted==null){
            lstExecuted = new Set<Id>();
            mapExecutedRecord.put('beforeUpdate', lstExecuted);

        }
        Map<Id,Opportunity> opportunityMap = getOpportunityMap(newOpportunityLineItemMap.values());
        for(OpportunityLineItem opli : newOpportunityLineItemMap.values()){          
         
            System.debug('***opportunityLineItem Id***'+opli.Id);
            System.debug('***opportunityLineItem.Is_Updated_By__c***'+opli.Is_Updated_By__c);
            System.debug('***oldOpportunityLineItemMap.get(opportunityLineItem.Id).Is_Updated_By__c***'+oldOpportunityLineItemMap.get(opli.Id).Is_Updated_By__c);
            
            if(!lstExecuted.contains(opli.Id)){
                if((opli.Is_Updated_By__c == 'Batch' && opli.Is_Updated_By__c == oldOpportunityLineItemMap.get(opli.Id).Is_Updated_By__c) ||
                    String.isBlank(opli.Is_Updated_By__c)||(opli.Parent_Opportunity_Product__c == null && opli.AGP_CPQ__c != opli.AGP_CPQ_QL__c && opli.SBQQ__QuoteLine__c !=null)
                ){
                    System.debug('***Is_Updated_By__c set to Trigger***');
                    opli.Is_Updated_By__c = 'Trigger';
                    if(opli.AGP_CPQ__c != opli.AGP_CPQ_QL__c && opli.SBQQ__QuoteLine__c !=null){
                        populateProductOverlayFields(opli, opli.Product_Family__c, opportunityMap.get(opli.OpportunityId));
                        updateOpliAGP(opli);
                    }
                }
                lstExecuted.add(opli.Id);
            }
            If(opli.Overlay_User__c != oldOpportunityLineItemMap.get(opli.Id).Overlay_User__c){
                opli.Recalculate_Sharing__c = true;
            }
            //Copied over from Flow
            updateContractTerm(opli);
            
        }
    }
    

    public static void handleAfterInsert(List<OpportunityLineItem> opportunityLineItems){
        /***Moved to ProcessOppLineItemOnUpsertBatch***/
        //added map & converted handle afterinsert logic to future
        //Map<Id, OpportunityLineItem> OpportunityLineItemMap = new Map<Id, OpportunityLineItem>(opportunityLineItems);
        //handleAfterInsertLogic(OpportunityLineItemMap.keySet());
    }

    public static void handleAfterUpdate(List<OpportunityLineItem> opportunityLineItems){
        List<OpportunityLineItem> lstChild = new List<OpportunityLineItem>();
        Set<Id> pIds = new Set<Id>();
        Set<Id> lstExecuted  = mapExecutedRecord.get('handleAfterUpdate');
        if(lstExecuted==null){
            lstExecuted = new Set<Id>();
            mapExecutedRecord.put('handleAfterUpdate', lstExecuted);

        }
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
            if(!lstExecuted.contains(opportunityLineItem.Id) && opportunityLineItem.Parent_Opportunity_Product__c == null && opportunityLineItem.Is_Updated_By__c != 'Batch'){
                pIds.add(opportunityLineItem.Id);
                lstExecuted.add(opportunityLineItem.Id);
            }
        }
        if(!pIds.isEmpty()){
            //mark update for all child to reculculate
            for(OpportunityLineItem childOpportunityLineItem : [SELECT Id, Parent_Opportunity_Product__c FROM OpportunityLineItem WHERE Parent_Opportunity_Product__c IN :pIds]){
                childOpportunityLineItem.Is_Updated_By__c = 'Trigger';
                lstChild.add(childOpportunityLineItem);
            }
            system.debug('lstChild:'+lstChild);
            if(!lstChild.isEmpty())  update lstChild;
        }
        
            /***Moved to ProcessOppLineItemOnUpsertBatch -  START**
            Map<Id, OpportunityLineItem> parentOpportunityLineItemsWithoutChildOpportunityLineItems = new Map<Id, OpportunityLineItem>();
            List<OpportunityLineItem> parentOLIsToUpdate = new List<OpportunityLineItem>();

        //Apex CPU Limit Optimization 
            Map<Id,OpportunityLineItem> parentOppLineItemToOppLineItemMap = new Map<Id,OpportunityLineItem>();
            for(OpportunityLineItem childOpportunityLineItem : [SELECT Id, Parent_Opportunity_Product__c FROM OpportunityLineItem WHERE Opportunity.Parent_Opportunity__c != null AND Parent_Opportunity_Product__c IN :new Map<Id,OpportunityLineItem>(opportunityLineItems).keySet()]){
                parentOppLineItemToOppLineItemMap.put(childOpportunityLineItem.Parent_Opportunity_Product__c, childOpportunityLineItem);
            }
            for(OpportunityLineItem oppLineItem: opportunityLineItems){
                if(!parentOppLineItemToOppLineItemMap.containsKey(oppLineItem.Id)){
                    parentOpportunityLineItemsWithoutChildOpportunityLineItems.put(oppLineItem.Id, oppLineItem);
                }
            }
            END*/
            
            /*List<OpportunityLineItem> childOpportunityLineItems = [SELECT Id, Parent_Opportunity_Product__c FROM OpportunityLineItem WHERE Opportunity.Parent_Opportunity__c != null AND Parent_Opportunity_Product__c IN :new Map<Id,OpportunityLineItem>(opportunityLineItems).keySet()];
            
            System.debug('opportunityLineItems>>>>' + opportunityLineItems);
            
            
            for(OpportunityLineItem opportunityLineItem:opportunityLineItems){
                Boolean hasOLI = false;
                for(OpportunityLineItem childOpportunityLineItem:childOpportunityLineItems){
                    System.debug('CRITERIA>>>>>>>>' + childOpportunityLineItem.Parent_Opportunity_Product__c + '<<<<>>>>>' + opportunityLineItem.Id);
                    if(childOpportunityLineItem.Parent_Opportunity_Product__c == opportunityLineItem.Id){
                        hasOLI = true;
                        System.debug('hasOLI>>>>' + hasOLI);
                    }
                }
                if(!hasOLI){
                    System.debug('***has No OLI>>>>' + opportunityLineItem);
                    parentOpportunityLineItemsWithoutChildOpportunityLineItems.add(opportunityLineItem);
        //End
                    // if(firstRun){
                    //     firstRun = false;
                    //     Map<Id,OpportunityLineItem> childOli = new Map<Id, OpportunityLineItem>();
                    //     childOli.put(opportunityLineItem.Id, opportunityLineItem);

                    //     List<Id> parentIds = new List<Id>();
                    //     for(OpportunityLineItem coli : childOli.values()){
                    //         parentIds.add(coli.Parent_Opportunity_Product__c);
                    //     }

                    //     Map<Id, OpportunityLineItem> parentOlis = new Map<Id, OpportunityLineItem> ([SELECT Id, Annualised_Gross_Profit__c, Overlay_Split_Percentage__c FROM OpportunityLineItem WHERE Id IN: parentIds]);

                    //     System.Debug('childOli>>>>>' + childOli);
                    //     System.Debug('parentOlis>>>>>' + parentOlis);


                    //     parentOLIsToUpdate.addAll(OpportunityProductHandler.updateParentOLIRelatedChild(parentOlis, childOli));
                    // }
        //Apex CPU Limit Optimization          
                    }
                }
                if(!parentOLIsToUpdate.isEmpty()){
                    System.debug('parentOLIsToUpdate>>>>'+parentOLIsToUpdate);
                    update parentOLIsToUpdate;
                }*/           
        //End

        /***Moved to ProcessOppLineItemOnUpsertBatch -  START**
            if(!parentOpportunityLineItemsWithoutChildOpportunityLineItems.isEmpty()){
                handleAfterInsertLogic(parentOpportunityLineItemsWithoutChildOpportunityLineItems.keySet());
            }       
            updateChildOpportunityLineItem(opportunityLineItems);
            //TriggerContextUtility.setFirstRunFalse()
        END**/
    }

    public static void handleBeforeDelete(List<OpportunityLineItem> opportunityLineItems){
        System.debug('***handleBeforeDelete***');
        //deleteChildOpportunityLineItems(opportunityLineItems);
    }

    public static void handleAfterDelete(List<OpportunityLineItem> opportunityLineItems){
        Set<Id> lstExecuted  = mapExecutedRecord.get('handleAfterDelete');
        if(lstExecuted==null){
            lstExecuted = new Set<Id>();
            mapExecutedRecord.put('handleAfterDelete', lstExecuted);

        }
        List<OpportunityLineItem> lstOpli = new List<OpportunityLineItem>();
        for(OpportunityLineItem opli:opportunityLineItems){
            if(!lstExecuted.contains(opli.Id)){
                lstExecuted.add(opli.Id);
                lstOpli.add(opli);
            }
        }
        if(!lstOpli.isEmpty()){
            System.debug('***handleAfterDelete***');
            deleteChildOpportunityLineItems(lstOpli);
            deleteChildOpportunities(lstOpli);
        }
      
    }

    public static void handleAfterUpdate(Map<Id,Opportunity> newOpportunityMap, Map<Id,Opportunity> oldOpportunityMap){
         Set<Id> lstExecuted  = mapExecutedRecord.get('handleAfterUpdate');
        if(lstExecuted==null){
            lstExecuted = new Set<Id>();
            mapExecutedRecord.put('handleAfterUpdate', lstExecuted);

        }
        Map<Id,Opportunity> mapOppUpdate = new Map<Id,Opportunity>();
        for(Id oppId : newOpportunityMap.keySet()){
            if(!lstExecuted.contains(oppId)){
                lstExecuted.add(oppId);
                mapOppUpdate.put(oppId, newOpportunityMap.get(oppId));
            }
        }
        System.debug('***handleAfterUpdate***');
        updateOpportunityProductOverlayFields(mapOppUpdate, oldOpportunityMap);
    }

    /**TO DEPRECATE */
    /***public static Map<Id,OpportunityProductFamiliesAndLineItems> createNewProductFamilyOpportunities(List<OpportunityLineItem> opportunityLineItems){
        System.debug('***createNewProductFamilyOpportunities***');
        Map<Id,Opportunity> opportunityMap = getOpportunityMap(opportunityLineItems);
        Map<Id,OpportunityProductFamiliesAndLineItems> opportunityIdToExistingProducts = getOpportunityIdToExistingProductFamilies(opportunityLineItems, opportunityMap.keySet());      
        if(!opportunityMap.isEmpty()){
            System.debug('***opportunityMap NOT EMPTY***');
            List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        //Apex CPU Limit Optimization
            /*for(Id opportunityId:opportunityIdToExistingProducts.keySet()){
                OpportunityProductFamiliesAndLineItems existingProducts = opportunityIdToExistingProducts.get(opportunityId);
                for(OpportunityLineItem opportunityLineItem:opportunityLineItems){
                    if(opportunityLineItem.OpportunityId == opportunityId){
                        if(!existingProducts.productFamiliesToChildOpportunities.keySet().contains(opportunityLineItem.Product_Family__c)){
                            Opportunity opportunity = opportunityMap.get(opportunityId);
                            Opportunity childOpportunity = createChildOpportunity(opportunity, opportunityLineItem.Product_Family__c);
                            if(childOpportunity != null){
                                existingProducts.productFamiliesToChildOpportunities.put(opportunityLineItem.Product_Family__c, childOpportunity);
                                opportunitiesToInsert.add(childOpportunity);
                            }
                            
                        }
                    }
                    else{
                        continue;
                    }
                }
            }*/

            /***for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
                if(opportunityIdToExistingProducts.containsKey(opportunityLineItem.OpportunityId)){
                    if(!opportunityIdToExistingProducts.get(opportunityLineItem.OpportunityId).productFamiliesToChildOpportunities.keySet().contains(opportunityLineItem.Product_Family__c)){
                        Opportunity opportunity = opportunityMap.get(opportunityLineItem.OpportunityId);
                        Opportunity childOpportunity = createChildOpportunity(opportunity, opportunityLineItem.Product_Family__c);
                        System.debug('***childOpportunity***'+childOpportunity);
                        if(childOpportunity != null){
                            opportunityIdToExistingProducts.get(opportunityLineItem.OpportunityId).productFamiliesToChildOpportunities.put(opportunityLineItem.Product_Family__c, childOpportunity);
                            opportunitiesToInsert.add(childOpportunity);
                        }
                    }
                }
            }
        //End
        System.debug('***opportunitiesToInsert***'+opportunitiesToInsert);
            if(!opportunitiesToInsert.isEmpty()){
                insert opportunitiesToInsert;
            }
        }     
        return opportunityIdToExistingProducts;
    }***/


    /**TO DEPRECATE */
    /***public static void cloneOpportunityLineItems(Map<Id,OpportunityProductFamiliesAndLineItems> opportunityIdToProposedProducts, List<OpportunityLineItem> opportunityLineItems){
        system.debug('***cloneOpportunityLineItems***');
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<Opportunity> childOpportunitiesCL = new List<Opportunity>();

        for(OpportunityLineItem opportunityLineItem:opportunityLineItems){

            //Added by deepak to optimize
            /*Opportunity childOpportunity = opportunityIdToProposedProducts.containsKey(opportunityLineItem.OpportunityId) ? 
            (opportunityIdToProposedProducts.get(opportunityLineItem.OpportunityId).productFamiliesToChildOpportunities.containsKey(opportunityLineItem.Product_Family__c) ? opportunityProductFamiliesAndLineItems.productFamiliesToChildOpportunities.get(opportunityLineItem.Product_Family__c) : NULL) : NULL;*/
            
            /***if(opportunityIdToProposedProducts.containsKey(opportunityLineItem.OpportunityId)){

                OpportunityProductFamiliesAndLineItems opportunityProductFamiliesAndLineItems = opportunityIdToProposedProducts.get(opportunityLineItem.OpportunityId);
                system.debug('***opportunityProductFamiliesAndLineItems***'+opportunityProductFamiliesAndLineItems);
                if(opportunityProductFamiliesAndLineItems.productFamiliesToChildOpportunities.containsKey(opportunityLineItem.Product_Family__c)){
                    Opportunity childOpportunity = opportunityProductFamiliesAndLineItems.productFamiliesToChildOpportunities.get(opportunityLineItem.Product_Family__c);
                    OpportunityLineItem childOpportunityLineItem = createChildOpportunityLineItem(opportunityLineItem, childOpportunity);
                    
                    if(childOpportunityLineItem <> null){
                        opportunityLineItemsToInsert.add(childOpportunityLineItem);
                        childOpportunitiesCL.add(childOpportunity);
                    }
                    
                }

            }
        }

        if(opportunityLineItemsToInsert.size() > 0 && !hasCloned){
            hasCloned = true;
            if(!childOpportunitiesCL.isEmpty()){
                updateClosedLostOpportunity(childOpportunitiesCL);
            }
            insert opportunityLineItemsToInsert;
            Map<Id, OpportunityLineItem> parentOlis = new Map<Id,OpportunityLineItem>(opportunityLineItems);
            Map<Id, OpportunityLineItem> childOlis = new Map<Id,OpportunityLineItem>(opportunityLineItemsToInsert);

            if(!parentOlis.isEmpty() && !childOlis.isEmpty()){
                List<OpportunityLineItem> parentOLIsToUpdate = OpportunityProductHandler.updateParentOLIRelatedChild(parentOlis, childOlis);          
                if(!parentOLIsToUpdate.isEmpty()){
                    update parentOLIsToUpdate;
                }
            }
        }
    }***/

    public static Map<Id,Opportunity> getOpportunityMap(List<OpportunityLineItem> opportunityLineItems){
        Set<Id> opportunityIds = new Set<Id>();

        for(OpportunityLineItem opportunityLineItem:opportunityLineItems){
            opportunityIds.add(opportunityLineItem.OpportunityId);
        }

        System.debug('oopportunityIds>>>>' + opportunityIds);

        return getOpportunityMap(opportunityIds);
    }

    public static Map<Id,Opportunity> getOpportunityMap(Set<Id> opportunityIds){
        return new Map<Id,Opportunity>([SELECT Id, IsDeleted, AccountId, Account.Name , RecordTypeId, IsPrivate, Name, Description, StageName, Amount,
        Probability, ExpectedRevenue, TotalOpportunityQuantity, CloseDate, Type, NextStep, LeadSource, IsClosed, IsWon, 
        ForecastCategory, ForecastCategoryName, CampaignId, HasOpportunityLineItem, Pricebook2Id, OwnerId, CreatedDate,
        CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, FiscalQuarter, FiscalYear, 
        Fiscal, ContactId, LastViewedDate, LastReferencedDate, ContractId, HasOpenActivity, HasOverdueTask, 
        LastAmountChangedHistoryId, LastCloseDateChangedHistoryId, Contract_Term__c, DB_Competitor__c, PushCount__c, 
        Authority_Comment_Justification__c, Authority_Question__c, Authority_Score__c, Authority__c, Budget__c, 
        Comment_Competition__c, Competition_Question__c, Competition_Score__c, Is_BANT_Completed__c, Is_Create_Via_NBA__c, 
        Money_Comment_Justification__c, Money_Question__c, Money_Score__c, Need_Comment_Justification__c, Need_Question__c,
        Need_Score__c, Need__c, Opportunity_Comment_Justification__c, Opportunity_Question__c, Opportunity_Score__c, 
        SCOTSMAN_Indicator__c, SCOTSMAN_Score__c, Size_Comment_Justification__c, Size_Question__c, Size_Score__c,
        Solution_Comment__c, Solution_Question__c, Solution_Score__c, Timeline__c, Timescale_Comment_Justification__c,
        Timescale_Question__c, Timescale_Score__c, Total_Score_RO__c, LostReasonDetail__c, LostReason__c, 
        Signed_Order_Form_attached__c, Forecast_Status__c, Expected_Annualised_Gross_Profit__c, Annualised_Gross_Profit__c,
        Total_Contract_Profit__c, Total_Contract_Value__c, Last_Click_UTM_Source__c, Last_Click_UTM_Medium__c,
        Last_Click_UTM_Campaign__c, Last_Click_UTM_Content__c, SCT_ID__c, SCT_Created_Date__c, NextActivity__c,
        Bid_Clinic_Approval_Required__c, Q_AGP__c, BANT_Completion__c, SCOTSMAN_Completion__c, AA_Number__c,
        PSU_Company_ID__c, PSU_Record_ID__c, Count_of_Oppty_LI__c, Count_of_Child_Opportunities__c, 
        Data_Split_Percentage__c, Flex_Space_Split_Percentage__c, IT_Services_Split_Percentage__c, LAN_Wifi_Split_Percentage__c, Mobile_Split_Percentage__c,
        Network_Monitoring_Split_Percentage__c, Physical_Install_Split_Percentage__c, Rental_Split_Percentage__c, Security_Split_Percentage__c, UC_Split_Percentage__c,
        Voice_Split_Percentage__c, Data_Overlay_Type__c, Data_Overlay_User__c, Flex_Space_Overlay_Type__c, Flex_Space_Overlay_User__c, IT_Services_Overlay_Type__c, 
        IT_Services_Overlay_User__c, LAN_Wifi_Overlay_Type__c, LAN_Wifi_Overlay_User__c, Mobile_Overlay_Type__c, Mobile_Overlay_User__c, Network_Monitoring_Overlay_Type__c,
        Network_Monitoring_Overlay_User__c, Physical_Install_Overlay_Type__c, Physical_Install_Overlay_User__c, Rental_Overlay_Type__c, Rental_Overlay_User__c, Security_Overlay_Type__c,
        Security_Overlay_User__c, UC_Overlay_Type__c, UC_Overlay_User__c, Voice_Overlay_Type__c, Voice_Overlay_User__c,
        Parent_Opportunity__c FROM Opportunity WHERE Id IN :opportunityIds AND Parent_Opportunity__c = null]);
    }

    /**TO DEPRECATE */
    /***public static Map<Id,OpportunityProductFamiliesAndLineItems> getOpportunityIdToExistingProductFamilies(List<OpportunityLineItem> opportunityLineItems, Set<Id> opportunityIds){
        Map<Id,OpportunityProductFamiliesAndLineItems> opportunityIdToExistingProducts = new Map<Id,OpportunityProductFamiliesAndLineItems>();
    //Apex CPU Limit Optimization
        for(Opportunity opportunity:[SELECT Id, (SELECT Id, Name, Product_Family__c FROM ChildOpportunities__r) FROM Opportunity WHERE Id IN :opportunityIds]){
            if(!opportunityIdToExistingProducts.containskey(opportunity.Id)){
                opportunityIdToExistingProducts.put(opportunity.Id, new OpportunityProductFamiliesAndLineItems());
            }
            for(Opportunity childOpportunity:opportunity.ChildOpportunities__r){
                opportunityIdToExistingProducts.get(opportunity.Id).productFamiliesToChildOpportunities.put(childOpportunity.Product_Family__c, childOpportunity);
            }
        }
        System.debug('***opportunityIdToExistingProducts****'+opportunityIdToExistingProducts);
        /*for(Opportunity opportunity:[SELECT Id, (SELECT Product2.Family FROM OpportunityLineItems), (SELECT Id, Name, Product_Family__c FROM ChildOpportunities__r) FROM Opportunity WHERE Id IN :opportunityIds]){
            if(!opportunityIdToExistingProducts.containskey(opportunity.Id)){
                opportunityIdToExistingProducts.put(opportunity.Id, new OpportunityProductFamiliesAndLineItems());
            }
            for(Opportunity childOpportunity:opportunity.ChildOpportunities__r){
                system.debug('****opportunity.Id**'+opportunity.Id);
                system.debug('****childOpportunity.Product_Family__c**'+childOpportunity.Product_Family__c);
                opportunityIdToExistingProducts.get(opportunity.Id).productFamiliesToChildOpportunities.put(childOpportunity.Product_Family__c, childOpportunity);
            }
        }*/
    //End
        /***return opportunityIdToExistingProducts;
    }***/

    /**TO DEPRECATE */
    /***public static Opportunity createChildOpportunity(Opportunity parentOpportunity, String productFamily){
        system.debug('****createChildOpportunity***');
        Opportunity childOpp = new Opportunity();
        childOpp.CloseDate=parentOpportunity.CloseDate;
        childOpp.StageName=parentOpportunity.StageName;
        childOpp.RecordTypeId = rt.Id;
        childOpp.Probability = parentOpportunity.Probability;
        childOpp.ForecastCategoryName = parentOpportunity.ForecastCategoryName;
        childOpp.Contract_Term__c = parentOpportunity.Contract_Term__c;
        childOpp.Type = parentOpportunity.Type;
        childOpp.AccountId = parentOpportunity.AccountId;
        childOpp.Parent_Opportunity__c = parentOpportunity.Id;
        childOpp.Name = parentOpportunity.Name+' - '+productFamily;
        childOpp.Product_Family__c = productFamily;
        childOpp.LostReasonDetail__c = parentOpportunity.LostReasonDetail__c;
        childOpp.Budget__c = parentOpportunity.Budget__c;
        childOpp.Need__c = parentOpportunity.Need__c;
        childOpp.Authority__c = parentOpportunity.Authority__c;
        childOpp.Timeline__c = parentOpportunity.Timeline__c;
        String overlayUserFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_User__c';
        String overlayTypeFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
        String splitPercentageFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Split_Percentage__c';
        if(parentOpportunity.get(overlayUserFieldName) != null && parentOpportunity.get(overlayTypeFieldName) != null && parentOpportunity.get(splitPercentageFieldName) != null){
            childOpp.put(overlayUserFieldName, parentOpportunity.get(overlayUserFieldName));
            //System.Debug('Owner Name>>>>>>' + parentOpportunity.get(overlayUserFieldName));
            childOpp.OwnerId = String.valueOf(parentOpportunity.get(overlayUserFieldName));
            childOpp.put(overlayTypeFieldName, parentOpportunity.get(overlayTypeFieldName));
            childOpp.put(splitPercentageFieldName, parentOpportunity.get(splitPercentageFieldName));
            return childOpp;
        }
        else{
            return null;
        }      
    }***/

    /**TO DEPRECATE */
    /***public static OpportunityLineItem createChildOpportunityLineItem(OpportunityLineItem parentOpportunityLineItem, Opportunity childOpportunity ){        
        System.debug('**createChildOpportunityLineItem***');
        OpportunityLineItem objNewopli = new OpportunityLineItem();
        String overlayTypeFieldName = parentOpportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
        System.debug('**createChildOpportunityLineItem1***');
        String overlayType =  parentOpportunityLineItem.Overlay_Type__c;

        objNewopli.Overlay_Type__c =  parentOpportunityLineItem.Overlay_Type__c;
        objNewopli.Overlay_User__c =  parentOpportunityLineItem.Overlay_User__c;


        Decimal splitPercentage =  parentOpportunityLineItem.Overlay_Split_Percentage__c;
        if(overlayType == null){
            return null;
            //throw new MissingOverlayDataException('The Opportunity Does not have overlay data for the chosen product family: '+parentOpportunityLineItem.Product_Family__c);
        }
        if(overlayType.equals(SALES_AGP)){
            System.debug('**createChildOpportunityLineItem2***');
            objNewopli.PricebookEntryId = parentOpportunityLineItem.PricebookEntryId; //priceBookList[0].Id;
            objNewopli.Product2Id = parentOpportunityLineItem.Product2Id;
            objNewopli.Quantity = parentOpportunityLineItem.Quantity;
            objNewopli.Contract_Term__c = parentOpportunityLineItem.Contract_Term__c; 
            objNewopli.Sell_Type__c = parentOpportunityLineItem.Sell_Type__c;
            objNewopli.UnitPrice = parentOpportunityLineItem.UnitPrice==Null ? Null : (parentOpportunityLineItem.UnitPrice * splitPercentage)/100;
            objNewopli.Recurring_Cost__c = parentOpportunityLineItem.Recurring_Cost__c==Null ? Null :(parentOpportunityLineItem.Recurring_Cost__c * splitPercentage)/100;
            objNewopli.Recurring_Dealer_Commission__c = parentOpportunityLineItem.Recurring_Dealer_Commission__c==Null ? Null  :(parentOpportunityLineItem.Recurring_Dealer_Commission__c * splitPercentage)/100;
            objNewopli.Sales_Price_Non_Recurring__c= parentOpportunityLineItem.Sales_Price_Non_Recurring__c==Null ? Null :(parentOpportunityLineItem.Sales_Price_Non_Recurring__c * splitPercentage)/100; 
            objNewopli.Non_Recurring_Cost__c = parentOpportunityLineItem.Non_Recurring_Cost__c==Null ? Null :(parentOpportunityLineItem.Non_Recurring_Cost__c * splitPercentage)/100;
            objNewopli.Non_Recurring_Dealer_Commission__c = parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c==Null ? Null :(parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c * splitPercentage)/100;
            objNewopli.AGP_CPQ__c = (parentOpportunityLineItem.AGP_CPQ__c * splitPercentage) /100;
            objNewopli.Unit_Sell__c = (parentOpportunityLineItem.Unit_Sell__c * splitPercentage) / 100;

        }else if(overlayType.equals(COMMISSION_AS_AGP)){
            System.debug('**createChildOpportunityLineItem3***');
            objNewopli.PricebookEntryId = parentOpportunityLineItem.PricebookEntryId; 
            objNewopli.Product2Id = parentOpportunityLineItem.Product2Id;
            objNewopli.Quantity = parentOpportunityLineItem.Quantity; // 1;//
            objNewopli.Contract_Term__c = parentOpportunityLineItem.Contract_Term__c; 
            objNewopli.Sell_Type__c = parentOpportunityLineItem.Sell_Type__c;
            objNewopli.UnitPrice =parentOpportunityLineItem.Recurring_Dealer_Commission__c; 
            objNewopli.Sales_Price_Non_Recurring__c= parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c * parentOpportunityLineItem.Quantity;//parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c
            objNewopli.Child_Opportunity_Commission_as_AGP__c = true;  
            objNewopli.AGP_CPQ__c = parentOpportunityLineItem.AGP_CPQ__c;
            objNewopli.Unit_Sell__c = parentOpportunityLineItem.Unit_Sell__c;
      
        }
        objNewopli.Description = parentOpportunityLineItem.Description;
        objNewopli.OpportunityId = childOpportunity.Id;
        objNewopli.Create_Overlay_Opportunity__c = false;
        objNewopli.Related_Child_Opportunity__c = Null;
        objNewopli.Parent_Opportunity_Product__c = parentOpportunityLineItem.Id;
        objNewopli.Parent_Annual_Dealer_Commission__c = parentOpportunityLineItem.Annual_Dealer_Commission__c;
        objNewopli.CPQ_Line_Item__c = parentOpportunityLineItem.CPQ_Line_Item__c;
        
        
        return objNewopli;
    }***/

    /**TO DEPRECATE */
    /***public static void updateChildOpportunityLineItem(List<OpportunityLineItem> opportunityLineItems){
        Map<Id,Opportunity> opportunityMap = getOpportunityMap(opportunityLineItems);
        List<OpportunityLineItem> childOpportunityLineItemsToUpdate = new List<OpportunityLineItem>();
        List<Opportunity> childOpportunities = getChildOpportunities(opportunityLineItems);
        List<Opportunity> childOpportunitiesCL = new List<Opportunity>();
        
    //Apex CPU Limit Optimization
        Map<Id, OpportunityLineItem> parentOppIdToChildOppLineItemMap = new Map<Id, OpportunityLineItem>();
        for(OpportunityLineItem childOpportunityLineItem : getChildOpportunityLineItems(opportunityMap.keySet())){
            parentOppIdToChildOppLineItemMap.put(childOpportunityLineItem.Opportunity.Parent_Opportunity__c, childOpportunityLineItem);
        }
        for(OpportunityLineItem parentLineItem:opportunityLineItems){
            if(parentOppIdToChildOppLineItemMap.containsKey(parentLineItem.OpportunityId) && parentOppIdToChildOppLineItemMap.get(parentLineItem.OpportunityId).Product2Id == parentLineItem.Product2Id){
                OpportunityLineItem childOpportunityLineItemToUpdate = createChildOpportunityLineItem(parentLineItem, new Opportunity(Id = parentOppIdToChildOppLineItemMap.get(parentLineItem.OpportunityId).OpportunityId));
                if(childOpportunityLineItemToUpdate != null){
                    childOpportunityLineItemToUpdate.Id = parentOppIdToChildOppLineItemMap.get(parentLineItem.OpportunityId).Id;
                    childOpportunityLineItemsToUpdate.add(childOpportunityLineItemToUpdate);
                    childOpportunitiesCL.add(new Opportunity(Id = parentOppIdToChildOppLineItemMap.get(parentLineItem.OpportunityId).OpportunityId));
                }
                
            }
        }
        

        /*system.debug('****childOpportunities***'+childOpportunities);
        for(Opportunity childOpportunity:childOpportunities){
            system.debug('****childOpportunity***'+childOpportunity);
            for(OpportunityLineItem childOpportunityLineItem:childOpportunity.OpportunityLineItems){
                system.debug('****childOpportunityLineItem***'+childOpportunityLineItem);
                for(OpportunityLineItem parentLineItem:opportunityLineItems){
                    system.debug('****parentLineItem***'+parentLineItem);
                    system.debug('****childOpportunityLineItem.Opportunity.Parent_Opportunity__c***'+childOpportunityLineItem.Opportunity.Parent_Opportunity__c);
                    system.debug('****parentLineItem.OpportunityId***'+parentLineItem.OpportunityId);
                    system.debug('****childOpportunityLineItem.Product2Id***'+childOpportunityLineItem.Product2Id);
                    system.debug('****parentLineItem.Product2Id***'+parentLineItem.Product2Id);
                    if(childOpportunityLineItem.Opportunity.Parent_Opportunity__c == parentLineItem.OpportunityId && childOpportunityLineItem.Product2Id == parentLineItem.Product2Id){
                        system.debug('****Match Found***');
                        OpportunityLineItem childOpportunityLineItemToUpdate = createChildOpportunityLineItem(parentLineItem, childOpportunity);
                        if(childOpportunityLineItemToUpdate != null){
                            childOpportunityLineItemToUpdate.Id = childOpportunityLineItem.Id;
                            childOpportunityLineItemsToUpdate.add(childOpportunityLineItemToUpdate);
                            childOpportunitiesCL.add(childOpportunity);
                        }
                        
                    }
                }
            }
        }*/
    //End
        
        /***if(!childOpportunityLineItemsToUpdate.isEmpty()){
            if(!childOpportunitiesCL.isEmpty()){
                updateClosedLostOpportunity(childOpportunitiesCL);
            }

            Map<Id,OpportunityLineItem> olisToUpdateMap = OpportunityProductHandler.convertListToMapOLI(childOpportunityLineItemsToUpdate);
            update olisToUpdateMap.values();
        }
    }***/

    public static void deleteChildOpportunityLineItems(List<OpportunityLineItem> opportunityLineItems){
        
        System.debug('deleteChildOpportunityLineItems Method Called');

        Map<Id,Opportunity> opportunityMap = getOpportunityMap(opportunityLineItems);
        List<OpportunityLineItem> childOpportunityLineItemToDelete = new List<OpportunityLineItem>();
        List<Opportunity> childOpportunities = getChildOpportunitiesTypes(opportunityLineItems);

        System.debug('delete childOpportunities >>>>>>' + childOpportunities);


        for(Opportunity childOpportunity:childOpportunities){
            
            System.debug('childOpportunity.OpportunityLineItems>>>>>' + childOpportunity.OpportunityLineItems);

            for(OpportunityLineItem childOpportunityLineItem:childOpportunity.OpportunityLineItems){

                for(OpportunityLineItem toDeleteLineItem:opportunityLineItems){

                    System.debug('toDeleteLineItem>>>>'+toDeleteLineItem);
                    System.debug('childOpportunityLineItem.Opportunity.Parent_Opportunity__c>>>>'+childOpportunityLineItem.Opportunity.Parent_Opportunity__c);
                    System.debug('childOpportunityLineItem.Product2Id == toDeleteLineItem.Product2Id >>>>>>>>>>' + childOpportunityLineItem.Product2Id + '<>' + toDeleteLineItem.Product2Id);

                    if(childOpportunityLineItem.Opportunity.Parent_Opportunity__c == toDeleteLineItem.OpportunityId && childOpportunityLineItem.Product2Id == toDeleteLineItem.Product2Id){
                        System.debug('IF STATMENT TRUE DELETING >>>>>' + childOpportunityLineItem);
                        childOpportunityLineItemToDelete.add(childOpportunityLineItem);
                    }
                }
            }
        }

        if(!childOpportunityLineItemToDelete.isEmpty()){
            delete childOpportunityLineItemToDelete;
        }
    }

    public static void deleteChildOpportunities(List<OpportunityLineItem> opportunityLineItems){
        //List<Opportunity> childOpportunitiesToDelete = new List<Opportunity>();
        List<Opportunity> childOpportunitiesToUpdate = new List<Opportunity>();
        List<Opportunity>  childOpportunities = getChildOpportunitiesTypes(opportunityLineItems);

        System.debug('opportunityLineItems>>>>>>' + opportunityLineItems);


        System.debug('childOpportunities>>>>>'+ childOpportunities);

        for(Opportunity opportunity:childOpportunities){

            System.debug('opportunity.OpportunityLineItems>>>>>' + opportunity.OpportunityLineItems);
            System.debug('opportunity.Parent_Opportunity__c>>>>' + opportunity.Parent_Opportunity__c);
            if(opportunity.Parent_Opportunity__c != null && opportunity.OpportunityLineItems.isEmpty()){
                
                //If Closed Losting empty Child Opps
                opportunity.StageName = 'Closed Lost';
                opportunity.LostReasonDetail__c = 'CPQ Row Delete';
                childOpportunitiesToUpdate.add(opportunity);

                //If deleting Child Opps
                //childOpportunitiesToDelete.add(opportunity);
            }
        }

        System.debug('childOpportunitiesToUpdate>>>>' + childOpportunitiesToUpdate);
        //If Closed Losting empty Child Opps
        if(!childOpportunitiesToUpdate.isEmpty()){
            
            update childOpportunitiesToUpdate;

        }
        //If deleting Child Opps
        // if(!childOpportunitiesToDelete.isEmpty()){
            
        //     delete childOpportunitiesToDelete;
        // }
    }

    public static void updateOpportunityProductOverlayFields(Map<Id,Opportunity> updatedOpportunities, Map<Id,Opportunity> oldOpportuityMap ){
        //List<Opportunity> opportunitiesWithProducts = getOpportunitiesWithProducts(updatedOpportunities.values());
        Map<Id, OpportunityLineItem> opportunityLineItemMap = new Map<Id, OpportunityLineItem>(getChildOppLineItemsByOppId(updatedOpportunities.values()));
        List<OpportunityLineItem> opportunityLineItemsToUpdate = new List<OpportunityLineItem>();
            System.debug('updatedOpportunities: '+updatedOpportunities.values());
        //Apex CPU Limit Optimization
        /*for(Opportunity opportunity:opportunitiesWithProducts){
            if(opportunity.Parent_Opportunity__c == null){
            
                for(OpportunityLineItem opportunityLineItem:opportunity.OpportunityLineItems){
                                System.debug('opportunityLineItem: '+opportunityLineItem);

                    String overlayUserFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_User__c';
                    String overlayTypeFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
                    String splitPercentageFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Split_Percentage__c';
                                System.debug('overlayUserFieldName: '+overlayUserFieldName);
                                System.debug('splitPercentageFieldName: '+splitPercentageFieldName);

                    opportunityLineItem.Overlay_Type__c = (String) opportunity.get(overlayTypeFieldName);
                    opportunityLineItem.Overlay_User__c = (String) opportunity.get(overlayUserFieldName);
                    opportunityLineItem.Overlay_Split_Percentage__c = (Decimal) opportunity.get(splitPercentageFieldName);
                    opportunityLineItemsToUpdate.add(opportunityLineItem);
                    System.debug('opportunityLineItem: '+opportunityLineItem);
                }
            }
        }*/
        //End
        for(OpportunityLineItem opli : opportunityLineItemMap.values()){
            populateProductOverlayFields(opli, opli.Product_Family__c, opli.Opportunity);
            Opportunity oldOpp = oldOpportuityMap.get(opli.OpportunityId);
            Opportunity newOpp = updatedOpportunities.get(opli.OpportunityId);
            //Code copied from the Flow Opportunity Total Calculation Flow version_1
            if((opli.AGP_CPQ__c != opli.AGP_CPQ_QL__c || newOpp.Amount != oldOpp.Amount || newOpp.TotalOpportunityQuantity != oldOpp.TotalOpportunityQuantity) && newOpp.SBQQ__PrimaryQuote__c != NULL){
               
                if(opli.SBQQ__QuoteLine__r != null && opli.SBQQ__QuoteLine__r.Recurring__c != null){
                    opli.put('Recurring__c', opli.SBQQ__QuoteLine__r.Recurring__c);
                }
                updateOpliAGP(opli);
            }
            //End of Flow Opportunity Total Calculation Flow version_1
            opportunityLineItemsToUpdate.add(opli);
        }

        if(!opportunityLineItemsToUpdate.isEmpty()){
            update opportunityLineItemsToUpdate;
        }
        system.debug('***opportunityLineItemsToUpdate****'+opportunityLineItemsToUpdate);
    }

    private static void updateOpliAGP(OpportunityLineItem opli){
        opli.AGP_CPQ__c = opli.AGP_CPQ_QL__c;
        opli.put('Total_Cost__c', opli.get('Total_Cost_Formula__c'));
        opli.put('Q_AGP_CPQ__c', opli.get('Q_AGP_CPQ_Formula__c'));
        // jamesgoode@fluidone.com
        //opportunityLineItem.put('Contract_Term__c', opportunityLineItem.get('Subscription_Term__c') == 0 ? '12' : String.valueOf( Math.floor(Double.valueOf(opportunityLineItem.get('Subscription_Term__c')))).left(1));
        opli.put('Contract_Term__c', opli.get('Subscription_Term__c') == 0 ? '12' : String.valueOf( Integer.valueOf(opli.get('Subscription_Term__c'))));
    }

    private static void populateProductOverlayFields(OpportunityLineItem opportunityLineItem, String productFamily, Opportunity opp){
        system.debug('***opportunityLineItem has value***'+opportunityLineItem.Id);
        String overlayUserFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_User__c';
        String overlayTypeFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
        String splitPercentageFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Split_Percentage__c';
        system.debug('***overlayUserFieldName***'+overlayUserFieldName);
        system.debug('***overlayTypeFieldName***'+overlayTypeFieldName);
        system.debug('***splitPercentageFieldName***'+splitPercentageFieldName);
      
        opportunityLineItem.put('Overlay_Type__c', getValueAsString(opp,overlayTypeFieldName));
        opportunityLineItem.put('Overlay_User__c', getValueAsString(opp,overlayUserFieldName));
        opportunityLineItem.put('Overlay_Split_Percentage__c', getFieldValue(opp,splitPercentageFieldName));
    }

    public static boolean isOpportunityField(String fieldName){
        Boolean isOpportunityFields = false;
        if(String.isNotBlank(fieldName)){
            isOpportunityFields = opportunityFieldNames.contains(fieldName.toLowerCase());
        }
        return isOpportunityFields;
    }

    public static Object getFieldValue(Opportunity opp, String fieldName){
        Object val = null;
        if(opp!=null && isOpportunityField(fieldName)){
            val = opp.get(fieldName);
        }
        
        return val;
    }

    public static String getValueAsString(Opportunity opp, String fieldName){
        String val = null;
        Object valAsObj = getFieldValue(opp, fieldName);
        if(valAsObj!=null){
            val = String.valueOf(valAsObj);
        }
        
        return val;
    }

    /**TO DEPRECATE */
    /***public static List<OpportunityLineItem> updateParentOLIRelatedChild(Map<Id,OpportunityLineItem> parentOLI, Map<Id,OpportunityLineItem> childOLI){
        List<OpportunityLineItem> parentOliToUpdate = new List<OpportunityLineItem>();
        Map<Id,Id> parentChildOLI = new Map<Id, Id>();

        for(OpportunityLineItem cOLI : childOLI.values()){
            parentChildOLI.put(cOLI.Parent_Opportunity_Product__c, cOLI.Id);
            System.debug('cOLI'+cOLI);

            System.debug('cOLI.Parent_Opportunity_Product__c, cOLI.Id>>>>>' + cOLI.Parent_Opportunity_Product__c + ' , ' + cOLI.Id);
        }


        for(OpportunityLineItem oli : parentOLI.values()){
            if(parentChildOLI.containsKey(oli.Id)){
                System.debug('oli>>>>' + oli);
                System.debug('OLI Values>>> GP ' + oli.Annualised_Gross_Profit__c + ' Split ' + oli.Overlay_Split_Percentage__c);
                OpportunityLineItem newOLI = new OpportunityLineItem(Id = oli.Id);
                //newOLI.Related_Child_Opportunity_Product__c = parentChildOLI.get(oli.Id);
                System.debug('Child Opp AGP Text >>>>' + oli.Annualised_Gross_Profit__c * oli.Overlay_Split_Percentage__c);
                newOLI.Child_Opportunity_AGP_Text__c =+ ((oli.Annualised_Gross_Profit__c * oli.Overlay_Split_Percentage__c)/100);
                
                System.debug('newOLI>>>>>> ' + newOLI);
                parentOliToUpdate.add(newOLI);
                System.debug('NEW OLI Added to List');
            }
        }

        System.debug('parentOliToUpdate>>>>' + parentOliToUpdate);
        return parentOliToUpdate;
        

    }***/

    /**TO DEPRECATE */
    /***public static Map<Id, OpportunityLineItem> convertListToMapOLI(List<OpportunityLineItem> olis) {
        Map<Id,OpportunityLineItem> oliMap = new Map<Id,OpportunityLineItem>();
        
        oliMap.putAll(olis);

        return oliMap;
    }***/

    /**TO DEPRECATE */
    /***public static void setOverlayFieldOnProduct(List<OpportunityLineItem> opportunityLineItems){
        Map<Id,Opportunity> opportunityMap = getOpportunityMap(opportunityLineItems);
        System.debug('opportunityMap: '+opportunityMap);

        List<OpportunityLineItem> lineItemsToUpdate = new List<OpportunityLineItem>();

        if(!opportunityMap.isEmpty()){
            for(OpportunityLineItem opportunityLineItem:opportunityLineItems){
    
                Opportunity parentOpportunity = opportunityMap.get(opportunityLineItem.OpportunityId);
                String overlayUserFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_User__c';
                String overlayTypeFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
                String splitPercentageFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Split_Percentage__c';
                
                opportunityLineItem.Overlay_Type__c = (String) parentOpportunity.get(overlayTypeFieldName);
                opportunityLineItem.Overlay_User__c = (String) parentOpportunity.get(overlayUserFieldName);
                opportunityLineItem.Overlay_Split_Percentage__c = (Decimal) parentOpportunity.get(splitPercentageFieldName);

                Decimal salesQAGPText = 0;

                if(parentOpportunity.get(overlayTypeFieldName) == SALES_AGP){

                    Decimal recurringProfit;
                    Decimal nonRecurringProfit;
                    Decimal splitPercentage;
                    
                    switch on opportunityLineItem.Contract_Term__c {
                        when '' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 0);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '1' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 1);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '3' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 3);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '6' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 6);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '12' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '24' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '36' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1.2 * 12);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '48' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1.2 * 12);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                        when '60' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1.4 * 12);
                            nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                            splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                        }
                    }
                    System.debug('recurringProfit>>'+recurringProfit);
                    System.debug('nonRecurringProfit>>'+nonRecurringProfit);
                    System.debug('splitPercentage>>'+splitPercentage);
                    salesQAGPText = (recurringProfit + nonRecurringProfit) - ((recurringProfit + nonRecurringProfit) * (splitPercentage/100));   
                }
                opportunityLineItem.Sales_AGP_QAGP_Text__c = salesQAGPText;
                opportunityLineItem.Child_Opportunity_AGP_Text__c = salesQAGPText;
                System.debug('updating line item: '+opportunityLineItem);
            }

        }
    }***/

    /**TO DEPRECATE */
    /***public static List<Opportunity> getOpportunitiesWithProducts(List<Opportunity> updatedOpportunities){
        return [SELECT Id, Parent_Opportunity__c, (SELECT Id, Product_Family__c FROM OpportunityLineItems), (SELECT Id, Product_Family__c FROM ChildOpportunities__r), Data_Split_Percentage__c, Flex_Space_Split_Percentage__c, IT_Services_Split_Percentage__c, LAN_Wifi_Split_Percentage__c, Mobile_Split_Percentage__c,
            Network_Monitoring_Split_Percentage__c, Physical_Install_Split_Percentage__c, Rental_Split_Percentage__c, Security_Split_Percentage__c, UC_Split_Percentage__c,
            Voice_Split_Percentage__c, Data_Overlay_Type__c, Data_Overlay_User__c, Flex_Space_Overlay_Type__c, Flex_Space_Overlay_User__c, IT_Services_Overlay_Type__c, 
            IT_Services_Overlay_User__c, LAN_Wifi_Overlay_Type__c, LAN_Wifi_Overlay_User__c, Mobile_Overlay_Type__c, Mobile_Overlay_User__c, Network_Monitoring_Overlay_Type__c,
            Network_Monitoring_Overlay_User__c, Physical_Install_Overlay_Type__c, Physical_Install_Overlay_User__c, Rental_Overlay_Type__c, Rental_Overlay_User__c, Security_Overlay_Type__c,
            Security_Overlay_User__c, UC_Overlay_Type__c, UC_Overlay_User__c, Voice_Overlay_Type__c, Voice_Overlay_User__c FROM Opportunity WHERE Id IN :new Map<Id,Opportunity>(updatedOpportunities).keySet() AND Parent_Opportunity__c = NULL];
    }***/

    /**TO DEPRECATE */
    /***public static List<Opportunity> getChildOpportunities(List<OpportunityLineItem> opportunityLineItems){
        Set<Id> parentOpportunityIds = getOpportunityMap(opportunityLineItems).keySet();
        return [SELECT Parent_Opportunity__c, Data_Split_Percentage__c, Flex_Space_Split_Percentage__c, IT_Services_Split_Percentage__c, LAN_Wifi_Split_Percentage__c, Mobile_Split_Percentage__c,
            Network_Monitoring_Split_Percentage__c, Physical_Install_Split_Percentage__c, Rental_Split_Percentage__c, Security_Split_Percentage__c, UC_Split_Percentage__c,
            Voice_Split_Percentage__c, Data_Overlay_Type__c, Data_Overlay_User__c, Flex_Space_Overlay_Type__c, Flex_Space_Overlay_User__c, IT_Services_Overlay_Type__c, 
            IT_Services_Overlay_User__c, LAN_Wifi_Overlay_Type__c, LAN_Wifi_Overlay_User__c, Mobile_Overlay_Type__c, Mobile_Overlay_User__c, Network_Monitoring_Overlay_Type__c,
            Network_Monitoring_Overlay_User__c, Physical_Install_Overlay_Type__c, Physical_Install_Overlay_User__c, Rental_Overlay_Type__c, Rental_Overlay_User__c, Security_Overlay_Type__c,
            Security_Overlay_User__c, UC_Overlay_Type__c, UC_Overlay_User__c, Voice_Overlay_Type__c, Voice_Overlay_User__c, (SELECT Id, Product_Family__c, Product2Id, OpportunityId, Opportunity.Parent_Opportunity__c FROM OpportunityLineItems) FROM Opportunity WHERE Parent_Opportunity__c IN :parentOpportunityIds];
    }***/

    /**TO DEPRECATE */
    //Apex CPU Limit Optimization
    /***public static List<OpportunityLineItem> getChildOpportunityLineItems(Set<Id> opportunityIds){
        return [SELECT Id, Product_Family__c, Product2Id, OpportunityId, Opportunity.Parent_Opportunity__c FROM OpportunityLineItem WHERE Opportunity.Parent_Opportunity__c IN :opportunityIds];
    }
    public static List<Opportunity> getChildOpportunitiesv1(Set<Id> opportunityIds){
        return [SELECT Id, Name, Product_Family__c, Parent_Opportunity__c  FROM Opportunity WHERE Parent_Opportunity__c IN :opportunityIds];
    }***/

    public static List<OpportunityLineItem> getChildOppLineItemsByOppId(List<Opportunity> updatedOpportunities){
        return [SELECT Id, AGP_CPQ__c, AGP_CPQ_QL__c, Recurring__c, SBQQ__QuoteLine__r.Recurring__c, Total_Cost__c, Total_Cost_Formula__c, Q_AGP_CPQ__c, Q_AGP_CPQ_Formula__c, Contract_Term__c, Subscription_Term__c,  Product_Family__c, Product2Id, OpportunityId, Opportunity.Parent_Opportunity__c, Overlay_Type__c, Overlay_User__c, Overlay_Split_Percentage__c, Opportunity.Data_Split_Percentage__c, Opportunity.Flex_Space_Split_Percentage__c, Opportunity.IT_Services_Split_Percentage__c, Opportunity.LAN_Wifi_Split_Percentage__c, Opportunity.Mobile_Split_Percentage__c,
        Opportunity.Network_Monitoring_Split_Percentage__c, Opportunity.Physical_Install_Split_Percentage__c, Opportunity.Rental_Split_Percentage__c, Opportunity.Security_Split_Percentage__c, Opportunity.UC_Split_Percentage__c,
        Opportunity.Voice_Split_Percentage__c, Opportunity.Data_Overlay_Type__c, Opportunity.Data_Overlay_User__c, Opportunity.Flex_Space_Overlay_Type__c, Opportunity.Flex_Space_Overlay_User__c, Opportunity.IT_Services_Overlay_Type__c, 
        Opportunity.IT_Services_Overlay_User__c, Opportunity.LAN_Wifi_Overlay_Type__c, Opportunity.LAN_Wifi_Overlay_User__c, Opportunity.Mobile_Overlay_Type__c, Opportunity.Mobile_Overlay_User__c, Opportunity.Network_Monitoring_Overlay_Type__c,
        Opportunity.Network_Monitoring_Overlay_User__c, Opportunity.Physical_Install_Overlay_Type__c, Opportunity.Physical_Install_Overlay_User__c, Opportunity.Rental_Overlay_Type__c, Opportunity.Rental_Overlay_User__c, Opportunity.Security_Overlay_Type__c,
        Opportunity.Security_Overlay_User__c, Opportunity.UC_Overlay_Type__c, Opportunity.UC_Overlay_User__c, Opportunity.Voice_Overlay_Type__c, Opportunity.Voice_Overlay_User__c FROM OpportunityLineItem WHERE Opportunity.Parent_Opportunity__c = NULL AND OpportunityId IN :updatedOpportunities];
    }

    

    /**TO DEPRECATE */
    /***public static List<OpportunityLineItem> getOpportunityLineItem(Set<Id> OpportunityLineItemIds){
        return [SELECT AGP_CPQ_QL__c,AGP_CPQ__c,Annualised_Gross_Profit_Total__c,Annualised_Gross_Profit__c,Annual_Dealer_Commission__c,
        Category__c,Child_Opportunity_AGP_Text__c,Child_Opportunity_AGP__c,Child_Opportunity_Commission_as_AGP__c,Competitor__c,
        Contract_Term__c,CPQ_Line_Item__c,CreatedById,CreatedDate,Create_Overlay_Opportunity__c,Description,Expected_Annualised_Gross_Profit__c,
        Gross_Upgrade_Margin__c,Id,IsDeleted,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Low_Annualised_Gross_Profit__c,
        Name,Non_Recurring_Cost__c,Non_Recurring_Dealer_Commission__c,Non_Recurring_Margin__c,Non_Recurring_Profit2__c,Non_Recurring_Profit__c,
        OpportunityId,Overlay_Sales_AGP_QAGP__c,Overlay_Split_Percentage__c,Overlay_Type__c,Overlay_User__c,Parent_Annual_Dealer_Commission__c,
        Parent_Bundle__c,Parent_Opportunity_Id__c,Parent_Opportunity_Product__c,Pillar__c,PricebookEntryId,Product2Id,Product_Family__c,Quantity,
        Q_AGP_CPQ_Formula__c,Q_AGP_CPQ__c,Q_AGP__c,Record_Type__c,Recurring_Cost__c,Recurring_Dealer_Commission__c,Recurring_Margin__c,Recurring_Profit2__c,
        Recurring_Profit__c,Recurring__c,Related_Child_Opportunity_Product__c,Related_Child_Opportunity__c,Sales_AGP_QAGP_Text__c,Sales_Price_Non_Recurring__c,
        sbaa__ApprovalStatus__c,SBQQ__ParentID__c,SBQQ__QuoteLine__c,SBQQ__SubscriptionType__c,Sell_Type__c,ServiceDate,SortOrder,SubCategory__c,
        Subscription_Term__c,SystemModstamp,TotalPrice,Total_Cost_Formula__c,Total_Cost__c,Total_Profit__c,Total_Value__c,UnitPrice,Unit_Sell__c 
        FROM OpportunityLineItem where Id IN: OpportunityLineItemIds];
    }***/
    //End

    public static List<Opportunity> getChildOpportunitiesTypes(List<OpportunityLineItem> opportunityLineItems){
        Set<Id> parentOpportunityIds = getOpportunityMap(opportunityLineItems).keySet();
        System.debug('parentOpportunityIds>>>'+ parentOpportunityIds);


        List<String> typesToDelete = new List<String>();

        for(OpportunityLineItem oli : opportunityLineItems){
            typesToDelete.add(oli.Product_Family__c);
        }

        System.debug('typesToDelete>>>'+ typesToDelete);

        return [SELECT Parent_Opportunity__c, Data_Split_Percentage__c, Flex_Space_Split_Percentage__c, IT_Services_Split_Percentage__c, LAN_Wifi_Split_Percentage__c, Mobile_Split_Percentage__c,
            Network_Monitoring_Split_Percentage__c, Physical_Install_Split_Percentage__c, Rental_Split_Percentage__c, Security_Split_Percentage__c, UC_Split_Percentage__c,
            Voice_Split_Percentage__c, Data_Overlay_Type__c, Data_Overlay_User__c, Flex_Space_Overlay_Type__c, Flex_Space_Overlay_User__c, IT_Services_Overlay_Type__c, 
            IT_Services_Overlay_User__c, LAN_Wifi_Overlay_Type__c, LAN_Wifi_Overlay_User__c, Mobile_Overlay_Type__c, Mobile_Overlay_User__c, Network_Monitoring_Overlay_Type__c,
            Network_Monitoring_Overlay_User__c, Physical_Install_Overlay_Type__c, Physical_Install_Overlay_User__c, Rental_Overlay_Type__c, Rental_Overlay_User__c, Security_Overlay_Type__c,
            Security_Overlay_User__c, UC_Overlay_Type__c, UC_Overlay_User__c, Voice_Overlay_Type__c, Voice_Overlay_User__c, (SELECT Id, Product_Family__c, Product2Id, OpportunityId, Opportunity.Parent_Opportunity__c FROM OpportunityLineItems WHERE Product_Family__c IN : typesToDelete) FROM Opportunity WHERE Parent_Opportunity__c IN :parentOpportunityIds];
    }

    /**TO DEPRECATE */
    /***public static void updateClosedLostOpportunity(List<Opportunity> opportunities){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        List<Opportunity> opps = [SELECT Id, StageName FROM Opportunity WHERE Id IN : opportunities];

        for(Opportunity opp : opps){
            if(opp.StageName == 'Closed Lost'){
                opp.StageName = 'Identified Opportunity';

                oppsToUpdate.add(opp);
            }
        }

        if(!oppsToUpdate.isEmpty()){
            System.debug('Opps To Update>>>>' + oppsToUpdate);
            update oppsToUpdate;
        }
    }***/

    /**TO DEPRECATE */
    /***public static void shareParentLI(Map<Id,OpportunityLineItem> newMap,Map<Id,OpportunityLineItem> oldMap){
        if(runShareOnce){
            try{
            runShareOnce=false;
            Organization org = [Select Id, DefaultAccountAccess, DefaultContactAccess, DefaultLeadAccess, DefaultOpportunityAccess from Organization];
            System.debug(org);
            if(org.DefaultOpportunityAccess=='None' || test.isRunningTest()){ 
                List<SObject> oppShrs  = new List<SObject>();
                if(newMap.size()>0){
                    for(Id key : newMap.keySet()){
                        if(newMap.size()>0 && oldMap!=null){
                            if(newMap.get(key).Overlay_User__c!=null && newMap.get(key).Overlay_User__c!=oldMap.get(key).Overlay_User__c){
                                oppShrs.add(createsharerecord(newMap.get(key).OpportunityId,newMap.get(key).Overlay_User__c));
                            }
                        }
                        else{
                            if(newMap.get(key).Overlay_User__c!=null){
                                oppShrs.add(createsharerecord(newMap.get(key).OpportunityId,newMap.get(key).Overlay_User__c));
                            }
                        }
                    }
                }
                
                if(oppShrs.size()>0){
                    Insert oppShrs;
                }
            }
        }
        catch(exception ex){
            System.debug('@@ Error '+ex.getLineNumber()+' - '+ex.getMessage());
        }
        }
    }***/
    
    /**TO DEPRECATE */
    /***public static SObject createsharerecord(String OpportunityId,String UserOrGroupId){
        System.debug(' Share Record Creation ');
        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        SObject share = tokens.get('OpportunityShare').newSObject();
        share.put('OpportunityId', OpportunityId);
        share.put('UserOrGroupId', UserOrGroupId);
        share.put('RowCause', '');
        share.put('OpportunityAccessLevel', 'Read');
        return share;
    }***/

    /**TO DEPRECATE */
    /***public class OpportunityProductFamiliesAndLineItems{
        Map<String,Opportunity> productFamiliesToChildOpportunities;
        List<OpportunityLineItem> opportunityLineItems;

        public OpportunityProductFamiliesAndLineItems(){
            this.productFamiliesToChildOpportunities = new Map<String,Opportunity>();
            this.opportunityLineItems = new List<OpportunityLineItem>();
        }

    }***/

    public class MissingOverlayDataException extends exception{

    }

    /**TO DEPRECATE */
    /***@future
    public static void handleAfterInsertLogic(Set<Id> opportunityLineItemIds){
        System.debug('***handleAfterInsertLogic****');
        //Moved from handleAfterInsert
    //Apex CPU Limit Optimization
        //Map<Id,OpportunityLineItem> opportunityLineItemsWithRelatedFields = new Map<Id,OpportunityLineItem>([SELECT Id, Opportunity.Parent_Opportunity__c FROM OpportunityLineItem WHERE Id IN :new Map<Id,OpportunityLineItem>(opportunityLineItems).keySet()]);
    //End 
        List<OpportunityLineItem> parentOpportunityLineItems = new List<OpportunityLineItem>();
        for(OpportunityLineItem opportunityLineItem : getOpportunityLineItem(opportunityLineItemIds)){
            if(opportunityLineItem.Parent_Opportunity_Id__c == NULL){ 
    //Apex CPU Limit Optimization   
            //if(opportunityLineItemsWithRelatedFields.get(opportunityLineItem.Id).Opportunity.Parent_Opportunity__c == null){    
    //End    
                parentOpportunityLineItems.add(opportunityLineItem);
            }
        }
        System.debug('***parentOpportunityLineItems****'+parentOpportunityLineItems);
        if(!parentOpportunityLineItems.isEmpty()){
            
            Map<Id,OpportunityProductFamiliesAndLineItems> opportunityIdToProposedProducts = createNewProductFamilyOpportunities(parentOpportunityLineItems);
            cloneOpportunityLineItems(opportunityIdToProposedProducts, parentOpportunityLineItems);
        }
    }***/
    public static void updateContractTerm(OpportunityLineItem opportunityLineItem){
        opportunityLineItem.Contract_Term__c =  opportunityLineItem.SBQQ__QuoteLine__c != NULL && 
                                                            opportunityLineItem.CPQ_Line_Item__c &&
                                                            opportunityLineItem.Parent_Bundle__c && 
                                                            opportunityLineItem.Subscription_Term__c > 0 ? String.valueOf(opportunityLineItem.Subscription_Term__c).left(2) : opportunityLineItem.Contract_Term__c;
    }

}