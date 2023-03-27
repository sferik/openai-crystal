module OpenAI
  record Model, id : String, owned_by : String, root : String do
  include JSON::Serializable
  end
end
