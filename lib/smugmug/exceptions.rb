module SmugMug
  ##
  # Generic module that provides access to the code and text separately of the exception
  module ReplyErrors
    attr_reader :reply_text, :reply_code

    def initialize(msg, reply_code=nil, reply_text=nil)
      super(msg)
      @reply_code, @reply_text = reply_code, reply_text
    end
  end

  ##
  # Errors specific to the OAuth request
  class OAuthError < StandardError
    include ReplyErrors
  end

  ##
  # HTTP errors
  class HTTPError < StandardError
    include ReplyErrors
  end

  ##
  # Problem with the request
  class RequestError < StandardError
    include ReplyErrors

  end

  ##
  # SmugMug is in read-only mode
  class ReadonlyMode < StandardError
  end
end