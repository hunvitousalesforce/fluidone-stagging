public with sharing class HierarchyClone {

    @InvocableMethod(label='Hierarchy Clone' description='returns cloned Ids')
    public static Response[] process(List<Request> requests) {
        Request request = requests[0];
        String[] objIdsToProcess = request.objIdsToProcess;
        Schema.sObjectType objType = ((Id)request.objIdsToProcess[0]).getSobjectType();
        Schema.DescribeSObjectResult descObjResult = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = descObjResult.fields.getMap();
        List<String> fieldList = new List<String>(fieldMap.keySet());

        //Query Object for Instance Values
        String soql = String.format('Select {0} from {1} Where Id IN: objIdsToProcess', new List<String>{String.join(fieldList, ', '), request.objTypeName});
        List<HieItem> queriedTops = new List<HieItem>();
        Map<String, HieItem[]> queriedChildren = new Map<String, HieItem[]>();
        for (sObject sObj : (List<sObject>)Database.query(soql)) {
            HieItem item = new HieItem(sObj, (String)sObj.get(request.fieldRef));
            if (String.isBlank(item.parentId)) {
                queriedTops.add(item);
            } else { 
                if (!queriedChildren.containsKey(item.parentId)) {
                    queriedChildren.put(item.parentId, new List<HieItem>());
                }
                queriedChildren.get(item.parentId).add(item);
            }
        }

        //Build hierarchy data
        for (HieItem top : queriedTops) {
            constructHie(top, queriedChildren);
        }

        //Find items which should be cloned
        List<HieItem> itemsToProcess = new List<HieItem>();
        for (HieItem top : queriedTops) {
            HieItem item = findContractToProcess(top);
            if (item != null) {
                itemsToProcess.add(item);
            }
        }

        //Process cloning items
        Map<String, sObject> objsProcessed = new Map<String, sObject>();
        for (HieItem item : itemsToProcess) {
            deepClone(item, objsProcessed);
        }
        insert objsProcessed.values();
        for (HieItem item : itemsToProcess) {
            correctParent(item, objsProcessed, request.fieldRef);
        }
        update objsProcessed.values();

        return new List<Response>{ new Response(objsProcessed.values())} ;
    }

    private static HieItem findContractToProcess(HieItem item) {
        Boolean beingRenew = String.isBlank((String)item.sObj.get('SBQQ__RenewalOpportunity__c'));
        if ( beingRenew ) {
            return item;
        }
        for (HieItem child : item.children) {
            HieItem i = findContractToProcess(child);
            if (i != null) {
                return i;
            }
        }   
        return null;
    }

    private static void deepClone(HieItem item, Map<String, sObject> objsProcessed) {
        objsProcessed.put(item.selfId, item.sObj.clone(false));
        for (HieItem child : item.children) {
            deepClone(child, objsProcessed);
        }
    }

    private static void correctParent(HieItem item, Map<String, sObject> objsProcessed, String fieldRef) {
        sObject sObjClone = objsProcessed.get(item.selfId);
        String parentIdClone = objsProcessed.get(item.parentId)?.Id;
        sObjClone.put(fieldRef, parentIdClone);
        for (HieItem child : item.children) {
            correctParent(child, objsProcessed, fieldRef);
        }
    }

    private static void constructHie(HieItem parent, Map<String, HieItem[]> mChildren) {
        HieItem[] children = mChildren.get(parent.selfId);
        if (children == null || children.isEmpty()) {
            return;
        }
        parent.children = children;
        for (HieItem item : children) {
            constructHie(item, mChildren);
        }
    }

    // Define a Request class to handle the input
    public class Request {
        @InvocableVariable(required=true)
        public String[] objIdsToProcess;
        @InvocableVariable(required=true)
        public String objTypeName;
        @InvocableVariable(required=true)
        public String fieldRef;
    }
    
    // Define a Response class to handle the output
    public class Response {
        @InvocableVariable
        public String[] objIdsClone;
        public Response(sObject[] sObjs) {
            objIdsClone = new List<String>();
            for (sObject sObj : sObjs) {
                objIdsClone.add(sObj.Id);
            }
        }
    }

    public class HieItem {
        public String selfId;
        public String parentId;
        public sObject sObj;
        public HieItem[] children;
        public HieItem(sObject sObj, String parentId) {
            this.selfId = sObj.Id;
            this.parentId = parentId;
            this.sObj = sObj;
            this.children = new List<HieItem>();
        }
    }
}