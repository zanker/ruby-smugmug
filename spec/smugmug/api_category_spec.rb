require "spec_helper"

describe SmugMug::ApiCategory do
  it "dispatches an API request" do
    http_mock = double("HTTP")
    http_mock.should_receive(:request).with("users.getStats", {:Month => 2, :Year => 2012}).and_return("Foo Bar")

    wrapper = SmugMug::ApiCategory.new(http_mock, "users")
    wrapper.getStats(:Month => 2, :Year => 2012).should == "Foo Bar"
  end

  it "errors on invalid method" do
    wrapper = SmugMug::ApiCategory.new(nil, "accounts")
    lambda { wrapper.foobar }.should raise_error(NoMethodError)
  end
end