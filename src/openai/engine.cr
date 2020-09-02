module OpenAI
  record Engine, id : String, owner : String, ready : Bool do
    include JSON::Serializable
  end
end
