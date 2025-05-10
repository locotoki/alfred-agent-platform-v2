-- 101_youtube_workflows.sql
-- Description: Add YouTube workflows tables

-- Migration
CREATE TABLE IF NOT EXISTS public.workflows (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    workflow_id TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    parameters JSONB DEFAULT '{}',
    results JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workflows_type ON public.workflows(type);
CREATE INDEX IF NOT EXISTS idx_workflows_status ON public.workflows(status);

-- Add specific tables for YouTube workflows
CREATE TABLE IF NOT EXISTS public.youtube_niche_scout_results (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    workflow_id UUID REFERENCES public.workflows(id) ON DELETE CASCADE,
    run_date TIMESTAMPTZ DEFAULT NOW(),
    trending_niches JSONB DEFAULT '[]',
    top_niches JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.youtube_blueprint_results (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    workflow_id UUID REFERENCES public.workflows(id) ON DELETE CASCADE,
    run_date TIMESTAMPTZ DEFAULT NOW(),
    seed_url TEXT,
    seed_data JSONB DEFAULT '{}',
    top_channels JSONB DEFAULT '[]',
    gap_analysis JSONB DEFAULT '[]',
    blueprint JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}'
);

-- Rollback (commented out)
-- DROP TABLE IF EXISTS public.youtube_blueprint_results;
-- DROP TABLE IF EXISTS public.youtube_niche_scout_results;
-- DROP TABLE IF EXISTS public.workflows;
