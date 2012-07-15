require "spec_helper"

describe SmugMug::HTTP do
  include Support::ResponseMock

  it "handles HTTP errors" do
    res_mock = mock("Response")
    res_mock.stub(:code).and_return("404")
    res_mock.stub(:message).and_return("Not Found")
    res_mock.stub(:header).and_return({})

    http_mock = mock("HTTP")
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
    postdata.should == "a=Foo+%26+Bar&b=5&c=Foo%0ABar&method=smugmug.foo.bar&oauth_consumer_key=1234-api&oauth_nonce=3858f62230ac3c915f300c664312c63f&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1341594000&oauth_token=abcd-token&oauth_version=1.0&oauth_signature=aACF%2BsJgVSyhWkhT%2BHlIwboZPSw%3D"
  end
end