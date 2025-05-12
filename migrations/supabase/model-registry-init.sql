-- Create model_registry schema if not exists
CREATE SCHEMA IF NOT EXISTS model_registry;

-- Create models table
CREATE TABLE IF NOT EXISTS model_registry.models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    model_type VARCHAR(50) NOT NULL,
    version VARCHAR(50),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create model_endpoints table
CREATE TABLE IF NOT EXISTS model_registry.model_endpoints (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES model_registry.models(id) ON DELETE CASCADE,
    endpoint_type VARCHAR(50) NOT NULL,
    endpoint_url VARCHAR(255),
    auth_type VARCHAR(50),
    headers JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create model_capabilities table
CREATE TABLE IF NOT EXISTS model_registry.model_capabilities (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES model_registry.models(id) ON DELETE CASCADE,
    capability VARCHAR(50) NOT NULL,
    capability_score FLOAT NOT NULL,
    UNIQUE(model_id, capability)
);

-- Create model_parameters table
CREATE TABLE IF NOT EXISTS model_registry.model_parameters (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES model_registry.models(id) ON DELETE CASCADE,
    parameter_name VARCHAR(100) NOT NULL,
    default_value JSONB NOT NULL,
    min_value JSONB,
    max_value JSONB,
    description TEXT,
    UNIQUE(model_id, parameter_name)
);

-- Create model_performance table
CREATE TABLE IF NOT EXISTS model_registry.model_performance (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES model_registry.models(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    task_category VARCHAR(100),
    sample_size INTEGER
);

-- Create model_usage table
CREATE TABLE IF NOT EXISTS model_registry.model_usage (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES model_registry.models(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    token_count INTEGER,
    request_count INTEGER DEFAULT 1,
    average_latency FLOAT,
    error_count INTEGER DEFAULT 0,
    cost DECIMAL(10, 6)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_model_capabilities_model_id ON model_registry.model_capabilities(model_id);
CREATE INDEX IF NOT EXISTS idx_model_capabilities_capability ON model_registry.model_capabilities(capability);
CREATE INDEX IF NOT EXISTS idx_model_parameters_model_id ON model_registry.model_parameters(model_id);
CREATE INDEX IF NOT EXISTS idx_model_performance_model_id ON model_registry.model_performance(model_id);
CREATE INDEX IF NOT EXISTS idx_model_performance_metric ON model_registry.model_performance(metric_name);
CREATE INDEX IF NOT EXISTS idx_model_usage_model_id ON model_registry.model_usage(model_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_timestamp ON model_registry.model_usage(timestamp);

-- Insert some default models
INSERT INTO model_registry.models (name, display_name, provider, model_type, description) 
VALUES
  ('gpt4o', 'GPT-4o', 'openai', 'chat', 'OpenAI''s GPT-4o (multimodal) model'),
  ('gpt4', 'GPT-4 Turbo', 'openai', 'chat', 'OpenAI''s GPT-4 Turbo model'),
  ('gpt35', 'GPT-3.5 Turbo', 'openai', 'chat', 'OpenAI''s GPT-3.5 Turbo model'),
  ('claude3', 'Claude 3 Opus', 'anthropic', 'chat', 'Anthropic''s Claude 3 Opus model'),
  ('claude3-sonnet', 'Claude 3 Sonnet', 'anthropic', 'chat', 'Anthropic''s Claude 3 Sonnet model'),
  ('claude3-haiku', 'Claude 3 Haiku', 'anthropic', 'chat', 'Anthropic''s Claude 3 Haiku model'),
  ('tinyllama', 'TinyLlama', 'ollama', 'chat', 'Small local Llama model'),
  ('llama2', 'Llama 2', 'ollama', 'chat', 'Meta''s Llama 2 model'),
  ('llama3', 'Llama 3', 'ollama', 'chat', 'Meta''s Llama 3 (8B) model'),
  ('codellama', 'Code Llama', 'ollama', 'chat', 'Specialized for code generation'),
  ('llava', 'LLaVA', 'ollama', 'multimodal', 'Multimodal model supporting images')
ON CONFLICT (name) DO UPDATE 
SET 
  display_name = EXCLUDED.display_name,
  provider = EXCLUDED.provider,
  model_type = EXCLUDED.model_type,
  description = EXCLUDED.description,
  updated_at = NOW();