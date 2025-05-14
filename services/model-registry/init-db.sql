-- Initialize model registry database schema

-- Create schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS model_registry;

-- Create models table if it doesn't exist
CREATE TABLE IF NOT EXISTS model_registry.models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    provider VARCHAR(50) NOT NULL,
    model_type VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255),
    description TEXT,
    parameters JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name, provider)
);

-- Add some default models
INSERT INTO model_registry.models (name, display_name, provider, model_type, endpoint, description, parameters)
VALUES
('gpt-3.5-turbo', 'GPT-3.5 Turbo', 'openai', 'chat', 'https://api.openai.com/v1/chat/completions', 'GPT-3.5 Turbo for general-purpose chat', '{"temperature": 0.7, "max_tokens": 2048}')
ON CONFLICT (name, provider) DO NOTHING;

INSERT INTO model_registry.models (name, display_name, provider, model_type, endpoint, description, parameters)
VALUES
('claude-3-sonnet', 'Claude 3 Sonnet', 'anthropic', 'chat', 'https://api.anthropic.com/v1/messages', 'Claude 3 Sonnet model', '{"temperature": 0.7, "max_tokens": 4096}')
ON CONFLICT (name, provider) DO NOTHING;

INSERT INTO model_registry.models (name, display_name, provider, model_type, endpoint, description, parameters)
VALUES
('llama2', 'Llama 2', 'ollama', 'chat', 'http://llm-service:11434/api/chat', 'Llama 2 for local inference', '{"temperature": 0.7, "max_tokens": 2048}')
ON CONFLICT (name, provider) DO NOTHING;