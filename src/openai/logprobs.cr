module OpenAI
  record Logprobs, tokens : Array(String), token_logprobs : Array(Float64), top_logprobs : Array(Hash(String, Float64)), text_offset : Array(Int32) do
    include JSON::Serializable
  end
end
