# GHCR PAT Setup Guide for Coordinator

## What is GHCR_PAT?
A GitHub Personal Access Token (PAT) with permissions to push container images to the GitHub Container Registry (GHCR).

## Why is it needed?
- The default GITHUB_TOKEN in workflows has limited permissions
- PRs from forks don't have access to secrets for security reasons
- We need elevated permissions to push Docker images to GHCR

## Step-by-Step Setup

### 1. Create the Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)**
   - Direct link: https://github.com/settings/tokens

2. Click **"Generate new token"** → **"Generate new token (classic)"**

3. Configure the token:
   - **Note**: `GHCR Push for Alfred Platform`
   - **Expiration**: 90 days (or custom)
   - **Scopes**: Select these permissions:
     - ✅ `write:packages` - Upload packages to GitHub Package Registry
     - ✅ `read:packages` - Download packages from GitHub Package Registry
     - ✅ `delete:packages` - Delete packages from GitHub Package Registry (optional)

4. Click **"Generate token"**

5. **IMPORTANT**: Copy the token immediately (you won't see it again)
   - Example format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 2. Add Token to Repository Environments

1. Navigate to the repository settings:
   - Go to: https://github.com/locotoki/alfred-agent-platform-v2/settings
   - Click on **"Environments"** in the left sidebar

2. Create/Configure the **staging** environment:
   - Click on **"staging"** (or create it if it doesn't exist)
   - Under **"Environment secrets"**, click **"Add secret"**
   - Name: `GHCR_PAT`
   - Value: Paste the token you created
   - Click **"Add secret"**

3. Create/Configure the **prod** environment:
   - Click on **"prod"** (or create it if it doesn't exist)
   - Under **"Environment secrets"**, click **"Add secret"**
   - Name: `GHCR_PAT`
   - Value: Paste the same token
   - Click **"Add secret"**

### 3. Verify the Setup

After adding the secrets, verify:
- Both environments show `GHCR_PAT` in their secrets list
- The deploy workflow in PR #56 references `secrets.GHCR_PAT`

## Security Considerations

- Keep the PAT secure and never commit it to the repository
- Set an expiration date and rotate regularly
- Use environment-specific tokens if needed for production
- The token should only have the minimum required permissions

## Testing

After merging PR #56, the workflow will:
1. Run only on pushes to the main branch
2. Use the `GHCR_PAT` from the staging environment
3. Build and push images to GHCR automatically

## Troubleshooting

If the push still fails after setup:
1. Check the token has not expired
2. Verify the token has `write:packages` permission
3. Ensure the environment name matches exactly (`staging`, not `Staging`)
4. Check GitHub Actions logs for specific error messages

## Alternative: Fine-grained PAT

You can also use a fine-grained personal access token:
1. Go to Settings → Developer settings → Personal access tokens → **Fine-grained tokens**
2. Set repository access to `locotoki/alfred-agent-platform-v2`
3. Set permissions:
   - **Packages**: Read and Write
4. This provides more granular control over token permissions

🤖 Generated with [Claude Code](https://claude.ai/code)