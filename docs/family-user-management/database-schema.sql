-- Family User Management System - Database Schema
-- This file contains the SQL schema for the family user management system
-- Created: May 11, 2025
-- Author: Alfred Development Team

-- Create schema for family management if it doesn't exist
CREATE SCHEMA IF NOT EXISTS family;

-- Family group table
CREATE TABLE family.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Family membership with roles
CREATE TABLE family.members (
  user_id UUID REFERENCES auth.users(id),
  family_id UUID REFERENCES family.groups(id),
  role TEXT NOT NULL CHECK (role IN ('admin', 'parent', 'child', 'teen', 'guest')),
  display_name TEXT,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  invited_by UUID REFERENCES auth.users(id),
  restrictions JSONB DEFAULT '{}'::jsonb, -- parental controls config
  PRIMARY KEY (user_id, family_id)
);

-- Shared resources table
CREATE TABLE family.shared_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES family.groups(id),
  resource_type TEXT NOT NULL, -- 'document', 'conversation', 'knowledge_base', etc.
  resource_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  permissions JSONB NOT NULL DEFAULT '{}'::jsonb -- who can view/edit/delete
);

-- User preferences table
CREATE TABLE family.user_preferences (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  interface_preferences JSONB DEFAULT '{
    "theme": "light",
    "fontSize": "medium",
    "notifications": true
  }'::jsonb,
  agent_preferences JSONB DEFAULT '{
    "responseStyle": "balanced",
    "contentLevel": "general"
  }'::jsonb,
  notification_settings JSONB DEFAULT '{
    "email": true,
    "push": true,
    "familyUpdates": true
  }'::jsonb,
  privacy_settings JSONB DEFAULT '{
    "shareHistory": false,
    "allowActivityTracking": true
  }'::jsonb,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Restriction templates for easy application to child accounts
CREATE TABLE family.restriction_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  age_group TEXT NOT NULL, -- 'child', 'teen', etc.
  restrictions JSONB NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Family invitations
CREATE TABLE family.invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES family.groups(id),
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'parent', 'child', 'teen', 'guest')),
  invited_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  token TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired'))
);

-- Family activity log
CREATE TABLE family.activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES family.groups(id),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL, -- 'login', 'content_access', 'settings_change', etc.
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Views

-- View for family admins to see family members
CREATE OR REPLACE VIEW family.family_member_details AS
SELECT 
  fm.family_id,
  fg.name AS family_name,
  fm.user_id,
  u.email,
  fm.display_name,
  fm.role,
  fm.joined_at,
  fm.invited_by,
  iu.email AS invited_by_email
FROM 
  family.members fm
JOIN 
  family.groups fg ON fm.family_id = fg.id
JOIN 
  auth.users u ON fm.user_id = u.id
LEFT JOIN
  auth.users iu ON fm.invited_by = iu.id;

-- View for active sharing within families
CREATE OR REPLACE VIEW family.active_sharing AS
SELECT 
  sr.id,
  sr.family_id,
  fg.name AS family_name,
  sr.resource_type,
  sr.resource_id,
  sr.name,
  sr.description,
  sr.created_by,
  u.email AS created_by_email,
  sr.created_at,
  sr.updated_at
FROM 
  family.shared_resources sr
JOIN 
  family.groups fg ON sr.family_id = fg.id
JOIN 
  auth.users u ON sr.created_by = u.id;

-- Functions

-- Function to check if a user is a member of a family
CREATE OR REPLACE FUNCTION family.is_family_member(p_user_id UUID, p_family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM family.members
    WHERE user_id = p_user_id AND family_id = p_family_id
  );
END;
$$ LANGUAGE plpgsql;

-- Function to check if a user has a specific role in a family
CREATE OR REPLACE FUNCTION family.has_family_role(p_user_id UUID, p_family_id UUID, p_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM family.members
    WHERE user_id = p_user_id 
    AND family_id = p_family_id
    AND role = p_role
  );
END;
$$ LANGUAGE plpgsql;

