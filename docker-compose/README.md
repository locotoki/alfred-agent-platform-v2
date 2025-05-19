# Docker Compose Configuration

This directory contains the Docker Compose configuration files for the Alfred Agent Platform.

## File Structure

- `docker-compose.yml` - Base configuration (in the project root)
- `docker-compose.dev.yml` - Development overrides (in the project root)
- `docker-compose.prod.yml` - Production optimizations (in the project root)
- `docker-compose.local.yml.template` - Template for personal developer settings

### Profiles Directory

The `profiles/` directory contains optional configuration profiles that can be used for specific scenarios:

- `docker-compose.mock.yml` - Mock services for testing without live dependencies
- `docker-compose.storage.yml` - Storage-specific configuration

## Usage

Continue using the files from the project root as normal. This directory is for specialized profiles and templates.

For detailed usage instructions, see the documentation:
- [Docker Compose Guide](../docs/operations/containerization/docker-compose-guide.md)
- [Docker Compose Health Checks](../docs/operations/containerization/docker-compose-health-checks.md)
- [Docker Compose History](../docs/operations/containerization/docker-compose-history.md)

## Configuration Tips

1. **Main and override files stay in the project root**
   - This maintains compatibility with existing scripts and documentation.

2. **Use profiles for conditional service groups**
   - This is cleaner than maintaining multiple override files.

3. **Personal settings go in docker-compose.local.yml**
   - Use the template as a starting point.
   - This file is gitignored to avoid conflicts.

4. **Loading order matters**
   - Files loaded later will override earlier ones.
   - The standard pattern is: `base → dev/prod → local`
