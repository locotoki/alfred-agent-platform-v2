# Backup Steps for Ubuntu-22.04 WSL Distribution

## Preparation Steps (Do These From Windows)

1. **Stop all running containers first**
   - Open a PowerShell or Command Prompt window
   - Stop running Docker containers (optional but recommended):
     ```
     wsl -d Ubuntu-22.04 -e bash -c "cd /home/locotoki/projects/alfred-agent-platform-v2 && docker compose down"
     ```

2. **Terminate the WSL distribution**
   - Open PowerShell as Administrator
   - Run:
     ```
     wsl --terminate Ubuntu-22.04
     ```

3. **Verify the distribution is stopped**
   - Run:
     ```
     wsl --list --verbose
     ```
   - Confirm Ubuntu-22.04 shows "Stopped" state

## Backup Process

1. **Export the entire WSL distribution**
   - In PowerShell (still as Administrator):
     ```
     wsl --export Ubuntu-22.04 F:\WSLBackups\Ubuntu-22.04-backup-$(Get-Date -Format "yyyyMMdd").tar
     ```

2. **Verify the backup was created**
   - Check that the file exists and has a reasonable size:
     ```
     Get-Item F:\WSLBackups\Ubuntu-22.04-backup-*.tar
     ```

## Alternative: Targeted Project Backup

If you want a smaller backup of just the project (in addition to the full backup):

1. **Start WSL again**
   ```
   wsl -d Ubuntu-22.04
   ```

2. **Create a targeted backup**
   From inside WSL:
   ```bash
   mkdir -p /mnt/f/WSLBackups/alfred-platform
   
   # Backup project files
   tar -czvf /mnt/f/WSLBackups/alfred-platform/alfred-backup-$(date +%Y%m%d).tar.gz -C /home/locotoki/projects alfred-agent-platform-v2
   
   # Backup Docker volumes (optional)
   docker run --rm -v alfred-agent-platform-v2_supabase-db-data:/data -v /mnt/f/WSLBackups/alfred-platform:/backup alpine tar -czvf /backup/db-backup-$(date +%Y%m%d).tar.gz -C /data .
   ```

## Restoration Process

If you need to restore the backup:

1. **Import the distribution**
   - In PowerShell as Administrator:
     ```
     wsl --import Ubuntu-22.04-Restored C:\path\to\new\location F:\WSLBackups\Ubuntu-22.04-backup-YYYYMMDD.tar
     ```

2. **Set the default user**
   - This is important because imported distributions typically default to root:
     ```
     Ubuntu-22.04-Restored config --default-user locotoki
     ```
   - Note: You might need to install the Ubuntu app from the Microsoft Store for this command to work

## Important Notes

- The backup file could be quite large (several GB)
- Ensure there's enough space on the F: drive
- Full WSL distribution backups include everything: project files, Docker images, and volumes
- You may want to schedule regular backups using Windows Task Scheduler
- Consider copying important backups to cloud storage for redundancy

## After Backup

To restart your WSL and the Alfred Agent Platform:

1. **Start WSL**
   ```
   wsl -d Ubuntu-22.04
   ```

2. **Restart Docker containers**
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2
   docker compose -f docker-compose.yml -f docker-compose.override.mission-control.yml up -d
   ```