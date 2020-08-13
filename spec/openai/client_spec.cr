require "./../spec_helper"

describe OpenAI::Client do
  describe "Unauthorized" do
    WebMock.stub(:get, "https://api.openai.com/v1/engines/davinci-v2")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/errors/unauthorized.json"), headers: response_headers, status: 401)

    it "raises an exception" do
      expect_raises(OpenAI::Client::Error, "Incorrect API key provided: sk-f00. You can find your API key at https://beta.openai.com.") do
        with_client do |client|
          client.engine("davinci-v2")
        end
      end
    end
  end

  describe "Not Found" do
    WebMock.stub(:get, "https://api.openai.com/v1/engines/turing")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/errors/not_found.json"), headers: response_headers, status: 404)

    it "raises an exception" do
      expect_raises(OpenAI::Client::Error, "No engine with that ID: turing") do
        with_client do |client|
          client.engine("turing")
        end
      end
    end
  end

  describe "#api_key" do
    it "returns the API key" do
      with_client do |client|
        client.api_key.should eq(mock_api_key)
      end
    end
  end

  describe "#default_engine" do
    it "returns the default engine" do
      with_client do |client|
        client.default_engine.should eq("davinci")
      end
    end
  end

  describe "#last_response" do
    WebMock.stub(:get, "https://api.openai.com/v1/engines/davinci")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/engine.json"), headers: response_headers)

    it "returns the last response" do
      with_client do |client|
        client.last_response.should be_nil
        client.engine("davinci")
        last_response = client.last_response
        last_response.should be_a(OpenAI::Client::LastResponse)
        last_response.not_nil!.organization.should be_a(String)
        last_response.not_nil!.date.should be_a(Time)
        last_response.not_nil!.processing_ms.should be_a(Int32)
        last_response.not_nil!.processing_ms.should be >= 0
        last_response.not_nil!.request_id.should be_a(String)
        last_response.not_nil!.request_id.size.should eq(32)
      end
    end
  end

  describe "#engine" do
    WebMock.stub(:get, "https://api.openai.com/v1/engines/davinci")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/engine.json"), headers: response_headers)

    it "retrieves an engine" do
      with_client do |client|
        engine = client.engine("davinci")
        engine.id.should eq("davinci")
        engine.owner.should eq("openai")
        engine.ready.should be_a(Bool)
      end
    end
  end

  describe "#engines" do
    WebMock.stub(:get, "https://api.openai.com/v1/engines")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/engines.json"), headers: response_headers)

    it "lists engines" do
      with_client do |client|
        engines = client.engines
        engines.should be_a(Array(OpenAI::Engine))
      end
    end
  end

  describe "#completions" do
    WebMock.stub(:post, "https://api.openai.com/v1/engines/ada/completions")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/completions.json"), headers: response_headers)

    it "creates a completion" do
      with_client do |client|
        prompt = "Once upon a time"
        max_tokens = 5
        results = client.completions(prompt: prompt, max_tokens: max_tokens, engine: "ada")
        results.should be_a(OpenAI::Completion)
      end
    end
  end

  describe "#search" do
    WebMock.stub(:post, "https://api.openai.com/v1/engines/ada/search")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/search.json"), headers: response_headers)

    it "searches" do
      with_client do |client|
        documents = ["White House", "hospital", "school"]
        query = "the president"
        results = client.search(documents: documents, query: query, engine: "ada")
        results.should be_a(Array(OpenAI::SearchResult))
        first_result = results.first
        first_result.document.should eq(0)
        first_result.score.should be_a(Float64)
        first_result.score.should be >= 0.0
      end
    end
  end
end
