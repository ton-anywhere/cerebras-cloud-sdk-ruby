# Cerebras Ruby SDK

> [!WARNING]
> **Early / Alpha release (v0.1)** — built for a hackathon project.  
> Not intended for production use. API and interfaces may change.

Ruby client for the [Cerebras AI](https://cerebras.ai) inference API.

## Installation

```ruby
gem 'cerebras', '~> 0.1.0'
```

Or add to your `Gemfile`:

```ruby
gem 'cerebras'
```

## Quick Start

```ruby
require 'cerebras'

client = Cerebras::Client.new(api_key: ENV['CEREBRAS_API_KEY'])

response = client.chat(
  model: 'llama3.1-8b',
  messages: [{ role: 'user', content: 'Hello!' }]
)

puts response
```

## Status

- Version: `0.1.0` (early development)
- Part of a hackathon submission
- Core features: chat, completions, retry logic, SSE streaming support

## License

MIT
