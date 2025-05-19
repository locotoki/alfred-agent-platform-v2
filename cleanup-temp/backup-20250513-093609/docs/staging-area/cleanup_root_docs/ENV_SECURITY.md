# Environment Variables and Security

This document provides guidelines for managing environment variables and security considerations for the Alfred Agent Platform v2.

## Environment Variables Management

### Overview

The platform uses environment variables for configuration, stored in a `.env` file. This file is excluded from version control using `.gitignore` to prevent leaking sensitive information like API keys and passwords.

### Security Best Practices

1. **Never commit sensitive information to Git**
   - The `.env` file is excluded from version control
   - Always use `.env.example` as a template with placeholder values
   - Create a local `.env` file with your actual credentials

2. **Key Management**
   - Rotate API keys and passwords regularly
   - Use different keys for development and production environments
   - Never share API keys in plaintext through email or chat

3. **Access Control**
   - Limit access to the `.env` file to only those who need it
   - Consider using a secret management solution for production environments

## Default Fallback Values

### Current Implementation

The Docker Compose configuration currently uses fallback values for some sensitive variables:

```yaml
- OPENAI_API_KEY=${ALFRED_OPENAI_API_KEY:-sk-mock-key-for-development-only}
```

### Security Considerations

Using default fallback values has pros and cons:

#### Pros
- Services start without errors even if not all keys are provided
- Development and testing are easier with mock values
- Clear indication (through naming) that these are not production keys

#### Cons
- Risk of accidentally using mock/default values in production
- Less visibility when a required key is missing
- May mask configuration issues

### Recommendation

For a more secure setup, consider:

1. Removing default fallback values for sensitive variables in production
2. Using the `check-env-vars.sh` script to validate all required variables before startup
3. Creating separate `.env.dev` and `.env.prod` files with appropriate settings for each environment

## Environment Variable Checker

The `check-env-vars.sh` script has been added to verify that all required environment variables are set before starting services. This script:

- Checks for the presence of critical variables
- Warns about optional variables that are missing
- Identifies default placeholder values that should be replaced in production
- Provides clear feedback about what needs to be fixed

Run this check before starting services:

```bash
./check-env-vars.sh
```

The `start-platform.sh` script now automatically runs this check before starting services.

## Internal Service Keys

### Current Implementation

Some internal service keys are directly specified in the Docker Compose configuration:

```yaml
- ALFRED_API_KEYS=atlas:atlas-key,alfred:alfred-key,financial:financial-key,legal:legal-key,social:social-key
- ALFRED_RAG_API_KEY=atlas-key
```

### Security Considerations

These internal keys are used for communication between services within the Docker network and present a lower security risk compared to external API keys because:

1. They're only accessible within the internal Docker network
2. They're used for service-to-service authentication, not external clients
3. These services aren't directly exposed to the internet

In a production environment, consider moving these to environment variables for easier management and rotation.

## Next Steps

1. **Environment Variable Audit**: Periodically review all environment variables to ensure only necessary ones are defined
2. **Secret Management**: Consider using a proper secret management solution for production
3. **Key Rotation**: Implement a key rotation schedule for all API keys and passwords
4. **Failing Fast**: In production, services should fail to start if critical variables are missing
