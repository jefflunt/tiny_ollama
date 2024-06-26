require 'net/http'
require 'json'

# tiny HTTP client for the non-streaming POST /api/generate endpoint for ollama
class TinyOllamaCompletion
  def initialize(model:, host: 'localhost', port: 11434, context_size: 2048, keep_alive: -1)
    @model = model
    @host = host
    @port = port
    @context_size = context_size
    @keep_alive = keep_alive
  end

  def prompt(user_prompt)
    uri = URI("http://#{@host}:#{@port}/api/generate")
    
    request_body = {
      model: @model,
      prompt: user_prompt,
      stream: false,
      keep_alive: @keep_alive,
      options: {
        num_ctx: @context_size,
      },
    }.to_json

    headers = { 'Content-Type' => 'application/json' }

    response = Net::HTTP.post(uri, request_body, headers)

    # Handle potential errors (e.g., non-200 responses)
    unless response.is_a?(Net::HTTPSuccess)
      raise TinyOllamaCompletionModelError.new("Ollama API Error: #{response.code} - #{response.body}")
    end

    JSON.parse(response.body)['response']
  end
end

class TinyOllamaCompletionModelError; end
