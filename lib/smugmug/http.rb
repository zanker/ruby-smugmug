require "cgi"
require "openssl"
require "base64"
require "net/http"
require "json"

module SmugMug
  class HTTP
    API_URI = URI("https://api.smugmug.com/services/api/json/1.3.0")
    UPLOAD_URI = URI("http://upload.smugmug.com/")
    UPLOAD_HEADERS = [:AlbumID, :Caption, :Altitude, :ImageID, :Keywords, :Latitude, :Longitude, :Hidden, :FileName]
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

      args[:http] = args.fetch(:http,{})  #checks for the existance of :http, sets to nill if does not exist.
      @http_proxy_host = args[:http].fetch(:proxy_host,nil)
      @http_proxy_port = args[:http].fetch(:proxy_port,nil)
      @http_proxy_user = args[:http].fetch(:proxy_user,nil)
      @http_proxy_pass = args[:http].fetch(:proxy_pass,nil)
    end

    def request(api, args)
      uri = api == :uploading ? UPLOAD_URI : API_URI
      args[:method] = "smugmug.#{api}" unless api == :uploading

      http = ::Net::HTTP.new(uri.host, uri.port, @http_proxy_host, @http_proxy_port, @http_proxy_user, @http_proxy_pass)
      http.set_debug_output(@config[:debug_output]) if @config[:debug_output]

      # Configure HTTPS if needed
      if uri.scheme == "https"
        http.use_ssl = true

        if @config[:http] and @config[:http][:verify_mode]
          http.verify_mode = @config[:http][:verify_mode]
          http.ca_file = @config[:http][:ca_file]
          http.ca_path = @config[:http][:ca_path]
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      # Upload request, which requires special handling
      if api == :uploading
        postdata = args.delete(:content)
        headers = @headers.merge("Content-Length" => postdata.length.to_s, "Content-MD5" => Digest::MD5.hexdigest(postdata), "X-Smug-Version" => "1.3.0", "X-Smug-ResponseType" => "JSON")

        UPLOAD_HEADERS.each do |key|
          next unless args[key] and args[key] != ""
          headers["X-Smug-#{key}"] = args[key].to_s
        end

        oauth = self.sign_request("POST", uri, nil)
        headers["Authorization"] = "OAuth oauth_consumer_key=\"#{oauth["oauth_consumer_key"]}\", oauth_nonce=\"#{oauth["oauth_nonce"]}\", oauth_signature_method=\"#{oauth["oauth_signature_method"]}\", oauth_signature=\"#{oauth["oauth_signature"]}\", oauth_timestamp=\"#{oauth["oauth_timestamp"]}\", oauth_version=\"#{oauth["oauth_version"]}\", oauth_token=\"#{oauth["oauth_token"]}\""

      # Normal API method
      else
        postdata = self.sign_request("POST", uri, args)
        headers = @headers
      end

      response = http.request_post(uri.request_uri, postdata, headers)
      if response.code == "204"
        return nil
      elsif response.code != "200"
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

      return nil if body == ""

      data = JSON.parse(body)

      if data["stat"] == "fail"
        # Special casing for SmugMug being in Read only mode
        if data["code"] == 99
          raise SmugMug::ReadonlyModeError.new("SmugMug is currently in read only mode, try again later")
        end

        klass = OAUTH_ERRORS[data["code"]] ? SmugMug::OAuthError : SmugMug::RequestError
        raise klass.new("Error ##{data["code"]}, #{data["message"]}", data["code"], data["message"])
      end

      data.delete("stat")
      data.delete("method")

      # smugmug.albums.changeSettings at the least doesn't return any data
      return nil if data.length == 0

      # It seems all smugmug APIs only return one hash of data, so this should be fine and not cause issues
      data.each do |_, value|
        return value
      end
    end

    ##
    # Generates an OAuth signature and updates the args with the required fields
    # @param [String] method HTTP method that the request is sent as
    # @param [String] uri Full URL of the request
    # @param [Hash] form_args Args to be passed to the server
    def sign_request(method, uri, form_args)
      # Convert non-string keys to strings so the sort works
      args = {}
      if form_args
        form_args.each do |key, value|
          next unless value and value != ""

          key = key.to_s unless key.is_a?(String)
          args[key] = value
        end
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
      signature = CGI::escape(Base64.encode64(signature).chomp)

      if uri == API_URI
        "#{postdata}&oauth_signature=#{signature}"
      else
        args["oauth_signature"] = signature
        args
      end
    end
  end
end