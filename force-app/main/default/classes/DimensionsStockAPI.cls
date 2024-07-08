/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 30-10-2022
 * @last modified by  : matthew.rosete@pracedo.com
**/
public with sharing class DimensionsStockAPI {
    public class StockCode {
        public String code;
        public String description;
        public Decimal cost;
        //public String currency;
        public String currencySymbol;
        public String pillar;
        public String category;
        public String subcategory;
        public String productLine;        
    }
    
    public static HttpResponse getDimensionsStock() {
        HttpResponse response = DimensionsAPIHelper.callDimensionsApi('https://api.fluidone.com:8443/Dimensions/api/stocks','GET','');
        return response;
    }
}