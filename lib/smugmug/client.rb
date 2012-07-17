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

    ##
    # Uploading media files to SmugMug, see http://wiki.smugmug.net/display/API/Uploading for more information
    # @param [Hash] args
    # @option args [File] :file File or stream that can have the content read to upload
    # @option args [String] :file Binary contents of the file to upload
    # @option args [String] :FileName What the file name is, only required when passing :file as a string
    # @option args [Integer] :AlbumID SmugMug Album ID to upload the media to
    # @option args [Integer, Optional] :ImageID Image ID to replace if reuploading media rather than adding new
    # @option args [String, Optional] :Caption The caption for the media
    # @option args [Boolean, Optional] :Hidden Whether the media should be visible
    # @option args [String, Optional] :Keywords Keywords to tag the media as
    # @option args [Integer, Optional] :Altitude Altitude the media was taken at
    # @option args [Float, Optional] :Latitude Latitude the media was taken at
    # @option args [Float, Optional] :Longitude Latitude the media was taken at
    #
    # @raise [SmugMug::OAuthError]
    # @raise [SmugMug::HTTPError]
    # @raise [SmugMug::RequestError]
    # @raise [SmugMug::ReadonlyModeError]
    # @raise [SmugMug::UnknownAPIError]
    def upload_media(args)
      raise ArgumentError, "File is required" unless args.has_key?(:file)
      raise ArgumentError, "AlbumID is required" unless args.has_key?(:AlbumID)

      if args[:file].is_a?(String)
        args[:FileName] ||= File.basename(args[:file])
        args[:content] = File.read(args[:file])
      elsif args[:file].is_a?(File)
        args[:FileName] ||= File.basename(args[:file].path)
        args[:content] = args[:file].read
      else
        raise ArgumentError, "File must be a String or File"
      end

      args.delete(:file)
      @http.request(:uploading, args)
    end

    ##
    # Direct mapping of SmugMug 1.3.0 API, either see http://wiki.smugmug.net/display/API/API+1.3.0 or the README for examples
    #
    # @raise [SmugMug::OAuthError]
    # @raise [SmugMug::HTTPError]
    # @raise [SmugMug::RequestError]
    # @raise [SmugMug::ReadonlyModeError]
    # @raise [SmugMug::UnknownAPIError]
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