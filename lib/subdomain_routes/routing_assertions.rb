module SubdomainRoutes
  module RoutingAssertions
    def self.included(base)
      [ :assert_recognizes, :recognized_request_for, :assert_generates ].each { |method| base.alias_method_chain method, :subdomains }
    end
        
    def assert_recognizes_with_subdomains(expected_options, path, extras={}, message=nil)
      if path.is_a? Hash
        request_method = path[:method]
        host           = path[:host]
        path           = path[:path]
      else
        request_method = nil
        host = nil
      end
      clean_backtrace do
        ActionController::Routing::Routes.reload if ActionController::Routing::Routes.empty?
        request = recognized_request_for(path, host, request_method)
        
        expected_options = expected_options.clone
        extras.each_key { |key| expected_options.delete key } unless extras.nil?

        expected_options.stringify_keys!
        routing_diff = expected_options.diff(request.path_parameters)
        
        msg = build_message(message, "The recognized options <?> did not match <?>, difference: <?>",
            request.path_parameters, expected_options, expected_options.diff(request.path_parameters))
        assert_block(msg) { request.path_parameters == expected_options }
      end
    end

    private

    def recognized_request_for_with_subdomains(path, host, request_method = nil)
      path = "/#{path}" unless path.first == '/'

      # Assume given controller
      request = ActionController::TestRequest.new
      request.env["REQUEST_METHOD"] = request_method.to_s.upcase if request_method
      request.path = path
      request.host = host if host
      ActionController::Routing::Routes.recognize(request)
      request
    end
    
    include SubdomainRoutes::RewriteSubdomainOptions
    def assert_generates_with_subdomains(expected_path, options, defaults={}, extras = {}, message=nil)
      host_options = options.dup
      rewrite_subdomain_options(host_options, expected_path[:host])
      host_options.slice!(:only_path, :host)
      if host_options[:only_path] == false
        expected_path[:path] = 
      assert_generates_without_subdomains(expected_path[:path], options, defaults, extras, message)
    end
  end
end

ActionController::Assertions::RoutingAssertions.send :include, SubdomainRoutes::RoutingAssertions