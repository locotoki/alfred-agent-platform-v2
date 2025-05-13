# Authentication System for Alfred Agent Platform

This document provides an overview of the authentication system implemented for the Alfred Agent Platform v2.

## Components

The authentication system consists of the following components:

1. **Database with Auth Schema** - PostgreSQL database with Supabase's auth schema extensions
2. **Auth Service (GoTrue)** - Provides authentication endpoints and manages users
3. **Mail Server (MailHog)** - For testing email functionality in development
4. **Auth UI** - A simple web interface for testing authentication

## Setup

The authentication system is set up as part of the standard Docker Compose configuration. You don't need to do anything special to enable it.

### URLs and Ports

- **Auth Service API**: http://localhost:9999
- **Mail Server Web UI**: http://localhost:8025
- **Auth UI**: http://localhost:8030

## Usage

### User Registration

1. Open the Auth UI at http://localhost:8030
2. Click on the "Register" link
3. Fill in your email and password
4. Submit the form

For development, you can enable auto-confirmation of email addresses by setting:
```
GOTRUE_MAILER_AUTOCONFIRM=true
```

### User Login

1. Open the Auth UI at http://localhost:8030
2. Click on the "Login" link
3. Enter your email and password
4. Submit the form

### Password Reset

1. Open the Auth UI at http://localhost:8030
2. Click on the "Reset Password" link
3. Enter your email
4. Submit the form
5. Check the Mail Server UI at http://localhost:8025 for the reset email

## API Endpoints

The auth service provides the following key endpoints:

- `POST /signup` - Create a new user
- `POST /token` - Get a JWT token (login)
- `POST /logout` - Invalidate the current session
- `GET /user` - Get the current user information
- `PUT /user` - Update user information
- `POST /recover` - Start the password recovery process
- `POST /verify` - Verify an email or recovery token

## Integration with Other Services

### Headers for Authentication

When making requests to protected services, include the JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

### Environment Variables

Key environment variables for the auth service:

- `GOTRUE_JWT_SECRET` - Used to sign and verify JWT tokens
- `GOTRUE_DB_DATABASE_URL` - Connection string for the database
- `GOTRUE_SITE_URL` - The URL of your site (for redirects)
- `GOTRUE_MAILER_AUTOCONFIRM` - Whether to auto-confirm emails in development

## Development Notes

### Viewing Emails

In development, all emails sent by the system can be viewed in the MailHog UI at http://localhost:8025.

### Database Schema

The auth schema in PostgreSQL contains tables for:

- `users` - User accounts
- `identities` - User identities (email, phone, social, etc.)
- `refresh_tokens` - Tokens for refreshing JWTs
- `sessions` - User sessions
- `mfa_factors` - Multi-factor authentication settings
- `flow_state` - Authentication workflow state

### Testing

To test the authentication system:

1. Use the Auth UI to register a new user
2. Check that you receive a confirmation email in MailHog
3. Try logging in with the registered user
4. Test the password reset functionality

For API testing, you can use tools like curl, Postman, or Insomnia to interact with the auth service endpoints.

## Production Considerations

For production deployment, consider:

1. Setting `GOTRUE_MAILER_AUTOCONFIRM=false` to require email verification
2. Configuring a real SMTP server instead of MailHog
3. Setting a strong, unique `GOTRUE_JWT_SECRET` value
4. Adjusting JWT expiry settings to match your security requirements
5. Setting up proper CORS settings for your domains