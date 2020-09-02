module OpenAI
  record SearchResult, document : Int32, score : Float64 do
    include JSON::Serializable
  end
end
