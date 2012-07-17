require "spec_helper"

describe SmugMug::Client do
  before :each do
    @client = SmugMug::Client.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})
  end

  it "creates a SmugMug API wrapper" do
    wrapper = @client.accounts
    wrapper.should be_a_kind_of(SmugMug::ApiCategory)
    wrapper.instance_variable_get(:@category).should == "accounts"
    @client.instance_variable_get(:@accounts_wrapper).should == wrapper
  end

  it "reuses created wrappers" do
    @client.users.should == @client.users
  end

  it "errors on invalid method" do
    lambda { @client.foobar }.should raise_error(NoMethodError)
  end

  it "prepares a File file for upload" do
    file = mock("File")
    file.should_receive(:is_a?).with(String).and_return(false)
    file.should_receive(:is_a?).with(File).and_return(true)
    file.should_receive(:path).and_return("/Users/foobar/Desktop/image.jpg")
    file.should_receive(:read).and_return("foo bar")

    http = mock("HTTP")
    http.should_receive(:request).with(:uploading, {:content => "foo bar", :FileName => "image.jpg", :AlbumID => 1234})
    @client.instance_variable_set(:@http, http)

    @client.upload_media(:file => file, :AlbumID => 1234)
  end

  it "prepares a String file for upload" do
    File.should_receive(:read).with("/Users/foobar/Desktop/image.jpg").and_return("foo bar")

    http = mock("HTTP")
    http.should_receive(:request).with(:uploading, {:content => "foo bar", :FileName => "image.jpg", :AlbumID => 1234})
    @client.instance_variable_set(:@http, http)

    @client.upload_media(:file => "/Users/foobar/Desktop/image.jpg", :AlbumID => 1234)
  end
end