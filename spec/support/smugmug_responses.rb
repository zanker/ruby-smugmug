class SmugMugResponses
  ERROR = '{"stat":"fail", "method":"smugmug.albums.getStats", "code":%d, "message":"invalid user"}'
  SUCCESS = '{"stat":"ok","method":"smugmug.users.getInfo","User":{"Name":"foobar","NickName":"FooBar","URL":"http://foobar.smugmug.com"}}'
  FILE_SUCCESS = '{"stat":"ok","method":"smugmug.images.upload","Image":{"id":1970029991, "Key":"rnSfAak", "URL":"http://foobar.smugmug.com/Other/Foo/51343_k8W1aR#1970029991_rnSfAak"}}'
end