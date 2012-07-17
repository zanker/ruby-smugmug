module SmugMug
  class Client
    ##
    # Creates a new client instance that can be used to access the SMugMug API
    # @param [Hash] args
    # @option args [String] :api_key Your SmugMug API key
    # @option args [String] :oauth_secret Your SmugMug OAuth secret key
    # @option args [Hash] :user Configuration for the user you are requesting/updating data for
    #   * :token [String] OAuth token for the user
    #   * :secret [String] OAuth secret token for the user
    # @option args [String, Optional :user_agent Helps SmugMug identify API calls
    # @option args [Hash, Optional] :http Additional configuration for the HTTP requests
    #   * :verify_mode [Integer, Optional] How to verify the SSL certificate when connecting through HTTPS, either OpenSSL::SSL::VERIFY_PEER or OpenSSL::SSL::VERIFY_NONE, defaults to OpenSSL::SSL::VERIFY_NONE
    #   * :ca_file [String, Optional] Path to the CA certification file in PEM format
    #   * :ca_path [String, Optional] Path to the directory containing CA certifications in PEM format
    #
    # @raise [ArgumentError]
    def initialize(args)
      raise ArgumentError, "API Key required" unless args.has_key?(:api_key)
      raise ArgumentError, "API OAuth secret required" unless args.has_key?(:oauth_secret)
      raise ArgumentError, "Must specify the users OAuth datA" unless args[:user].is_a?(Hash)
      raise ArgumentError, "Users OAuth token required" unless args[:user][:token]
      raise ArgumentError, "Users OAuth secret token required" unless args[:user][:secret]

      @http = HTTP.new(args)
    end

    def method_missing(method, *args)
      api_cat = method.to_s
      return super unless SmugMug::API_METHODS[api_cat]

      if klass = self.instance_variable_get("@#{api_cat}_wrapper")
        klass
      else
        self.instance_variable_set("@#{api_cat}_wrapper", SmugMug::ApiCategory.new(@http, api_cat))
      end
    end
  end
end