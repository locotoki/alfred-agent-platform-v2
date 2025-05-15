# Google A2A Authentication Implementation Plan

## Overview
This document outlines the implementation plan for Google Application-to-Application (A2A) authentication for the CrewAI service in Phase 7C. Google A2A authentication will provide secure service-to-service communication without requiring shared secrets.

## Architecture

### Components
1. **Service Accounts**: Google Cloud service accounts with appropriate IAM permissions
2. **Workload Identity Federation**: For services running outside GCP
3. **Authentication Client**: Python library for handling A2A authentication
4. **Middleware**: For validating incoming requests with Google A2A tokens
5. **Token Management**: Caching and refresh mechanisms for performance

### Flow Diagram
```
┌────────────┐         ┌─────────────┐         ┌──────────────┐
│            │ Request │             │ Validate │              │
│  Service A ├────────►│  Google IAM │◄────────┤  Service B   │
│            │ Token   │             │ Token    │              │
└────────────┘         └─────────────┘         └──────────────┘
       │                                               ▲
       │                                               │
       │            ┌─────────────────┐                │
       └───────────►│ Token Cache and │────────────────┘
                    │ Refresh Manager │
                    └─────────────────┘
```

## Implementation Steps

### 1. Google Cloud Setup
- Create service accounts for each service that will use A2A authentication
- Configure IAM permissions with the principle of least privilege
- Set up Workload Identity Federation for services running outside GCP
- Generate and securely store service account keys (if needed)

### 2. Client Library Implementation
```python
# google_a2a/client.py
import google.auth
from google.auth.transport.requests import Request
from google.oauth2 import service_account
import os
import time

class GoogleA2AClient:
    def __init__(self, service_account_file=None):
        """Initialize the Google A2A client."""
        self.credentials = None
        self.token_expiry = 0
        self.token_cache = None
        
        # Use service account file if provided, otherwise use default credentials
        if service_account_file:
            self.credentials = service_account.Credentials.from_service_account_file(
                service_account_file,
                scopes=['https://www.googleapis.com/auth/cloud-platform']
            )
        else:
            # Use application default credentials
            self.credentials, _ = google.auth.default(
                scopes=['https://www.googleapis.com/auth/cloud-platform']
            )
    
    def get_token(self, force_refresh=False):
        """Get an OAuth token for authentication, with caching."""
        current_time = time.time()
        
        # Check if token is still valid and not forcing refresh
        if not force_refresh and self.token_cache and current_time < self.token_expiry - 300:
            return self.token_cache
        
        # Token expired or force refresh, get a new one
        if not self.credentials.valid or force_refresh:
            request = Request()
            self.credentials.refresh(request)
        
        # Update cache and expiry
        self.token_cache = self.credentials.token
        self.token_expiry = current_time + self.credentials.expiry
        
        return self.token_cache
    
    def add_auth_headers(self, headers=None):
        """Add authentication headers to the request."""
        if headers is None:
            headers = {}
        
        token = self.get_token()
        headers['Authorization'] = f'Bearer {token}'
        
        return headers
```

### 3. Flask Middleware Implementation
```python
# google_a2a/middleware.py
from functools import wraps
from flask import request, jsonify
from google.oauth2 import id_token
from google.auth.transport import requests

def verify_a2a_token(audience=None):
    """Decorator to verify Google A2A tokens in incoming requests."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            auth_header = request.headers.get('Authorization', '')
            
            if not auth_header.startswith('Bearer '):
                return jsonify({'error': 'Invalid authorization header'}), 401
            
            token = auth_header.split(' ')[1]
            
            try:
                # Verify the token
                request_adapter = requests.Request()
                id_info = id_token.verify_oauth2_token(token, request_adapter, audience)
                
                # Add the validated identity to the request context
                request.a2a_identity = id_info
                
                return f(*args, **kwargs)
            except Exception as e:
                return jsonify({'error': f'Invalid token: {str(e)}'}), 401
        
        return decorated_function
    return decorator
```