-- Function to create an invitation
CREATE OR REPLACE FUNCTION family.create_invitation(
  p_family_id UUID,
  p_email TEXT,
  p_role TEXT,
  p_invited_by UUID
)
RETURNS UUID AS $$
DECLARE
  v_invitation_id UUID;
  v_token TEXT;
BEGIN
  -- Generate a unique token
  v_token := encode(gen_random_bytes(32), 'hex');
  
  -- Create the invitation
  INSERT INTO family.invitations (
    family_id, email, role, invited_by, token
  ) VALUES (
    p_family_id, p_email, p_role, p_invited_by, v_token
  ) RETURNING id INTO v_invitation_id;
  
  RETURN v_invitation_id;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security

-- Enable RLS on all tables
ALTER TABLE family.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.shared_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.restriction_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.activity_log ENABLE ROW LEVEL SECURITY;

-- Family groups: admins can see all, users can only see their own families
CREATE POLICY groups_select_policy ON family.groups
    FOR SELECT USING (
      EXISTS (
        SELECT 1 FROM family.members 
        WHERE user_id = auth.uid() AND family_id = family.groups.id
      )
    );

-- Family members can only be viewed by members of the same family
CREATE POLICY members_select_policy ON family.members
    FOR SELECT USING (
      family_id IN (
        SELECT family_id FROM family.members WHERE user_id = auth.uid()
      )
    );

-- Only family admins and parents can modify user restrictions
CREATE POLICY restrictions_update_policy ON family.members
    FOR UPDATE USING (
      EXISTS (
        SELECT 1 FROM family.members 
        WHERE user_id = auth.uid() 
        AND family_id = family.members.family_id
        AND role IN ('admin', 'parent')
      )
    );

-- Users can only access their own preferences
CREATE POLICY preferences_access_policy ON family.user_preferences
    FOR ALL USING (user_id = auth.uid());

-- Activity logs can only be viewed by family admins and parents
CREATE POLICY activity_log_select_policy ON family.activity_log
    FOR SELECT USING (
      EXISTS (
        SELECT 1 FROM family.members 
        WHERE user_id = auth.uid() 
        AND family_id = family.activity_log.family_id
        AND role IN ('admin', 'parent')
      )
    );

-- Invitations can be managed by family admins
CREATE POLICY invitations_manage_policy ON family.invitations
    FOR ALL USING (
      EXISTS (
        SELECT 1 FROM family.members 
        WHERE user_id = auth.uid() 
        AND family_id = family.invitations.family_id
        AND role = 'admin'
      )
    );

-- Indexes for performance

-- Indexes on members table
CREATE INDEX idx_members_user_id ON family.members(user_id);
CREATE INDEX idx_members_family_id ON family.members(family_id);
CREATE INDEX idx_members_role ON family.members(role);

-- Indexes on shared resources table
CREATE INDEX idx_shared_resources_family_id ON family.shared_resources(family_id);
CREATE INDEX idx_shared_resources_resource_type ON family.shared_resources(resource_type);
CREATE INDEX idx_shared_resources_created_by ON family.shared_resources(created_by);

-- Indexes on activity log
CREATE INDEX idx_activity_log_family_id ON family.activity_log(family_id);
CREATE INDEX idx_activity_log_user_id ON family.activity_log(user_id);
CREATE INDEX idx_activity_log_created_at ON family.activity_log(created_at);

-- Indexes on invitations
CREATE INDEX idx_invitations_family_id ON family.invitations(family_id);
CREATE INDEX idx_invitations_email ON family.invitations(email);
CREATE INDEX idx_invitations_status ON family.invitations(status);

-- Comments
COMMENT ON TABLE family.groups IS 'Family groups that users can belong to';
COMMENT ON TABLE family.members IS 'Family membership with roles and relationships';
COMMENT ON TABLE family.shared_resources IS 'Resources shared within a family group';
COMMENT ON TABLE family.user_preferences IS 'Individual user preferences for the platform';
COMMENT ON TABLE family.restriction_templates IS 'Predefined restriction templates for child accounts';
COMMENT ON TABLE family.invitations IS 'Invitations to join family groups';
COMMENT ON TABLE family.activity_log IS 'Activity tracking for family monitoring';