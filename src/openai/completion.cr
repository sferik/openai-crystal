module OpenAI
  class Completion
    include JSON::Serializable
    property choices : Array(Choice)
    @[JSON::Field(converter: Time::EpochConverter)]
    property created : Time
    property id : String
    property model : String
  end
end
