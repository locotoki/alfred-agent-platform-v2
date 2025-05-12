// Configuration for connecting to the auth service
const AUTH_API_URL = 'http://localhost:9999';

// Login function
async function login(email, password) {
    try {
        const response = await fetch(`${AUTH_API_URL}/token?grant_type=password`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email,
                password
            })
        });

        const data = await response.json();
        if (!response.ok) {
            return { error: data };
        }

        return { data };
    } catch (error) {
        return { error: { message: 'Network error, please try again.' } };
    }
}

// Register function
async function register(email, password) {
    try {
        const response = await fetch(`${AUTH_API_URL}/signup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email,
                password
            })
        });
        
        const data = await response.json();
        if (!response.ok) {
            return { error: data };
        }
        
        return { data };
    } catch (error) {
        return { error: { message: 'Network error, please try again.' } };
    }
}

// Reset password function
async function resetPassword(email) {
    try {
        const response = await fetch(`${AUTH_API_URL}/recover`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email
            })
        });
        
        if (response.status === 204) {
            return { data: { message: 'Password reset email sent' } };
        }
        
        const data = await response.json();
        if (!response.ok) {
            return { error: data };
        }
        
        return { data };
    } catch (error) {
        return { error: { message: 'Network error, please try again.' } };
    }
}

// Validate token
async function validateToken(token) {
    try {
        const response = await fetch(`${AUTH_API_URL}/user`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        const data = await response.json();
        if (!response.ok) {
            return { error: data };
        }
        
        return { data };
    } catch (error) {
        return { error: { message: 'Network error, please try again.' } };
    }
}