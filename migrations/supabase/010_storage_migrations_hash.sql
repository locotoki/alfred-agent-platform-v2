-- Insert completed migrations with hash values
INSERT INTO storage.migrations (id, name, hash) VALUES
(1, 'add-public-to-buckets', 'placeholder-hash-1'),
(2, 'add-rls-to-buckets', 'placeholder-hash-2'),
(3, 'pathtoken-column', 'placeholder-hash-3')
ON CONFLICT (id) DO NOTHING;
