require "http/client"

module OpenAI
  class Client
    class Error < Exception
    end

    class LastResponse
      getter date : Time
      getter organization : String
      getter processing_ms : Int32
      getter request_id : String

      def initialize(response : HTTP::Client::Response)
        @date = Time::Format::HTTP_DATE.parse(response.headers.fetch("date", Time::Format::HTTP_DATE.format(Time.utc)).to_s)
        @organization = response.headers.fetch("openai-organization", "none")
        @processing_ms = response.headers.fetch("openai-processing-ms", "0").to_i
        @request_id = response.headers.fetch("x-request-id", "")
        @response = response
      end

      delegate status, to: @response
      delegate status_code, to: @response
      delegate status_message, to: @response
    end

    getter last_response : LastResponse?
    property api_key : String
    property default_engine : String

    def initialize(api_key : String, default_engine : String = "davinci")
      @api_key = api_key
      @default_engine = default_engine
    end

    def engine(id : String = default_engine)
      response = client.get("/v1/engines/#{id}", headers: headers)
      @last_response = LastResponse.new(response)
      case response.status
      when HTTP::Status::OK
        Engine.from_json(response.body)
      else
        json = JSON.parse(response.body)
        raise Error.new(json["error"]["message"].to_s)
      end
    end

    def engines
      response = client.get("/v1/engines", headers: headers)
      @last_response = LastResponse.new(response)
      json = JSON.parse(response.body)
      case response.status
      when HTTP::Status::OK
        Array(Engine).from_json(json["data"].to_json)
      else
        raise Error.new(json["error"]["message"].to_s)
      end
    end

    def completions(prompt : String? = nil, max_tokens : Int32? = nil, temperature : Float64? = nil, top_p : Float64? = nil, n : Int32? = nil, logprobs : Int32? = nil, echo : Bool? = nil, stop : String? | Array(String) = nil, presence_penalty : Float64? = nil, frequency_penalty : Float64? = nil, engine : String = default_engine)
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
      }.compact
      response = client.post("/v1/engines/#{engine}/completions", headers: headers, body: body.to_json)
      @last_response = LastResponse.new(response)
      case response.status
      when HTTP::Status::OK
        Completion.from_json(response.body)
      else
        json = JSON.parse(response.body)
        raise Error.new(json["error"]["message"].to_s)
      end
    end

    def completions(prompt : String? = nil, max_tokens : Int32? = nil, temperature : Float64? = nil, top_p : Float64? = nil, n : Int32? = nil, logprobs : Int32? = nil, echo : Bool? = nil, stop : String? | Array(String) = nil, presence_penalty : Float64? = nil, frequency_penalty : Float64? = nil, engine : String = default_engine, &block : Completion -> _)
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
      }.compact

      event_source = EventSource.new("https://api.openai.com/v1/engines/#{engine}/completions", base_headers: headers, body: body.to_json)

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

    def search(documents : Array(String), query : String, engine : String = default_engine)
      body = {
        "documents" => documents,
        "query"     => query,
      }.compact
      response = client.post("/v1/engines/#{engine}/search", headers: headers, body: body.to_json)
      @last_response = LastResponse.new(response)
      json = JSON.parse(response.body)
      case response.status
      when HTTP::Status::OK
        results = Array(SearchResult).from_json(json["data"].to_json)
        results.each.with_index do |result, index|
          result.text = documents[index]
        end
        results
      else
        raise Error.new(json["error"]["message"].to_s)
      end
    end

    private def client
      @client ||= HTTP::Client.new(URI.parse("https://api.openai.com"))
    end

    private def headers
      @headers ||= HTTP::Headers{
        "Authorization" => "Bearer #{api_key}",
        "Content-Type"  => "application/json",
      }
    end
  end
end
