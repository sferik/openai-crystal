module OpenAI
  record Completion, choices : Array(Choice), created : Int32, id : String, model : String do
    include JSON::Serializable

    def created_at
      Time.unix(created)
    end
  end
end
