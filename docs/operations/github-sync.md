# GitHub Sync Guide

This document outlines best practices for keeping your local repository in sync with GitHub and preventing unintended file transfers or merge issues.

## Key Tools

1. **Enhanced `.gitignore`**:  
   We've updated the `.gitignore` file to exclude temporary files, backups, and other non-essential files from git tracking.

2. **Pre-commit Hook**:  
   A custom pre-commit hook has been installed in `.git/hooks/pre-commit` that prevents:
   - Accidental commits of large files (>5MB)
   - Temporary files and backup files
   - Non-essential files in the root directory

3. **Safe Sync Script**:  
   We've created a script at `scripts/safe-sync.sh` for safely synchronizing with GitHub. This script:
   - Checks for uncommitted changes
   - Handles the push/pull process safely
   - Provides options for viewing changes before committing
   - Cleans up untracked files (optional)

## Best Practices

1. **Always Run Safe Sync**: Use `./scripts/safe-sync.sh` instead of regular git commands when syncing.

2. **Clean Root Directory**: Keep the root directory clean, with only essential files:
   - README.md, CLAUDE.md, SECURITY.md, CONTRIBUTING.md, LICENSE
   - Configuration files (.env.example, Makefile, etc.)
   - Docker Compose files
   - Key startup scripts

3. **Regular Cleaning**: Periodically run `git clean -fxdn` to see what untracked files exist (add `-f` to remove them).

4. **Branch Management**:
   - Use feature branches for new work
   - Keep the main branch clean and stable
   - Regularly merge from main into feature branches to prevent divergence

5. **Handle Merge Conflicts Carefully**:
   - When resolving conflicts, don't blindly accept changes
   - Check which files are being modified in merge operations
   - Consider using a visual diff tool (`git difftool`)

## Preventing Unintended Files in Git

1. **Check Status Before Committing**:  
   Always run `git status` before committing to see what files will be included.

2. **Review Diffs**:  
   Use `git diff --cached` to review changes before committing.

3. **Use Explicit Adds**:  
   Avoid using `git add .` which adds everything. Instead, add files explicitly:
   ```bash
   git add specific-file.py specific-directory/
   ```

4. **Clean Up After Merges**:  
   After resolving merge conflicts, check for any unexpected files that may have been pulled in.

5. **Git Attributes**:  
   Consider using `.gitattributes` to control how certain file types are handled.

## Recovering from Mistakes

If unintended files appear in your repository:

1. **Revert to Previous State**:  
   ```bash
   git reset --hard HEAD~1  # Go back one commit
   ```

2. **Remove Specific Files**:  
   ```bash
   git rm --cached unwanted-file.txt
   ```

3. **Clean Up Repository**:  
   ```bash
   ./scripts/safe-sync.sh  # Use the safe sync script
   ```

## Handling Large Files

For large files that need version tracking:

1. **Consider Git LFS**:  
   Set up Git Large File Storage for binary files, ML models, etc.

2. **Documentation Strategies**:  
   For very large files, consider documenting download links instead of storing them in Git.

---

By following these guidelines, you can maintain a clean, efficient repository and prevent unintended files from being pulled again.