# OpenAI API client library to access GPT-3 in Crystal

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     openai:
       github: sferik/openai-crystal
   ```

2. Run `shards install`

## Usage

```crystal
require "openai"

openai_client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"), default_engine: "ada")

# List Engines
openai_client.engines

# Retrieve Engine
openai_client.engine("babbage")

# Search
openai_client.search(documents: ["White House", "hospital", "school"], query: "the president")

# Create Completion
openai_client.completions(prompt: "Once upon a time", max_tokens: 5)

# Stream Completion
openai_client.completions(prompt: "Once upon a time", max_tokens: 100) do |completion|
  puts completion.choices.first.text
end
```

## Contributing

1. Fork it (<https://github.com/sferik/openai-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Erik Berlin](https://github.com/sferik) - creator and maintainer
