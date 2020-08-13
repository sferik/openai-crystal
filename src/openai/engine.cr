module OpenAI
  class Engine
    include JSON::Serializable
    property id : String
    property owner : String
    property ready : Bool
  end
end
