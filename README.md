# Alfred Agent Platform

This is the main repository for the Alfred Agent Platform project. It contains the following components:

## Project Structure

- `alfred-agent-platform-v2`: Main implementation of the Alfred Agent Platform (submodule)
- `alfred-docs-repo`: Documentation repository for the project (submodule)
- `alfred-agent-orchestrator`: Agent Orchestrator UI (submodule)
- `alfred-mission-control`: Mission Control UI (symlink to local repository)

## Quick Start

Clone the repository with submodules:

```bash
git clone --recurse-submodules https://github.com/locotoki/alfred-agent-platform.git
```

If you already cloned without submodules:

```bash
git submodule init
git submodule update
```

To pull latest changes for everything:

```bash
git pull
git submodule update --remote
```

## Working with Submodules

When making changes to submodules:

1. Change to the submodule directory
2. Make your changes
3. Commit and push from within the submodule
4. Return to parent repo
5. Commit the updated submodule reference
6. Push from the parent repo

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

## Documentation

For detailed documentation, please see the [Documentation Repository](https://github.com/locotoki/alfred-docs-repo).