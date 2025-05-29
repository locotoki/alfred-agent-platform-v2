# WSL Backup Guide

This document outlines the process for backing up your WSL (Windows Subsystem for Linux) environment, specifically focusing on the Alfred Agent Platform v2 project.

## Option 1: Export WSL Distribution (From Windows)

The most reliable method is to export your entire WSL distribution to a file. This creates a complete backup that can be imported later if needed.

1. Open PowerShell or Command Prompt as Administrator in Windows
2. Run the following command to see your WSL distributions:
   ```powershell
   wsl --list --verbose
   ```
3. Export your distribution (replace `Ubuntu` with your distribution name if different):
   ```powershell
   wsl --export Ubuntu C:\backups\ubuntu-backup.tar
   ```
4. This creates a `.tar` file containing your entire WSL environment that can be imported later if needed:
   ```powershell
   wsl --import Ubuntu-restored C:\WSL\Ubuntu-restored C:\backups\ubuntu-backup.tar
   ```

## Option 2: Backup Specific Project Files (From Inside WSL)

If you only need to backup your Alfred Agent Platform v2 project:

1. Create a backup directory in a location accessible from Windows:
   ```bash
   mkdir -p /mnt/c/backups/alfred-platform
   ```

2. Create a tarball of the project:
   ```bash
   tar -czvf /mnt/c/backups/alfred-platform/alfred-platform-backup-$(date +%Y%m%d).tar.gz -C /home/locotoki/projects alfred-agent-platform-v2
   ```

3. Backup Docker volumes (if needed):
   ```bash
   # First, list all volumes used by the project
   docker volume ls | grep alfred

   # Export important volumes (example for supabase-db-data)
   docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/c/backups/alfred-platform:/backup alpine tar -czvf /backup/supabase-db-data-$(date +%Y%m%d).tar.gz -C /data .

   # Repeat for other important volumes
   ```

## Option 3: Docker Compose Project Backup

For a more targeted backup of just the Docker-related elements:

1. Create backup directories:
   ```bash
   mkdir -p /mnt/c/backups/alfred-platform/docker-config
   ```

2. Copy Docker configuration files:
   ```bash
   cp /home/locotoki/projects/alfred-agent-platform-v2/docker-compose.yml /mnt/c/backups/alfred-platform/docker-config/
   cp /home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.*.yml /mnt/c/backups/alfred-platform/docker-config/
   cp /home/locotoki/projects/alfred-agent-platform-v2/.env* /mnt/c/backups/alfred-platform/docker-config/
   ```

3. Export Docker volumes (most critical for database persistence):
   ```bash
   docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/c/backups/alfred-platform/volumes:/backup alpine tar -czvf /backup/supabase-db-data-$(date +%Y%m%d).tar.gz -C /data .
   ```

## Backup the Database Only

If you only need to backup the database:

```bash
# Create a directory for the backup
mkdir -p /mnt/c/backups/alfred-platform/database

# Get the database container ID
DB_CONTAINER=$(docker ps -qf "name=supabase-db")

# Export the database
docker exec $DB_CONTAINER pg_dump -U postgres postgres > /mnt/c/backups/alfred-platform/database/alfred-db-backup-$(date +%Y%m%d).sql
```

## Backup Verification

To verify your backup:

1. For the database backup, check the SQL file size:
   ```bash
   ls -lh /mnt/c/backups/alfred-platform/database/
   ```
   If it's only a few bytes, the backup likely failed.

2. For project files, check the tarball:
   ```bash
   tar -tvf /mnt/c/backups/alfred-platform/alfred-platform-backup-*.tar.gz | head
   ```
   This should show the files included in the backup.

## Restoration Process

### Restore WSL Distribution (Option 1)
From Windows PowerShell/Command Prompt as Administrator:
```powershell
wsl --import Ubuntu-restored C:\WSL\Ubuntu-restored C:\backups\ubuntu-backup.tar
```

### Restore Project Files (Option 2)
```bash
# Create target directory if needed
mkdir -p /home/locotoki/projects/

# Extract the backup
tar -xzvf /mnt/c/backups/alfred-platform/alfred-platform-backup-YYYYMMDD.tar.gz -C /home/locotoki/projects/
```

### Restore Docker Volumes (Option 3)
```bash
# Stop containers
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose down

# Remove existing volume
docker volume rm alfred-agent-platform-v2_supabase-db-data

# Create empty volume
docker volume create alfred-agent-platform-v2_supabase-db-data

# Restore from backup
docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/c/backups/alfred-platform/volumes:/backup alpine sh -c "cd /data && tar -xzvf /backup/supabase-db-data-YYYYMMDD.tar.gz"

# Start containers again
docker-compose up -d
```

## Important Notes

1. Windows paths in WSL are accessed through `/mnt/c/` (for the C: drive)
2. Always verify your backups after creating them
3. Consider automating this process with a scheduled script for regular backups
4. Store backups in multiple locations (local and cloud) for redundancy
5. Remember to backup your Docker volumes - they contain persistent data like databases
6. Consider database-specific backup tools for proper database backup/restoration
7. If using the WSL export method, be aware that it requires Administrator privileges on Windows

## Regular Backup Schedule Recommendation

For a project like Alfred Agent Platform v2:

1. Daily: Database backups (SQL dumps)
2. Weekly: Full project code and volume backups
3. Monthly: Complete WSL distribution export

---

*This document was created on May 6, 2025 for the Alfred Agent Platform v2 project.*
