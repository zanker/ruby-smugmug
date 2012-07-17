module SmugMug
  class ApiCategory
    def initialize(http, category)
      @http, @category = http, category
    end

    def method_missing(method, *args)
      return super unless SmugMug::API_METHODS[@category][method.to_s]
      @http.request("#{@category}.#{method}", args.pop || {})
    end
  end
end