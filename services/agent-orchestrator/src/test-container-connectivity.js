// Test connectivity to social-intel service from within the container
console.log('Testing connectivity to social-intel service...');

fetch('http://social-intel:9000/health/')
  .then(response => {
    console.log('Response status:', response.status);
    return response.json();
  })
  .then(data => {
    console.log('Response data:', data);
    console.log('Social Intelligence service is available.');
  })
  .catch(error => {
    console.error('Error connecting to social-intel:', error.message);
    console.log('Social Intelligence service is unavailable.');
  });
