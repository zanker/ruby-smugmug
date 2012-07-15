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
  # 
  class OAuthError < StandardError
    include ReplyErrors
  end

  ##
  # HTTP errors
  class HTTPError < StandardError
    include ReplyErrors
  end

  ##
  # Error with doing that due to permissions (Trying to write with a read only key)
  class PermissionError < StandardError
    include ReplyErrors

  end
end