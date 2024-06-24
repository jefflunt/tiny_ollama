require 'net/http'
require 'json'

# tiny HTTP client for the non-streaming POST /api/generate endpoint for ollama
class TinyOllamaCompletion
  def initialize(model:, host: 'localhost', port: 11434)
    @model = model
    @host = host
    @port = port
  end

  def prompt(user_prompt)
    uri = URI("http://#{@host}:#{@port}/api/generate")
    
    request_body = {
      model: @model,
      prompt: user_prompt,
      stream: false
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
