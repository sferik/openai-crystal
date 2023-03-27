require "./../spec_helper"

describe OpenAI::Client do
  describe "Unauthorized" do
    WebMock.stub(:get, "https://api.openai.com/v1/models/davinci-v2")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/errors/unauthorized.json"), headers: response_headers, status: 401)

    it "raises an exception" do
      expect_raises(OpenAI::Client::Error, "Incorrect API key provided: sk-f00. You can find your API key at https://beta.openai.com.") do
        with_client do |client|
          client.model("davinci-v2")
        end
      end
    end
  end

  describe "Not Found" do
    WebMock.stub(:get, "https://api.openai.com/v1/models/turing")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/errors/not_found.json"), headers: response_headers, status: 404)

    it "raises an exception" do
      expect_raises(OpenAI::Client::Error, "No model with that ID: turing") do
        with_client do |client|
          client.model("turing")
        end
      end
    end
  end

  describe "#default_model" do
    it "returns the default model" do
      with_client do |client|
        client.default_model.should eq("davinci")
      end
    end
  end

  describe "#last_response" do
    WebMock.stub(:get, "https://api.openai.com/v1/models/davinci")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/model.json"), headers: response_headers)

    it "returns the last response" do
      with_client do |client|
        client.last_response.should be_nil
        client.model("davinci")
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

  describe "#model" do
    WebMock.stub(:get, "https://api.openai.com/v1/models/davinci")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/model.json"), headers: response_headers)

    it "retrieves a model" do
      with_client do |client|
        model = client.model("davinci")
        model.id.should eq("davinci")
        model.owned_by.should eq("openai")
        model.root.should eq("davinci")
      end
    end
  end

  describe "#models" do
    WebMock.stub(:get, "https://api.openai.com/v1/models")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/models.json"), headers: response_headers)

    it "lists models" do
      with_client do |client|
        models = client.models
        models.should be_a(Array(OpenAI::Model))
      end
    end
  end

  describe "#completions" do
    WebMock.stub(:post, "https://api.openai.com/v1/completions")
      .with(headers: request_headers)
      .to_return(body: File.read("spec/fixtures/completions.json"), headers: response_headers)

    it "creates a completion" do
      with_client do |client|
        prompt = "Once upon a time"
        max_tokens = 5
        results = client.completions(prompt: prompt, max_tokens: max_tokens, model: "ada")
        results.should be_a(OpenAI::Completion)
      end
    end
  end
end
