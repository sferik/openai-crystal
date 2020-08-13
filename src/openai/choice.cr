module OpenAI
  class Choice
    include JSON::Serializable
    property finish_reason : String?
    property index : Int32
    property logprobs : Logprobs?
    property text : String
  end
end
