require 'net/http'
require 'json'

# tiny HTTP client for the /api/generate and /api/chat endpoints of ollama
# see also: https://ollama.com/
class TinyOllama
  # a good rule of thumb would be to have a .tiny_ollama.yml config in your
  # project, to parse that as YAML, and pass the parsed reulst into here.
  def initialize(
    model:,
    format: nil,
    host: 'localhost',
    port: 11434,
    context_size: 2048,
    keep_alive: -1,
    stream: false
  )

    @model = model
    @host = host
    @port = port
    @context_size = context_size
    @keep_alive = keep_alive
    @stream = stream
    @format = format
  end

  # sends a request to POST /api/generate
  def generate(prompt)
    request_body = {
      model: @model,
      prompt: prompt,
      stream: @stream,
      keep_alive: @keep_alive,
      options: {
        num_ctx: @context_size,
      }.merge(@format ? { format: @format } : {})
    }.to_json

    uri = URI("http://#{@host}:#{@port}/api/generate")
    headers = { 'Content-Type' => 'application/json' }
    response = Net::HTTP.post(uri, request_body, headers)

    # Handle potential errors (e.g., non-200 responses)
    unless response.is_a?(Net::HTTPSuccess)
      raise TinyOllamaModelError.new("Ollama API Error: #{response.code} - #{response.body}")
    end

    JSON.parse(response.body)['response']
  end

  # sends a request to POST /api/chat
  #
  # messages: an array of hashes in the following format:
  # [
  #   {
  #     "role": "system",
  #     "content": <optional message to override model instructions>,
  #   },
  #   {
  #     "role": "user",
  #     "content": <the first user message>,
  #   },
  #   {
  #     "role": "assistant",
  #     "content": <the LLM's first response>,
  #   },
  #   {
  #     "role": "user",
  #     "content": <the next user message>,
  #   },
  # ]
  #
  # NOTE: the messages parameter needs to include a system message if you want
  # to override the model's default instructions
  def chat(messages)
    request_body = {
      model: @model,
      messages: messages,
      stream: @stream,
      format: @format,
      keep_alive: @keep_alive,
      options: {
        num_ctx: @context_size,
      }
    }.to_json

    uri = URI("http://#{@host}:#{@port}/api/chat")
    headers = { 'Content-Type' => 'application/json' }
    response = Net::HTTP.post(uri, request_body, headers)

    # Handle potential errors (e.g., non-200 responses)
    unless response.is_a?(Net::HTTPSuccess)
      raise TinyOllamaModelError.new("Ollama API Error: #{response.code} - #{response.body}")
    end

    JSON.parse(response.body)['message']['content']
  end
end

class TinyOllamaModelError; end
