require "ruby_llm"
# require "colorize"

RubyLLM.configure do |config|
  # config.openai_api_key = Rails.application.credentials[:openai_api_key]
  config.anthropic_api_key = Rails.application.credentials[:anthropic_api_key]
  config.default_model = "claude-sonnet-4" # optional, makes Claude the default
end

def white(char)     = "\e[97m#{char}\e[0m"
def blue(char)      = "\e[94m#{char}\e[0m"
def deep_blue(char) = "\e[34m#{char}\e[0m"
def bright_green(char) = "\e[92m#{char}\e[0m"
def bright_orange(char) = "\e[38;2;255;165;0m#{char}\e[0m"

def type_out(text, delay: 0.003)
  text.each_char do |char|
    print bright_orange(char)
    sleep(delay)
  end
end

chat = RubyLLM.chat

loop do
  print "=> "
  prompt = gets.chomp

  response = chat.ask prompt do |chunk|
    # The block receives RubyLLM::Chunk objects as they arrive
    # print chunk.content # Print content fragment immediately
    type_out(chunk.content) if chunk.content
  end
end

def cost
  input_tokens = response.input_tokens   # Tokens in the prompt sent TO the model
  output_tokens = response.output_tokens # Tokens in the response FROM the model
  cached_tokens = response.cached_tokens # Tokens served from the provider's prompt cache (if supported) - v1.9.0+
  cache_creation_tokens = response.cache_creation_tokens # Tokens written to the cache (Anthropic/Bedrock) - v1.9.0+

  # Estimate cost for this turn
  model_info = RubyLLM.models.find(response.model_id)
  if model_info.input_price_per_million && model_info.output_price_per_million
    input_cost = input_tokens * model_info.input_price_per_million / 1_000_000
    output_cost = output_tokens * model_info.output_price_per_million / 1_000_000
    turn_cost = input_cost + output_cost
    puts "Estimated Cost for this turn: $#{format('%.6f', turn_cost)}"
  else
    puts "Pricing information not available for #{model_info.id}"
  end
end
