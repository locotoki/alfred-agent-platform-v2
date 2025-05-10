// Wait for page to load
document.addEventListener('DOMContentLoaded', () => {
  console.log('Test script loaded');

  // Find the RUN NOW button and click it after 2 seconds
  setTimeout(() => {
    const runButton = document.querySelector('button.btn-primary');
    if (runButton && runButton.textContent.includes('RUN NOW')) {
      console.log('Clicking RUN NOW button');
      runButton.click();
    } else {
      console.log('RUN NOW button not found');
    }
  }, 2000);
});