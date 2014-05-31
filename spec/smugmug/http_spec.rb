require "spec_helper"
require "zlib"

describe SmugMug::HTTP do
  include Support::ResponseMock

  it "uploads a file" do
    res_mock = double("Response")
    res_mock.stub(:body).and_return(SmugMugResponses::FILE_SUCCESS)
    res_mock.stub(:code).and_return("200")
    res_mock.stub(:message).and_return("OK")
    res_mock.stub(:header).and_return({})

    http_mock = double("HTTP")
    http_mock.should_receive(:request_post).with("/", "foo bar", hash_including("Content-Length" => "7", "Content-MD5" => "327b6f07435811239bc47e1544353273", "X-Smug-FileName" => "image.jpg", "X-Smug-AlbumID" => "1234", "Authorization" => "OAuth oauth_consumer_key=\"consumer\", oauth_nonce=\"nonce\", oauth_signature_method=\"sig-method\", oauth_signature=\"sig\", oauth_timestamp=\"1234\", oauth_version=\"1.0\", oauth_token=\"token\"")).and_return(res_mock)

    Net::HTTP.should_receive(:new).and_return(http_mock)

    http = SmugMug::HTTP.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})
    http.should_receive(:sign_request).with("POST", SmugMug::HTTP::UPLOAD_URI, nil).and_return({"oauth_consumer_key" => "consumer", "oauth_nonce" => "nonce", "oauth_signature_method" => "sig-method", "oauth_signature" => "sig", "oauth_timestamp" => "1234", "oauth_version" => "1.0", "oauth_token" => "token"})

    data = http.request(:uploading, {:FileName => "image.jpg", :content => "foo bar", :AlbumID => 1234})
    data.should == JSON.parse(SmugMugResponses::FILE_SUCCESS)["Image"]
  end

  it "unzips gzipped responses" do
    mock_response(SmugMugResponses::SUCCESS)

    http = SmugMug::HTTP.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})

    data = http.request("users.getInfo", {})
    data.should == JSON.parse(SmugMugResponses::SUCCESS)["User"]
  end

  it "unzips gzipped responses" do
    output = StringIO.new
    gz = Zlib::GzipWriter.new(output)
    gz.write(SmugMugResponses::SUCCESS)
    gz.close

    res_mock = double("Response")
    res_mock.stub(:body).and_return(output.string)
    res_mock.stub(:code).and_return("200")
    res_mock.stub(:message).and_return("OK")
    res_mock.stub(:header).and_return({"content-encoding" => "gzip"})

    http_mock = double("HTTP")
    http_mock.should_receive(:use_ssl=).with(true)
    http_mock.should_receive(:verify_mode=).with(anything)
    http_mock.should_receive(:request_post).with(anything, anything, anything).and_return(res_mock)

    Net::HTTP.should_receive(:new).and_return(http_mock)

    http = SmugMug::HTTP.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})

    data = http.request("users.getInfo", {})
    data.should == JSON.parse(SmugMugResponses::SUCCESS)["User"]
  end

  it "handles response errors" do
    http = SmugMug::HTTP.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})

    mock_response(SmugMugResponses::ERROR % 99)
    lambda { http.request("users.getInfo", {}) }.should raise_error(SmugMug::ReadonlyModeError)

    mock_response(SmugMugResponses::ERROR % 30)
    lambda { http.request("users.getInfo", {}) }.should raise_error(SmugMug::OAuthError)

    mock_response(SmugMugResponses::ERROR % 1)
    lambda { http.request("users.getInfo", {}) }.should raise_error(SmugMug::RequestError)
  end

  it "handles HTTP errors" do
    res_mock = double("Response")
    res_mock.stub(:code).and_return("404")
    res_mock.stub(:message).and_return("Not Found")
    res_mock.stub(:header).and_return({})

    http_mock = double("HTTP")
    http_mock.should_receive(:use_ssl=).with(true)
    http_mock.should_receive(:verify_mode=).with(anything)
    http_mock.should_receive(:request_post).with(anything, anything, anything).and_return(res_mock)

    Net::HTTP.should_receive(:new).and_return(http_mock)

    http = SmugMug::HTTP.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})
    lambda { http.request("users.getInfo", {}) }.should raise_error(SmugMug::HTTPError)
  end

  it "generates a correct HMAC-SHA1 digest" do
    Time.stub(:now).and_return(Time.at(1341594000))

    nonce = Digest::MD5.hexdigest("foobar")
    Digest::MD5.should_receive(:hexdigest).and_return(nonce)

    http = SmugMug::HTTP.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})
    postdata = http.sign_request("POST", SmugMug::HTTP::API_URI, {"method" => "smugmug.foo.bar", "a" => "Foo & Bar", "b" => 5, "c" => "Foo\nBar"})
    postdata.should == "a=Foo%20%26%20Bar&b=5&c=Foo%0ABar&method=smugmug.foo.bar&oauth_consumer_key=1234-api&oauth_nonce=3858f62230ac3c915f300c664312c63f&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1341594000&oauth_token=abcd-token&oauth_version=1.0&oauth_signature=C8f06Vw2HDBxSFzTlyBztGjoCXw%3D"
  end
end
