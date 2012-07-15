module Support
  module ResponseMock
    def mock_response(body)
      res_mock = mock("Response")
      res_mock.stub(:body).and_return(body)
      res_mock.stub(:code).and_return("200")
      res_mock.stub(:message).and_return("OK")
      res_mock.stub(:header).and_return({})

      http_mock = mock("HTTP")
      http_mock.should_receive(:start).and_yield
      http_mock.should_receive(:request_get).with(any_args).and_yield(res_mock)

      Net::HTTP.should_receive(:new).and_return(http_mock)
    end
  end
end