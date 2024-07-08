public class GetRelatedProductsByKeywords {
	@InvocableMethod(label='Get Related Products' description='Get related product from previous subscription')
    public static List<ProductResponse> getRelatedProducts(List<Request> requests) {
        // List to hold the results
        List<Response> results = new List<Response>();
        List<ProductResponse> productResponses = new List<ProductResponse>();
        // Loop through each request
        for(Request req : requests) {
            // Split the product name into keywords using whitespace as the delimiter
            List<String> keywords = req.productName.split(' ');
            
            // Create a new Response object to hold the keywords
            Response res = new Response();
            res.keywords = keywords;
            
            // Add the Response object to the results list
            results.add(res);
        }
        
		List<String> productName = results[0].keywords;
        
        if (productName.isEmpty()) {
            return new List<ProductResponse>();
        }
        String searchTerm = '';
        for (String word : productName) {
            searchTerm += word + '*  OR ';
        }
        searchTerm = searchTerm.substringBeforeLast('OR');
        List<List<SObject>> searchList = [FIND :searchTerm IN NAME FIELDS RETURNING Product2 (Id, Name)];
        
        List<ID> productIds = new List<ID>();
        List<Product2> products = (List<Product2>)searchList[0];
        
        for (Product2 p : products) {
            productIds.add(p.Id);
        }
        		
        ProductResponse pr = new ProductResponse();
        pr.products = productIds;
        productResponses.add(pr);
        
        return productResponses;        
    }
    
    
      // Define a Request class to handle the input
    public class Request {
        @InvocableVariable(required=true)
        public String productName;
    }
    
    // Define a Response class to handle the output
    public class Response {
        @InvocableVariable
        public List<String> keywords;
    }
    
    public class ProductResponse {
        @InvocableVariable
        public List<ID> products;
    }
    
}