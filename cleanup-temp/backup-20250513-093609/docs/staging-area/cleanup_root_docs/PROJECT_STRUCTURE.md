# Alfred Agent Platform v2 - Project Structure

This document outlines the cleaned and organized project structure after the comprehensive cleanup performed on May 12, 2025.

## Directory Structure

```
alfred-agent-platform-v2/
├── agents/                    # Agent module definitions
├── backup/                    # Backup and archive storage
│   ├── archives/              # Archived files and directories
│   │   ├── cleanup-20250512/  # Archived cleanup files
│   │   ├── dev-20250512/      # Archived development files
│   │   └── storage-20250512/  # Archived storage service files
│   └── configs/               # Configuration backups
├── config/                    # Configuration files
│   ├── env/                   # Environment configuration files
│   ├── postgres/              # PostgreSQL configuration
│   └── project/               # Project configuration files
├── docker-compose/            # Environment-specific Docker Compose files
│   ├── docker-compose.dev.yml # Development environment config
│   └── docker-compose.prod.yml # Production environment config
├── docs/                      # Documentation
│   └── staging-area/          # Documentation staging area
│       └── cleanup_root_docs/ # Consolidated documentation from root
├── libs/                      # Shared libraries
├── logs/                      # Log files
├── migrations/                # Database migrations
├── monitoring/                # Monitoring configuration
│   ├── grafana/               # Grafana dashboards
│   └── prometheus/            # Prometheus configuration
├── scripts/                   # Utility and management scripts
│   ├── db/                    # Database scripts and SQL files
│   ├── setup/                 # Setup and initialization scripts
│   ├── tests/                 # Test scripts
│   ├── utils/                 # Utility scripts
│   │   └── llm/               # LLM-specific utilities
│   ├── web/                   # Web-related files
│   └── youtube/               # YouTube-related scripts
├── services/                  # Service implementations
│   ├── alfred-bot/            # Alfred bot service
│   ├── alfred-core/           # Core agent service
│   ├── financial-tax/         # Financial tax agent
│   ├── legal-compliance/      # Legal compliance agent
│   ├── social-intel/          # Social intelligence agent
│   └── ...                    # Other services
├── tests/                     # Test scripts and tools
│   └── integration/           # Integration tests
├── docker-compose-clean.yml   # Unified Docker Compose configuration
├── docker-compose-optimized.yml # Optimized Docker Compose configuration
├── start-platform.sh          # Platform management script
├── check-env-vars.sh          # Environment variable validation
├── verify-platform.sh         # Platform verification tool
├── .env                       # Environment variables
├── .env.example               # Example environment variables
├── README.md                  # Main project documentation
├── CONTRIBUTING.md            # Contribution guidelines
├── SECURITY.md                # Security policies
├── LICENSE                    # License information
└── CLAUDE.md                  # Claude AI assistant instructions
```

## Root Directory

The root directory has been cleaned to contain only essential files:

1. **Core Git Files**:
   - .gitattributes
   - .gitignore
   - .dockerignore

2. **Core Environment**:
   - .env
   - .env.example

3. **Core Documentation**:
   - README.md
   - CONTRIBUTING.md
   - SECURITY.md
   - LICENSE
   - CLAUDE.md

4. **Core Docker Files**:
   - docker-compose-clean.yml
   - docker-compose-optimized.yml

5. **Core Scripts**:
   - start-platform.sh
   - check-env-vars.sh
   - verify-platform.sh

## Organizing Additional Files

All other files have been organized into appropriate directories:

1. **Documentation**: Over 90 markdown documentation files moved to `docs/staging-area/cleanup_root_docs/`

2. **Configuration Files**: Environment files, project configuration files moved to `config/` directory

3. **Utility Scripts**: All scripts moved to appropriate subdirectories in `scripts/`

4. **Backup Files**: All backup and archive files consolidated in `backup/archives/`

## Backup Structure

The backup system is now organized as follows:

```
backup/
├── archives/                  # Archives of various file types
│   ├── cleanup-20250512/      # Archived cleanup files
│   │   ├── backup_20250511_164713.tar.gz
│   │   ├── cleanup_backup_20250512.tar.gz
│   │   ├── cleanup_backup_20250512_final.tar.gz
│   │   └── cleanup_backup_20250512_part2.tar.gz
│   ├── dev-20250512/          # Archived development files
│   │   ├── agents_stubs.tar.gz
│   │   ├── helpers.tar.gz
│   │   ├── refactor-plan.tar.gz
│   │   ├── refactor-unified.tar.gz
│   │   ├── ui-redesign.tar.gz
│   │   └── youtube-test-env.tar.gz
│   └── storage-20250512/      # Archived storage service files
│       ├── custom-storage-service.tar.gz
│       ├── storage-proxy-simple.tar.gz
│       └── storage-proxy.tar.gz
└── configs/                   # Configuration backups
    └── container-configs-20250512/
        ├── container-config-backup-20250512103503.tar.gz
        ├── container-config-backup-20250512103547.tar.gz
        ├── container-config-backup-20250512104028.tar.gz
        └── container-config-backup-20250512104221.tar.gz
```

## Benefits of the New Structure

1. **Cleaner Root Directory**: Reduced from 140+ files to just 15 essential files
2. **Logical Organization**: Related files grouped together
3. **Better Maintainability**: Easier to find and update specific files
4. **Improved Navigation**: Clear directory structure with logical naming
5. **Documentation Consolidation**: All documentation in a central location
6. **Effective Backup System**: Archives organized by purpose and date
7. **Space Efficiency**: Compressed archives reduce storage requirements

## Usage Guidelines

When working with the project:

1. **Documentation**: Refer to files in `docs/staging-area/cleanup_root_docs/`
2. **Development**: Use the appropriate scripts in the `scripts/` directory
3. **Configuration**: Update environment variables in `.env` and other config files in `config/`
4. **Testing**: Run tests from the `tests/` directory
5. **Services**: Work with service implementations in the `services/` directory

## Restoration

If you need to restore any archived files:

```bash
# Extract an archive to a temporary directory
tar -xzf backup/archives/dev-20250512/refactor-unified.tar.gz -C /tmp/

# Copy specific files as needed
cp /tmp/refactor-unified/specific-file.txt destination/
```