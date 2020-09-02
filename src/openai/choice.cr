module OpenAI
  record Choice, finish_reason : String?, index : Int32, logprobs : Logprobs?, text : String do
    include JSON::Serializable
  end
end
