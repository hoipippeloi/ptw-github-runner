#!/bin/bash

# Script to validate required environment variables
# This script is called during the Railway build process

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                VALIDATING REQUIRED ENVIRONMENT VARIABLES             ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

ERROR=0

# Check for REPO_URL
if [ -z "$REPO_URL" ]; then
    echo "❌ ERROR: REPO_URL is not set!"
    echo "   This variable is REQUIRED for deployment."
    echo "   Please set it in the Railway UI under the Variables tab."
    echo "   Format should be: https://github.com/owner/repo"
    ERROR=1
else
    echo "✅ REPO_URL is set: $REPO_URL"
    
    # Validate REPO_URL format
    if [[ ! "$REPO_URL" =~ ^https://github.com/[^/]+/[^/]+$ ]]; then
        echo "❌ ERROR: REPO_URL has invalid format!"
        echo "   The URL must be in the format: https://github.com/owner/repo"
        echo "   Current value: $REPO_URL"
        ERROR=1
    else
        echo "✅ REPO_URL format is valid"
    fi
fi

# Check for RUNNER_TOKEN
if [ -z "$RUNNER_TOKEN" ]; then
    echo "❌ ERROR: RUNNER_TOKEN is not set!"
    echo "   This variable is REQUIRED for deployment."
    echo "   Please set it in the Railway UI under the Variables tab."
    echo "   Get this token from GitHub repository Settings > Actions > Runners > New self-hosted runner"
    ERROR=1
else
    echo "✅ RUNNER_TOKEN is set"
fi

# Display summary
echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
if [ $ERROR -eq 0 ]; then
    echo "║                    ✅ ALL REQUIRED VARIABLES SET                    ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    exit 0
else
    echo "║                    ❌ MISSING REQUIRED VARIABLES                    ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Please set all required variables in the Railway UI before deployment."
    echo "1. Go to your service in the Railway dashboard"
    echo "2. Click on the 'Variables' tab"
    echo "3. Add the required variables"
    echo "4. Redeploy the service"
    exit 1
fi 