### 4. FastAPI Middleware Implementation
```python
# google_a2a/fastapi_middleware.py
from fastapi import Request, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from google.oauth2 import id_token
from google.auth.transport import requests

security = HTTPBearer()

async def verify_a2a_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    audience: str = None
):
    """FastAPI dependency for verifying Google A2A tokens."""
    token = credentials.credentials
    
    try:
        # Verify the token
        request_adapter = requests.Request()
        id_info = id_token.verify_oauth2_token(token, request_adapter, audience)
        
        return id_info
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid authentication token: {str(e)}"
        )
```

### 5. Integration with CrewAI
```python
# crew_service.py
from fastapi import FastAPI, Depends, HTTPException
from google_a2a.fastapi_middleware import verify_a2a_token
from google_a2a.client import GoogleA2AClient
import os

app = FastAPI()

# Initialize the Google A2A client
a2a_client = GoogleA2AClient(
    service_account_file=os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
)

@app.post("/api/crews")
async def create_crew(
    crew_data: dict,
    identity: dict = Depends(verify_a2a_token)
):
    """Create a new crew with A2A authentication."""
    # Validate caller's identity
    caller_service = identity.get("service_name")
    if caller_service not in ["service-a", "service-b"]:
        raise HTTPException(
            status_code=403,
            detail="Service not authorized to create crews"
        )
    
    # Process the crew creation
    # ...
    
    return {"status": "success", "crew_id": "new-crew-id"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint (no authentication required)."""
    return {"status": "healthy"}
```

### 6. Configuration Management
```python
# settings.py
import os
from pydantic import BaseSettings

class GoogleA2ASettings(BaseSettings):
    """Google A2A authentication settings."""
    # Service account settings
    GOOGLE_APPLICATION_CREDENTIALS: str = os.environ.get(
        "GOOGLE_APPLICATION_CREDENTIALS", "/app/secrets/service-account.json"
    )
    
    # Audience configuration for token validation
    A2A_AUDIENCE: str = os.environ.get(
        "A2A_AUDIENCE", "https://crew-service.alfred.io"
    )
    
    # Token refresh settings
    TOKEN_REFRESH_MARGIN_SECONDS: int = int(os.environ.get(
        "TOKEN_REFRESH_MARGIN_SECONDS", "300"
    ))
    
    # Identity management
    ALLOWED_SERVICES: list = os.environ.get(
        "ALLOWED_SERVICES", "service-a,service-b"
    ).split(",")
    
    class Config:
        env_file = ".env"
```

## Testing Plan

### Unit Tests
1. Test token generation and caching
2. Test middleware token validation
3. Test error handling for invalid tokens
4. Test permission handling based on service identity

### Integration Tests
1. Test service-to-service communication with A2A authentication
2. Test token refresh scenarios
3. Test performance impact of token validation
4. Test error scenarios (network issues, expired tokens, etc.)

### Security Tests
1. Test with invalid tokens
2. Test with expired tokens
3. Test with tokens from unauthorized services
4. Test for proper handling of sensitive information

## Deployment Considerations

### Environment Variables
```
# Required for service account authentication
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Service-specific configuration
A2A_AUDIENCE=https://crew-service.alfred.io
ALLOWED_SERVICES=service-a,service-b

# Performance tuning
TOKEN_REFRESH_MARGIN_SECONDS=300
```

### Security Best Practices
1. Store service account keys as Kubernetes secrets
2. Rotate service account keys regularly
3. Use the principle of least privilege for IAM permissions
4. Implement proper logging for authentication events
5. Set up monitoring for authentication failures

## Next Steps
1. Create Google Cloud service accounts
2. Implement the A2A client library
3. Create middleware for Flask and FastAPI
4. Integrate with CrewAI service
5. Deploy to staging environment
6. Conduct testing and security review
7. Deploy to production