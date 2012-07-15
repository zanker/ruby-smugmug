require "cgi"
require "openssl"
require "base64"
require "net/http"

module SmugMug
  class HTTP
    API_URI = URI("https://api.smugmug.com/services/api/json/1.3.0")
    OAUTH_ERRORS = {30 => true, 32 => true, 33 => true, 35 => true, 36 => true, 37 => true, 38 => true, 98 => true}

    ##
    # Creates a new HTTP wrapper to handle the network portions of the API requests
    # @param [Hash] args Same as [SmugMug::HTTP]
    #
    def initialize(args)
      @config = args
      @digest = OpenSSL::Digest::Digest.new("SHA1")

      @headers = {"Accept-Encoding" => "gzip"}
      if args[:user_agent]
        @headers["User-Agent"] = "#{args.delete(:user_agent)} (ruby-smugmug v#{SmugMug::VERSION})"
      else
        @headers["User-Agent"] = "Ruby-SmugMug v#{SmugMug::VERSION}"
      end
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
      if response.code != "200"
        raise SmugMug::HTTPError.new("HTTP #{response.code}, #{response.message}", response.code, response.message)
      end

      # Check for GZIP encoding
      if response.header["content-encoding"] == "gzip"
        begin
          body = Zlib::GzipReader.new(StringIO.new(response.body)).read
        rescue Zlib::GzipFile::Error
          raise
        end
      else
        body = response.body
      end

      body = JSON.parse(body)

      if body["stat"] == "fail"
        # Special casing for SmugMug being in Read only mode
        if body["code"] == 99
          raise SmugMug::ReadonlyMode.new("SmugMug is currently in read only mode, try again later")
        end

        klass = OAUTH_ERRORS[body["code"]] ? SmugMug::OAuthError : SmugMug::RequestError
        raise klass.new("Error ##{body["code"]}, #{body["message"]}", body["code"], body["message"])
      end

      body.delete("stat")
      body.delete("method")
      body
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
        sorted_args.push("#{key.to_s}=#{CGI::escape(value.to_s)}")
      end

      postdata = sorted_args.join("&")

      # Final string to hash
      sig_base = "#{method}&#{CGI::escape("#{uri.scheme}://#{uri.host}#{uri.path}")}&#{CGI::escape(postdata)}"

      signature = OpenSSL::HMAC.digest(@digest, "#{@config[:oauth_secret]}&#{@config[:user][:secret]}", sig_base)
      signature = Base64.encode64(signature).chomp

      "#{postdata}&oauth_signature=#{CGI::escape(signature)}"
    end
  end
end