# WSL Backup Guide

This document outlines the process for backing up your WSL (Windows Subsystem for Linux) environment, specifically focusing on the Alfred Agent Platform v2 project.

## Preparation Steps (Do These From Windows)

1. **Stop all running containers first**
   - Open a PowerShell or Command Prompt window
   - Stop running Docker containers (optional but recommended):
     ```powershell
     wsl -d Ubuntu-22.04 -e bash -c "cd /home/locotoki/projects/alfred-agent-platform-v2 && docker compose down"
     ```

2. **Terminate the WSL distribution**
   - Open PowerShell as Administrator
   - Run:
     ```powershell
     wsl --terminate Ubuntu-22.04
     ```

3. **Verify the distribution is stopped**
   - Run:
     ```powershell
     wsl --list --verbose
     ```
   - Confirm Ubuntu-22.04 shows "Stopped" state

## Backup Options

### Option 1: Export Full WSL Distribution (From Windows)

The most reliable method is to export your entire WSL distribution to a file. This creates a complete backup that can be imported later if needed.

1. In PowerShell (as Administrator):
   ```powershell
   wsl --export Ubuntu-22.04 F:\WSLBackups\Ubuntu-22.04-backup-$(Get-Date -Format "yyyyMMdd").tar
   ```

2. Verify the backup was created:
   ```powershell
   Get-Item F:\WSLBackups\Ubuntu-22.04-backup-*.tar
   ```

3. This creates a `.tar` file containing your entire WSL environment that can be imported later if needed

### Option 2: Backup Specific Project Files (From Inside WSL)

If you only need to backup your Alfred Agent Platform v2 project:

1. Start WSL again:
   ```powershell
   wsl -d Ubuntu-22.04
   ```

2. Create a backup directory in a location accessible from Windows:
   ```bash
   mkdir -p /mnt/f/WSLBackups/alfred-platform
   ```

3. Create a tarball of the project:
   ```bash
   tar -czvf /mnt/f/WSLBackups/alfred-platform/alfred-backup-$(date +%Y%m%d).tar.gz -C /home/locotoki/projects alfred-agent-platform-v2
   ```

4. Backup Docker volumes (if needed):
   ```bash
   # First, list all volumes used by the project
   docker volume ls | grep alfred
   
   # Export important volumes (example for supabase-db-data)
   docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/f/WSLBackups/alfred-platform:/backup alpine tar -czvf /backup/db-backup-$(date +%Y%m%d).tar.gz -C /data .
   
   # Repeat for other important volumes
   ```

### Option 3: Docker Compose Project Backup

For a more targeted backup of just the Docker-related elements:

1. Create backup directories:
   ```bash
   mkdir -p /mnt/f/WSLBackups/alfred-platform/docker-config
   ```

2. Copy Docker configuration files:
   ```bash
   cp /home/locotoki/projects/alfred-agent-platform-v2/docker-compose.yml /mnt/f/WSLBackups/alfred-platform/docker-config/
   cp /home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.*.yml /mnt/f/WSLBackups/alfred-platform/docker-config/
   cp /home/locotoki/projects/alfred-agent-platform-v2/.env* /mnt/f/WSLBackups/alfred-platform/docker-config/
   ```

3. Export Docker volumes (most critical for database persistence):
   ```bash
   docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/f/WSLBackups/alfred-platform/volumes:/backup alpine tar -czvf /backup/supabase-db-data-$(date +%Y%m%d).tar.gz -C /data .
   ```

### Option 4: Database-only Backup

If you only need to backup the database:

```bash
# Create a directory for the backup
mkdir -p /mnt/f/WSLBackups/alfred-platform/database

# Get the database container ID 
DB_CONTAINER=$(docker ps -qf "name=supabase-db")

# Export the database
docker exec $DB_CONTAINER pg_dump -U postgres postgres > /mnt/f/WSLBackups/alfred-platform/database/alfred-db-backup-$(date +%Y%m%d).sql
```

## Backup Verification

To verify your backup:

1. For the database backup, check the SQL file size:
   ```bash
   ls -lh /mnt/f/WSLBackups/alfred-platform/database/
   ```
   If it's only a few bytes, the backup likely failed.

2. For project files, check the tarball:
   ```bash
   tar -tvf /mnt/f/WSLBackups/alfred-platform/alfred-backup-*.tar.gz | head
   ```
   This should show the files included in the backup.

## Restoration Process

### Restore Full WSL Distribution (Option 1)

1. **Import the distribution**
   - In PowerShell as Administrator:
     ```powershell
     wsl --import Ubuntu-22.04-Restored C:\path\to\new\location F:\WSLBackups\Ubuntu-22.04-backup-YYYYMMDD.tar
     ```

2. **Set the default user**
   - This is important because imported distributions typically default to root:
     ```powershell
     Ubuntu-22.04-Restored config --default-user locotoki
     ```
   - Note: You might need to install the Ubuntu app from the Microsoft Store for this command to work

### Restore Project Files (Option 2)

```bash
# Create target directory if needed
mkdir -p /home/locotoki/projects/

# Extract the backup
tar -xzvf /mnt/f/WSLBackups/alfred-platform/alfred-backup-YYYYMMDD.tar.gz -C /home/locotoki/projects/
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
docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/f/WSLBackups/alfred-platform:/backup alpine sh -c "cd /data && tar -xzvf /backup/db-backup-YYYYMMDD.tar.gz"

# Start containers again
docker-compose up -d
```

## After Backup/Restoration

To restart your WSL and the Alfred Agent Platform:

1. **Start WSL**
   ```powershell
   wsl -d Ubuntu-22.04
   ```

2. **Restart Docker containers**
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2
   docker compose -f docker-compose.yml -f docker-compose.override.mission-control.yml up -d
   ```

## Important Notes

1. Windows paths in WSL are accessed through `/mnt/c/` (for the C: drive) or similar mounts
2. Always verify your backups after creating them
3. Consider automating this process with a scheduled script for regular backups
4. Store backups in multiple locations (local and cloud) for redundancy
5. Remember to backup your Docker volumes - they contain persistent data like databases
6. The backup file for a full WSL distribution could be quite large (several GB)
7. If using the WSL export method, be aware that it requires Administrator privileges on Windows

## Regular Backup Schedule Recommendation

For a project like Alfred Agent Platform v2:

1. Daily: Database backups (SQL dumps)
2. Weekly: Full project code and volume backups
3. Monthly: Complete WSL distribution export

---

*This document was created on May 7, 2025 for the Alfred Agent Platform v2 project.*