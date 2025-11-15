RubyLLM.configure do |config|
  config.openai_api_key = Rails.application.credentials[:openai_api_key]
  config.anthropic_api_key = Rails.application.credentials[:anthropic_api_key]
  config.default_embedding_model = "text-embedding-3-small"
  config.default_model = "claude-sonnet-4" # optional, makes Claude the default
end
