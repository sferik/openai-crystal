module OpenAI
  class SearchResult
    include JSON::Serializable
    property document : Int32
    property score : Float64
    property text : String?
  end
end
