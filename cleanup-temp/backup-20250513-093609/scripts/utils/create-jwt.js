// Quick script to generate a JWT token for Supabase using the default secret
const crypto = require('crypto');

// JWT header
const header = {
  alg: 'HS256',
  typ: 'JWT'
};

// JWT payload
const payload = {
  role: 'service_role',
  exp: Math.floor(Date.now() / 1000) + 3600 * 24 * 30  // 30 days
};

// Encode JWT header and payload
const encodeBase64Url = (obj) => {
  return Buffer.from(JSON.stringify(obj))
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
};

const encodedHeader = encodeBase64Url(header);
const encodedPayload = encodeBase64Url(payload);

// Create signature
const jwtSecret = 'your-super-secret-jwt-token-with-at-least-32-characters-long';
const signature = crypto
  .createHmac('sha256', jwtSecret)
  .update(`${encodedHeader}.${encodedPayload}`)
  .digest('base64')
  .replace(/=/g, '')
  .replace(/\+/g, '-')
  .replace(/\//g, '_');

// Create JWT token
const jwtToken = `${encodedHeader}.${encodedPayload}.${signature}`;

console.log(`SUPABASE_SERVICE_ROLE_KEY=${jwtToken}`);
