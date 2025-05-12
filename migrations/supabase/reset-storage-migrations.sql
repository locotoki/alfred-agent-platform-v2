-- Delete existing migrations
DELETE FROM storage.migrations;

-- Mark all current migrations as completed with fake hashes
INSERT INTO storage.migrations (id, name, hash) VALUES
(0, '0_create-migrations-table.sql', '5f200a7d9df9cf47384789b041638a44c6c2cdb5'),
(1, '0001-initialmigration.sql', '5f200a7d9df9cf47384789b041638a44c6c2cdb5'),
(2, 'pathtoken-column', 'a7ef485ce4a9b4e6034bc4459a30a85f0c2401ed'),
(3, 'add-migrations-table', 'cdb051d37bf23bcc12f6b7e6636fbae6cd160a10'),
(4, 'create-webhooks-table', 'fe7ec31db84473ba5ab4f7a8d3d0e4c04633ec81');