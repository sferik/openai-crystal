require "../src/openai"
require "spec"
require "webmock"

def with_client
  client = OpenAI::Client.new(api_key: mock_api_key)
  yield client
end

def mock_api_key
  "sk-f00"
end

def request_headers
  HTTP::Headers{
    "Authorization" => "Bearer #{mock_api_key}",
    "Content-Type"  => "application/json",
  }
end

def response_headers
  HTTP::Headers{
    "Access-Control-Allow-Origin" => "*",
    "Connection"                  => "keep-alive",
    "Content-Length"              => "145",
    "Content-Type"                => "application/json",
    "Date"                        => "Wed, 12 Aug 2020 18:05:26 GMT",
    "OpenAI-Organization"         => "none",
    "OpenAI-Processing-Ms"        => "318",
    "Server"                      => "nginx/1.17.10",
    "Strict-Transport-Security"   => "max-age=15724800; includeSubDomains",
    "X-Request-ID"                => "b74777d5149fd1f641346933bf7b774c",
  }
end
