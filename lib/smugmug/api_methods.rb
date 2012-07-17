module SmugMug
  API_METHODS = {
    "accounts" => {"browse" => true},
    "albums" => {"applyWatermark" => true, "browse" => true, "changeSettings" => true, "comments" => true, "create" => true, "delete" => true, "get" => true, "getInfo" => true, "getStats" => true, "removeWatermark" => true, "reSort" => true},
    "albumtemplates" => {"changeSettings" => true, "create" => true, "delete" => true, "get" => true}, "auth" => {"checkAccessToken" => true, "getAccessToken" => true, "getRequestToken" => true},
    "categories" => {"create" => true, "delete" => true, "get" => true, "rename" => true}, "communities" => {"get" => true}, "coupons" => {"create" => true, "get" => true, "getInfo" => true, "modify" => true, "restrictions" => true},
    "family" => {"add" => true, "get" => true, "remove" => true, "removeAll" => true}, "fans" => {"get" => true}, "featured" => {"albums" => true}, "friends" => {"add" => true, "get" => true, "remove" => true, "removeAll" => true},
    "images" => {"applyWatermark" => true, "changePosition" => true, "changeSettings" => true, "collect" => true, "comments" => true, "crop" => true, "delete" => true, "get" => true, "getEXIF" => true, "getInfo" => true, "getStats" => true, "getURLs" => true, "removeWatermark" => true, "rotate" => true, "uploadFromURL" => true, "zoomThumbnail" => true},
    "printmarks" => {"create" => true, "delete" => true, "get" => true, "getInfo" => true, "modify" => true},
    "service" => {"ping" => true},
    "sharegroups" => {"albums" => true, "browse" => true, "create" => true, "delete" => true, "get" => true, "getInfo" => true, "modify" => true},
    "styles" => {"getTemplates" => true},
    "subcategories" => {"create" => true, "delete" => true, "get" => true, "getAll" => true, "rename" => true},
    "themes" => {"get" => true},
    "users" => {"getInfo" => true, "getStats" => true, "getTree" => true},
    "watermarks" => {"changeSettings" => true, "create" => true, "delete" => true, "get" => true, "getInfo" => true}
  }
end