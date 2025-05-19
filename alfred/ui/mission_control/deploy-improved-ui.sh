#!/bin/bash
# Full deployment script for improved Niche-Scout UI

set -e  # Exit on error

# Print current directory and time
echo "Starting deployment at $(date)"
echo "Working directory: $(pwd)"

# 1. Stop any running services
echo "Stopping any running services..."
fuser -k 3007/tcp 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
docker stop mission-control 2>/dev/null || true

# 2. Update the code files
echo "Updating Niche-Scout interface..."
cp src/pages/workflows/niche-scout/index.improved.tsx src/pages/workflows/niche-scout/index.tsx

# 3. Verify CSS file exists
if [ -f "src/styles/niche-scout-improvements.css" ]; then
  echo "CSS file is in place"
else
  echo "Creating CSS file..."
  cat > src/styles/niche-scout-improvements.css << 'EOF'
/* Animation for step transitions */
.animate-fadeIn {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Enhanced form elements */
.input:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.5);
  transition: all 0.2s ease;
}

/* Card hover effects */
.card {
  transition: all 0.2s ease;
}

.card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

/* Tag/subcategory selection */
.subcategory-tag {
  transition: all 0.2s ease;
}

.subcategory-tag:hover {
  transform: translateY(-2px);
}

/* Wizard progress indicator animation */
.step-indicator {
  position: relative;
}

.step-indicator::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 0;
  height: 100%;
  background-color: rgba(59, 130, 246, 0.2);
  transition: width 0.5s ease;
}

.step-indicator.active::after {
  width: 100%;
}
EOF
fi

# 4. Check globals.css for import
if grep -q "niche-scout-improvements.css" src/styles/globals.css; then
  echo "CSS import already in globals.css"
else
  echo "Adding CSS import to globals.css..."
  sed -i '/@tailwind utilities;/a\
\
/* Import custom component styles */\
@import '\''./niche-scout-improvements.css'\'';' src/styles/globals.css
fi

# 5. Build and start the server
echo "Building the application..."
npm run build

echo "Starting Next.js server..."
nohup npm start > /tmp/mission-control.log 2>&1 &
echo $! > /tmp/mission-control.pid

echo "Deployment complete! Server running with PID: $(cat /tmp/mission-control.pid)"
echo "Access the application at: http://localhost:3007/workflows/niche-scout"
echo "Check /tmp/mission-control.log for any errors"
