# Alfred Agent Platform Repository Structure

This document explains the repository structure and how the different components of the Alfred Agent Platform are organized.

## Main Repository

The `alfred-agent-platform` repository serves as the main repository that ties together all components of the Alfred Agent Platform. It uses Git submodules and symbolic links to reference the various components.

### Components

1. **alfred-agent-platform-v2** (submodule)
   - Main implementation of the Alfred Agent Platform
   - Contains all core services, libraries, and agents
   - GitHub Repository: https://github.com/locotoki/alfred-agent-platform-v2.git

2. **alfred-docs-repo** (submodule)
   - Documentation repository for the project
   - Contains all documentation, guides, and reference materials
   - GitHub Repository: https://github.com/locotoki/alfred-docs-repo.git

3. **alfred-agent-orchestrator** (submodule)
   - Agent Orchestrator UI service
   - User interface for managing agent workflows and mission control
   - GitHub Repository: https://github.com/locotoki/alfred-agent-orchestrator.git

## Working with the Repository

### Cloning

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/locotoki/alfred-agent-platform.git
```

### Updating

```bash
# Pull changes
git pull

# Update submodules
git submodule update --remote
```

### Making Changes

When making changes to a submodule:

1. Change directory to the submodule
2. Make your changes
3. Commit and push from within the submodule
4. Return to the main repository
5. Commit the updated submodule reference
6. Push from the main repository

Example:

```bash
# Make changes in a submodule
cd alfred-docs-repo
git add .
git commit -m "Update documentation"
git push

# Update parent repository
cd ..
git add alfred-docs-repo
git commit -m "Update alfred-docs-repo submodule"
git push
```

## Local Development Setup

For local development, the components are set up as follows:

1. **alfred-agent-platform-v2** - Main project with core services
   - Managed via Git locally
   - Contains all core containers and services

2. **alfred-docs-repo** - Documentation
   - Connected to GitHub via submodule
   - Contains all project documentation

3. **alfred-agent-orchestrator** - Agent Orchestrator UI
   - Connected to GitHub via submodule
   - UI for agent workflows and mission control

## CI/CD Integration

When CI/CD is configured, it should:

1. Clone the main repository with all submodules
2. Build and test each component
3. Deploy the components as necessary

## Future Improvements

1. Implement a unified build and deployment process via the main repository
2. Add CI/CD workflows that respect the submodule structure