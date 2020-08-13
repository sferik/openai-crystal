module OpenAI
  class Logprobs
    include JSON::Serializable
    property tokens : Array(String)
    property token_logprobs : Array(Float64)
    property top_logprobs : Array(Hash(String, Float64))
    property text_offset : Array(Int32)
  end
end
