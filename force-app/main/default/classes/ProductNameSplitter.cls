public class ProductNameSplitter {
    @InvocableMethod(label='Split Product Name' description='Splits the product name into separate keywords.')
    public static List<Response> splitProductName(List<Request> requests) {
        // List to hold the results
        List<Response> results = new List<Response>();
        
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
        
        return results;
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
    
    
}