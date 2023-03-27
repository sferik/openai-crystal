require "http/client"

module OpenAI
  class Client
    class Error < Exception
    end

    record LastResponse, date : Time, organization : String, processing_ms : Int32, request_id : String, response : HTTP::Client::Response do
      def initialize(@response : HTTP::Client::Response)
        @date = Time::Format::HTTP_DATE.parse(@response.headers.fetch("date", Time::Format::HTTP_DATE.format(Time.utc).to_s))
        @organization = @response.headers.fetch("openai-organization", "none")
        @processing_ms = @response.headers.fetch("openai-processing-ms", "0").to_i
        @request_id = @response.headers.fetch("x-request-id", "")
      end

      forward_missing_to(@response)
    end

    getter last_response : LastResponse?
    setter api_key : String
    property default_model : String

    def initialize(api_key : String, default_model : String = "davinci")
      @api_key = api_key
      @default_model = default_model
    end

    def model(id : String = default_model)
      model = get("/v1/models/#{id}")
      Model.from_json(model)
    end

    def models
      response_body = get("/v1/models")
      models = JSON.parse(response_body)
      Array(Model).from_json(models["data"].to_json)
    end

    def completions(
      prompt : String? = nil,
      max_tokens : Int32? = nil,
      temperature : Float64? = nil,
      top_p : Float64? = nil,
      n : Int32? = nil,
      logprobs : Int32? = nil,
      echo : Bool? = nil,
      stop : String? | Array(String) = nil,
      presence_penalty : Float64? = nil,
      frequency_penalty : Float64? = nil,
      model : String = default_model
    )
      body = {
        "prompt"            => prompt,
        "max_tokens"        => max_tokens,
        "temperature"       => temperature,
        "top_p"             => top_p,
        "n"                 => n,
        "logprobs"          => logprobs,
        "echo"              => echo,
        "stop"              => stop,
        "presence_penalty"  => presence_penalty,
        "frequency_penalty" => frequency_penalty,
        "model"             => model,
      }.compact

      response_body = post("/v1/completions", body: body)
      Completion.from_json(response_body)
    end

    def completions(
      prompt : String? = nil,
      max_tokens : Int32? = nil,
      temperature : Float64? = nil,
      top_p : Float64? = nil,
      n : Int32? = nil,
      logprobs : Int32? = nil,
      echo : Bool? = nil,
      stop : String? | Array(String) = nil,
      presence_penalty : Float64? = nil,
      frequency_penalty : Float64? = nil,
      model : String = default_model,
      &block : Completion -> _
    )
      body = {
        "prompt"            => prompt,
        "max_tokens"        => max_tokens,
        "temperature"       => temperature,
        "top_p"             => top_p,
        "n"                 => n,
        "logprobs"          => logprobs,
        "echo"              => echo,
        "stop"              => stop,
        "stream"            => true,
        "presence_penalty"  => presence_penalty,
        "frequency_penalty" => frequency_penalty,
        "model"             => model,
      }.compact

      event_source = EventSource.new("https://api.openai.com/v1/completions", base_headers: headers, body: body.to_json)

      event_source.on_message do |message|
        message.data.each do |datum|
          if datum == "[DONE]"
            event_source.stop
          else
            block.call(Completion.from_json(datum))
          end
        end
      end

      event_source.on_error do |error|
        raise Error.new(error[:message])
      end

      event_source.run
    end

    private def get(path : String, headers : HTTP::Headers = default_headers) : String
      response = client.get(path, headers: headers)
      handle_response(response)
    end

    private def post(path : String, body : Hash, headers : HTTP::Headers = default_headers) : String
      response = client.post(path, headers: headers, body: body.to_json)
      handle_response(response)
    end

    private def handle_response(response) : String
      @last_response = LastResponse.new(response)
      if response.success?
        response.body
      else
        error = JSON.parse(response.body)
        raise Error.new(error["error"]["message"].to_s)
      end
    end

    private def client
      @client ||= HTTP::Client.new(URI.parse("https://api.openai.com"))
    end

    private def default_headers
      @headers ||= HTTP::Headers{
        "Authorization" => "Bearer #{@api_key}",
        "Content-Type"  => "application/json",
      }
    end
  end
end
