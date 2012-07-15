require "cgi"
require "openssl"
require "base64"
require "net/http"

module SmugMug
  class HTTP
    API_URI = URI("https://api.smugmug.com/services/api/json/1.3.0")

    ##
    # Creates a new HTTP wrapper to handle the network portions of the API requests
    # @param [Hash] args Same as [SmugMug::HTTP]
    #
    def initialize(args)
      @config = args
      @headers = {"User-Agent" => args.delete(:user_agent) || "Ruby-SmugMug v#{SmugMug::VERSION}"}
      @digest = OpenSSL::Digest::Digest.new("SHA1")
    end

    def request(api, args)
      args[:method] = "smugmug.#{api}"

      http = ::Net::HTTP.new(API_URI.host, API_URI.port)
      http.set_debug_output(@config[:debug_output]) if @config[:debug_output]

      # Configure HTTPS if needed
      if API_URI.scheme == "https"
        http.use_ssl = true

        if @config[:http] and @config[:http][:verify_mode]
          http.verify_mode = @config[:http][:verify_mode]
          http.ca_file = @config[:http][:ca_file]
          http.ca_path = @config[:http][:ca_path]
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      # Parse post data
      postdata = self.sign_request("POST", API_URI, args)

      response = http.request_post(API_URI.request_uri, postdata, @headers)
    end

    ##
    # Generates an OAuth signature and updates the args with the required fields
    # @param [String] method HTTP method that the request is sent as
    # @param [String] uri Full URL of the request
    # @param [Hash] form_args Args to be passed to the server
    def sign_request(method, uri, form_args)
      # Convert non-string keys to strings so the sort works
      args = {}
      form_args.each do |key, value|
        next unless value and value != ""

        key = key.to_s unless key.is_a?(String)
        args[key] = value
      end

      # Add the necessary OAuth args
      args["oauth_version"] = "1.0"
      args["oauth_consumer_key"] = @config[:api_key]
      args["oauth_nonce"] = Digest::MD5.hexdigest("#{Time.now.to_f}#{rand(10 ** 30)}")
      args["oauth_signature_method"] = "HMAC-SHA1"
      args["oauth_timestamp"] = Time.now.utc.to_i
      args["oauth_token"] = @config[:user][:token]

      # Sort the params
      sorted_args = []
      args.sort.each do |key, value|
        sorted_args.push("#{key.to_s}=#{URI::encode_www_form_component(value.to_s)}")
      end

      postdata = sorted_args.join("&")

      # Final string to hash
      sig_base = "#{method}&#{URI::encode_www_form_component("#{uri.scheme}://#{uri.host}#{uri.path}")}&#{URI::encode_www_form_component(postdata)}"

      signature = OpenSSL::HMAC.digest(@digest, "#{@config[:oauth_secret]}&#{@config[:user][:secret]}", sig_base)
      signature = Base64.encode64(signature).chomp

      "#{postdata}&oauth_signature=#{URI::encode_www_form_component(signature)}"
    end
  end
end