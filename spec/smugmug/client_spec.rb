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
end